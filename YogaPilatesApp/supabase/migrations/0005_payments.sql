-- =====================================================================
--  Модуль «Оплата» — RPC-функции (тест-режим подтверждения)
--  Зависит от schema.sql. Применять после 0002–0004.
--
--  Тест-режим: confirm_payment сразу переводит платёж в 'succeeded' и
--  выполняет фулфилмент (активирует абонемент / создаёт запись). В бою
--  confirm_payment вызывается из webhook YooKassa после реальной оплаты
--  (см. supabase/functions/process-payment/index.ts).
-- =====================================================================

-- ---------------------------------------------------------------------
--  1. create_payment — расчёт суммы (скидки/промокод) + создание платежа
--     Возвращает (payment_id, amount).
-- ---------------------------------------------------------------------
create or replace function create_payment(
    p_purchase_type purchase_type,
    p_related_id    uuid,
    p_promo_code    text default null
)
returns table (payment_id uuid, amount numeric)
language plpgsql
security definer
set search_path = public
as $$
declare
    v_uid       uuid := auth.uid();
    v_base      numeric;
    v_final     numeric;
    v_promo_id  uuid;
    v_dtype     text;
    v_dval      numeric;
    v_personal  numeric;
    v_id        uuid;
begin
    if v_uid is null then
        raise exception 'not_authenticated';
    end if;

    -- Базовая цена
    if p_purchase_type = 'membership' then
        select price into v_base from membership_plans
            where id = p_related_id and is_active;
    elsif p_purchase_type = 'single_class' then
        select price into v_base from scheduled_classes where id = p_related_id;
    else
        raise exception 'unsupported_purchase_type';
    end if;

    if v_base is null then
        raise exception 'item_not_found';
    end if;

    v_final := v_base;

    -- Промокод
    if p_promo_code is not null then
        select id, discount_type, discount_value
          into v_promo_id, v_dtype, v_dval
        from promo_codes
        where code = p_promo_code and is_active
          and (valid_from  is null or valid_from  <= current_date)
          and (valid_until is null or valid_until >= current_date)
          and (usage_limit is null or used_count < usage_limit);
        if found then
            if v_dtype = 'percent' then
                v_final := v_final * (1 - v_dval / 100);
            else
                v_final := v_final - v_dval;
            end if;
        else
            v_promo_id := null;  -- невалидный промокод игнорируем
        end if;
    end if;

    -- Персональная скидка клиента
    select personal_discount_pct into v_personal from profiles where id = v_uid;
    if v_personal is not null and v_personal > 0 then
        v_final := v_final * (1 - v_personal / 100);
    end if;

    if v_final < 0 then
        v_final := 0;
    end if;
    v_final := round(v_final, 2);

    insert into payments(client_id, amount, currency, method, status,
                         purchase_type, related_id, provider, promo_code_id)
    values (v_uid, v_final, 'RUB', 'card', 'pending',
            p_purchase_type, p_related_id, 'test', v_promo_id)
    returning id into v_id;

    return query select v_id, v_final;
end;
$$;

-- ---------------------------------------------------------------------
--  2. confirm_payment — подтверждение + фулфилмент
--     Возвращает: 'succeeded' | 'already_succeeded'
-- ---------------------------------------------------------------------
create or replace function confirm_payment(p_payment_id uuid)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
    v_uid  uuid := auth.uid();
    v_pay  record;
    v_plan record;
begin
    select * into v_pay from payments
        where id = p_payment_id and client_id = v_uid for update;
    if not found then
        raise exception 'payment_not_found';
    end if;
    if v_pay.status = 'succeeded' then
        return 'already_succeeded';
    end if;

    update payments set status = 'succeeded' where id = p_payment_id;

    if v_pay.promo_code_id is not null then
        update promo_codes set used_count = used_count + 1
            where id = v_pay.promo_code_id;
    end if;

    -- Фулфилмент
    if v_pay.purchase_type = 'membership' then
        select * into v_plan from membership_plans where id = v_pay.related_id;
        insert into client_memberships(
            client_id, plan_id, classes_total, classes_left,
            valid_from, valid_until, status, payment_id)
        values (
            v_uid, v_plan.id, v_plan.classes_count, v_plan.classes_count,
            current_date,
            case when v_plan.duration_days is not null
                 then current_date + v_plan.duration_days else null end,
            'active', p_payment_id);

    elsif v_pay.purchase_type = 'single_class' then
        -- Защита от овербукинга: блокируем строку занятия и проверяем места.
        perform 1 from scheduled_classes
            where id = v_pay.related_id for update;
        if (select count(*) from bookings
                where scheduled_class_id = v_pay.related_id and status = 'booked')
           >= (select capacity from scheduled_classes where id = v_pay.related_id)
           and not exists (select 1 from bookings
                where scheduled_class_id = v_pay.related_id
                  and client_id = v_uid and status = 'booked') then
            raise exception 'class_full';
        end if;
        insert into bookings(scheduled_class_id, client_id, status, payment_id)
        values (v_pay.related_id, v_uid, 'booked', p_payment_id)
        on conflict (scheduled_class_id, client_id) do update
            set status = 'booked', cancelled_at = null,
                payment_id = excluded.payment_id;
    end if;

    return 'succeeded';
end;
$$;

-- ---------------------------------------------------------------------
--  3. get_payment_status — статус платежа (для пользователя)
-- ---------------------------------------------------------------------
create or replace function get_payment_status(p_payment_id uuid)
returns text
language sql
stable
security definer
set search_path = public
as $$
    select status::text from payments
        where id = p_payment_id and client_id = auth.uid();
$$;

-- ---------------------------------------------------------------------
--  4. book_into_class — ОБНОВЛЕНО: списываем занятие с активного абонемента
--     (count_based → декремент; unlimited → бесплатно; иначе без абонемента)
-- ---------------------------------------------------------------------
create or replace function book_into_class(p_class_id uuid)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
    v_uid        uuid := auth.uid();
    v_capacity   int;
    v_status     class_status;
    v_count      int;
    v_membership uuid;
    v_left       int;
begin
    if v_uid is null then
        raise exception 'not_authenticated';
    end if;

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
                and client_id = v_uid and status = 'booked') then
        return 'already_booked';
    end if;

    select count(*) into v_count from bookings
        where scheduled_class_id = p_class_id and status = 'booked';
    if v_count >= v_capacity then
        return 'full';
    end if;

    -- Подбираем абонемент: 1) поштучный с остатком
    v_membership := null;
    select id, classes_left into v_membership, v_left
    from client_memberships
    where client_id = v_uid and status = 'active'
      and classes_left is not null and classes_left > 0
      and (valid_until is null or valid_until >= current_date)
    order by valid_until asc nulls last
    limit 1 for update;

    if found then
        update client_memberships
            set classes_left = classes_left - 1,
                status = case when classes_left - 1 <= 0 then 'used_up'
                              else status end
            where id = v_membership;
    else
        -- 2) безлимитный
        select id into v_membership
        from client_memberships
        where client_id = v_uid and status = 'active'
          and classes_left is null
          and (valid_until is null or valid_until >= current_date)
        limit 1 for update;
        -- если безлимита нет — v_membership останется null
    end if;

    insert into bookings(scheduled_class_id, client_id, status, membership_id)
        values (p_class_id, v_uid, 'booked', v_membership)
    on conflict (scheduled_class_id, client_id) do update
        set status = 'booked', cancelled_at = null,
            membership_id = excluded.membership_id;

    return 'booked';
end;
$$;

-- ---------------------------------------------------------------------
--  5. cancel_booking — ОБНОВЛЕНО: возвращаем занятие на абонемент
--     + продвижение из листа ожидания (как в 0002)
-- ---------------------------------------------------------------------
create or replace function cancel_booking(p_booking_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
    v_uid        uuid := auth.uid();
    v_class      uuid;
    v_membership uuid;
    v_next       record;
begin
    select scheduled_class_id, membership_id into v_class, v_membership
    from bookings
    where id = p_booking_id and client_id = v_uid
    for update;
    if not found then
        raise exception 'booking_not_found';
    end if;

    update bookings
        set status = 'cancelled_by_client', cancelled_at = now()
    where id = p_booking_id;

    -- Возврат занятия на поштучный абонемент
    if v_membership is not null then
        update client_memberships
            set classes_left = case when classes_left is not null
                                    then classes_left + 1 else classes_left end,
                status = case when status = 'used_up' then 'active' else status end
        where id = v_membership and classes_total is not null;
    end if;

    -- Продвижение первого из листа ожидания
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
--  6. Гранты
-- ---------------------------------------------------------------------
grant execute on function create_payment(purchase_type, uuid, text) to authenticated;
grant execute on function confirm_payment(uuid)    to authenticated;
grant execute on function get_payment_status(uuid) to authenticated;
