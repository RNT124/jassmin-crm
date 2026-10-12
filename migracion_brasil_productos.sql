create table if not exists brasil_productos (
  id uuid primary key default gen_random_uuid(),
  nombre text not null,
  precio_venta numeric,
  variantes jsonb not null default '[]'::jsonb,
  creado_en timestamptz not null default now()
);
alter table brasil_productos disable row level security;
