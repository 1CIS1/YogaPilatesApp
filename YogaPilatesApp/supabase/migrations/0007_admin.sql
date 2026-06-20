-- =====================================================================
--  Модуль «Админ-панель» (базовый) — RPC-функции
--  Зависит от schema.sql. Применять после 0002–0006.
--
--  Все функции — SECURITY DEFINER с проверкой is_staff(). Это позволяет
--  админам выполнять операции (в т.ч. там, где на таблицах нет RLS),
--  и блокирует доступ всем остальным. Действия пишутся в audit_log.
-- =====================================================================

-- ---------------------------------------------------------------------
--  Вспомогательные
-- ---------------------------------------------------------------------
create or replace function _require_staff() returns void
language plpgsql security definer set search_path = public as $$
begin
    if not is_staff() then
        raise exception 'forbidden: staff only';
    end if;
end;
$$;

create or replace function _audit(
    p_action text, p_entity text, p_entity_id uuid, p_details jsonb default null)
returns void
language plpgsql security definer set search_path = public as $$
begin
    insert into audit_log(admin_id, action, entity_type, entity_id, details)
    values (auth.uid(), p_action, p_entity, p_entity_id, p_details);
end;
$$;

-- ---------------------------------------------------------------------
--  Расписание (CRUD)
-- ---------------------------------------------------------------------
create or replace function admin_get_classes(p_from timestamptz, p_to timestamptz)
returns table (
    id uuid, starts_at timestamptz, ends_at timestamptz, capacity int,
    booked_count bigint, difficulty difficulty_level, status class_status,
    price numeric, class_type_name text, instructor_name text, hall_name text,
    class_type_id uuid, instructor_id uuid, hall_id uuid
)
language plpgsql security definer set search_path = public as $$
begin
    perform _require_staff();
    return query
        select sc.id, sc.starts_at, sc.ends_at, sc.capacity,
            (select count(*) from bookings b
                where b.scheduled_class_id = sc.id and b.status = 'booked'),
            sc.difficulty, sc.status, sc.price,
            ct.name, i.full_name, h.name,
            sc.class_type_id, sc.instructor_id, sc.hall_id
        from scheduled_classes sc
        join class_types ct on ct.id = sc.class_type_id
        left join instructors i on i.id = sc.instructor_id
        left join halls h on h.id = sc.hall_id
        where sc.starts_at >= p_from and sc.starts_at < p_to
        order by sc.starts_at;
end;
$$;

create or replace function admin_create_class(
    p_class_type_id uuid, p_instructor_id uuid, p_hall_id uuid,
    p_starts_at timestamptz, p_ends_at timestamptz, p_capacity int,
    p_difficulty text, p_price numeric)
returns uuid
language plpgsql security definer set search_path = public as $$
declare v_id uuid;
begin
    perform _require_staff();
    insert into scheduled_classes(class_type_id, instructor_id, hall_id,
        starts_at, ends_at, capacity, difficulty, status, price, created_by)
    values (p_class_type_id, p_instructor_id, p_hall_id, p_starts_at, p_ends_at,
            p_capacity, p_difficulty::difficulty_level, 'scheduled', p_price, auth.uid())
    returning id into v_id;
    perform _audit('class.create', 'scheduled_class', v_id, null);
    return v_id;
end;
$$;

create or replace function admin_update_class(
    p_id uuid, p_class_type_id uuid, p_instructor_id uuid, p_hall_id uuid,
    p_starts_at timestamptz, p_ends_at timestamptz, p_capacity int,
    p_difficulty text, p_price numeric)
returns void
language plpgsql security definer set search_path = public as $$
begin
    perform _require_staff();
    update scheduled_classes set
        class_type_id = p_class_type_id, instructor_id = p_instructor_id,
        hall_id = p_hall_id, starts_at = p_starts_at, ends_at = p_ends_at,
        capacity = p_capacity, difficulty = p_difficulty::difficulty_level,
        price = p_price
    where id = p_id;
    perform _audit('class.update', 'scheduled_class', p_id, null);
end;
$$;

create or replace function admin_cancel_class(p_id uuid)
returns void
language plpgsql security definer set search_path = public as $$
begin
    perform _require_staff();
    update scheduled_classes set status = 'cancelled' where id = p_id;
    -- триггер notify_class_cancelled уведомит записанных
    perform _audit('class.cancel', 'scheduled_class', p_id, null);
end;
$$;

create or replace function admin_get_halls()
returns table (id uuid, name text, capacity int)
language plpgsql security definer set search_path = public as $$
begin
    perform _require_staff();
    return query select h.id, h.name, h.capacity from halls h order by h.name;
end;
$$;

-- ---------------------------------------------------------------------
--  Клиенты
-- ---------------------------------------------------------------------
create or replace function admin_get_clients(p_search text default null)
returns table (
    id uuid, full_name text, phone text, email text,
    tier client_tier, is_blocked boolean)
language plpgsql security definer set search_path = public as $$
begin
    perform _require_staff();
    return query
        select p.id, p.full_name, p.phone, p.email, p.tier, p.is_blocked
        from profiles p
        where p.role = 'client'
          and (p_search is null or p_search = '' or
               p.full_name ilike '%' || p_search || '%' or
               p.phone     ilike '%' || p_search || '%' or
               p.email     ilike '%' || p_search || '%')
        order by p.full_name nulls last
        limit 200;
end;
$$;

create or replace function admin_get_client(p_client_id uuid)
returns table (
    id uuid, full_name text, phone text, email text, birth_date date,
    tier client_tier, is_blocked boolean, bonus_balance int)
language plpgsql security definer set search_path = public as $$
begin
    perform _require_staff();
    return query
        select p.id, p.full_name, p.phone, p.email, p.birth_date,
               p.tier, p.is_blocked,
               coalesce(ba.balance, 0)
        from profiles p
        left join bonus_accounts ba on ba.client_id = p.id
        where p.id = p_client_id;
end;
$$;

create or replace function admin_get_client_memberships(p_client_id uuid)
returns table (
    plan_name text, classes_left int, classes_total int,
    valid_until date, status membership_status)
language plpgsql security definer set search_path = public as $$
begin
    perform _require_staff();
    return query
        select mp.name, cm.classes_left, cm.classes_total, cm.valid_until, cm.status
        from client_memberships cm
        join membership_plans mp on mp.id = cm.plan_id
        where cm.client_id = p_client_id
        order by (cm.status = 'active') desc, cm.valid_until desc nulls last;
end;
$$;

create or replace function admin_get_client_bookings(p_client_id uuid)
returns table (starts_at timestamptz, class_name text, status booking_status)
language plpgsql security definer set search_path = public as $$
begin
    perform _require_staff();
    return query
        select sc.starts_at, ct.name, b.status
        from bookings b
        join scheduled_classes sc on sc.id = b.scheduled_class_id
        join class_types ct on ct.id = sc.class_type_id
        where b.client_id = p_client_id
        order by sc.starts_at desc
        limit 20;
end;
$$;

create or replace function admin_adjust_bonuses(
    p_client_id uuid, p_amount int, p_reason text)
returns int
language plpgsql security definer set search_path = public as $$
declare v_balance int;
begin
    perform _require_staff();
    insert into bonus_accounts(client_id, balance)
        values (p_client_id, 0) on conflict (client_id) do nothing;
    update bonus_accounts set balance = greatest(0, balance + p_amount)
        where client_id = p_client_id
        returning balance into v_balance;
    insert into bonus_transactions(client_id, type, amount, reason, balance_after, admin_id)
        values (p_client_id,
                case when p_amount >= 0 then 'manual_add' else 'manual_remove' end,
                p_amount, p_reason, v_balance, auth.uid());
    perform _audit('bonus.adjust', 'profile', p_client_id,
                   jsonb_build_object('amount', p_amount, 'reason', p_reason));
    return v_balance;
end;
$$;

-- ---------------------------------------------------------------------
--  Лист ожидания / записи на занятие
-- ---------------------------------------------------------------------
create or replace function admin_get_class_bookings(p_class_id uuid)
returns table (booking_id uuid, client_name text, client_email text, status booking_status)
language plpgsql security definer set search_path = public as $$
begin
    perform _require_staff();
    return query
        select b.id, p.full_name, p.email, b.status
        from bookings b
        join profiles p on p.id = b.client_id
        where b.scheduled_class_id = p_class_id and b.status = 'booked'
        order by p.full_name nulls last;
end;
$$;

create or replace function admin_get_class_waitlist(p_class_id uuid)
returns table (waitlist_id uuid, client_name text, position int)
language plpgsql security definer set search_path = public as $$
begin
    perform _require_staff();
    return query
        select w.id, p.full_name, w.position
        from waitlist w
        join profiles p on p.id = w.client_id
        where w.scheduled_class_id = p_class_id and w.status = 'waiting'
        order by w.position;
end;
$$;

create or replace function admin_promote_waitlist(p_waitlist_id uuid)
returns text
language plpgsql security definer set search_path = public as $$
declare
    v_class uuid; v_client uuid; v_capacity int; v_count int;
begin
    perform _require_staff();
    select scheduled_class_id, client_id into v_class, v_client
        from waitlist where id = p_waitlist_id and status = 'waiting' for update;
    if not found then raise exception 'waitlist_entry_not_found'; end if;

    select capacity into v_capacity from scheduled_classes where id = v_class;
    select count(*) into v_count from bookings
        where scheduled_class_id = v_class and status = 'booked';
    if v_count >= v_capacity then return 'full'; end if;

    update waitlist set status = 'promoted', promoted_at = now()
        where id = p_waitlist_id;
    insert into bookings(scheduled_class_id, client_id, status)
        values (v_class, v_client, 'booked')
    on conflict (scheduled_class_id, client_id) do update
        set status = 'booked', cancelled_at = null;
    insert into notifications(client_id, channel, title, body, data, status)
        values (v_client, 'push', 'Вы записаны!',
                'Администратор перенёс вас из листа ожидания в запись.',
                jsonb_build_object('type', 'promotion'), 'queued');
    perform _audit('waitlist.promote', 'waitlist', p_waitlist_id, null);
    return 'promoted';
end;
$$;

create or replace function admin_cancel_booking(p_booking_id uuid)
returns void
language plpgsql security definer set search_path = public as $$
declare
    v_class uuid; v_membership uuid; v_next record;
begin
    perform _require_staff();
    select scheduled_class_id, membership_id into v_class, v_membership
        from bookings where id = p_booking_id for update;
    if not found then raise exception 'booking_not_found'; end if;

    update bookings set status = 'cancelled_by_admin', cancelled_at = now()
        where id = p_booking_id;

    if v_membership is not null then
        update client_memberships
            set classes_left = case when classes_left is not null
                                    then classes_left + 1 else classes_left end,
                status = case when status = 'used_up' then 'active' else status end
            where id = v_membership and classes_total is not null;
    end if;

    select * into v_next from waitlist
        where scheduled_class_id = v_class and status = 'waiting'
        order by position asc limit 1 for update;
    if found then
        update waitlist set status = 'promoted', promoted_at = now()
            where id = v_next.id;
        insert into bookings(scheduled_class_id, client_id, status)
            values (v_class, v_next.client_id, 'booked')
        on conflict (scheduled_class_id, client_id) do update
            set status = 'booked', cancelled_at = null;
        insert into notifications(client_id, channel, title, body, status)
            values (v_next.client_id, 'push', 'Вы записаны!',
                    'Освободилось место — вы перенесены из листа ожидания.', 'queued');
    end if;

    perform _audit('booking.cancel_by_admin', 'booking', p_booking_id, null);
end;
$$;

-- ---------------------------------------------------------------------
--  Отчёты + статистика дашборда
-- ---------------------------------------------------------------------
create or replace function admin_report_sales(p_from date, p_to date)
returns table (day date, revenue numeric, cnt int)
language plpgsql security definer set search_path = public as $$
begin
    perform _require_staff();
    return query
        select pay.created_at::date as day,
               coalesce(sum(pay.amount), 0)::numeric,
               count(*)::int
        from payments pay
        where pay.status = 'succeeded'
          and pay.created_at::date >= p_from
          and pay.created_at::date <= p_to
        group by pay.created_at::date
        order by day;
end;
$$;

create or replace function admin_report_attendance(p_from date, p_to date)
returns table (day date, bookings int)
language plpgsql security definer set search_path = public as $$
begin
    perform _require_staff();
    return query
        select sc.starts_at::date as day, count(*)::int
        from bookings b
        join scheduled_classes sc on sc.id = b.scheduled_class_id
        where b.status in ('booked', 'attended')
          and sc.starts_at::date >= p_from
          and sc.starts_at::date <= p_to
        group by sc.starts_at::date
        order by day;
end;
$$;

create or replace function admin_dashboard_stats()
returns table (
    today_classes int, today_bookings int,
    today_revenue numeric, total_clients int)
language plpgsql security definer set search_path = public as $$
begin
    perform _require_staff();
    return query select
        (select count(*)::int from scheduled_classes
            where starts_at::date = current_date and status <> 'cancelled'),
        (select count(*)::int from bookings b
            join scheduled_classes sc on sc.id = b.scheduled_class_id
            where sc.starts_at::date = current_date and b.status = 'booked'),
        (select coalesce(sum(amount), 0)::numeric from payments
            where status = 'succeeded' and created_at::date = current_date),
        (select count(*)::int from profiles where role = 'client');
end;
$$;

-- ---------------------------------------------------------------------
--  Гранты (внутри — проверка is_staff)
-- ---------------------------------------------------------------------
grant execute on function admin_get_classes(timestamptz, timestamptz) to authenticated;
grant execute on function admin_create_class(uuid, uuid, uuid, timestamptz, timestamptz, int, text, numeric) to authenticated;
grant execute on function admin_update_class(uuid, uuid, uuid, uuid, timestamptz, timestamptz, int, text, numeric) to authenticated;
grant execute on function admin_cancel_class(uuid) to authenticated;
grant execute on function admin_get_halls() to authenticated;
grant execute on function admin_get_clients(text) to authenticated;
grant execute on function admin_get_client(uuid) to authenticated;
grant execute on function admin_get_client_memberships(uuid) to authenticated;
grant execute on function admin_get_client_bookings(uuid) to authenticated;
grant execute on function admin_adjust_bonuses(uuid, int, text) to authenticated;
grant execute on function admin_get_class_bookings(uuid) to authenticated;
grant execute on function admin_get_class_waitlist(uuid) to authenticated;
grant execute on function admin_promote_waitlist(uuid) to authenticated;
grant execute on function admin_cancel_booking(uuid) to authenticated;
grant execute on function admin_report_sales(date, date) to authenticated;
grant execute on function admin_report_attendance(date, date) to authenticated;
grant execute on function admin_dashboard_stats() to authenticated;
