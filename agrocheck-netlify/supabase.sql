-- AgroCheck – Esquema básico (ejecutar en Supabase SQL Editor)
-- Activa extensiones necesarias
create extension if not exists "pgcrypto";

-- PERFIL DE USUARIO
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  full_name text,
  plan text check (plan in ('BASICO','PRO','EMPRESA')) default 'BASICO',
  ia_quota integer not null default 30,
  ia_used integer not null default 0,
  created_at timestamptz default now()
);
alter table public.profiles enable row level security;
drop policy if exists "profiles select own" on public.profiles;
drop policy if exists "profiles update own" on public.profiles;
create policy "profiles select own" on public.profiles for select using (id = auth.uid());
create policy "profiles update own" on public.profiles for update using (id = auth.uid());

-- TRIGGER: crear perfil al registrarse
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles(id, email) values (new.id, new.email);
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

-- CATÁLOGOS
create table if not exists public.required_docs (
  doc_type text primary key,
  label text not null,
  default_required boolean not null default true
);
insert into public.required_docs (doc_type, label, default_required) values
  ('FITO','Certificado fitosanitario', true),
  ('REG_SAN','Registro sanitario', true),
  ('FORM_EXP','Formulario de exportación', true)
on conflict (doc_type) do nothing;

create table if not exists public.products (
  name text primary key,
  varieties text[]
);
insert into public.products (name, varieties) values
  ('palta', array['Hass','Fuerte','Zutano']),
  ('uva', array['Red Globe','Crimson','Thompson']),
  ('arándano', array['Biloxi','Ventura','Emerald']),
  ('fresa', array['Albión','San Andreas','Monterey']),
  ('mango', array['Kent','Keitt','Haden'])
on conflict (name) do nothing;

create table if not exists public.countries (
  code text primary key,
  name text not null
);
insert into public.countries (code, name) values
  ('CL','Chile'),
  ('CO','Colombia'),
  ('EC','Ecuador'),
  ('BO','Bolivia'),
  ('BR','Brasil')
on conflict (code) do nothing;

create table if not exists public.doc_requirements (
  id bigserial primary key,
  product text references public.products(name),
  country_code text references public.countries(code),
  doc_type text references public.required_docs(doc_type),
  required boolean default true
);

-- De momento, todos requieren FITO/REG_SAN/FORM_EXP por defecto
insert into public.doc_requirements (product, country_code, doc_type, required)
select p.name, c.code, d.doc_type, true
from public.products p, public.countries c, public.required_docs d
on conflict do nothing;

-- LOTES
create table if not exists public.lots (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  product text references public.products(name),
  variety text,
  lot_code text,
  origin_region text,
  origin_province text,
  destination_country text references public.countries(code),
  status text check (status in ('pendiente','aprobado','rechazado')) default 'pendiente',
  approved boolean,
  observations text,
  created_at timestamptz default now()
);
alter table public.lots enable row level security;
drop policy if exists "lots select own" on public.lots;
drop policy if exists "lots insert own" on public.lots;
drop policy if exists "lots update own" on public.lots;
drop policy if exists "lots delete own" on public.lots;
create policy "lots select own" on public.lots for select using (user_id = auth.uid());
create policy "lots insert own" on public.lots for insert with check (user_id = auth.uid());
create policy "lots update own" on public.lots for update using (user_id = auth.uid());
create policy "lots delete own" on public.lots for delete using (user_id = auth.uid());

-- DOCUMENTOS
create table if not exists public.documents (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  lot_id uuid not null references public.lots(id) on delete cascade,
  doc_type text references public.required_docs(doc_type),
  is_required boolean default true,
  status text check (status in ('pendiente','aprobado','observado')) default 'pendiente',
  file_path text,
  ai_feedback text,
  created_at timestamptz default now()
);
alter table public.documents enable row level security;
drop policy if exists "docs select own" on public.documents;
drop policy if exists "docs insert own" on public.documents;
drop policy if exists "docs update own" on public.documents;
drop policy if exists "docs delete own" on public.documents;
create policy "docs select own" on public.documents for select using (user_id = auth.uid());
create policy "docs insert own" on public.documents for insert with check (user_id = auth.uid());
create policy "docs update own" on public.documents for update using (user_id = auth.uid());
create policy "docs delete own" on public.documents for delete using (user_id = auth.uid());

-- FOTOS DEL LOTE
create table if not exists public.lot_photos (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  lot_id uuid not null references public.lots(id) on delete cascade,
  file_path text,
  created_at timestamptz default now()
);
alter table public.lot_photos enable row level security;
drop policy if exists "lot_photos select own" on public.lot_photos;
drop policy if exists "lot_photos insert own" on public.lot_photos;
drop policy if exists "lot_photos delete own" on public.lot_photos;
create policy "lot_photos select own" on public.lot_photos for select using (user_id = auth.uid());
create policy "lot_photos insert own" on public.lot_photos for insert with check (user_id = auth.uid());
create policy "lot_photos delete own" on public.lot_photos for delete using (user_id = auth.uid());

-- BUCKETS DE STORAGE
insert into storage.buckets (id, name, public) values ('docs','docs', false) on conflict (id) do nothing;
insert into storage.buckets (id, name, public) values ('photos','photos', false) on conflict (id) do nothing;

-- POLÍTICAS DE STORAGE (acceso por propietario usando prefijo userId/)
-- Nota: storage.objects ya tiene RLS activo por defecto.
drop policy if exists "storage docs select own" on storage.objects;
drop policy if exists "storage docs insert own" on storage.objects;
drop policy if exists "storage docs delete own" on storage.objects;
create policy "storage docs select own"
  on storage.objects for select to authenticated
  using (bucket_id = 'docs' and position(auth.uid()::text || '/' in name) = 1);

create policy "storage docs insert own"
  on storage.objects for insert to authenticated
  with check (bucket_id = 'docs' and position(auth.uid()::text || '/' in name) = 1);

create policy "storage docs delete own"
  on storage.objects for delete to authenticated
  using (bucket_id = 'docs' and position(auth.uid()::text || '/' in name) = 1);

drop policy if exists "storage photos select own" on storage.objects;
drop policy if exists "storage photos insert own" on storage.objects;
drop policy if exists "storage photos delete own" on storage.objects;
create policy "storage photos select own"
  on storage.objects for select to authenticated
  using (bucket_id = 'photos' and position(auth.uid()::text || '/' in name) = 1);

create policy "storage photos insert own"
  on storage.objects for insert to authenticated
  with check (bucket_id = 'photos' and position(auth.uid()::text || '/' in name) = 1);

create policy "storage photos delete own"
  on storage.objects for delete to authenticated
  using (bucket_id = 'photos' and position(auth.uid()::text || '/' in name) = 1);

-- VISTAS/AYUDA (opcional): resumen del uso de IA
create or replace view public.vw_usage as
select id as user_id, email, plan, ia_used, ia_quota, (ia_quota - ia_used) as ia_remaining
from public.profiles;
