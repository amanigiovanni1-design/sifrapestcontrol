create table if not exists public.clients (
    id uuid primary key default gen_random_uuid(),
    full_name text not null,
    phone text not null,
    email text not null unique,
    property_type text not null,
    address text not null,
    marketing_consent boolean not null default false,
    created_at timestamptz not null default now()
);

create table if not exists public.bookings (
    id uuid primary key default gen_random_uuid(),
    full_name text not null,
    phone text not null,
    email text not null,
    service text not null,
    preferred_date date not null,
    preferred_time time not null,
    message text,
    status text not null default 'pending'
        check (status in ('pending', 'confirmed', 'completed', 'cancelled')),
    created_at timestamptz not null default now()
);

alter table public.clients enable row level security;
alter table public.bookings enable row level security;

grant usage on schema public to anon, authenticated;
grant insert on public.clients to anon;
grant insert on public.bookings to anon;
grant select on public.clients to authenticated;
grant select on public.bookings to authenticated;

drop policy if exists "Website can register clients" on public.clients;
create policy "Website can register clients"
on public.clients
for insert
to anon
with check (true);

drop policy if exists "Website can request bookings" on public.bookings;
create policy "Website can request bookings"
on public.bookings
for insert
to anon
with check (true);

drop policy if exists "Staff can view client registrations" on public.clients;
create policy "Staff can view client registrations"
on public.clients
for select
to authenticated
using ((auth.jwt() -> 'app_metadata' ->> 'role') = 'staff');

drop policy if exists "Registered staff email can view client registrations" on public.clients;
create policy "Registered staff email can view client registrations"
on public.clients
for select
to authenticated
using (lower(coalesce(auth.jwt() ->> 'email', '')) = 'amanigiovanni1@gmail.com');

drop policy if exists "Staff can view bookings" on public.bookings;
create policy "Staff can view bookings"
on public.bookings
for select
to authenticated
using ((auth.jwt() -> 'app_metadata' ->> 'role') = 'staff');

drop policy if exists "Registered staff email can view bookings" on public.bookings;
create policy "Registered staff email can view bookings"
on public.bookings
for select
to authenticated
using (lower(coalesce(auth.jwt() ->> 'email', '')) = 'amanigiovanni1@gmail.com');

-- Create each staff account in Supabase Authentication, then assign its role with:
-- update auth.users
-- set raw_app_meta_data = coalesce(raw_app_meta_data, '{}'::jsonb) || '{"role":"staff"}'::jsonb
-- where email = 'staff@example.com';
