-- Gastos de Brasil (envíos, impuestos, etc.) para calcular la ganancia real
create table if not exists brasil_gastos (
  id uuid primary key default gen_random_uuid(),
  fecha date not null default current_date,
  tipo text not null,                 -- Envío Brasil→Lima | Impuestos / aduana | Flete local | Otro
  monto numeric not null default 0,
  moneda text not null default 'R$',  -- 'R$' o 'S/'
  nota text,
  creado_en timestamptz not null default now()
);
alter table brasil_gastos disable row level security;
