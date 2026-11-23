-- Laundry POS: run this once in Supabase (SQL Editor > New query > paste > Run)

-- Staff profiles. The FIRST account created becomes admin, everyone after is a cashier.
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  role text not null default 'cashier' check (role in ('admin','cashier'))
);

create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, email, role)
  values (new.id, new.email,
          case when exists (select 1 from public.profiles) then 'cashier' else 'admin' end);
  return new;
end $$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

create or replace function public.is_staff() returns boolean
language sql security definer stable set search_path = public as
$$ select exists (select 1 from public.profiles where id = auth.uid()) $$;

create or replace function public.is_admin() returns boolean
language sql security definer stable set search_path = public as
$$ select exists (select 1 from public.profiles where id = auth.uid() and role = 'admin') $$;

-- Shop settings and price list (one row)
create table public.settings (
  id int primary key default 1 check (id = 1),
  shop text not null default 'My Laundry Shop',
  cur text not null default '₱',
  next_pid int not null default 8,
  prices jsonb not null default '[
    {"id":1,"name":"Wash, dry and fold","unit":"kg","price":60},
    {"id":2,"name":"Wash only","unit":"kg","price":35},
    {"id":3,"name":"Dry only","unit":"kg","price":30},
    {"id":4,"name":"Ironing","unit":"kg","price":40},
    {"id":5,"name":"Comforter / blanket","unit":"pc","price":150},
    {"id":6,"name":"Dry clean","unit":"pc","price":120},
    {"id":7,"name":"Detergent and fabric conditioner","unit":"load","price":20}
  ]'::jsonb
);
insert into public.settings (id) values (1);

-- Orders. "no" is the order number, assigned by the database so it is always unique.
create table public.orders (
  no bigint generated always as identity primary key,
  created_at timestamptz not null default now(),
  order_date date not null,
  order_time text,
  name text not null default 'Walk-in',
  phone text,
  lines jsonb not null,
  sub numeric not null,
  disc numeric not null default 0,
  fee numeric not null default 0,
  total numeric not null,
  paid numeric not null default 0,
  given numeric not null default 0,
  status text not null default 'Received' check (status in ('Received','Washing','Ready','Claimed'))
);
create index orders_date_idx on public.orders (order_date);

-- Row level security: only signed-in staff can touch anything
alter table public.profiles enable row level security;
alter table public.settings enable row level security;
alter table public.orders   enable row level security;

create policy "read own profile" on public.profiles for select to authenticated using (id = auth.uid());

create policy "staff read settings"   on public.settings for select to authenticated using (public.is_staff());
create policy "admin update settings" on public.settings for update to authenticated using (public.is_admin()) with check (public.is_admin());

create policy "staff read orders"   on public.orders for select to authenticated using (public.is_staff());
create policy "staff add orders"    on public.orders for insert to authenticated with check (public.is_staff());
create policy "staff update orders" on public.orders for update to authenticated using (public.is_staff()) with check (public.is_staff());
create policy "admin delete orders" on public.orders for delete to authenticated using (public.is_admin());

-- Live updates between devices
alter publication supabase_realtime add table public.orders, public.settings;
