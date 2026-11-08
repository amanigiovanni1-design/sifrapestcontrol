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
