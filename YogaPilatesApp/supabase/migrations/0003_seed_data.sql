-- =====================================================================
--  SEED-данные «Йога & Пилатес Студия»
--  Применять ПОСЛЕ schema.sql и 0002_schedule_booking.sql.
--
--  ВНИМАНИЕ (auth): тестовые пользователи создаются прямой вставкой в
--  auth.users / auth.identities. Набор колонок auth.users может меняться
--  между версиями Supabase/GoTrue. Если вставка в auth.* упадёт — создайте
--  пользователей через Dashboard (Authentication → Add user) с теми же
--  UUID и e-mail, а блок auth.* в этом файле закомментируйте.
--
--  Имена таблиц/колонок соответствуют нашему schema.sql:
--   * залы — halls (без address; адрес — в studios),
--   * баллы — bonus_accounts.balance (а не profiles.bonus_balance),
--   * абонементы — membership_plans + client_memberships
--     (а не subscriptions/user_subscriptions).
--
--  Пароль у всех тестовых пользователей: Passw0rd!
-- =====================================================================

begin;

-- ---------------------------------------------------------------------
--  1. Студия, залы
-- ---------------------------------------------------------------------
insert into studios (id, name, description, address, phone, email, working_hours)
values (
    'a0000000-0000-4000-8000-000000000001',
    'Йога & Пилатес Студия',
    'Студия йоги и пилатеса в центре города.',
    'г. Москва, ул. Примерная, д. 1',
    '+74950000000',
    'info@yoga.test',
    '{"mon":"08:00-22:00","tue":"08:00-22:00","wed":"08:00-22:00","thu":"08:00-22:00","fri":"08:00-22:00","sat":"09:00-20:00","sun":"09:00-18:00"}'
) on conflict (id) do nothing;

insert into halls (id, studio_id, name, capacity) values
    ('a0000000-0000-4000-8000-000000000011', 'a0000000-0000-4000-8000-000000000001', 'Основной зал', 15),
    ('a0000000-0000-4000-8000-000000000012', 'a0000000-0000-4000-8000-000000000001', 'Малый зал', 8)
on conflict (id) do nothing;

-- ---------------------------------------------------------------------
--  2. Типы занятий (с цветами для календаря)
-- ---------------------------------------------------------------------
insert into class_types (id, name, color) values
    ('a0000000-0000-4000-8000-000000000021', 'Йога',        '#1A73E8'),
    ('a0000000-0000-4000-8000-000000000022', 'Пилатес',     '#34A853'),
    ('a0000000-0000-4000-8000-000000000023', 'Стретчинг',   '#F9AB00'),
    ('a0000000-0000-4000-8000-000000000024', 'Хатха-йога',  '#9C27B0'),
    ('a0000000-0000-4000-8000-000000000025', 'Йога-нидра',  '#00897B'),
    ('a0000000-0000-4000-8000-000000000026', 'Аэройога',    '#E91E63')
on conflict (id) do nothing;

-- ---------------------------------------------------------------------
--  3. Преподаватели
-- ---------------------------------------------------------------------
insert into instructors (id, full_name, bio, photo_url, rating) values
    ('a0000000-0000-4000-8000-000000000031', 'Анна Иванова',    'Сертифицированный инструктор по йоге, 8 лет опыта.', 'https://i.pravatar.cc/150?img=31', 4.9),
    ('a0000000-0000-4000-8000-000000000032', 'Мария Петрова',   'Преподаватель пилатеса и стретчинга.',              'https://i.pravatar.cc/150?img=32', 4.8),
    ('a0000000-0000-4000-8000-000000000033', 'Елена Смирнова',  'Хатха-йога и йога-нидра.',                          'https://i.pravatar.cc/150?img=33', 4.7),
    ('a0000000-0000-4000-8000-000000000034', 'Дмитрий Орлов',   'Аэройога и силовые практики.',                      'https://i.pravatar.cc/150?img=34', 4.6),
    ('a0000000-0000-4000-8000-000000000035', 'Ольга Кузнецова', 'Йога для начинающих.',                              'https://i.pravatar.cc/150?img=35', 5.0)
on conflict (id) do nothing;

-- ---------------------------------------------------------------------
--  4. Абонементы (тарифы)
-- ---------------------------------------------------------------------
insert into membership_plans (id, name, kind, classes_count, duration_days, price) values
    ('a0000000-0000-4000-8000-000000000041', 'Абонемент 4 занятия',  'count_based', 4,  30,  4000),
    ('a0000000-0000-4000-8000-000000000042', 'Абонемент 8 занятий',  'count_based', 8,  30,  7000),
    ('a0000000-0000-4000-8000-000000000043', 'Безлимит на месяц',    'unlimited',   null, 30, 12000)
on conflict (id) do nothing;

-- ---------------------------------------------------------------------
--  5. Тестовые пользователи (auth.users + auth.identities)
--     Пароль: Passw0rd!  (crypt/gen_salt — из расширения pgcrypto)
-- ---------------------------------------------------------------------
insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password,
    email_confirmed_at, created_at, updated_at,
    raw_app_meta_data, raw_user_meta_data
) values
    ('00000000-0000-0000-0000-000000000000','b0000000-0000-4000-8000-0000000000c1','authenticated','authenticated','client1@yoga.test', crypt('Passw0rd!', gen_salt('bf')), now(), now(), now(), '{"provider":"email","providers":["email"]}','{"full_name":"Светлана Клиентова"}'),
    ('00000000-0000-0000-0000-000000000000','b0000000-0000-4000-8000-0000000000c2','authenticated','authenticated','client2@yoga.test', crypt('Passw0rd!', gen_salt('bf')), now(), now(), now(), '{"provider":"email","providers":["email"]}','{"full_name":"Игорь Клиентов"}'),
    ('00000000-0000-0000-0000-000000000000','b0000000-0000-4000-8000-0000000000c3','authenticated','authenticated','client3@yoga.test', crypt('Passw0rd!', gen_salt('bf')), now(), now(), now(), '{"provider":"email","providers":["email"]}','{"full_name":"Наталья Клиентова"}'),
    ('00000000-0000-0000-0000-000000000000','b0000000-0000-4000-8000-0000000000c4','authenticated','authenticated','client4@yoga.test', crypt('Passw0rd!', gen_salt('bf')), now(), now(), now(), '{"provider":"email","providers":["email"]}','{"full_name":"Павел Клиентов"}'),
    ('00000000-0000-0000-0000-000000000000','b0000000-0000-4000-8000-0000000000c5','authenticated','authenticated','client5@yoga.test', crypt('Passw0rd!', gen_salt('bf')), now(), now(), now(), '{"provider":"email","providers":["email"]}','{"full_name":"Ирина Клиентова"}'),
    ('00000000-0000-0000-0000-000000000000','b0000000-0000-4000-8000-0000000000a1','authenticated','authenticated','admin@yoga.test',   crypt('Passw0rd!', gen_salt('bf')), now(), now(), now(), '{"provider":"email","providers":["email"]}','{"full_name":"Администратор"}')
on conflict (id) do nothing;

insert into auth.identities (
    id, user_id, identity_data, provider, provider_id,
    last_sign_in_at, created_at, updated_at
) values
    (gen_random_uuid(),'b0000000-0000-4000-8000-0000000000c1', json_build_object('sub','b0000000-0000-4000-8000-0000000000c1','email','client1@yoga.test'),'email','b0000000-0000-4000-8000-0000000000c1', now(), now(), now()),
    (gen_random_uuid(),'b0000000-0000-4000-8000-0000000000c2', json_build_object('sub','b0000000-0000-4000-8000-0000000000c2','email','client2@yoga.test'),'email','b0000000-0000-4000-8000-0000000000c2', now(), now(), now()),
    (gen_random_uuid(),'b0000000-0000-4000-8000-0000000000c3', json_build_object('sub','b0000000-0000-4000-8000-0000000000c3','email','client3@yoga.test'),'email','b0000000-0000-4000-8000-0000000000c3', now(), now(), now()),
    (gen_random_uuid(),'b0000000-0000-4000-8000-0000000000c4', json_build_object('sub','b0000000-0000-4000-8000-0000000000c4','email','client4@yoga.test'),'email','b0000000-0000-4000-8000-0000000000c4', now(), now(), now()),
    (gen_random_uuid(),'b0000000-0000-4000-8000-0000000000c5', json_build_object('sub','b0000000-0000-4000-8000-0000000000c5','email','client5@yoga.test'),'email','b0000000-0000-4000-8000-0000000000c5', now(), now(), now()),
    (gen_random_uuid(),'b0000000-0000-4000-8000-0000000000a1', json_build_object('sub','b0000000-0000-4000-8000-0000000000a1','email','admin@yoga.test'),  'email','b0000000-0000-4000-8000-0000000000a1', now(), now(), now())
on conflict do nothing;

-- ---------------------------------------------------------------------
--  6. Профили (роли) + бонусные счета
-- ---------------------------------------------------------------------
insert into profiles (id, role, full_name, phone, email, birth_date, tier) values
    ('b0000000-0000-4000-8000-0000000000c1','client','Светлана Клиентова','+79110000001','client1@yoga.test','1992-03-15','regular'),
    ('b0000000-0000-4000-8000-0000000000c2','client','Игорь Клиентов',    '+79110000002','client2@yoga.test','1988-07-22','new'),
    ('b0000000-0000-4000-8000-0000000000c3','client','Наталья Клиентова', '+79110000003','client3@yoga.test','1995-11-30','vip'),
    ('b0000000-0000-4000-8000-0000000000c4','client','Павел Клиентов',    '+79110000004','client4@yoga.test','1990-01-10','new'),
    ('b0000000-0000-4000-8000-0000000000c5','client','Ирина Клиентова',   '+79110000005','client5@yoga.test','1993-05-05','regular'),
    ('b0000000-0000-4000-8000-0000000000a1','admin', 'Администратор',     '+79110000099','admin@yoga.test',  '1985-09-01','regular')
on conflict (id) do nothing;

insert into bonus_accounts (client_id, balance) values
    ('b0000000-0000-4000-8000-0000000000c1', 150),
    ('b0000000-0000-4000-8000-0000000000c2', 0),
    ('b0000000-0000-4000-8000-0000000000c3', 500),
    ('b0000000-0000-4000-8000-0000000000c4', 0),
    ('b0000000-0000-4000-8000-0000000000c5', 80)
on conflict (client_id) do nothing;

-- ---------------------------------------------------------------------
--  7. Купленные абонементы (без платежа — payment_id null)
-- ---------------------------------------------------------------------
insert into client_memberships (id, client_id, plan_id, classes_total, classes_left, valid_until, status) values
    (gen_random_uuid(),'b0000000-0000-4000-8000-0000000000c1','a0000000-0000-4000-8000-000000000042', 8, 6, current_date + 30, 'active'),
    (gen_random_uuid(),'b0000000-0000-4000-8000-0000000000c3','a0000000-0000-4000-8000-000000000043', null, null, current_date + 30, 'active')
on conflict do nothing;

-- ---------------------------------------------------------------------
--  8. Расписание — ФИКСИРОВАННЫЕ занятия на сегодня
--     (детерминированные UUID, чтобы привязать записи и лист ожидания)
-- ---------------------------------------------------------------------
insert into scheduled_classes
    (id, class_type_id, instructor_id, hall_id, studio_id, starts_at, ends_at, capacity, difficulty, status, price)
values
    -- FC1: ПОЛНОЕ занятие (3 места) — для проверки листа ожидания
    ('c0000000-0000-4000-8000-0000000000f1','a0000000-0000-4000-8000-000000000021','a0000000-0000-4000-8000-000000000031','a0000000-0000-4000-8000-000000000012','a0000000-0000-4000-8000-000000000001', current_date + time '09:00', current_date + time '10:00', 3, 'beginner','scheduled', 800),
    -- FC2: есть места (10) — клиент client1 сюда записан
    ('c0000000-0000-4000-8000-0000000000f2','a0000000-0000-4000-8000-000000000022','a0000000-0000-4000-8000-000000000032','a0000000-0000-4000-8000-000000000011','a0000000-0000-4000-8000-000000000001', current_date + time '11:00', current_date + time '12:00', 10, 'intermediate','scheduled', 900),
    -- FC3: ОТМЕНЁННОЕ занятие
    ('c0000000-0000-4000-8000-0000000000f3','a0000000-0000-4000-8000-000000000023','a0000000-0000-4000-8000-000000000033','a0000000-0000-4000-8000-000000000012','a0000000-0000-4000-8000-000000000001', current_date + time '18:00', current_date + time '19:00', 8, 'beginner','cancelled', 700),
    -- FC4: полное (2 места) — client1 стоит в листе ожидания
    ('c0000000-0000-4000-8000-0000000000f4','a0000000-0000-4000-8000-000000000024','a0000000-0000-4000-8000-000000000034','a0000000-0000-4000-8000-000000000011','a0000000-0000-4000-8000-000000000001', current_date + time '19:00', current_date + time '20:00', 2, 'advanced','scheduled', 1000)
on conflict (id) do nothing;

-- ---------------------------------------------------------------------
--  9. Расписание — BULK на 14 дней (по 5 занятий в день)
-- ---------------------------------------------------------------------
insert into scheduled_classes
    (id, class_type_id, instructor_id, hall_id, studio_id, starts_at, ends_at, capacity, difficulty, status, price)
select
    gen_random_uuid(),
    s.class_type_id, s.instructor_id, s.hall_id,
    'a0000000-0000-4000-8000-000000000001',
    d + s.slot,
    d + s.slot + interval '1 hour',
    s.capacity, s.difficulty, 'scheduled', s.price
from generate_series(current_date::timestamp, (current_date + interval '13 days')::timestamp, interval '1 day') as d
cross join (values
    (interval '8 hours',  'a0000000-0000-4000-8000-000000000021'::uuid, 'a0000000-0000-4000-8000-000000000035'::uuid, 'a0000000-0000-4000-8000-000000000011'::uuid, 12, 'beginner'::difficulty_level,     700::numeric),
    (interval '10 hours', 'a0000000-0000-4000-8000-000000000022'::uuid, 'a0000000-0000-4000-8000-000000000032'::uuid, 'a0000000-0000-4000-8000-000000000011'::uuid, 10, 'intermediate'::difficulty_level, 900::numeric),
    (interval '12 hours', 'a0000000-0000-4000-8000-000000000025'::uuid, 'a0000000-0000-4000-8000-000000000033'::uuid, 'a0000000-0000-4000-8000-000000000012'::uuid,  8, 'beginner'::difficulty_level,     650::numeric),
    (interval '17 hours', 'a0000000-0000-4000-8000-000000000026'::uuid, 'a0000000-0000-4000-8000-000000000034'::uuid, 'a0000000-0000-4000-8000-000000000012'::uuid,  6, 'advanced'::difficulty_level,     1100::numeric),
    (interval '20 hours', 'a0000000-0000-4000-8000-000000000024'::uuid, 'a0000000-0000-4000-8000-000000000031'::uuid, 'a0000000-0000-4000-8000-000000000011'::uuid, 15, 'intermediate'::difficulty_level, 850::numeric)
) as s(slot, class_type_id, instructor_id, hall_id, capacity, difficulty, price);

-- ---------------------------------------------------------------------
--  10. Записи (bookings) на фиксированные занятия
-- ---------------------------------------------------------------------
insert into bookings (id, scheduled_class_id, client_id, status) values
    -- FC1 заполнено: client1, client2, client3
    (gen_random_uuid(),'c0000000-0000-4000-8000-0000000000f1','b0000000-0000-4000-8000-0000000000c1','booked'),
    (gen_random_uuid(),'c0000000-0000-4000-8000-0000000000f1','b0000000-0000-4000-8000-0000000000c2','booked'),
    (gen_random_uuid(),'c0000000-0000-4000-8000-0000000000f1','b0000000-0000-4000-8000-0000000000c3','booked'),
    -- FC2: client1 записан (есть свободные места)
    (gen_random_uuid(),'c0000000-0000-4000-8000-0000000000f2','b0000000-0000-4000-8000-0000000000c1','booked'),
    -- FC4 заполнено: client2, client3
    (gen_random_uuid(),'c0000000-0000-4000-8000-0000000000f4','b0000000-0000-4000-8000-0000000000c2','booked'),
    (gen_random_uuid(),'c0000000-0000-4000-8000-0000000000f4','b0000000-0000-4000-8000-0000000000c3','booked')
on conflict (scheduled_class_id, client_id) do nothing;

-- ---------------------------------------------------------------------
--  11. Лист ожидания (waitlist)
-- ---------------------------------------------------------------------
insert into waitlist (id, scheduled_class_id, client_id, position, status) values
    -- FC1 (полное): client4 (1), client5 (2)
    (gen_random_uuid(),'c0000000-0000-4000-8000-0000000000f1','b0000000-0000-4000-8000-0000000000c4', 1, 'waiting'),
    (gen_random_uuid(),'c0000000-0000-4000-8000-0000000000f1','b0000000-0000-4000-8000-0000000000c5', 2, 'waiting'),
    -- FC4 (полное): client1 (1) — чтобы увидеть статус «В очереди» под client1
    (gen_random_uuid(),'c0000000-0000-4000-8000-0000000000f4','b0000000-0000-4000-8000-0000000000c1', 1, 'waiting')
on conflict (scheduled_class_id, client_id) do nothing;

commit;

-- =====================================================================
--  Готово. Тестовые аккаунты (пароль у всех: Passw0rd!):
--    client1@yoga.test  — записан на FC2, в очереди на FC4, абонемент 8 (6 ост.)
--    client2@yoga.test  — записан на FC1, FC4
--    client3@yoga.test  — записан на FC1, FC4, безлимит-абонемент
--    client4@yoga.test  — в листе ожидания FC1 (поз. 1)
--    client5@yoga.test  — в листе ожидания FC1 (поз. 2)
--    admin@yoga.test    — роль admin (доступ к админ-панели)
--
--  Проверка листа ожидания: войдите как client1, отмените запись на FC1?
--  (client1 не записан на FC1) → лучше отменить FC1 от client2 — тогда
--  client4 автоматически перейдёт из очереди в запись и получит уведомление.
-- =====================================================================
