begin;

-- Ripristina i permessi di lettura pubblica.
grant usage on schema public to anon, authenticated;
grant select on public.products, public.product_translations, public.global_images to anon;

alter table public.products enable row level security;
alter table public.product_translations enable row level security;

-- Ricrea le policy pubbliche, così lo script è rieseguibile.
drop policy if exists "Public can read published available products" on public.products;
create policy "Public can read published available products"
on public.products for select to anon, authenticated
using (publication_status = 'published' and is_available = true);

drop policy if exists "Public can read translations of visible products" on public.product_translations;
create policy "Public can read translations of visible products"
on public.product_translations for select to anon, authenticated
using (
  exists (
    select 1 from public.products
    where products.id = product_translations.product_id
      and products.publication_status = 'published'
      and products.is_available = true
  )
);

-- Inserisce o riallinea l'intero menu italiano attuale.
with source_data as (
  select * from (values
    ('ANTICO','salata',8.90,1,true,false,false,false,false,array['gluten','fish','eggs','mustard','sulphites']::text[],array[]::text[],$txt$L'ANTICO PIEMONTE$txt$,$txt$Girello di Vitello, Salsa Tonnata e Scaglie di Topinambur$txt$),
    ('RUSTICA','salata',7.90,2,true,false,false,true,false,array['gluten','soy']::text[],array[]::text[],$txt$LA RUSTICA D'INVERNO$txt$,$txt$Pancetta Arrotolata, Crema di Patate, Cavolo Viola e Miele di Acacia$txt$),
    ('FRESCHEZZA','salata',7.90,3,true,true,true,true,false,array['gluten','soy','nuts','sulphites']::text[],array['almond']::text[],$txt$FRESCHEZZA CONTADINA$txt$,$txt$Zucchine, Porri Marinati, Scaglie di Mandorle e Maionese Vegana$txt$),
    ('TRICOLORE','salata',10.90,4,false,false,true,false,false,array['gluten','milk']::text[],array[]::text[],$txt$LA TRICOLORE$txt$,$txt$Mozzarella di Bufala, Pomodoro Confit, Rucola ed Emulsione al Basilico$txt$),
    ('BRA_TARTUFO','salata',11.90,5,false,false,false,true,false,array['gluten','milk']::text[],array[]::text[],$txt$BRA AL TARTUFO$txt$,$txt$Salsiccia di Bra, Scaglie di Kinara al Tartufo, Porri Caramellati, Crema di Topinambur$txt$),
    ('ZIO_AMERICA','salata',10.90,6,false,false,false,false,false,array['gluten','milk','celery']::text[],array[]::text[],$txt$LO ZIO D'AMERICA$txt$,$txt$Pulled Pork, Zucchine, Provola Affumicata$txt$),
    ('ORTO_AUTUNNO','salata',7.90,7,false,true,true,true,false,array['gluten']::text[],array[]::text[],$txt$L'ORTO D'AUTUNNO$txt$,$txt$Crema di Zucca, Zucchine, Peperoni, Cavolo Viola$txt$),
    ('CARMAGNOLA_BRA','salata',10.90,8,false,false,false,false,false,array['gluten','milk']::text[],array[]::text[],$txt$CARMAGNOLA – BRA$txt$,$txt$Salsiccia di Bra, Peperoni e Provola Affumicata$txt$),
    ('PACCO','salata',7.90,9,false,false,false,false,true,array['gluten','milk']::text[],array[]::text[],$txt$IL PACCO DA GIÙ$txt$,$txt$N'duja, Patate, Mozzarella Fior di Latte, Rucola e Sale Maldon$txt$),
    ('PESCA','salata',10.90,10,false,false,false,false,false,array['gluten','fish','milk','nuts']::text[],array['hazelnut']::text[],$txt$A PESCA NELLE LANGHE$txt$,$txt$Baccalà Mantecato, Spinaci e Granella di Nocciola$txt$),
    ('BOLOGNESE','salata',7.90,11,false,false,false,false,false,array['gluten','milk','nuts','sulphites']::text[],array['pistachio']::text[],$txt$BOLOGNESE IN LANGA$txt$,$txt$Mortadella, Mozzarella Fior di Latte, Gentilina$txt$),
    ('FONDUTA','salata',8.90,12,false,false,false,false,false,array['gluten','milk','sulphites']::text[],array[]::text[],$txt$FONDUTA D'ALTA LANGA$txt$,$txt$Funghi Porcini Trifolati, Fonduta di Toma, Prosciutto Cotto e Glassa di Aceto Balsamico$txt$),
    ('BOSCO_VEGANO','salata',7.90,13,false,true,true,true,false,array['gluten','soy','sulphites']::text[],array[]::text[],$txt$IL BOSCO VEGANO$txt$,$txt$Zucca, Patate e Radicchio Marinato$txt$),
    ('GIANDUJA','dolce',1.00,1,false,false,true,false,false,array['gluten','milk','nuts']::text[],array['hazelnut']::text[],$txt$GIANDUJA$txt$,$txt$Crema alla Nocciola e Granella di Nocciola$txt$),
    ('TIRAMISU','dolce',1.00,2,false,false,true,false,false,array['gluten','milk','eggs']::text[],array[]::text[],$txt$TIRAMISU$txt$,$txt$Crema al Mascarpone e Cacao$txt$),
    ('NUTELLA','dolce',1.00,3,false,false,true,false,false,array['gluten','milk','nuts']::text[],array['hazelnut']::text[],$txt$NUTELLA$txt$,$txt$Non servono presentazioni$txt$),
    ('GORGO_PERE','dolce',1.00,4,false,false,true,false,false,array['gluten','milk','nuts']::text[],array['walnut']::text[],$txt$GORGO E PERE$txt$,$txt$Pere Caramellate, Gorgonzola e Granella di Noci$txt$)
  ) as v(internal_code,category,price,display_order,is_bestseller,is_vegan,is_vegetarian,is_lactose_free,is_spicy,allergens,nut_types,name,description)
), upserted as (
  insert into public.products (
    internal_code,category,price,display_order,publication_status,is_available,
    is_bestseller,is_vegan,is_vegetarian,is_lactose_free,is_spicy,allergens,nut_types
  )
  select internal_code,category,price,display_order,'published',true,
         is_bestseller,is_vegan,is_vegetarian,is_lactose_free,is_spicy,allergens,nut_types
  from source_data
  on conflict (internal_code) do update set
    category=excluded.category,
    price=excluded.price,
    display_order=excluded.display_order,
    publication_status='published',
    is_available=true,
    is_bestseller=excluded.is_bestseller,
    is_vegan=excluded.is_vegan,
    is_vegetarian=excluded.is_vegetarian,
    is_lactose_free=excluded.is_lactose_free,
    is_spicy=excluded.is_spicy,
    allergens=excluded.allergens,
    nut_types=excluded.nut_types
  returning id, internal_code
)
insert into public.product_translations(product_id,language_code,name,description)
select u.id,'it',s.name,s.description
from upserted u
join source_data s using(internal_code)
on conflict(product_id,language_code) do update set
  name=excluded.name,
  description=excluded.description;

commit;

-- Controllo finale: deve restituire 17 righe.
select p.internal_code, pt.name, p.category, p.price, p.publication_status, p.is_available
from public.products p
join public.product_translations pt on pt.product_id=p.id and pt.language_code='it'
order by case when p.category='salata' then 1 else 2 end, p.display_order;
