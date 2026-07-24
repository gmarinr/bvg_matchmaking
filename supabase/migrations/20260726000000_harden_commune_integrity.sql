-- Complete the commune catalog migration without inventing values for legacy
-- profiles whose free-text commune cannot be matched safely.

update public.profiles p
set commune_code = c.code,
    commune = c.name
from public.communes c
where p.commune_code is null
  and lower(btrim(p.commune)) = lower(c.name)
  and c.is_active;

update public.matches m
set commune_code = c.code,
    commune = c.name
from public.communes c
where m.commune_code is null
  and lower(btrim(m.commune)) = lower(c.name)
  and c.is_active;

-- Invalid legacy profile text is retained as an incomplete profile rather than
-- being mapped to an invented commune. The onboarding flow will require a new
-- catalog selection before the profile can be used normally.
update public.profiles
set commune = '',
    commune_code = null
where commune_code is null
  and btrim(commune) <> '';

alter table public.profiles
  validate constraint profiles_commune_catalog_check;

alter table public.matches
  validate constraint matches_commune_catalog_check;

create or replace function public.normalize_commune_catalog_value()
returns trigger
language plpgsql
set search_path = public
as $$
declare
  v_name text;
begin
  if new.commune_code is null then
    if tg_table_name = 'matches' or btrim(new.commune) <> '' then
      raise exception 'A catalog commune is required'
        using errcode = '23514';
    end if;
    new.commune = '';
    return new;
  end if;

  select name
  into v_name
  from public.communes
  where code = new.commune_code
    and is_active;

  if v_name is null then
    raise exception 'The selected commune is not active'
      using errcode = '23503';
  end if;

  -- The display name is derived from the code so the two columns cannot drift.
  new.commune = v_name;
  return new;
end;
$$;

drop trigger if exists profiles_normalize_commune_catalog
on public.profiles;
create trigger profiles_normalize_commune_catalog
before insert or update of commune, commune_code on public.profiles
for each row execute function public.normalize_commune_catalog_value();

drop trigger if exists matches_normalize_commune_catalog
on public.matches;
create trigger matches_normalize_commune_catalog
before insert or update of commune, commune_code on public.matches
for each row execute function public.normalize_commune_catalog_value();

revoke all on function public.normalize_commune_catalog_value() from public;

comment on function public.normalize_commune_catalog_value() is
  'Canonicalizes commune display names from the active commune catalog.';
