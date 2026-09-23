create extension if not exists pgcrypto;

create type public.order_status as enum ('new','confirmed','processing','shipped','completed','cancelled');

create table public.categories (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  slug text not null unique,
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.products (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  name text not null,
  category_id uuid references public.categories(id) on delete set null,
  price numeric(12,2) not null check (price >= 0),
  old_price numeric(12,2) check (old_price is null or old_price >= price),
  stock integer not null default 0 check (stock >= 0),
  low_stock_threshold integer not null default 5 check (low_stock_threshold >= 0),
  weight text not null default '',
  flavor text,
  description text not null default '',
  badge text,
  image_url text not null default '',
  gallery_urls text[] not null default '{}',
  sort_order integer not null default 0,
  is_active boolean not null default true,
  deleted_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create sequence public.order_number_seq start 1001;

create table public.orders (
  id uuid primary key default gen_random_uuid(),
  order_number text not null unique default ('NL-' || lpad(nextval('public.order_number_seq')::text, 6, '0')),
  customer_name text,
  customer_phone text not null,
  customer_email text,
  delivery_method text,
  delivery_address text,
  comment text,
  manager_note text,
  tracking_number text,
  status public.order_status not null default 'new',
  total numeric(12,2) not null default 0 check (total >= 0),
  stock_applied boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  product_id uuid references public.products(id) on delete set null,
  product_name text not null,
  product_weight text,
  quantity integer not null check (quantity > 0),
  unit_price numeric(12,2) not null check (unit_price >= 0),
  line_total numeric(12,2) generated always as (quantity * unit_price) stored,
  created_at timestamptz not null default now()
);

create table public.order_status_history (
  id bigint generated always as identity primary key,
  order_id uuid not null references public.orders(id) on delete cascade,
  from_status public.order_status,
  to_status public.order_status not null,
  changed_by uuid references auth.users(id),
  created_at timestamptz not null default now()
);

create index products_catalog_idx on public.products(is_active, deleted_at, sort_order);
create index products_category_idx on public.products(category_id);
create index orders_status_created_idx on public.orders(status, created_at desc);
create index order_items_order_idx on public.order_items(order_id);

create or replace function public.set_updated_at() returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end $$;
create trigger categories_updated_at before update on public.categories for each row execute function public.set_updated_at();
create trigger products_updated_at before update on public.products for each row execute function public.set_updated_at();
create trigger orders_updated_at before update on public.orders for each row execute function public.set_updated_at();

create or replace function public.is_admin() returns boolean
language sql stable security definer set search_path = public, auth as $$
  select coalesce((select raw_app_meta_data ->> 'role' = 'admin' from auth.users where id = auth.uid()), false)
$$;

create or replace function public.create_order(
  p_customer jsonb,
  p_items jsonb
) returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v_order public.orders;
  v_item jsonb;
  v_product public.products;
  v_total numeric(12,2) := 0;
  v_qty integer;
begin
  if nullif(trim(p_customer->>'phone'), '') is null then raise exception 'PHONE_REQUIRED'; end if;
  if jsonb_array_length(p_items) = 0 then raise exception 'EMPTY_ORDER'; end if;

  for v_item in select * from jsonb_array_elements(p_items) loop
    v_qty := (v_item->>'quantity')::integer;
    select * into v_product from public.products
      where id = (v_item->>'product_id')::uuid and is_active and deleted_at is null
      for share;
    if not found then raise exception 'PRODUCT_NOT_FOUND'; end if;
    if v_qty <= 0 or v_product.stock < v_qty then raise exception 'INSUFFICIENT_STOCK:%', v_product.name; end if;
    v_total := v_total + (v_product.price * v_qty);
  end loop;

  insert into public.orders(customer_name, customer_phone, customer_email, delivery_method, delivery_address, comment, total)
  values (nullif(trim(p_customer->>'name'),''), trim(p_customer->>'phone'), nullif(trim(p_customer->>'email'),''),
          nullif(trim(p_customer->>'delivery_method'),''), nullif(trim(p_customer->>'address'),''), nullif(trim(p_customer->>'comment'),''), v_total)
  returning * into v_order;

  for v_item in select * from jsonb_array_elements(p_items) loop
    select * into v_product from public.products where id = (v_item->>'product_id')::uuid;
    v_qty := (v_item->>'quantity')::integer;
    insert into public.order_items(order_id, product_id, product_name, product_weight, quantity, unit_price)
    values(v_order.id, v_product.id, v_product.name, v_product.weight, v_qty, v_product.price);
  end loop;
  return jsonb_build_object('id', v_order.id, 'order_number', v_order.order_number, 'total', v_order.total);
end $$;

create or replace function public.change_order_status(p_order_id uuid, p_status public.order_status)
returns public.orders
language plpgsql security definer set search_path = public as $$
declare v_order public.orders; v_item public.order_items; v_old public.order_status;
begin
  if not public.is_admin() then raise exception 'FORBIDDEN'; end if;
  select * into v_order from public.orders where id = p_order_id for update;
  if not found then raise exception 'ORDER_NOT_FOUND'; end if;
  v_old := v_order.status;

  if p_status = 'confirmed' and not v_order.stock_applied then
    for v_item in select * from public.order_items where order_id = p_order_id loop
      update public.products set stock = stock - v_item.quantity
      where id = v_item.product_id and stock >= v_item.quantity;
      if not found then raise exception 'INSUFFICIENT_STOCK:%', v_item.product_name; end if;
    end loop;
    v_order.stock_applied := true;
  elsif p_status = 'cancelled' and v_order.stock_applied then
    update public.products p set stock = p.stock + i.quantity
    from public.order_items i where i.order_id = p_order_id and i.product_id = p.id;
    v_order.stock_applied := false;
  end if;

  update public.orders set status = p_status, stock_applied = v_order.stock_applied where id = p_order_id returning * into v_order;
  insert into public.order_status_history(order_id, from_status, to_status, changed_by) values(p_order_id, v_old, p_status, auth.uid());
  return v_order;
end $$;

alter table public.categories enable row level security;
alter table public.products enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;
alter table public.order_status_history enable row level security;

create policy categories_public_read on public.categories for select using (is_active or public.is_admin());
create policy categories_admin_write on public.categories for all using (public.is_admin()) with check (public.is_admin());
create policy products_public_read on public.products for select using ((is_active and deleted_at is null) or public.is_admin());
create policy products_admin_write on public.products for all using (public.is_admin()) with check (public.is_admin());
create policy orders_admin_read on public.orders for select using (public.is_admin());
create policy orders_admin_write on public.orders for all using (public.is_admin()) with check (public.is_admin());
create policy order_items_admin_all on public.order_items for all using (public.is_admin()) with check (public.is_admin());
create policy order_history_admin_read on public.order_status_history for select using (public.is_admin());

grant execute on function public.create_order(jsonb,jsonb) to anon, authenticated;
grant execute on function public.change_order_status(uuid,public.order_status) to authenticated;

insert into storage.buckets(id, name, public) values ('product-images','product-images',true) on conflict (id) do update set public = true;
create policy product_images_public_read on storage.objects for select using (bucket_id = 'product-images');
create policy product_images_admin_insert on storage.objects for insert with check (bucket_id = 'product-images' and public.is_admin());
create policy product_images_admin_update on storage.objects for update using (bucket_id = 'product-images' and public.is_admin());
create policy product_images_admin_delete on storage.objects for delete using (bucket_id = 'product-images' and public.is_admin());

alter publication supabase_realtime add table public.products;
alter publication supabase_realtime add table public.orders;
