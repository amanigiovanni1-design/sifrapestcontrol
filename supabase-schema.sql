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

create or replace function public.get_staff_bookings()
returns setof public.bookings
language sql
security definer
set search_path = public
as $$
    select *
    from public.bookings
    where lower(coalesce(auth.jwt() ->> 'email', '')) = 'amanigiovanni1@gmail.com'
       or coalesce(auth.jwt() -> 'app_metadata' ->> 'role', '') = 'staff'
    order by created_at desc;
$$;

revoke all on function public.get_staff_bookings() from public, anon;
grant execute on function public.get_staff_bookings() to authenticated;

create or replace function public.get_staff_clients()
returns setof public.clients
language sql
security definer
set search_path = public
as $$
    select *
    from public.clients
    where lower(coalesce(auth.jwt() ->> 'email', '')) = 'amanigiovanni1@gmail.com'
       or coalesce(auth.jwt() -> 'app_metadata' ->> 'role', '') = 'staff'
    order by created_at desc;
$$;

revoke all on function public.get_staff_clients() from public, anon;
grant execute on function public.get_staff_clients() to authenticated;

notify pgrst, 'reload schema';

-- Optional demo records. Run this section only when dummy staff-dashboard data is wanted.
insert into public.clients
    (full_name, phone, email, property_type, address, marketing_consent)
values
    ('Test Client One', '+260970000001', 'dummy.client1@example.com', 'Residential home', '1 Test Street, Lusaka', true),
    ('Test Client Two', '+260970000002', 'dummy.client2@example.com', 'Office / commercial', '2 Sample Avenue, Lusaka', false)
on conflict (email) do nothing;

insert into public.bookings
    (full_name, phone, email, service, preferred_date, preferred_time, message)
select demo.*
from (values
    ('Test Booking One'::text, '+260970000011'::text, 'dummy.booking1@example.com'::text, 'Termite Inspection & Treatment'::text, '2026-11-12'::date, '10:00:00'::time, 'Dummy booking for staff dashboard testing.'::text),
    ('Test Booking Two'::text, '+260970000012'::text, 'dummy.booking2@example.com'::text, 'Rodent Control'::text, '2026-11-13'::date, '14:00:00'::time, 'Dummy booking for staff dashboard testing.'::text)
) as demo(full_name, phone, email, service, preferred_date, preferred_time, message)
where not exists (
    select 1
    from public.bookings existing
    where existing.email in ('dummy.booking1@example.com', 'dummy.booking2@example.com')
);

-- Create each staff account in Supabase Authentication, then assign its role with:
-- update auth.users
-- set raw_app_meta_data = coalesce(raw_app_meta_data, '{}'::jsonb) || '{"role":"staff"}'::jsonb
-- where email = 'staff@example.com';
