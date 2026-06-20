-- =====================================================================
--  Модуль «Расписание + запись» — RPC-функции (PostgreSQL / Supabase)
--  Зависит от schema.sql (таблицы scheduled_classes, bookings, waitlist,
--  notifications, class_types, instructors, halls и enum-типов).
--
--  Все мутации выполняются атомарно (FOR UPDATE блокирует строку занятия),
--  что исключает гонки за последнее свободное место.
-- =====================================================================

-- ---------------------------------------------------------------------
--  1. get_schedule — расписание за период с агрегатами и контекстом юзера
-- ---------------------------------------------------------------------
create or replace function get_schedule(
    p_from        timestamptz,
    p_to          timestamptz,
    p_class_type  uuid             default null,
    p_difficulty  difficulty_level default null,
    p_instructor  uuid             default null
)
returns table (
    id                   uuid,
    starts_at            timestamptz,
    ends_at              timestamptz,
    capacity             int,
    booked_count         bigint,
    difficulty           difficulty_level,
    status               class_status,
    price                numeric,
    class_type_id        uuid,
    class_type_name      text,
    class_type_color     text,
    instructor_id        uuid,
    instructor_name      text,
    instructor_photo     text,
    instructor_rating    numeric,
    hall_name            text,
    is_booked            boolean,
    my_booking_id        uuid,
    my_waitlist_position int
)
language sql
stable
security definer
set search_path = public
as $$
    select
        sc.id,
        sc.starts_at,
        sc.ends_at,
        sc.capacity,
        (select count(*) from bookings b
            where b.scheduled_class_id = sc.id and b.status = 'booked') as booked_count,
        sc.difficulty,
        sc.status,
        sc.price,
        ct.id, ct.name, ct.color,
        i.id, i.full_name, i.photo_url, i.rating,
        h.name,
        exists(select 1 from bookings b2
            where b2.scheduled_class_id = sc.id
              and b2.client_id = auth.uid()
              and b2.status = 'booked') as is_booked,
        (select b3.id from bookings b3
            where b3.scheduled_class_id = sc.id
              and b3.client_id = auth.uid()
              and b3.status = 'booked' limit 1) as my_booking_id,
        (select w.position from waitlist w
            where w.scheduled_class_id = sc.id
              and w.client_id = auth.uid()
              and w.status = 'waiting' limit 1) as my_waitlist_position
    from scheduled_classes sc
    join class_types ct on ct.id = sc.class_type_id
    left join instructors i on i.id = sc.instructor_id
    left join halls h on h.id = sc.hall_id
    where sc.starts_at >= p_from
      and sc.starts_at <  p_to
      and (p_class_type is null or sc.class_type_id = p_class_type)
      and (p_difficulty is null or sc.difficulty   = p_difficulty)
      and (p_instructor is null or sc.instructor_id = p_instructor)
    order by sc.starts_at;
$$;

-- ---------------------------------------------------------------------
--  2. book_into_class — запись на занятие (атомарно)
--     Возвращает: 'booked' | 'full' | 'already_booked'
-- ---------------------------------------------------------------------
create or replace function book_into_class(p_class_id uuid)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
    v_uid      uuid := auth.uid();
    v_capacity int;
    v_status   class_status;
    v_count    int;
begin
    if v_uid is null then
        raise exception 'not_authenticated';
    end if;

    -- Блокируем строку занятия до конца транзакции.
    select capacity, status into v_capacity, v_status
    from scheduled_classes where id = p_class_id for update;

    if not found then
        raise exception 'class_not_found';
    end if;
    if v_status <> 'scheduled' then
        raise exception 'class_not_available';
    end if;

    if exists(select 1 from bookings
              where scheduled_class_id = p_class_id
                and client_id = v_uid
                and status = 'booked') then
        return 'already_booked';
    end if;

    select count(*) into v_count from bookings
        where scheduled_class_id = p_class_id and status = 'booked';

    if v_count >= v_capacity then
        return 'full';
    end if;

    insert into bookings(scheduled_class_id, client_id, status)
        values (p_class_id, v_uid, 'booked')
    on conflict (scheduled_class_id, client_id) do update
        set status = 'booked', cancelled_at = null;

    return 'booked';
end;
$$;

-- ---------------------------------------------------------------------
--  3. cancel_booking — отмена записи + продвижение из листа ожидания
-- ---------------------------------------------------------------------
create or replace function cancel_booking(p_booking_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
    v_uid   uuid := auth.uid();
    v_class uuid;
    v_next  record;
begin
    select scheduled_class_id into v_class
    from bookings
    where id = p_booking_id and client_id = v_uid
    for update;

    if not found then
        raise exception 'booking_not_found';
    end if;

    update bookings
        set status = 'cancelled_by_client', cancelled_at = now()
    where id = p_booking_id;

    -- Берём первого в очереди и переносим в запись.
    select * into v_next
    from waitlist
    where scheduled_class_id = v_class and status = 'waiting'
    order by position asc
    limit 1
    for update;

    if found then
        update waitlist set status = 'promoted', promoted_at = now()
        where id = v_next.id;

        insert into bookings(scheduled_class_id, client_id, status)
            values (v_class, v_next.client_id, 'booked')
        on conflict (scheduled_class_id, client_id) do update
            set status = 'booked', cancelled_at = null;

        insert into notifications(client_id, channel, title, body, status)
            values (v_next.client_id, 'push', 'Вы записаны!',
                    'Освободилось место — вы перенесены из листа ожидания в запись.',
                    'queued');
    end if;
end;
$$;

-- ---------------------------------------------------------------------
--  4. join_waitlist — встать в лист ожидания. Возвращает позицию.
-- ---------------------------------------------------------------------
create or replace function join_waitlist(p_class_id uuid)
returns int
language plpgsql
security definer
set search_path = public
as $$
declare
    v_uid uuid := auth.uid();
    v_pos int;
begin
    if v_uid is null then
        raise exception 'not_authenticated';
    end if;

    select position into v_pos from waitlist
        where scheduled_class_id = p_class_id
          and client_id = v_uid
          and status = 'waiting';
    if found then
        return v_pos;            -- уже в очереди
    end if;

    select coalesce(max(position), 0) + 1 into v_pos
    from waitlist
    where scheduled_class_id = p_class_id and status = 'waiting';

    insert into waitlist(scheduled_class_id, client_id, position, status)
        values (p_class_id, v_uid, v_pos, 'waiting')
    on conflict (scheduled_class_id, client_id) do update
        set status = 'waiting', position = excluded.position;

    return v_pos;
end;
$$;

-- ---------------------------------------------------------------------
--  5. leave_waitlist — выйти из листа ожидания
-- ---------------------------------------------------------------------
create or replace function leave_waitlist(p_class_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
    v_uid uuid := auth.uid();
begin
    update waitlist set status = 'cancelled'
    where scheduled_class_id = p_class_id
      and client_id = v_uid
      and status = 'waiting';
end;
$$;

-- ---------------------------------------------------------------------
--  6. Права на выполнение для авторизованных пользователей
-- ---------------------------------------------------------------------
grant execute on function get_schedule(timestamptz, timestamptz, uuid, difficulty_level, uuid) to authenticated;
grant execute on function book_into_class(uuid) to authenticated;
grant execute on function cancel_booking(uuid)  to authenticated;
grant execute on function join_waitlist(uuid)   to authenticated;
grant execute on function leave_waitlist(uuid)  to authenticated;
