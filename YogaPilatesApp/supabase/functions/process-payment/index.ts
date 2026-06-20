// =====================================================================
//  Edge Function: process-payment (СКЕЛЕТ под YooKassa)
//  Deno / Supabase Edge Functions.
//
//  Назначение (боевой режим):
//   POST /process-payment           -> создать платёж в YooKassa, вернуть
//                                      confirmation_url для оплаты.
//   POST /process-payment/webhook   -> принять уведомление YooKassa и
//                                      вызвать RPC confirm_payment.
//
//  ВНИМАНИЕ: секретный ключ YooKassa живёт ТОЛЬКО здесь (env), не в приложении.
//  Это скелет: основные места помечены TODO. В тест-режиме приложение
//  использует RPC confirm_payment напрямую и эта функция не нужна.
//
//  Переменные окружения (supabase secrets set ...):
//   YOOKASSA_SHOP_ID, YOOKASSA_SECRET_KEY,
//   SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY
// =====================================================================

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const YOOKASSA_API = "https://api.yookassa.ru/v3";

const shopId = Deno.env.get("YOOKASSA_SHOP_ID")!;
const secretKey = Deno.env.get("YOOKASSA_SECRET_KEY")!;
const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const admin = createClient(supabaseUrl, serviceKey);

function authHeader(): string {
  return "Basic " + btoa(`${shopId}:${secretKey}`);
}

// --- Создание платежа в YooKassa -------------------------------------
async function createYooKassaPayment(
  paymentId: string,
  amount: number,
  description: string,
  returnUrl: string,
): Promise<Response> {
  const res = await fetch(`${YOOKASSA_API}/payments`, {
    method: "POST",
    headers: {
      "Authorization": authHeader(),
      "Idempotence-Key": crypto.randomUUID(),
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      amount: { value: amount.toFixed(2), currency: "RUB" },
      capture: true,
      confirmation: { type: "redirect", return_url: returnUrl },
      description,
      metadata: { payment_id: paymentId },
      // TODO(54-ФЗ): при включении фискализации добавить объект "receipt".
    }),
  });

  const data = await res.json();
  return new Response(
    JSON.stringify({
      confirmation_url: data?.confirmation?.confirmation_url,
      yookassa_id: data?.id,
    }),
    { headers: { "Content-Type": "application/json" }, status: res.status },
  );
}

// --- Обработка webhook от YooKassa -----------------------------------
async function handleWebhook(req: Request): Promise<Response> {
  const event = await req.json();
  // TODO(security): проверить подлинность уведомления (IP YooKassa / подпись).

  if (event?.event === "payment.succeeded") {
    const paymentId = event?.object?.metadata?.payment_id;
    if (paymentId) {
      // Подтверждаем платёж нашей RPC (фулфилмент: абонемент / запись).
      await admin.rpc("confirm_payment", { p_payment_id: paymentId });
    }
  }
  return new Response("ok", { status: 200 });
}

Deno.serve(async (req: Request) => {
  const url = new URL(req.url);

  if (req.method === "POST" && url.pathname.endsWith("/webhook")) {
    return handleWebhook(req);
  }

  if (req.method === "POST") {
    const body = await req.json();
    // body: { payment_id, amount, description, return_url }
    return createYooKassaPayment(
      body.payment_id,
      Number(body.amount),
      body.description ?? "Оплата услуг студии",
      body.return_url ?? "yogapilates://payment-result",
    );
  }

  return new Response("Method Not Allowed", { status: 405 });
});
