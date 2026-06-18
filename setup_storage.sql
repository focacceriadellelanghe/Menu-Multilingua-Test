-- Facoltativo: predisposizione futura delle immagini globali
insert into storage.buckets (id, name, public) values ('menu-assets','menu-assets',true) on conflict (id) do nothing;

create policy "Public read menu assets" on storage.objects for select to public using (bucket_id='menu-assets');
create policy "Admins upload menu assets" on storage.objects for insert to authenticated with check (bucket_id='menu-assets' and public.is_admin());
create policy "Admins update menu assets" on storage.objects for update to authenticated using (bucket_id='menu-assets' and public.is_admin()) with check (bucket_id='menu-assets' and public.is_admin());
create policy "Admins delete menu assets" on storage.objects for delete to authenticated using (bucket_id='menu-assets' and public.is_admin());
