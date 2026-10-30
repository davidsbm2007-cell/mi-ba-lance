-- Tarjetas de crédito y débito (registro manual, sin conexión bancaria).
-- Espejo de la tabla `cards` de la base local (Drift, schemaVersion 2).
-- Crédito: balance_cents = lo que se ha usado del cupo. Débito: saldo disponible.

create table public.cards (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  name text not null,
  network text not null default 'other'
    check (network in ('visa', 'mastercard', 'amex', 'diners', 'other')),
  kind text not null check (kind in ('credit', 'debit')),
  last4 text check (last4 ~ '^[0-9]{4}$'),
  limit_cents bigint check (limit_cents >= 0),
  balance_cents bigint not null default 0 check (balance_cents >= 0),
  cut_day smallint check (cut_day between 1 and 31),
  due_day smallint check (due_day between 1 and 31),
  color_index integer not null default 0,
  currency char(3) not null default 'USD',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

alter table public.cards enable row level security;
create policy "own cards" on public.cards
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

create index on public.cards (user_id, updated_at);

create trigger touch_cards before update on public.cards
  for each row execute function public.touch_updated_at();
