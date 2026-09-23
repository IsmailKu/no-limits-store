insert into public.categories(name,slug,sort_order) values
('Протеин','protein',10),('Креатин','creatine',20),('Аминокислоты','amino',30),('Предтреники','preworkout',40),
('Витамины','vitamins',50),('Жиросжигатели','fat-burners',60),('Аксессуары','accessories',70)
on conflict (slug) do nothing;

insert into public.products(slug,name,category_id,price,old_price,stock,weight,flavor,description,badge,image_url,sort_order)
select v.slug,v.name,c.id,v.price,v.old_price,20,v.weight,v.flavor,v.description,v.badge,v.image_url,v.sort_order
from (values
('shadow-whey','DY SHADOWHEY','protein',3290::numeric,3690::numeric,'2000 г','Cookies & Cream','Сывороточный протеин DY Nutrition для ежедневного рациона.','ХИТ','/products/real/shadow-whey-cutout.webp',10),
('dy-creatine','DY CREATINE MONOHYDRATE','creatine',1890::numeric,null,'300 г','Без вкуса','Чистый моногидрат креатина, 1000 мг в порции.','НОВИНКА','/products/real/dy-creatine-cutout.webp',20),
('anabolic-glutamine','ANABOLIC GLUTAMINE','amino',2450::numeric,null,'300 г','Без вкуса','Kevin Levrone Signature Series с витамином B6.',null,'/products/real/anabolic-glutamine-cutout.webp',30),
('shaaboom-pump','SHAABOOM PUMP','preworkout',2690::numeric,null,'385 г',null,'Предтренировочный комплекс Kevin Levrone Signature Series.','ХИТ','/products/real/shaaboom-pump-cutout.webp',40),
('olimp-creatine','OLIMP CREATINE MONOHYDRATE','creatine',2190::numeric,null,'250 г',null,'Моногидрат креатина Olimp Sport Nutrition.',null,'/products/real/olimp-cutout.webp',50),
('vamp-juice','CORE LABS VAMP JUICE','vitamins',1990::numeric,null,'80 капс.',null,'Комплекс Core Labs в капсулах.',null,'/products/real/vamp-cutout.webp',60),
('lotus-black','LOTUS BLACK FAT BURNER','fat-burners',2390::numeric,null,'80 капс.',null,'Капсульный комплекс для контроля формы.','НОВИНКА','/products/real/lotus-cutout.webp',70),
('zinc','FUELUP ZINC PICOLINATE','vitamins',1490::numeric,null,'50 мг',null,'Пиколинат цинка в удобном капсульном формате.',null,'/products/real/zinc-cutout.webp',80),
('carnitine','DY L-CARNITINE XL','fat-burners',1690::numeric,null,'1000 мл','Ананас','Жидкий L-карнитин DY Nutrition.',null,'/products/real/carnitine-cutout.webp',90),
('mass','ULTRA MASS','protein',3790::numeric,4290::numeric,'3000 г','Chocolate Caramel','Высококалорийный гейнер с белково-углеводной формулой.','-20%','/products/real/mass-cutout.webp',100),
('animal-flex','ANIMAL FLEX','vitamins',3190::numeric,null,'44 пакета',null,'Комплексная поддержка суставов и связок.',null,'/products/real/flex-cutout.webp',110),
('animal-pak','ANIMAL PAK','vitamins',3490::numeric,null,'44 пакета',null,'Ежедневный витаминно-минеральный комплекс.','ХИТ','/products/real/pak-cutout.webp',120),
('shaker','NO LIMITS SHAKER','accessories',690::numeric,null,'700 мл',null,'Фирменный шейкер NO LIMITS для тренировок.',null,'/products/real/shaker-cutout.webp',130),
('retatrutide','RETATRUTIDE','amino',2890::numeric,null,'4 мг',null,'Специализированный продукт; перед применением требуется консультация.',null,'/products/real/retatrutide-cutout.webp',140)
) as v(slug,name,category_slug,price,old_price,weight,flavor,description,badge,image_url,sort_order)
join public.categories c on c.slug=v.category_slug
on conflict (slug) do nothing;

-- После создания пользователя в Supabase Auth назначьте роль администратора в SQL Editor:
-- update auth.users set raw_app_meta_data = raw_app_meta_data || '{"role":"admin"}'::jsonb where email='admin@example.com';
