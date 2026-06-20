// =====================================================================
//  Edge Function: dispatch-notifications  (запускать по cron, раз в минуту)
//  Берёт уведомления notifications со status='queued' и channel='push',
//  отправляет через OneSignal (external_user_id = client_id),
//  помечает status='sent'.
//
//  Env: SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY,
//       ONESIGNAL_APP_ID, ONESIGNAL_REST_API_KEY
// =====================================================================

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const appId = Deno.env.get("ONESIGNAL_APP_ID")!;
const restKey = Deno.env.get("ONESIGNAL_REST_API_KEY")!;

const admin = createClient(supabaseUrl, serviceKey);

async function sendOneSignal(
  clientId: string,
  title: string,
  body: string,
  data: Record<string, unknown>,
) {
  await fetch("https://onesignal.com/api/v1/notifications", {
    method: "POST",
    headers: {
      "Authorization": `Basic ${restKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      app_id: appId,
      include_external_user_ids: [clientId],
      channel_for_external_user_ids: "push",
      headings: { en: title, ru: title },
      contents: { en: body, ru: body },
      data,
    }),
  });
}

Deno.serve(async () => {
  const { data: rows, error } = await admin
    .from("notifications")
    .select("id, client_id, title, body, data")
    .eq("status", "queued")
    .eq("channel", "push")
    .order("created_at", { ascending: true })
    .limit(200);

  if (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
    });
  }

  let dispatched = 0;
  for (const n of rows ?? []) {
    try {
      await sendOneSignal(
        n.client_id,
        n.title ?? "",
        n.body ?? "",
        n.data ?? {},
      );
      await admin
        .from("notifications")
        .update({ status: "sent", sent_at: new Date().toISOString() })
        .eq("id", n.id);
      dispatched++;
    } catch (_e) {
      await admin
        .from("notifications")
        .update({ status: "failed" })
        .eq("id", n.id);
    }
  }

  return new Response(JSON.stringify({ dispatched }), {
    headers: { "Content-Type": "application/json" },
  });
});
