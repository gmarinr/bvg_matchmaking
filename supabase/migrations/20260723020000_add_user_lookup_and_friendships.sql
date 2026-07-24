-- Safe exact user lookup and friendship requests.
--
-- This migration intentionally exposes only a minimal public profile.
-- It never returns email, auth metadata, avatar_url or general_availability.

create type public.friendship_status as enum (
  'pending',
  'accepted',
  'rejected',
  'cancelled'
);

create table public.friendships (
  id uuid primary key default gen_random_uuid(),
  requester_id uuid not null references public.profiles(id) on delete cascade,
  addressee_id uuid not null references public.profiles(id) on delete cascade,
  status public.friendship_status not null default 'pending',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint friendships_different_users check (requester_id <> addressee_id)
);

-- Only one pending request or accepted friendship can exist for a pair,
-- regardless of which user initiated it. Rejected/cancelled rows remain as
-- history and do not prevent a later new request.
create unique index friendships_active_pair_unique
  on public.friendships (
    least(requester_id, addressee_id),
    greatest(requester_id, addressee_id)
  )
  where status in ('pending', 'accepted');

create index friendships_requester_status_idx
  on public.friendships (requester_id, status, updated_at desc);

create index friendships_addressee_status_idx
  on public.friendships (addressee_id, status, updated_at desc);

create trigger friendships_set_updated_at
before update on public.friendships
for each row execute function public.set_updated_at();

create or replace function private.validate_friendship_change()
returns trigger
language plpgsql
security definer
set search_path = public, private
as $$
declare
  v_user_id uuid := (select auth.uid());
begin
  if v_user_id is null then
    raise exception 'Authentication is required'
      using errcode = '42501';
  end if;

  if tg_op = 'INSERT' then
    if new.requester_id <> v_user_id
       or new.requester_id = new.addressee_id
       or new.status <> 'pending' then
      raise exception 'Invalid friendship request'
        using errcode = '42501';
    end if;

    return new;
  end if;

  if new.id <> old.id
     or new.requester_id <> old.requester_id
     or new.addressee_id <> old.addressee_id
     or new.created_at <> old.created_at then
    raise exception 'Friendship identity cannot change'
      using errcode = 'P0001';
  end if;

  if old.status = 'pending' then
    if v_user_id = old.addressee_id
       and new.status in ('accepted', 'rejected') then
      return new;
    end if;

    if v_user_id = old.requester_id
       and new.status = 'cancelled' then
      return new;
    end if;
  elsif old.status = 'accepted' then
    if v_user_id in (old.requester_id, old.addressee_id)
       and new.status = 'cancelled' then
      return new;
    end if;
  end if;

  raise exception 'Invalid friendship status transition'
    using errcode = '42501';
end;
$$;

revoke all on function private.validate_friendship_change()
  from public, anon, authenticated, service_role;

create trigger friendships_validate_change
before insert or update on public.friendships
for each row execute function private.validate_friendship_change();

alter table public.friendships enable row level security;

create policy friendships_select_participant
on public.friendships for select to authenticated
using (
  requester_id = (select auth.uid())
  or addressee_id = (select auth.uid())
);

create policy friendships_insert_as_requester
on public.friendships for insert to authenticated
with check (
  requester_id = (select auth.uid())
  and addressee_id <> (select auth.uid())
  and status = 'pending'
);

create policy friendships_update_participant
on public.friendships for update to authenticated
using (
  requester_id = (select auth.uid())
  or addressee_id = (select auth.uid())
)
with check (
  requester_id = (select auth.uid())
  or addressee_id = (select auth.uid())
);

grant usage on type public.friendship_status to authenticated;
grant select, insert, update on public.friendships to authenticated;

-- Exact lookup used after a user shares their UUID externally. SECURITY
-- DEFINER is required because profiles and user_sports are otherwise private
-- to their owner. The returned shape is deliberately restricted.
create or replace function public.find_public_profile_by_id(p_user_id uuid)
returns table (
  id uuid,
  display_name text,
  commune text,
  sports jsonb
)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select
    p.id,
    p.display_name,
    p.commune,
    coalesce(
      (
        select jsonb_agg(
          jsonb_build_object(
            'id', s.id,
            'name', s.name,
            'skill_level', us.skill_level
          )
          order by s.name
        )
        from public.user_sports us
        join public.sports s on s.id = us.sport_id
        where us.user_id = p.id
          and s.is_active = true
      ),
      '[]'::jsonb
    ) as sports
  from public.profiles p
  where (select auth.uid()) is not null
    and p.id = p_user_id;
$$;

revoke all on function public.find_public_profile_by_id(uuid) from public;
revoke execute on function public.find_public_profile_by_id(uuid)
  from anon, service_role;
grant execute on function public.find_public_profile_by_id(uuid)
  to authenticated;
