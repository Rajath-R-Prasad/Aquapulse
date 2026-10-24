-- Public impact estimate (aggregate only; no pipe, valve, coordinate or engineer data).
create table if not exists public_impact (
  id boolean primary key default true check (id),
  status text not null default 'NORMAL' check (status in ('NORMAL','LEAK')),
  active_leaks integer not null default 0 check (active_leaks >= 0),
  water_lost_l bigint not null default 0 check (water_lost_l >= 0),
  households_affected integer not null default 0 check (households_affected >= 0),
  household_days numeric(12,2) not null default 0 check (household_days >= 0),
  updated_at timestamptz not null default now()
);
insert into public_impact (id) values (true) on conflict (id) do nothing;

alter table public_impact enable row level security;

insert into app_settings (key, value) values
  ('public_impact', '{"lpcd":135,"persons_per_household":4}')
on conflict (key) do nothing;
