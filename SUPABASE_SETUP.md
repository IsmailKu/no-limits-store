# Подключение Supabase к NO LIMITS

1. Создайте проект на Supabase.
2. Откройте **SQL Editor** и выполните файл `supabase/migrations/202609220001_no_limits.sql`.
3. Затем выполните `supabase/seed.sql` — он добавит категории и текущие товары.
4. В **Authentication → Users** создайте пользователя администратора вручную (регистрации на сайте нет).
5. В SQL Editor назначьте ему роль, заменив email:

```sql
update auth.users
set raw_app_meta_data = raw_app_meta_data || '{"role":"admin"}'::jsonb
where email = 'admin@example.com';
```

6. В настройках опубликованного сайта добавьте:

```text
VITE_SUPABASE_URL=https://YOUR_PROJECT.supabase.co
VITE_SUPABASE_ANON_KEY=YOUR_PUBLIC_ANON_KEY
VITE_STORE_WHATSAPP=79997772121
```

Публичный `anon key` предназначен для браузера и защищён RLS. `service_role` на сайт добавлять нельзя.

После подключения:

- вход: `/admin/login`;
- управление товарами, категориями, заказами и остатками: `/admin`;
- подтверждение заказа списывает остаток атомарно;
- отмена подтверждённого заказа возвращает остаток;
- новые заявки и изменения товаров поступают в админку в реальном времени.

EmailJS остаётся дополнительным уведомлением. Заказ сначала сохраняется в Supabase, и только затем отправляется письмо.
