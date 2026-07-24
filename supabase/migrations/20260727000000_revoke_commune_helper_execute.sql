-- Trigger-only helper; it must not be callable through the public API.
revoke execute on function public.normalize_commune_catalog_value()
  from public, anon, authenticated, service_role;
