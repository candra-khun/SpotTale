-- Jalankan sekali di Supabase: SQL Editor -> New query -> paste -> Run.

-- ============ Tabel tangkapan ============
create table if not exists public.catches (
  id                 uuid primary key,
  user_id            uuid not null default auth.uid()
                     references auth.users(id) on delete cascade,
  species_id         text not null,
  species_name       text not null,
  category           text not null check (category in ('tawar', 'asin')),
  weight_kg          numeric(8, 2),
  rod                text,
  reel               text,
  bait               text,
  lat                double precision not null,
  lng                double precision not null,
  caught_at          timestamptz not null default now(),
  photo_path         text,
  is_public          boolean not null default false,
  angler_name        text,
  angler_avatar_url  text,
  created_at         timestamptz not null default now()
);

create index if not exists catches_user_time_idx
  on public.catches (user_id, caught_at desc);

create index if not exists catches_public_idx
  on public.catches (is_public, caught_at desc);

alter table public.catches enable row level security;

-- Pengguna bisa melihat tangkapan miliknya sendiri ATAU tangkapan universal (publik)
drop policy if exists "catches_select_own" on public.catches;
drop policy if exists "catches_select_all" on public.catches;
create policy "catches_select_all" on public.catches
  for select to authenticated
  using (auth.uid() = user_id or is_public = true);
create policy "catches_insert_own" on public.catches
  for insert to authenticated with check (auth.uid() = user_id);
create policy "catches_update_own" on public.catches
  for update to authenticated
  using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "catches_delete_own" on public.catches
  for delete to authenticated using (auth.uid() = user_id);

-- ============ Tabel alat (joran / reel / umpan) ============
create table if not exists public.gear (
  id       uuid primary key default gen_random_uuid(),
  user_id  uuid not null default auth.uid()
           references auth.users(id) on delete cascade,
  kind     text not null check (kind in ('rod', 'reel', 'bait')),
  name     text not null,
  unique (user_id, kind, name)
);

alter table public.gear enable row level security;

create policy "gear_select_own" on public.gear
  for select to authenticated using (auth.uid() = user_id);
create policy "gear_insert_own" on public.gear
  for insert to authenticated with check (auth.uid() = user_id);
create policy "gear_update_own" on public.gear
  for update to authenticated
  using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "gear_delete_own" on public.gear
  for delete to authenticated using (auth.uid() = user_id);

-- ============ Penyimpanan foto ============
-- Bucket publik: siapa pun yang punya URL foto bisa melihatnya (URL berisi UUID acak).
-- Hanya pemilik yang bisa mengunggah/mengubah/menghapus di folder miliknya.
insert into storage.buckets (id, name, public)
values ('catch-photos', 'catch-photos', true)
on conflict (id) do nothing;

create policy "photos_read" on storage.objects
  for select using (bucket_id = 'catch-photos');

create policy "photos_insert_own" on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'catch-photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "photos_update_own" on storage.objects
  for update to authenticated
  using (
    bucket_id = 'catch-photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  )
  with check (
    bucket_id = 'catch-photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "photos_delete_own" on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'catch-photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
