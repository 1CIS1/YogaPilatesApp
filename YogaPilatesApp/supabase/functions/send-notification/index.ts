// =====================================================================
//  Edge Function: send-notification
//  Отправка одного push-уведомления через OneSignal по external_user_id
//  (= Supabase user id). Используется как примитив (например, ручная
//  рассылка из админки) и из dispatch-notifications.
//
//  Env: ONESIGNAL_APP_ID, ONESIGNAL_REST_API_KEY
//  Тело запроса: { client_id, title, body, data? }
// =====================================================================

const appId = Deno.env.get("ONESIGNAL_APP_ID")!;
const restKey = Deno.env.get("ONESIGNAL_REST_API_KEY")!;

export async function sendOneSignal(
  clientId: string,
  title: string,
  body: string,
  data?: Record<string, unknown>,
): Promise<Response> {
  return await fetch("https://onesignal.com/api/v1/notifications", {
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
      data: data ?? {},
    }),
  });
}

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") {
    return new Response("Method Not Allowed", { status: 405 });
  }
  const { client_id, title, body, data } = await req.json();
  const res = await sendOneSignal(client_id, title, body, data);
  return new Response(await res.text(), { status: res.status });
});
