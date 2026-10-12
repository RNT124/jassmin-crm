-- Sección Brasil: tablas independientes (no tocan stock, pedidos ni dashboard normal)
create table if not exists brasil_pedidos (
  id uuid primary key default gen_random_uuid(),
  cliente_id uuid not null,
  estado text not null default 'por_comprar', -- por_comprar | comprado | listo_lima | despachado
  pagado boolean not null default false,
  courier_codigo text,
  creado_en timestamptz not null default now(),
  despachado_en timestamptz
);
create table if not exists brasil_items (
  id uuid primary key default gen_random_uuid(),
  pedido_id uuid not null references brasil_pedidos(id) on delete cascade,
  producto text not null,
  variante text,
  cantidad int not null default 1,
  precio_venta numeric not null default 0,   -- soles por unidad
  comprado boolean not null default false,
  costo_rl numeric,                           -- reales por unidad (al comprar)
  creado_en timestamptz not null default now()
);
alter table brasil_pedidos disable row level security;
alter table brasil_items disable row level security;
create index if not exists brasil_items_pedido_idx on brasil_items(pedido_id);
