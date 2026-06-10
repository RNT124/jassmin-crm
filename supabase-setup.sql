-- ══════════════════════════════════════════════════════
--  JASSMIN CRM — Setup completo de base de datos
--  Pega todo esto en Supabase > SQL Editor > New query
-- ══════════════════════════════════════════════════════


-- ── 1. USUARIOS DEL SISTEMA ──────────────────────────
create table usuarios (
  id uuid primary key default gen_random_uuid(),
  username text unique not null,
  password_hash text not null,
  nombre text not null,
  rol text not null check (rol in ('admin','operador')),
  activo boolean default true,
  creado_en timestamptz default now()
);

insert into usuarios (username, password_hash, nombre, rol) values
  ('admin',    'jassmin2025', 'Renato',   'admin'),
  ('operador', 'tienda123',   'Operador', 'operador');


-- ── 2. CLIENTAS ──────────────────────────────────────
create table clientes (
  id uuid primary key default gen_random_uuid(),
  telefono text unique not null,
  nombre text,
  talla text,
  distrito text,
  direccion text,
  referencia text,
  costo_envio integer default 13,
  total_gastado numeric default 0,
  pedidos_count integer default 0,
  creado_en timestamptz default now(),
  actualizado_en timestamptz default now()
);

create index idx_clientes_telefono on clientes(telefono);


-- ── 3. PRENDAS (catálogo) ────────────────────────────
create table prendas (
  id uuid primary key default gen_random_uuid(),
  nombre text not null,
  codigo text unique,
  precio numeric not null,
  costo numeric default 0,
  categoria text,
  tallas text[] default '{}',
  foto_url text,
  activo boolean default true,
  creado_en timestamptz default now()
);

insert into prendas (nombre, codigo, precio, costo, categoria, tallas) values
  ('Vestido lino manga larga', 'VES-001', 89, 38, 'Vestido',  '{S,M,L}'),
  ('Blusa flores bordadas',    'BLU-001', 55, 22, 'Blusa',    '{S,M,L,XL}'),
  ('Pantalon palazzo beige',   'PAN-001', 75, 30, 'Pantalon', '{S,M,L}'),
  ('Conjunto jogger rosa',     'CON-001', 98, 42, 'Conjunto', '{M,L,XL}'),
  ('Top encaje crema',         'TOP-001', 45, 18, 'Top',      '{S,M,L}');


-- ── 4. CARRITOS ──────────────────────────────────────
create table carritos (
  id uuid primary key default gen_random_uuid(),
  cliente_id uuid references clientes(id) on delete cascade,
  estado text default 'abierto' check (estado in ('abierto','en_pedido','cerrado')),
  total numeric default 0,
  creado_en timestamptz default now(),
  actualizado_en timestamptz default now()
);

create index idx_carritos_cliente on carritos(cliente_id);


-- ── 5. ITEMS DEL CARRITO ─────────────────────────────
create table carrito_items (
  id uuid primary key default gen_random_uuid(),
  carrito_id uuid references carritos(id) on delete cascade,
  prenda_id uuid references prendas(id),
  talla text not null,
  precio_unitario numeric not null,
  agregado_en timestamptz default now()
);

create index idx_items_carrito on carrito_items(carrito_id);


-- ── 6. PEDIDOS ───────────────────────────────────────
create table pedidos (
  id uuid primary key default gen_random_uuid(),
  numero text unique not null,
  cliente_id uuid references clientes(id),
  carrito_id uuid references carritos(id),
  estado text default 'pago_pendiente' check (
    estado in (
      'pago_pendiente','pago_parcial','pago_completo',
      'empaquetado','en_camino','entregado'
    )
  ),
  subtotal numeric not null,
  costo_envio numeric default 13,
  total numeric not null,
  monto_pagado numeric default 0,
  tipo_envio text,
  distrito text,
  direccion text,
  courier_codigo text,
  creado_en timestamptz default now(),
  actualizado_en timestamptz default now()
);

create index idx_pedidos_cliente on pedidos(cliente_id);
create index idx_pedidos_estado on pedidos(estado);


-- ── 7. PAGOS ─────────────────────────────────────────
create table pagos (
  id uuid primary key default gen_random_uuid(),
  pedido_id uuid references pedidos(id) on delete cascade,
  metodo text check (metodo in ('Yape','Plin','Transferencia')),
  monto numeric not null,
  estado text default 'confirmado' check (estado in ('pendiente','confirmado')),
  captura_url text,
  confirmado_por text,
  pagado_en timestamptz default now()
);

create index idx_pagos_pedido on pagos(pedido_id);


-- ── 8. LIVES (registro de cada transmisión) ──────────
create table lives (
  id uuid primary key default gen_random_uuid(),
  fecha date not null default current_date,
  duracion_min integer,
  total_vendido numeric default 0,
  num_pedidos integer default 0,
  notas text,
  creado_en timestamptz default now()
);


-- ── 9. FUNCIÓN: número automático de pedido ──────────
create or replace function generar_numero_pedido()
returns trigger as $$
declare
  ultimo integer;
  nuevo_numero text;
begin
  select coalesce(max(
    cast(substring(numero from 'JAS-\d{4}-(\d+)') as integer)
  ), 0)
  into ultimo
  from pedidos
  where numero like 'JAS-' || to_char(now(), 'YYYY') || '-%';

  nuevo_numero := 'JAS-' || to_char(now(), 'YYYY') || '-' ||
                  lpad((ultimo + 1)::text, 4, '0');
  new.numero := nuevo_numero;
  return new;
end;
$$ language plpgsql;

create trigger trigger_numero_pedido
before insert on pedidos
for each row
when (new.numero is null or new.numero = '')
execute function generar_numero_pedido();


-- ── 10. FUNCIÓN: actualizar total del carrito ────────
create or replace function actualizar_total_carrito()
returns trigger as $$
begin
  update carritos
  set total = (
    select coalesce(sum(precio_unitario), 0)
    from carrito_items
    where carrito_id = coalesce(new.carrito_id, old.carrito_id)
  ),
  actualizado_en = now()
  where id = coalesce(new.carrito_id, old.carrito_id);
  return new;
end;
$$ language plpgsql;

create trigger trigger_total_carrito_insert
after insert on carrito_items
for each row execute function actualizar_total_carrito();

create trigger trigger_total_carrito_delete
after delete on carrito_items
for each row execute function actualizar_total_carrito();


-- ── 11. FUNCIÓN: actualizar monto pagado en pedido ───
create or replace function actualizar_monto_pagado()
returns trigger as $$
declare
  total_pagado numeric;
  pedido_total numeric;
begin
  select coalesce(sum(monto), 0) into total_pagado
  from pagos
  where pedido_id = new.pedido_id and estado = 'confirmado';

  select total into pedido_total
  from pedidos where id = new.pedido_id;

  update pedidos
  set monto_pagado = total_pagado,
      estado = case
        when total_pagado >= pedido_total then 'pago_completo'
        when total_pagado > 0            then 'pago_parcial'
        else                                  'pago_pendiente'
      end,
      actualizado_en = now()
  where id = new.pedido_id;

  return new;
end;
$$ language plpgsql;

create trigger trigger_monto_pagado
after insert or update on pagos
for each row execute function actualizar_monto_pagado();


-- ── 12. ROW LEVEL SECURITY (básico) ─────────────────
-- Por ahora abierto para que funcione sin auth compleja.
-- Cuando escales puedes restringir por usuario.
alter table usuarios      enable row level security;
alter table clientes      enable row level security;
alter table prendas       enable row level security;
alter table carritos      enable row level security;
alter table carrito_items enable row level security;
alter table pedidos       enable row level security;
alter table pagos         enable row level security;
alter table lives         enable row level security;

-- Política: acceso total con la anon key (para tu app)
create policy "acceso_total" on usuarios      for all using (true) with check (true);
create policy "acceso_total" on clientes      for all using (true) with check (true);
create policy "acceso_total" on prendas       for all using (true) with check (true);
create policy "acceso_total" on carritos      for all using (true) with check (true);
create policy "acceso_total" on carrito_items for all using (true) with check (true);
create policy "acceso_total" on pedidos       for all using (true) with check (true);
create policy "acceso_total" on pagos         for all using (true) with check (true);
create policy "acceso_total" on lives         for all using (true) with check (true);


-- ══════════════════════════════════════════════════════
--  FIN — ejecuta este script y tendrás todo listo
-- ══════════════════════════════════════════════════════
