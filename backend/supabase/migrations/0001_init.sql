-- Esquema inicial: finanzas personales + suscripción (trial 30 días + PayPhone)

create extension if not exists "pgcrypto";

-- Perfiles ---------------------------------------------------------------
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  default_currency char(3) not null default 'USD',
  created_at timestamptz not null default now()
);

-- Cuentas ----------------------------------------------------------------
create table public.accounts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  name text not null,
  currency char(3) not null default 'USD',
  created_at timestamptz not null default now()
);

-- Categorías -------------------------------------------------------------
create table public.categories (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  name text not null,
  kind text not null check (kind in ('expense', 'income')),
  icon text,
  color text
);

-- Transacciones ----------------------------------------------------------
create table public.transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  account_id uuid references public.accounts(id) on delete set null,
  category_id uuid references public.categories(id) on delete set null,
  amount numeric(14,2) not null check (amount >= 0),
  currency char(3) not null default 'USD',
  kind text not null check (kind in ('expense', 'income')),
  occurred_on date not null default current_date,
  note text,
  recurrence text check (recurrence in ('weekly', 'monthly', 'yearly')),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);
create index on public.transactions (user_id, occurred_on desc);

-- Presupuestos -----------------------------------------------------------
create table public.budgets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  category_id uuid references public.categories(id) on delete cascade,
  month date not null,
  limit_amount numeric(14,2) not null check (limit_amount >= 0),
  unique (user_id, category_id, month)
);

-- Inversiones ------------------------------------------------------------
create table public.investments (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  name text not null,
  asset_type text not null,
  quantity numeric(18,6) not null default 0,
  cost_basis numeric(14,2) not null default 0,
  current_value numeric(14,2) not null default 0,
  currency char(3) not null default 'USD',
  updated_at timestamptz not null default now()
);

-- Suscripciones ----------------------------------------------------------
create table public.subscriptions (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  plan text not null default 'premium',
  status text not null default 'trialing'
    check (status in ('trialing', 'active', 'past_due', 'expired')),
  trial_ends_at timestamptz not null default (now() + interval '30 days'),
  current_period_end timestamptz,
  grace_until timestamptz,
  updated_at timestamptz not null default now()
);

-- Pagos (PayPhone) -------------------------------------------------------
create table public.payments (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  provider text not null default 'payphone',
  client_transaction_id text not null unique,   -- generado por nuestro backend
  provider_transaction_id text unique,          -- id de PayPhone (idempotencia)
  amount_cents integer not null check (amount_cents > 0),
  currency char(3) not null default 'USD',
  status text not null default 'pending'
    check (status in ('pending', 'approved', 'rejected', 'canceled')),
  raw_response jsonb,
  created_at timestamptz not null default now(),
  verified_at timestamptz
);

-- Alta automática de perfil + trial al registrarse -----------------------
create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, display_name)
    values (new.id, coalesce(new.raw_user_meta_data->>'name', split_part(new.email, '@', 1)));
  insert into public.subscriptions (user_id) values (new.id);
  return new;
end $$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Row Level Security -----------------------------------------------------
alter table public.profiles      enable row level security;
alter table public.accounts      enable row level security;
alter table public.categories    enable row level security;
alter table public.transactions  enable row level security;
alter table public.budgets       enable row level security;
alter table public.investments   enable row level security;
alter table public.subscriptions enable row level security;
alter table public.payments      enable row level security;

create policy "own profile"      on public.profiles     for all using (id = auth.uid())      with check (id = auth.uid());
create policy "own accounts"     on public.accounts     for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "own categories"   on public.categories   for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "own transactions" on public.transactions for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "own budgets"      on public.budgets      for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "own investments"  on public.investments  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

-- Suscripción y pagos: el usuario solo LEE; solo el backend (service role) escribe.
create policy "read own subscription" on public.subscriptions for select using (user_id = auth.uid());
create policy "read own payments"     on public.payments      for select using (user_id = auth.uid());

-- Acceso premium vigente (para usar en políticas/funciones del servidor)
create or replace function public.has_active_access(uid uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.subscriptions s
    where s.user_id = uid and (
      (s.status = 'trialing' and s.trial_ends_at > now()) or
      (s.status = 'active'   and s.current_period_end > now()) or
      (s.grace_until is not null and s.grace_until > now())
    )
  );
$$;
