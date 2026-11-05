-- Ya aplicada desde Claude (5 nov 2026). Lista oficial de agencias de shalom.com.pe/agencias
create table if not exists shalom_agencias (
  nombre text primary key,
  departamento text, provincia text, distrito text, direccion text,
  destino boolean default true,
  actualizado_en timestamptz default now()
);
alter table shalom_agencias disable row level security;
alter table clientes add column if not exists shalom_agencia text;
