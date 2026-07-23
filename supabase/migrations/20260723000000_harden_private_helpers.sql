-- Keep database helper functions outside the exposed public API schema.

create schema if not exists private;
revoke all on schema private from public;
grant usage on schema private to authenticated;

create or replace function private.is_match_organizer(p_match_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, private
as $$
  select exists (
    select 1
    from public.matches
    where id = p_match_id and organizer_id = (select auth.uid())
  );
$$;

create or replace function private.is_accepted_participant(p_match_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, private
as $$
  select exists (
    select 1
    from public.match_participations
    where match_id = p_match_id
      and user_id = (select auth.uid())
      and participation_status = 'accepted'
  );
$$;

create or replace function private.accepted_participant_count(p_match_id uuid)
returns integer
language sql
stable
security definer
set search_path = public, private
as $$
  select count(*)::integer
  from public.match_participations
  where match_id = p_match_id
    and participation_status = 'accepted';
$$;

revoke all on function private.is_match_organizer(uuid) from public;
revoke all on function private.is_accepted_participant(uuid) from public;
revoke all on function private.accepted_participant_count(uuid) from public;
grant execute on function private.is_match_organizer(uuid) to authenticated;
grant execute on function private.is_accepted_participant(uuid) to authenticated;
grant execute on function private.accepted_participant_count(uuid) to authenticated;

revoke all on function public.is_match_organizer(uuid) from public;
revoke all on function public.is_accepted_participant(uuid) from public;
revoke all on function public.accepted_participant_count(uuid) from public;
revoke all on function public.handle_new_user() from public;
revoke all on function public.create_organizer_participation() from public;
revoke all on function public.validate_participation_change() from public;
revoke all on function public.sync_match_capacity() from public;

create index if not exists matches_organizer_idx
  on public.matches (organizer_id);

create index if not exists matches_sport_idx
  on public.matches (sport_id);

create index if not exists user_sports_sport_idx
  on public.user_sports (sport_id);

create or replace view public.matches_with_counts
with (security_invoker = true)
as
select
  m.*,
  private.accepted_participant_count(m.id) as accepted_count
from public.matches m;

drop policy if exists profiles_select_own on public.profiles;
create policy profiles_select_own
on public.profiles for select to authenticated
using (id = (select auth.uid()));

drop policy if exists profiles_insert_own on public.profiles;
create policy profiles_insert_own
on public.profiles for insert to authenticated
with check (id = (select auth.uid()));

drop policy if exists profiles_update_own on public.profiles;
create policy profiles_update_own
on public.profiles for update to authenticated
using (id = (select auth.uid()))
with check (id = (select auth.uid()));

drop policy if exists user_sports_select_own on public.user_sports;
create policy user_sports_select_own
on public.user_sports for select to authenticated
using (user_id = (select auth.uid()));

drop policy if exists user_sports_insert_own on public.user_sports;
create policy user_sports_insert_own
on public.user_sports for insert to authenticated
with check (user_id = (select auth.uid()));

drop policy if exists user_sports_update_own on public.user_sports;
create policy user_sports_update_own
on public.user_sports for update to authenticated
using (user_id = (select auth.uid()))
with check (user_id = (select auth.uid()));

drop policy if exists user_sports_delete_own on public.user_sports;
create policy user_sports_delete_own
on public.user_sports for delete to authenticated
using (user_id = (select auth.uid()));

drop policy if exists matches_select_published_or_related on public.matches;
create policy matches_select_published_or_related
on public.matches for select to authenticated
using (
  organizer_id = (select auth.uid())
  or status in ('open', 'full')
  or (select private.is_accepted_participant(id))
);

drop policy if exists matches_insert_own on public.matches;
create policy matches_insert_own
on public.matches for insert to authenticated
with check (organizer_id = (select auth.uid()));

drop policy if exists matches_update_own on public.matches;
create policy matches_update_own
on public.matches for update to authenticated
using (organizer_id = (select auth.uid()))
with check (organizer_id = (select auth.uid()));

drop policy if exists match_participations_select_related
on public.match_participations;
create policy match_participations_select_related
on public.match_participations for select to authenticated
using (
  user_id = (select auth.uid())
  or (select private.is_match_organizer(match_id))
);

drop policy if exists match_participations_insert_own
on public.match_participations;
create policy match_participations_insert_own
on public.match_participations for insert to authenticated
with check (user_id = (select auth.uid()) and role = 'participant');

drop policy if exists match_participations_update_related
on public.match_participations;
create policy match_participations_update_related
on public.match_participations for update to authenticated
using (
  user_id = (select auth.uid())
  or (select private.is_match_organizer(match_id))
)
with check (
  user_id = (select auth.uid())
  or (select private.is_match_organizer(match_id))
);
