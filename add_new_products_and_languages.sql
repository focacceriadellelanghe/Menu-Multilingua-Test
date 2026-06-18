begin;

-- ============================================================
-- 1. ESTENSIONE LINGUE DISPONIBILI
-- Aggiunge: polacco, albanese, rumeno, ungherese,
-- olandese, croato, greco e turco.
-- ============================================================

do $$
declare
  c record;
begin
  for c in
    select conname
    from pg_constraint
    where conrelid = 'public.product_translations'::regclass
      and contype = 'c'
      and pg_get_constraintdef(oid) ilike '%language_code%'
  loop
    execute format(
      'alter table public.product_translations drop constraint %I',
      c.conname
    );
  end loop;
end $$;

alter table public.product_translations
add constraint product_translations_language_code_check
check (
  language_code in (
    'it','en','fr','es','de','pt','ru','ar','zh','ja','ko',
    'pl','sq','ro','hu','nl','hr','el','tr'
  )
);

-- ============================================================
-- 2. NUOVE FOCACCE
-- Inserite come BOZZE, prezzo 0,00 e senza badge.
-- Potrai completare prezzo, badge e disponibilità dall'admin.
-- ============================================================

with source_data as (
  select * from (values
    (
      'MERENDA_SINOIRA','salata',0.00,14,
      array['gluten','milk','sulphites']::text[],array[]::text[],
      $txt$LA MERENDA SINOIRA$txt$,
      $txt$Tomino, Zucchine, Prosciutto Cotto e Glassa di Aceto Balsamico$txt$
    ),
    (
      'NORMA_BRA','salata',0.00,15,
      array['gluten','milk','sulphites']::text[],array[]::text[],
      $txt$LA NORMA DI BRA$txt$,
      $txt$Salsiccia di Bra, Cipolla Rossa Caramellata, Crema di Melanzana e Ricotta Salata$txt$
    ),
    (
      'GENOVESE','salata',0.00,16,
      array['gluten','milk','nuts']::text[],array['pine_nut']::text[],
      $txt$LA GENOVESE$txt$,
      $txt$Pancetta Arrotolata, Pesto, Patate e Mozzarella Fior di Latte$txt$
    ),
    (
      'PARMIGIANA','salata',0.00,17,
      array['gluten','milk','sulphites']::text[],array[]::text[],
      $txt$LA PARMIGIANA$txt$,
      $txt$Passata di Pomodoro, Melanzana Marinata, Kinara ed Emulsione al Basilico$txt$
    ),
    (
      'BAGNET_VERD','salata',0.00,18,
      array['gluten','milk','fish','sulphites']::text[],array[]::text[],
      $txt$BAGNET VERD$txt$,
      $txt$Lingua di Vitello, Bagnetto Verde e Patate$txt$
    ),
    (
      'POL_TUMIN','salata',0.00,19,
      array['gluten','milk','celery','nuts']::text[],array['walnut']::text[],
      $txt$POL E TUMIN$txt$,
      $txt$Pollo Sfilacciato, Sedano, Tomino e Noci$txt$
    ),
    (
      'FRESCHEZZA_ESTIVA','salata',0.00,20,
      array['gluten','soy','nuts','sulphites']::text[],array['almond']::text[],
      $txt$FRESCHEZZA ESTIVA$txt$,
      $txt$Zucchine, Cipolla Rossa Marinata, Scaglie di Mandorle e Maionese Vegana$txt$
    ),
    (
      'ORTO_ESTATE','salata',0.00,21,
      array['gluten','sulphites']::text[],array[]::text[],
      $txt$L'ORTO D'ESTATE$txt$,
      $txt$Crema di Carota, Zucchine, Peperoni e Melanzane$txt$
    )
  ) as v(
    internal_code,category,price,display_order,
    allergens,nut_types,name,description
  )
), upserted as (
  insert into public.products (
    internal_code,category,price,display_order,
    publication_status,is_available,
    is_bestseller,is_vegan,is_vegetarian,is_lactose_free,is_spicy,
    allergens,nut_types
  )
  select
    internal_code,category,price,display_order,
    'draft',true,
    false,false,false,false,false,
    allergens,nut_types
  from source_data
  on conflict (internal_code) do update set
    category = excluded.category,
    display_order = excluded.display_order,
    allergens = excluded.allergens,
    nut_types = excluded.nut_types
  returning id, internal_code
)
insert into public.product_translations (
  product_id,language_code,name,description
)
select
  u.id,'it',s.name,s.description
from upserted u
join source_data s using (internal_code)
on conflict (product_id,language_code) do update set
  name = excluded.name,
  description = excluded.description;

commit;

-- Controllo finale: devono comparire 8 righe in stato draft.
select
  p.internal_code,
  pt.name,
  pt.description,
  p.price,
  p.publication_status,
  p.allergens,
  p.nut_types
from public.products p
join public.product_translations pt
  on pt.product_id = p.id
 and pt.language_code = 'it'
where p.internal_code in (
  'MERENDA_SINOIRA','NORMA_BRA','GENOVESE','PARMIGIANA',
  'BAGNET_VERD','POL_TUMIN','FRESCHEZZA_ESTIVA','ORTO_ESTATE'
)
order by p.display_order;
