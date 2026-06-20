-- =====================================================================
--  Модуль «Личный кабинет» — RPC-функции
--  Зависит от schema.sql. Применять после 0002/0003.
-- =====================================================================

-- ---------------------------------------------------------------------
--  1. get_my_schedule — записи + лист ожидания текущего пользователя
--     в одном списке (для экрана «Мои занятия»).
-- ---------------------------------------------------------------------
create or replace function get_my_schedule()
returns table (
    item_id            uuid,
    kind               text,            -- 'booking' | 'waitlist'
    scheduled_class_id uuid,
    starts_at          timestamptz,
    ends_at            timestamptz,
    class_type_name    text,
    class_type_color   text,
    instructor_name    text,
    hall_name          text,
    booking_status     booking_status,  -- для kind='booking'
    waitlist_position  int,             -- для kind='waitlist'
    is_past            boolean
)
language sql
stable
security definer
set search_path = public
as $$
    -- Записи
    select
        b.id, 'booking'::text, sc.id, sc.starts_at, sc.ends_at,
        ct.name, ct.color, i.full_name, h.name,
        b.status, null::int, (sc.ends_at < now())
    from bookings b
    join scheduled_classes sc on sc.id = b.scheduled_class_id
    join class_types ct on ct.id = sc.class_type_id
    left join instructors i on i.id = sc.instructor_id
    left join halls h on h.id = sc.hall_id
    where b.client_id = auth.uid()

    union all

    -- Лист ожидания (только активные позиции)
    select
        w.id, 'waitlist'::text, sc.id, sc.starts_at, sc.ends_at,
        ct.name, ct.color, i.full_name, h.name,
        null::booking_status, w.position, (sc.ends_at < now())
    from waitlist w
    join scheduled_classes sc on sc.id = w.scheduled_class_id
    join class_types ct on ct.id = sc.class_type_id
    left join instructors i on i.id = sc.instructor_id
    left join halls h on h.id = sc.hall_id
    where w.client_id = auth.uid() and w.status = 'waiting'

    order by starts_at;
$$;

-- ---------------------------------------------------------------------
--  2. get_my_memberships — абонементы текущего пользователя.
-- ---------------------------------------------------------------------
create or replace function get_my_memberships()
returns table (
    id            uuid,
    plan_name     text,
    kind          membership_kind,
    classes_total int,
    classes_left  int,
    valid_from    date,
    valid_until   date,
    status        membership_status
)
language sql
stable
security definer
set search_path = public
as $$
    select
        cm.id, mp.name, mp.kind,
        cm.classes_total, cm.classes_left,
        cm.valid_from, cm.valid_until, cm.status
    from client_memberships cm
    join membership_plans mp on mp.id = cm.plan_id
    where cm.client_id = auth.uid()
    order by (cm.status = 'active') desc, cm.valid_until desc nulls last;
$$;

grant execute on function get_my_schedule()    to authenticated;
grant execute on function get_my_memberships() to authenticated;
