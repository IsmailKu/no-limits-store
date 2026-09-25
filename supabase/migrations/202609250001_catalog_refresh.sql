-- Apply once in Supabase SQL Editor for an existing NO LIMITS database.
begin;

alter table public.products
  add column if not exists featured_order integer;

insert into public.categories (name, slug, sort_order, is_active) values
  ('Пептиды', 'peptides', 70, true),
  ('Гейнеры', 'gainers', 80, true),
  ('Бустеры тестостерона', 'testosterone-boosters', 90, true),
  ('Добавки для суставов и связок', 'joint-support', 100, true),
  ('L-карнитины', 'l-carnitine', 110, true),
  ('Для ПКТ', 'pct', 120, true)
on conflict (slug) do update
  set name = excluded.name,
      sort_order = excluded.sort_order,
      is_active = true;

update public.products p set category_id = c.id
from public.categories c
where (p.slug = 'retatrutide' and c.slug = 'peptides')
   or (p.slug = 'mass' and c.slug = 'gainers')
   or (p.slug = 'animal-flex' and c.slug = 'joint-support')
   or (p.slug = 'carnitine' and c.slug = 'l-carnitine');

-- Accessories are no longer a storefront filter. Keep old records intact.
update public.categories set is_active = false where slug = 'accessories';

-- Initial carousel stays visually the same until edited in the admin panel.
update public.products set featured_order = case slug
  when 'shadow-whey' then 1
  when 'dy-creatine' then 2
  when 'anabolic-glutamine' then 3
  when 'shaaboom-pump' then 4
  else featured_order
end
where slug in ('shadow-whey','dy-creatine','anabolic-glutamine','shaaboom-pump');

commit;
