-- Controlled commune catalog. The application stores the DPA code while
-- keeping the current display name columns during the migration period.
create table public.communes (
  code text primary key,
  name text not null unique,
  province text not null,
  region text not null,
  is_active boolean not null default true,
  constraint communes_code_length check (char_length(btrim(code)) between 4 and 8),
  constraint communes_name_length check (char_length(btrim(name)) between 1 and 80)
);

insert into public.communes (code, name, province, region)
values
  ('rm0101', 'Santiago', 'Santiago', 'Metropolitana de Santiago'),
  ('rm0106', 'Estación Central', 'Santiago', 'Metropolitana de Santiago'),
  ('rm0113', 'La Reina', 'Santiago', 'Metropolitana de Santiago'),
  ('rm0114', 'Las Condes', 'Santiago', 'Metropolitana de Santiago'),
  ('rm0119', 'Maipú', 'Santiago', 'Metropolitana de Santiago'),
  ('rm0120', 'Ñuñoa', 'Santiago', 'Metropolitana de Santiago'),
  ('rm0122', 'Peñalolén', 'Santiago', 'Metropolitana de Santiago'),
  ('rm0123', 'Providencia', 'Santiago', 'Metropolitana de Santiago'),
  ('rm0201', 'Puente Alto', 'Cordillera', 'Metropolitana de Santiago'),
  ('co0102', 'Coquimbo', 'Elqui', 'Coquimbo'),
  ('vs0101', 'Valparaíso', 'Valparaíso', 'Valparaíso'),
  ('vs0109', 'Viña del Mar', 'Valparaíso', 'Valparaíso'),
  ('bi0101', 'Concepción', 'Concepción', 'Biobío'),
  ('ar0101', 'Temuco', 'Cautín', 'La Araucanía'),
  ('lr0101', 'Valdivia', 'Valdivia', 'Los Ríos'),
  ('ll0101', 'Puerto Montt', 'Llanquihue', 'Los Lagos')
on conflict (code) do update set
  name = excluded.name,
  province = excluded.province,
  region = excluded.region,
  is_active = true;

alter table public.profiles add column if not exists commune_code text;
alter table public.matches add column if not exists commune_code text;

alter table public.profiles
  add constraint profiles_commune_code_fkey
  foreign key (commune_code) references public.communes(code);

alter table public.matches
  add constraint matches_commune_code_fkey
  foreign key (commune_code) references public.communes(code);

update public.profiles p
set commune_code = c.code
from public.communes c
where p.commune_code is null and lower(btrim(p.commune)) = lower(c.name);

update public.matches m
set commune_code = c.code
from public.communes c
where m.commune_code is null and lower(btrim(m.commune)) = lower(c.name);

create index if not exists profiles_commune_code_idx
  on public.profiles (commune_code);
create index if not exists matches_commune_code_idx
  on public.matches (commune_code);

alter table public.communes enable row level security;
create policy communes_select_active
on public.communes for select to authenticated
using (is_active = true);

grant select on public.communes to authenticated;

comment on table public.communes is
  'Catalogo DPA de comunas de Chile. Se actualiza mediante migraciones versionadas.';
