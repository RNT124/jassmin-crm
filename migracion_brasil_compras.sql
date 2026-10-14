-- Registro de compras de Brasil (la asignación a las ventas se calcula sola)
create table if not exists brasil_compras (
  id uuid primary key default gen_random_uuid(),
  fecha date not null default current_date,
  producto text not null,
  variante text,
  cantidad int not null,
  costo_rl numeric not null default 0,   -- reales por unidad
  creado_en timestamptz not null default now()
);
alter table brasil_compras disable row level security;
alter table brasil_productos add column if not exists costo_rl numeric;

-- Pasa al registro lo que ya habías marcado como comprado (solo si aún no hay compras registradas)
insert into brasil_compras (fecha, producto, variante, cantidad, costo_rl)
select creado_en::date, producto, variante, sum(cantidad), costo_rl
from brasil_items
where comprado = true and costo_rl is not null
  and not exists (select 1 from brasil_compras)
group by creado_en::date, producto, variante, costo_rl;
