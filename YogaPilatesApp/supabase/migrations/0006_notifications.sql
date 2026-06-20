-- =====================================================================
--  Модуль «Push-уведомления» — RPC, генераторы и триггеры
--  Зависит от schema.sql. Применять после 0002–0005.
--
--  Дизайн: уведомления СОЗДАЮТСЯ в таблице notifications (status='queued')
--  серверной логикой (RPC/функции/триггеры), а ОТПРАВКА push выполняется
--  Edge Function dispatch-notifications (OneSignal). Таким образом вся
--  логика тестируется в БД даже без подключённого OneSignal.
-- =====================================================================

-- ---------------------------------------------------------------------
--  1. Регистрация push-токена устройства
-- ---------------------------------------------------------------------
create or replace function register_push_token(
    p_token    text,
    p_platform device_platform
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
    if auth.uid() is null then
        raise exception 'not_authenticated';
    end if;
    insert into push_tokens(profile_id, token, platform)
        values (auth.uid(), p_token, p_platform)
    on conflict (token) do update set profile_id = excluded.profile_id;
end;
$$;

-- ---------------------------------------------------------------------
--  2. Отметка уведомлений прочитанными
-- ---------------------------------------------------------------------
create or replace function mark_notification_read(p_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
    update notifications
        set is_read = true, read_at = now()
    where id = p_id and client_id = auth.uid();
end;
$$;

create or replace function mark_all_notifications_read()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
    update notifications
        set is_read = true, read_at = now()
    where client_id = auth.uid() and is_read = false;
end;
$$;

-- ---------------------------------------------------------------------
--  3. Настройки уведомлений (хранятся в profiles.notify_prefs)
-- ---------------------------------------------------------------------
create or replace function update_notify_prefs(p_prefs jsonb)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
    update profiles set notify_prefs = p_prefs where id = auth.uid();
end;
$$;

-- ---------------------------------------------------------------------
--  4. Генератор напоминаний о занятиях (за 24 ч и за 2 ч)
--     Вызывается по расписанию (pg_cron, раз в час). Дедупликация — по
--     типу уведомления и id занятия.
-- ---------------------------------------------------------------------
create or replace function enqueue_class_reminders()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
    -- За 24 часа
    insert into notifications(client_id, channel, title, body, data, status)
    select b.client_id, 'push', 'Напоминание о занятии',
           'Завтра в ' || to_char(sc.starts_at, 'HH24:MI') || ' — ' || ct.name,
           jsonb_build_object('type', 'reminder_24h',
                              'scheduled_class_id', sc.id), 'queued'
    from scheduled_classes sc
    join bookings b on b.scheduled_class_id = sc.id and b.status = 'booked'
    join class_types ct on ct.id = sc.class_type_id
    join profiles p on p.id = b.client_id
    where sc.status = 'scheduled'
      and sc.starts_at >= now() + interval '24 hours'
      and sc.starts_at <  now() + interval '25 hours'
      and coalesce((p.notify_prefs->>'reminders')::boolean, true)
      and not exists (
          select 1 from notifications n
          where n.client_id = b.client_id
            and n.data->>'type' = 'reminder_24h'
            and (n.data->>'scheduled_class_id')::uuid = sc.id);

    -- За 2 часа
    insert into notifications(client_id, channel, title, body, data, status)
    select b.client_id, 'push', 'Скоро занятие',
           'Через 2 часа в ' || to_char(sc.starts_at, 'HH24:MI') || ' — ' || ct.name,
           jsonb_build_object('type', 'reminder_2h',
                              'scheduled_class_id', sc.id), 'queued'
    from scheduled_classes sc
    join bookings b on b.scheduled_class_id = sc.id and b.status = 'booked'
    join class_types ct on ct.id = sc.class_type_id
    join profiles p on p.id = b.client_id
    where sc.status = 'scheduled'
      and sc.starts_at >= now() + interval '2 hours'
      and sc.starts_at <  now() + interval '3 hours'
      and coalesce((p.notify_prefs->>'reminders')::boolean, true)
      and not exists (
          select 1 from notifications n
          where n.client_id = b.client_id
            and n.data->>'type' = 'reminder_2h'
            and (n.data->>'scheduled_class_id')::uuid = sc.id);
end;
$$;

-- ---------------------------------------------------------------------
--  5. Поздравления с днём рождения + начисление бонусов
--     Вызывается по расписанию (pg_cron, раз в день).
-- ---------------------------------------------------------------------
create or replace function enqueue_birthday_notifications(p_bonus int default 100)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
    r record;
begin
    for r in
        select id from profiles
        where role = 'client' and birth_date is not null
          and extract(month from birth_date) = extract(month from current_date)
          and extract(day   from birth_date) = extract(day   from current_date)
          and not exists (
              select 1 from notifications n
              where n.client_id = profiles.id
                and n.data->>'type' = 'birthday'
                and n.created_at::date = current_date)
    loop
        -- Бонусный счёт
        insert into bonus_accounts(client_id, balance)
            values (r.id, 0) on conflict (client_id) do nothing;
        update bonus_accounts set balance = balance + p_bonus
            where client_id = r.id;
        insert into bonus_transactions(client_id, type, amount, reason, balance_after)
            select r.id, 'birthday', p_bonus, 'Подарок на день рождения', balance
            from bonus_accounts where client_id = r.id;

        -- Уведомление
        insert into notifications(client_id, channel, title, body, data, status)
            values (r.id, 'push', 'С днём рождения!',
                    'Дарим ' || p_bonus || ' бонусов в подарок.',
                    jsonb_build_object('type', 'birthday'), 'queued');
    end loop;
end;
$$;

-- ---------------------------------------------------------------------
--  6. Триггер: отмена занятия администратором → уведомить записанных
-- ---------------------------------------------------------------------
create or replace function notify_class_cancelled()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
    if new.status = 'cancelled' and old.status <> 'cancelled' then
        insert into notifications(client_id, channel, title, body, data, status)
        select b.client_id, 'push', 'Занятие отменено',
               'К сожалению, занятие ' ||
               to_char(new.starts_at, 'DD.MM в HH24:MI') || ' отменено.',
               jsonb_build_object('type', 'class_cancelled',
                                  'scheduled_class_id', new.id), 'queued'
        from bookings b
        where b.scheduled_class_id = new.id and b.status = 'booked';
    end if;
    return new;
end;
$$;

drop trigger if exists trg_notify_class_cancelled on scheduled_classes;
create trigger trg_notify_class_cancelled
    after update on scheduled_classes
    for each row execute function notify_class_cancelled();

-- ---------------------------------------------------------------------
--  7. Гранты
-- ---------------------------------------------------------------------
grant execute on function register_push_token(text, device_platform) to authenticated;
grant execute on function mark_notification_read(uuid)  to authenticated;
grant execute on function mark_all_notifications_read()  to authenticated;
grant execute on function update_notify_prefs(jsonb)     to authenticated;

-- ---------------------------------------------------------------------
--  8. Планировщик (pg_cron). Включить расширение и раскомментировать.
--     Требует включённого pg_cron (Dashboard → Database → Extensions).
-- ---------------------------------------------------------------------
-- create extension if not exists pg_cron;
-- select cron.schedule('class-reminders', '0 * * * *',
--                      $$ select enqueue_class_reminders(); $$);
-- select cron.schedule('birthday-greetings', '0 9 * * *',
--                      $$ select enqueue_birthday_notifications(); $$);
--
-- Рассылку queued-уведомлений выполняет Edge Function dispatch-notifications.
-- Её можно вызывать по cron через pg_net, например:
-- select cron.schedule('dispatch-notifications', '* * * * *', $$
--   select net.http_post(
--     url := 'https://<project>.functions.supabase.co/dispatch-notifications',
--     headers := jsonb_build_object('Authorization', 'Bearer <service-role-key>')
--   );
-- $$);
