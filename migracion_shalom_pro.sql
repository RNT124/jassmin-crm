-- Excel Shalom PRO: recuerda qué agencia de la lista oficial de Shalom corresponde a cada agencia que eligen las clientas
create table if not exists shalom_pro_destinos (
  agencia text primary key,
  destino text not null,
  actualizado_en timestamptz default now()
);
alter table shalom_pro_destinos disable row level security;
