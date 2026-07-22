-- Match Making MVP schema.
-- The wire values mirror lib/core/domain/enums.dart.

create type public.match_status as enum (
  'draft',
  'open',
  'full',
  'confirmed',
  'completed',
  'cancelled'
);

create type public.recruitment_mode as enum (
  'players',
  'rival_team'
);

create type public.skill_level as enum (
  'beginner',
  'intermediate',
  'advanced'
);

create type public.participant_role as enum (
  'organizer',
  'participant'
);

create type public.participation_status as enum (
  'pending',
  'accepted',
  'rejected',
  'cancelled'
);

create type public.attendance_status as enum (
  'unknown',
  'confirmed',
  'declined'
);

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default '',
  commune text not null default '',
  avatar_url text,
  general_availability text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint profiles_display_name_length check (char_length(display_name) <= 80),
  constraint profiles_commune_length check (char_length(commune) <= 80)
);

create table public.sports (
  id text primary key,
  name text not null unique,
  is_active boolean not null default true
);

create table public.user_sports (
  user_id uuid not null references auth.users(id) on delete cascade,
  sport_id text not null references public.sports(id),
  skill_level public.skill_level not null,
  primary key (user_id, sport_id)
);

create table public.matches (
  id uuid primary key default gen_random_uuid(),
  organizer_id uuid not null references auth.users(id),
  sport_id text not null references public.sports(id),
  title text not null,
  description text,
  start_at timestamptz not null,
  commune text not null,
  location_text text not null,
  skill_level public.skill_level not null,
  min_participants integer not null,
  max_participants integer not null,
  status public.match_status not null default 'draft',
  recruitment_mode public.recruitment_mode not null default 'players',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint matches_title_length check (char_length(btrim(title)) between 1 and 120),
  constraint matches_description_length check (description is null or char_length(description) <= 2000),
  constraint matches_commune_length check (char_length(btrim(commune)) between 1 and 80),
  constraint matches_location_length check (char_length(btrim(location_text)) between 1 and 200),
  constraint matches_participant_range check (
    min_participants >= 1 and max_participants >= min_participants
  )
);

create table public.match_participations (
  id uuid primary key default gen_random_uuid(),
  match_id uuid not null references public.matches(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role public.participant_role not null,
  participation_status public.participation_status not null default 'pending',
  attendance_status public.attendance_status not null default 'unknown',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint match_participations_match_user_unique unique (match_id, user_id)
);

create index matches_search_idx
  on public.matches (status, sport_id, commune, start_at);

create index match_participations_user_idx
  on public.match_participations (user_id, participation_status);

create index match_participations_match_idx
  on public.match_participations (match_id, participation_status);

insert into public.sports (id, name)
values
  ('futbol', 'Futbol'),
  ('basquetbol', 'Basquetbol'),
  ('tenis', 'Tenis'),
  ('padel', 'Padel'),
  ('voleibol', 'Voleibol')
on conflict (id) do update
set name = excluded.name, is_active = true;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger profiles_set_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

create trigger matches_set_updated_at
before update on public.matches
for each row execute function public.set_updated_at();

create trigger match_participations_set_updated_at
before update on public.match_participations
for each row execute function public.set_updated_at();

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, display_name, commune)
  values (
    new.id,
    coalesce(
      nullif(btrim(new.raw_user_meta_data ->> 'display_name'), ''),
      split_part(coalesce(new.email, ''), '@', 1)
    ),
    ''
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

create or replace function public.create_organizer_participation()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.match_participations (
    match_id,
    user_id,
    role,
    participation_status,
    attendance_status
  )
  values (
    new.id,
    new.organizer_id,
    'organizer',
    'accepted',
    'unknown'
  );
  return new;
end;
$$;

create trigger matches_create_organizer_participation
after insert on public.matches
for each row execute function public.create_organizer_participation();

create or replace function public.is_match_organizer(p_match_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.matches
    where id = p_match_id and organizer_id = auth.uid()
  );
$$;

create or replace function public.is_accepted_participant(p_match_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.match_participations
    where match_id = p_match_id
      and user_id = auth.uid()
      and participation_status = 'accepted'
  );
$$;

create or replace function public.accepted_participant_count(p_match_id uuid)
returns integer
language sql
stable
security definer
set search_path = public
as $$
  select count(*)::integer
  from public.match_participations
  where match_id = p_match_id
    and participation_status = 'accepted';
$$;

revoke all on function public.is_match_organizer(uuid) from public;
revoke all on function public.is_accepted_participant(uuid) from public;
revoke all on function public.accepted_participant_count(uuid) from public;
grant execute on function public.is_match_organizer(uuid) to authenticated;
grant execute on function public.is_accepted_participant(uuid) to authenticated;
grant execute on function public.accepted_participant_count(uuid) to authenticated;

create or replace function public.validate_match_status_transition()
returns trigger
language plpgsql
set search_path = public
as $$
declare
  v_accepted_count integer;
begin
  if tg_op = 'INSERT' then
    if new.status not in ('draft', 'open') then
      raise exception 'A new match must start as draft or open'
        using errcode = 'P0001';
    end if;
    return new;
  end if;

  if new.status <> old.status and not (
    (old.status = 'draft' and new.status in ('open', 'cancelled')) or
    (old.status = 'open' and new.status in ('full', 'confirmed', 'cancelled')) or
    (old.status = 'full' and new.status in ('open', 'confirmed', 'cancelled')) or
    (old.status = 'confirmed' and new.status in ('completed', 'cancelled'))
  ) then
    raise exception 'Invalid match status transition from % to %', old.status, new.status
      using errcode = 'P0001';
  end if;

  select count(*)::integer
  into v_accepted_count
  from public.match_participations
  where match_id = new.id
    and participation_status = 'accepted';

  if v_accepted_count > new.max_participants then
    raise exception 'Maximum participants cannot be below current participation'
      using errcode = 'P0001';
  end if;

  if new.status = 'full' and v_accepted_count < new.max_participants then
    raise exception 'A match can be full only at maximum capacity'
      using errcode = 'P0001';
  end if;

  if new.status = 'open' and v_accepted_count >= new.max_participants then
    raise exception 'A match with no free slots cannot be open'
      using errcode = 'P0001';
  end if;

  if new.status = 'confirmed' and v_accepted_count < new.min_participants then
    raise exception 'A match needs its minimum participants before confirmation'
      using errcode = 'P0001';
  end if;

  return new;
end;
$$;

create trigger matches_validate_status_transition
before insert or update of status, min_participants, max_participants
on public.matches
for each row execute function public.validate_match_status_transition();

create or replace function public.validate_participation_change()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_match public.matches%rowtype;
  v_accepted_count integer;
begin
  if tg_op = 'INSERT' then
    select * into v_match
    from public.matches
    where id = new.match_id
    for update;

    if new.role = 'organizer' then
      if new.user_id <> v_match.organizer_id
         or new.participation_status <> 'accepted'
         or new.attendance_status <> 'unknown' then
        raise exception 'Invalid organizer participation'
          using errcode = 'P0001';
      end if;
    elsif new.role = 'participant' then
      if new.user_id = v_match.organizer_id
         or new.participation_status <> 'pending'
         or new.attendance_status <> 'unknown'
         or v_match.status <> 'open' then
        raise exception 'This match does not accept this participation request'
          using errcode = 'P0001';
      end if;
    else
      raise exception 'Invalid participation role'
        using errcode = 'P0001';
    end if;

    return new;
  end if;

  if new.match_id <> old.match_id
     or new.user_id <> old.user_id
     or new.role <> old.role then
    raise exception 'Participation identity cannot change'
      using errcode = 'P0001';
  end if;

  select * into v_match
  from public.matches
  where id = new.match_id
  for update;

  if new.participation_status is distinct from old.participation_status then
    if auth.uid() = v_match.organizer_id then
      if old.participation_status <> 'pending'
         or new.participation_status not in ('accepted', 'rejected')
         or old.role <> 'participant' then
        raise exception 'The organizer can only answer pending requests'
          using errcode = 'P0001';
      end if;
    elsif auth.uid() = old.user_id then
      if old.role <> 'participant'
         or old.participation_status not in ('pending', 'accepted')
         or new.participation_status <> 'cancelled' then
        raise exception 'A participant can only cancel their own participation'
          using errcode = 'P0001';
      end if;
    else
      raise exception 'The user cannot change this participation'
        using errcode = 'P0001';
    end if;
  end if;

  if new.attendance_status is distinct from old.attendance_status then
    if auth.uid() <> old.user_id
       or old.role <> 'participant'
       or old.participation_status <> 'accepted'
       or new.attendance_status not in ('confirmed', 'declined') then
      raise exception 'Only an accepted participant can update attendance'
        using errcode = 'P0001';
    end if;
  end if;

  if new.participation_status = 'accepted'
     and old.participation_status <> 'accepted' then
    if v_match.status <> 'open' then
      raise exception 'This match is not accepting participants'
        using errcode = 'P0001';
    end if;

    select count(*)::integer
    into v_accepted_count
    from public.match_participations
    where match_id = new.match_id
      and participation_status = 'accepted';

    if v_accepted_count >= v_match.max_participants then
      raise exception 'This match has no free slots'
        using errcode = 'P0001';
    end if;
  end if;

  return new;
end;
$$;

create trigger match_participations_validate_change
before insert or update on public.match_participations
for each row execute function public.validate_participation_change();

create or replace function public.sync_match_capacity()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_match public.matches%rowtype;
  v_accepted_count integer;
begin
  select * into v_match
  from public.matches
  where id = new.match_id
  for update;

  select count(*)::integer
  into v_accepted_count
  from public.match_participations
  where match_id = new.match_id
    and participation_status = 'accepted';

  if v_match.status in ('open', 'full') then
    update public.matches
    set status = case
      when v_accepted_count >= v_match.max_participants then 'full'::public.match_status
      else 'open'::public.match_status
    end
    where id = v_match.id;
  end if;

  return new;
end;
$$;

create trigger match_participations_sync_capacity
after insert or update of participation_status on public.match_participations
for each row execute function public.sync_match_capacity();

create view public.matches_with_counts
with (security_invoker = true)
as
select
  m.*,
  public.accepted_participant_count(m.id) as accepted_count
from public.matches m;

alter table public.profiles enable row level security;
alter table public.sports enable row level security;
alter table public.user_sports enable row level security;
alter table public.matches enable row level security;
alter table public.match_participations enable row level security;

create policy profiles_select_own
on public.profiles for select to authenticated
using (id = auth.uid());

create policy profiles_insert_own
on public.profiles for insert to authenticated
with check (id = auth.uid());

create policy profiles_update_own
on public.profiles for update to authenticated
using (id = auth.uid())
with check (id = auth.uid());

create policy sports_select_active
on public.sports for select to authenticated
using (is_active = true);

create policy user_sports_select_own
on public.user_sports for select to authenticated
using (user_id = auth.uid());

create policy user_sports_insert_own
on public.user_sports for insert to authenticated
with check (user_id = auth.uid());

create policy user_sports_update_own
on public.user_sports for update to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

create policy user_sports_delete_own
on public.user_sports for delete to authenticated
using (user_id = auth.uid());

create policy matches_select_published_or_related
on public.matches for select to authenticated
using (
  organizer_id = auth.uid()
  or status in ('open', 'full')
  or public.is_accepted_participant(id)
);

create policy matches_insert_own
on public.matches for insert to authenticated
with check (organizer_id = auth.uid());

create policy matches_update_own
on public.matches for update to authenticated
using (organizer_id = auth.uid())
with check (organizer_id = auth.uid());

create policy match_participations_select_related
on public.match_participations for select to authenticated
using (user_id = auth.uid() or public.is_match_organizer(match_id));

create policy match_participations_insert_own
on public.match_participations for insert to authenticated
with check (user_id = auth.uid() and role = 'participant');

create policy match_participations_update_related
on public.match_participations for update to authenticated
using (user_id = auth.uid() or public.is_match_organizer(match_id))
with check (user_id = auth.uid() or public.is_match_organizer(match_id));

grant usage on schema public to authenticated;
grant select, insert, update on public.profiles to authenticated;
grant select on public.sports to authenticated;
grant select, insert, update, delete on public.user_sports to authenticated;
grant select, insert, update on public.matches to authenticated;
grant select, insert, update on public.match_participations to authenticated;
grant select on public.matches_with_counts to authenticated;
