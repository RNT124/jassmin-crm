alter table brasil_pedidos alter column cliente_id drop not null;
alter table brasil_pedidos add column if not exists usuario_wa text;
