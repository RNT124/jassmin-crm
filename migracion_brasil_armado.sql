-- Armado en Lima: marca por prenda si está en mano y fecha de empaque del pedido
alter table brasil_items add column if not exists en_mano boolean;
alter table brasil_pedidos add column if not exists empacado_en timestamptz;
