-- Aplicada el 2026-11-16: seguimiento de productos retenidos en aduanas (módulo Brasil)
alter table brasil_pedidos
  add column if not exists aduana_avisado_en timestamptz,
  add column if not exists aduana_respuesta_en timestamptz,
  add column if not exists aduana_enviar_disponible boolean,
  add column if not exists aduana_opcion text,
  add column if not exists aduana_yape text,
  add column if not exists aduana_titular text,
  add column if not exists aduana_monto numeric,
  add column if not exists aduana_cerrado_en timestamptz;
