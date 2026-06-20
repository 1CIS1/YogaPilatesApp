-- =====================================================================
--  Йога & Пилатес Студия — Схема БД (PostgreSQL / Supabase)
--  Версия: 1.0  (MVP + перспективные сущности)
--  Кодировка: UTF-8
--
--  Принципы:
--   * Все PK — uuid (gen_random_uuid()).
--   * Профили пользователей привязаны к auth.users (Supabase Auth).
--   * Денежные значения — numeric(12,2), валюта по умолчанию RUB.
--   * Включён RLS на всех пользовательских таблицах (политики — ниже).
--   * audit_log защищён от UPDATE/DELETE на уровне политик и триггера.
-- =====================================================================

-- Расширения -----------------------------------------------------------
create extension if not exists "pgcrypto";   -- gen_random_uuid()

-- =====================================================================
--  1. ENUM-ТИПЫ
-- =====================================================================
create type app_role            as enum ('owner', 'senior_admin', 'admin', 'client');
create type difficulty_level    as enum ('beginner', 'intermediate', 'advanced');
create type class_status        as enum ('scheduled', 'cancelled', 'completed');
create type booking_status      as enum ('booked', 'attended', 'no_show',
                                         'cancelled_by_client', 'cancelled_by_admin');
create type waitlist_status     as enum ('waiting', 'promoted', 'expired', 'cancelled');
create type membership_kind     as enum ('count_based', 'unlimited', 'time_restricted', 'package');
create type membership_status   as enum ('active', 'expired', 'frozen', 'used_up');
create type purchase_type       as enum ('single_class', 'membership', 'package', 'gift_certificate');
create type payment_method      as enum ('card', 'apple_pay', 'google_pay', 'bonus', 'gift_certificate', 'cash');
create type payment_status      as enum ('pending', 'succeeded', 'failed', 'refunded', 'partially_refunded');
create type client_tier         as enum ('new', 'regular', 'vip');
create type bonus_txn_type      as enum ('earn', 'redeem', 'manual_add', 'manual_remove', 'birthday', 'expire');
create type notification_channel as enum ('push', 'email', 'sms', 'in_app');
create type notification_status as enum ('queued', 'sent', 'delivered', 'read', 'failed');
create type contract_status     as enum ('draft', 'sent', 'signed');
create type device_platform     as enum ('android', 'ios');

-- =====================================================================
--  2. СТУДИЯ, ЗАЛЫ, ОБ ОРГАНИЗАЦИИ
-- =====================================================================
create table studios (
    id            uuid primary key default gen_random_uuid(),
    name          text not null,
    description   text,
    address       text,
    phone         text,
    email         text,
    working_hours jsonb,                       -- {"mon":"08:00-22:00", ...}
    latitude      double precision,
    longitude     double precision,
    created_at    timestamptz not null default now()
);

create table halls (
    id         uuid primary key default gen_random_uuid(),
    studio_id  uuid not null references studios(id) on delete cascade,
    name       text not null,
    capacity   int  not null check (capacity > 0)
);

create table studio_photos (
    id         uuid primary key default gen_random_uuid(),
    studio_id  uuid not null references studios(id) on delete cascade,
    url        text not null,
    sort_order int  not null default 0
);

-- =====================================================================
--  3. ПОЛЬЗОВАТЕЛИ / ПЕРСОНАЛ / ПРЕПОДАВАТЕЛИ
-- =====================================================================
-- Профиль расширяет auth.users (1:1). role = client | admin | senior_admin | owner.
create table profiles (
    id                   uuid primary key references auth.users(id) on delete cascade,
    role                 app_role    not null default 'client',
    full_name            text,
    phone                text,
    email                text,
    birth_date           date,
    tier                 client_tier not null default 'new',
    personal_discount_pct numeric(5,2) not null default 0 check (personal_discount_pct between 0 and 100),
    is_blocked           boolean     not null default false,
    blocked_reason       text,
    rules_accepted_at    timestamptz,
    rules_version        int,
    notify_prefs         jsonb       not null default '{"push":true,"email":true,"sms":false}'::jsonb,
    created_at           timestamptz not null default now()
);

create table instructors (
    id         uuid primary key default gen_random_uuid(),
    full_name  text not null,
    bio        text,
    photo_url  text,
    rating     numeric(3,2) not null default 0 check (rating between 0 and 5),
    is_active  boolean not null default true,
    created_at timestamptz not null default now()
);

create table push_tokens (
    id         uuid primary key default gen_random_uuid(),
    profile_id uuid not null references profiles(id) on delete cascade,
    token      text not null,
    platform   device_platform not null,
    created_at timestamptz not null default now(),
    unique (token)
);

-- =====================================================================
--  4. КАТАЛОГ ЗАНЯТИЙ И РАСПИСАНИЕ
-- =====================================================================
create table class_types (
    id          uuid primary key default gen_random_uuid(),
    name        text not null,                  -- Йога, Пилатес, Стретчинг ...
    description text,
    color       text,                           -- для UI-календаря
    is_active   boolean not null default true
);

create table scheduled_classes (
    id             uuid primary key default gen_random_uuid(),
    class_type_id  uuid not null references class_types(id),
    instructor_id  uuid references instructors(id),
    hall_id        uuid references halls(id),
    studio_id      uuid references studios(id),
    starts_at      timestamptz not null,
    ends_at        timestamptz not null,
    capacity       int  not null check (capacity > 0),
    difficulty     difficulty_level not null default 'beginner',
    status         class_status not null default 'scheduled',
    price          numeric(12,2) not null default 0,
    created_by     uuid references profiles(id),
    created_at     timestamptz not null default now(),
    check (ends_at > starts_at)
);
create index idx_sched_starts_at on scheduled_classes (starts_at);
create index idx_sched_type      on scheduled_classes (class_type_id);
create index idx_sched_instr     on scheduled_classes (instructor_id);

-- =====================================================================
--  5. АБОНЕМЕНТЫ, ПАКЕТЫ, СЕРТИФИКАТЫ, ПРОМОКОДЫ
-- =====================================================================
create table membership_plans (
    id               uuid primary key default gen_random_uuid(),
    name             text not null,
    kind             membership_kind not null,
    classes_count    int,                       -- для count_based / package
    duration_days    int,                       -- срок действия
    time_restriction jsonb,                      -- {"window":"morning","from":"06:00","to":"12:00"}
    price            numeric(12,2) not null,
    is_active        boolean not null default true,
    created_at       timestamptz not null default now()
);

create table client_memberships (
    id            uuid primary key default gen_random_uuid(),
    client_id     uuid not null references profiles(id) on delete cascade,
    plan_id       uuid not null references membership_plans(id),
    classes_total int,
    classes_left  int,
    valid_from    date not null default current_date,
    valid_until   date,
    status        membership_status not null default 'active',
    payment_id    uuid,                          -- FK добавляется после payments
    created_at    timestamptz not null default now()
);
create index idx_cm_client on client_memberships (client_id);

create table gift_certificates (
    id            uuid primary key default gen_random_uuid(),
    code          text not null unique,
    amount        numeric(12,2),                 -- на сумму ...
    classes_count int,                           -- ... или на кол-во занятий
    purchaser_id  uuid references profiles(id),
    recipient_email text,
    is_redeemed   boolean not null default false,
    redeemed_by   uuid references profiles(id),
    redeemed_at   timestamptz,
    valid_until   date,
    created_at    timestamptz not null default now()
);

create table promo_codes (
    id            uuid primary key default gen_random_uuid(),
    code          text not null unique,
    discount_type text not null check (discount_type in ('percent','amount')),
    discount_value numeric(12,2) not null,
    valid_from    date,
    valid_until   date,
    usage_limit   int,
    used_count    int not null default 0,
    is_active     boolean not null default true
);

-- =====================================================================
--  6. ПЛАТЕЖИ И ФИСКАЛИЗАЦИЯ (54-ФЗ)
-- =====================================================================
create table payments (
    id                  uuid primary key default gen_random_uuid(),
    client_id           uuid not null references profiles(id),
    amount              numeric(12,2) not null,
    currency            char(3) not null default 'RUB',
    method              payment_method not null,
    status              payment_status not null default 'pending',
    purchase_type       purchase_type not null,
    related_id          uuid,                     -- ссылка на abonement/занятие/сертификат
    provider            text,                     -- yookassa | cloudpayments | stripe
    provider_payment_id text,
    promo_code_id       uuid references promo_codes(id),
    created_at          timestamptz not null default now()
);
create index idx_pay_client on payments (client_id);
create index idx_pay_created on payments (created_at);

-- Привязка оплаченного абонемента к платежу
alter table client_memberships
    add constraint fk_cm_payment foreign key (payment_id) references payments(id);

create table receipts (                           -- фискальные чеки
    id              uuid primary key default gen_random_uuid(),
    payment_id      uuid not null references payments(id) on delete cascade,
    fiscal_provider text,                          -- atol | yookassa
    fiscal_doc_number text,
    status          text,
    sent_to_email   text,
    sent_to_phone   text,
    url             text,
    created_at      timestamptz not null default now()
);

-- =====================================================================
--  7. ЗАПИСИ И ЛИСТ ОЖИДАНИЯ
-- =====================================================================
create table bookings (
    id                  uuid primary key default gen_random_uuid(),
    scheduled_class_id  uuid not null references scheduled_classes(id) on delete cascade,
    client_id           uuid not null references profiles(id) on delete cascade,
    status              booking_status not null default 'booked',
    membership_id       uuid references client_memberships(id),  -- если списано с абонемента
    payment_id          uuid references payments(id),            -- если разовая оплата
    check_in_method     text,                                    -- qr | manual
    booked_at           timestamptz not null default now(),
    cancelled_at        timestamptz,
    attended_at         timestamptz,
    unique (scheduled_class_id, client_id)
);
create index idx_book_class  on bookings (scheduled_class_id);
create index idx_book_client on bookings (client_id);

create table waitlist (
    id                  uuid primary key default gen_random_uuid(),
    scheduled_class_id  uuid not null references scheduled_classes(id) on delete cascade,
    client_id           uuid not null references profiles(id) on delete cascade,
    position            int  not null,
    status              waitlist_status not null default 'waiting',
    created_at          timestamptz not null default now(),
    promoted_at         timestamptz,
    unique (scheduled_class_id, client_id)
);
create index idx_wl_class on waitlist (scheduled_class_id, position);

-- =====================================================================
--  8. БОНУСНАЯ СИСТЕМА
-- =====================================================================
create table bonus_accounts (
    client_id uuid primary key references profiles(id) on delete cascade,
    balance   int not null default 0 check (balance >= 0)
);

create table bonus_transactions (
    id            uuid primary key default gen_random_uuid(),
    client_id     uuid not null references profiles(id) on delete cascade,
    type          bonus_txn_type not null,
    amount        int not null,                  -- + начисление / - списание
    reason        text,
    balance_after int not null,
    admin_id      uuid references profiles(id),  -- кто провёл (если вручную)
    created_at    timestamptz not null default now()
);
create index idx_bonus_client on bonus_transactions (client_id, created_at);

-- =====================================================================
--  9. CRM: ШАБЛОНЫ И РАССЫЛКИ
-- =====================================================================
create table notification_templates (
    id         uuid primary key default gen_random_uuid(),
    code       text not null unique,             -- welcome | reminder_24h | birthday ...
    channel    notification_channel not null,
    subject    text,
    body       text not null,                    -- с переменными {{имя}}, {{занятие}} ...
    variables  jsonb,
    is_active  boolean not null default true,
    created_at timestamptz not null default now()
);

create table campaigns (
    id              uuid primary key default gen_random_uuid(),
    template_id     uuid references notification_templates(id),
    audience_filter jsonb,                        -- {"tier":"vip"} | {"birthday_today":true}
    scheduled_at    timestamptz,
    sent_at         timestamptz,
    status          text not null default 'draft',
    stats           jsonb,                        -- {"sent":120,"opened":80}
    created_by      uuid references profiles(id),
    created_at      timestamptz not null default now()
);

create table notifications (
    id         uuid primary key default gen_random_uuid(),
    client_id  uuid not null references profiles(id) on delete cascade,
    channel    notification_channel not null,
    title      text,
    body       text not null,
    data       jsonb,
    status     notification_status not null default 'queued',
    is_read    boolean not null default false,
    read_at    timestamptz,
    sent_at    timestamptz,
    created_at timestamptz not null default now()
);
create index idx_notif_client on notifications (client_id, created_at);

-- =====================================================================
--  10. ДОГОВОРЫ
-- =====================================================================
create table contract_templates (
    id         uuid primary key default gen_random_uuid(),
    name       text not null,
    file_url   text,                              -- исходный PDF/DOCX-шаблон
    body       text,                              -- тело с переменными
    created_at timestamptz not null default now()
);

create table contracts (
    id                uuid primary key default gen_random_uuid(),
    client_id         uuid not null references profiles(id) on delete cascade,
    template_id       uuid references contract_templates(id),
    status            contract_status not null default 'draft',
    generated_pdf_url text,
    signature_consent boolean not null default false,
    signed_at         timestamptz,
    uploaded_scan_url text,
    created_at        timestamptz not null default now()
);

-- =====================================================================
--  11. ПРАВИЛА СТУДИИ
-- =====================================================================
create table studio_rules (
    id           uuid primary key default gen_random_uuid(),
    version      int not null,
    content      text not null,
    published_at timestamptz not null default now(),
    unique (version)
);

create table rule_acceptances (
    id            uuid primary key default gen_random_uuid(),
    client_id     uuid not null references profiles(id) on delete cascade,
    rules_version int not null,
    accepted_at   timestamptz not null default now(),
    unique (client_id, rules_version)
);

-- =====================================================================
--  12. НОВОСТИ И ОТЗЫВЫ
-- =====================================================================
create table news_posts (
    id           uuid primary key default gen_random_uuid(),
    author_id    uuid references profiles(id),
    title        text not null,
    body         text,
    media        jsonb,                           -- [{"type":"image","url":...}]
    is_published boolean not null default false,
    published_at timestamptz,
    created_at   timestamptz not null default now()
);

create table news_comments (
    id         uuid primary key default gen_random_uuid(),
    post_id    uuid not null references news_posts(id) on delete cascade,
    client_id  uuid not null references profiles(id) on delete cascade,
    body       text not null,
    created_at timestamptz not null default now()
);

create table class_reviews (
    id                 uuid primary key default gen_random_uuid(),
    booking_id         uuid references bookings(id) on delete set null,
    client_id          uuid not null references profiles(id) on delete cascade,
    scheduled_class_id uuid references scheduled_classes(id) on delete set null,
    instructor_id      uuid references instructors(id),
    rating             int not null check (rating between 1 and 5),
    comment            text,
    created_at         timestamptz not null default now()
);

-- =====================================================================
--  13. AUDIT LOG (только чтение/добавление)
-- =====================================================================
create table audit_log (
    id          uuid primary key default gen_random_uuid(),
    admin_id    uuid references profiles(id),
    action      text not null,                   -- booking.cancel | client.update | payment.refund ...
    entity_type text,
    entity_id   uuid,
    details     jsonb,
    ip_address  inet,
    created_at  timestamptz not null default now()
);
create index idx_audit_admin on audit_log (admin_id, created_at);

-- Запрет UPDATE/DELETE логов на уровне триггера
create or replace function prevent_audit_mutation() returns trigger as $$
begin
    raise exception 'audit_log is append-only';
end;
$$ language plpgsql;

create trigger trg_audit_no_update before update on audit_log
    for each row execute function prevent_audit_mutation();
create trigger trg_audit_no_delete before delete on audit_log
    for each row execute function prevent_audit_mutation();

-- =====================================================================
--  14. ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ДЛЯ RLS
-- =====================================================================
-- Возвращает роль текущего пользователя из profiles.
create or replace function current_role_name() returns app_role as $$
    select role from profiles where id = auth.uid();
$$ language sql stable security definer;

create or replace function is_staff() returns boolean as $$
    select coalesce(current_role_name() in ('owner','senior_admin','admin'), false);
$$ language sql stable security definer;

-- =====================================================================
--  15. ВКЛЮЧЕНИЕ RLS + БАЗОВЫЕ ПОЛИТИКИ
--      (клиент видит/меняет только своё; персонал видит всё)
-- =====================================================================
alter table profiles            enable row level security;
alter table bookings            enable row level security;
alter table waitlist            enable row level security;
alter table client_memberships  enable row level security;
alter table payments            enable row level security;
alter table bonus_accounts      enable row level security;
alter table bonus_transactions  enable row level security;
alter table notifications       enable row level security;
alter table contracts           enable row level security;
alter table class_reviews       enable row level security;
alter table audit_log           enable row level security;

-- profiles: клиент видит/правит свой профиль; персонал — все.
create policy profiles_select_self_or_staff on profiles
    for select using (id = auth.uid() or is_staff());
create policy profiles_update_self on profiles
    for update using (id = auth.uid()) with check (id = auth.uid());
create policy profiles_staff_all on profiles
    for all using (is_staff()) with check (is_staff());

-- Защита от повышения привилегий: клиент не может сам менять
-- роль, статус, персональную скидку и флаг блокировки — только персонал.
create or replace function guard_profile_privileged_fields() returns trigger as $$
begin
    if is_staff() then
        return new;  -- персоналу можно всё
    end if;
    if new.role is distinct from old.role
       or new.tier is distinct from old.tier
       or new.personal_discount_pct is distinct from old.personal_discount_pct
       or new.is_blocked is distinct from old.is_blocked then
        raise exception 'Изменение привилегированных полей профиля запрещено';
    end if;
    return new;
end;
$$ language plpgsql security definer;

create trigger trg_profiles_guard before update on profiles
    for each row execute function guard_profile_privileged_fields();

-- bookings: клиент — свои; персонал — все.
create policy bookings_self on bookings
    for select using (client_id = auth.uid() or is_staff());
create policy bookings_insert_self on bookings
    for insert with check (client_id = auth.uid() or is_staff());
create policy bookings_staff on bookings
    for all using (is_staff()) with check (is_staff());

-- Шаблон «своё или персонал» для остальных клиентских таблиц
create policy wl_self        on waitlist           for select using (client_id = auth.uid() or is_staff());
create policy cm_self        on client_memberships for select using (client_id = auth.uid() or is_staff());
create policy pay_self       on payments           for select using (client_id = auth.uid() or is_staff());
create policy bonus_acc_self on bonus_accounts     for select using (client_id = auth.uid() or is_staff());
create policy bonus_txn_self on bonus_transactions for select using (client_id = auth.uid() or is_staff());
create policy notif_self     on notifications      for select using (client_id = auth.uid() or is_staff());
create policy contracts_self on contracts          for select using (client_id = auth.uid() or is_staff());
create policy reviews_read   on class_reviews      for select using (true);
create policy reviews_write  on class_reviews      for insert with check (client_id = auth.uid());

-- audit_log: только персонал читает, добавлять может любой аутентифицированный
create policy audit_select_staff on audit_log for select using (is_staff());
create policy audit_insert       on audit_log for insert with check (auth.uid() is not null);

-- =====================================================================
--  Конец схемы v1.0
-- =====================================================================
