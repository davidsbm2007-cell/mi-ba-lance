-- Paridad con la base local (Drift/SQLite) de la app.
-- Montos en centavos (bigint) para que ambos lados guarden exactamente lo mismo,
-- más metas, deudas y columnas de sincronización (updated_at / deleted_at).

-- Montos: numeric(14,2) -> centavos ---------------------------------------
alter table public.transactions
  alter column amount type bigint using round(amount * 100);
alter table public.transactions rename column amount to amount_cents;

alter table public.budgets
  alter column limit_amount type bigint using round(limit_amount * 100);
alter table public.budgets rename column limit_amount to limit_cents;

alter table public.investments
  alter column cost_basis type bigint using round(cost_basis * 100);
alter table public.investments rename column cost_basis to cost_basis_cents;
alter table public.investments
  alter column current_value type bigint using round(current_value * 100);
alter table public.investments rename column current_value to current_value_cents;

-- Transacciones: instante exacto además del día -----------------------------
alter table public.transactions
  add column occurred_at timestamptz not null default now();

-- Presupuestos: el límite de la app es mensual y recurrente (sin mes fijo) --
alter table public.budgets alter column month drop not null;
create unique index budgets_recurring_unique
  on public.budgets (user_id, category_id) where month is null;

-- Columnas de sincronización en el resto de tablas --------------------------
alter table public.accounts    add column updated_at timestamptz not null default now(),
                               add column deleted_at timestamptz;
alter table public.categories  add column updated_at timestamptz not null default now(),
                               add column deleted_at timestamptz;
alter table public.budgets     add column updated_at timestamptz not null default now(),
                               add column deleted_at timestamptz;
alter table public.investments add column deleted_at timestamptz;

-- Metas ------------------------------------------------------------------
create table public.goals (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  name text not null,
  note text not null default '',
  target_cents bigint not null check (target_cents >= 0),
  saved_cents bigint not null default 0 check (saved_cents >= 0),
  icon_key text not null default 'savings',
  color_index integer not null default 0,
  currency char(3) not null default 'USD',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

-- Deudas -----------------------------------------------------------------
-- owed_to_me: alguien me debe. i_owe: yo debo.
create table public.debts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  kind text not null check (kind in ('owed_to_me', 'i_owe')),
  person text not null,
  concept text not null default '',
  total_cents bigint not null check (total_cents >= 0),
  paid_cents bigint not null default 0 check (paid_cents >= 0),
  due_date timestamptz,
  currency char(3) not null default 'USD',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

alter table public.goals enable row level security;
alter table public.debts enable row level security;
create policy "own goals" on public.goals for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "own debts" on public.debts for all using (user_id = auth.uid()) with check (user_id = auth.uid());

-- Índices para sincronizar "lo que cambió desde la última vez" ---------------
create index on public.transactions (user_id, updated_at);
create index on public.budgets      (user_id, updated_at);
create index on public.goals        (user_id, updated_at);
create index on public.debts        (user_id, updated_at);

-- updated_at automático --------------------------------------------------
create or replace function public.touch_updated_at() returns trigger
language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end $$;

create trigger touch_transactions before update on public.transactions for each row execute function public.touch_updated_at();
create trigger touch_accounts     before update on public.accounts     for each row execute function public.touch_updated_at();
create trigger touch_categories   before update on public.categories   for each row execute function public.touch_updated_at();
create trigger touch_budgets      before update on public.budgets      for each row execute function public.touch_updated_at();
create trigger touch_investments  before update on public.investments  for each row execute function public.touch_updated_at();
create trigger touch_goals        before update on public.goals        for each row execute function public.touch_updated_at();
create trigger touch_debts        before update on public.debts        for each row execute function public.touch_updated_at();
