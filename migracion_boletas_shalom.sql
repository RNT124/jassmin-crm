alter table pedidos
  add column if not exists etiqueta_en timestamptz,
  add column if not exists shalom_orden text,
  add column if not exists shalom_clave text,
  add column if not exists shalom_emision timestamptz,
  add column if not exists shalom_foto text;
alter table brasil_pedidos
  add column if not exists shalom_orden text,
  add column if not exists shalom_clave text,
  add column if not exists shalom_emision timestamptz,
  add column if not exists shalom_foto text;
insert into storage.buckets (id, name, public) values ('boletas-shalom','boletas-shalom',true) on conflict do nothing;
create policy "boletas_anon" on storage.objects for all to anon using (bucket_id='boletas-shalom') with check (bucket_id='boletas-shalom');
