-- Supabase grants API roles explicitly, so revoke them by role as well as PUBLIC.

revoke execute on function public.is_match_organizer(uuid)
  from anon, authenticated, service_role;
revoke execute on function public.is_accepted_participant(uuid)
  from anon, authenticated, service_role;
revoke execute on function public.accepted_participant_count(uuid)
  from anon, authenticated, service_role;
revoke execute on function public.handle_new_user()
  from anon, authenticated, service_role;
revoke execute on function public.create_organizer_participation()
  from anon, authenticated, service_role;
revoke execute on function public.validate_participation_change()
  from anon, authenticated, service_role;
revoke execute on function public.sync_match_capacity()
  from anon, authenticated, service_role;
