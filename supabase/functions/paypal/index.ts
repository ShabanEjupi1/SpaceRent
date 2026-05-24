// SpaceRent Kosovo — PayPal Payment Edge Function
// Deploy: supabase functions deploy paypal

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

// Helper: Obtain PayPal OAuth2 Access Token
async function getPayPalAccessToken(clientId: string, clientSecret: string, apiBase: string): Promise<string> {
  const auth = btoa(`${clientId}:${clientSecret}`);
  const response = await fetch(`${apiBase}/v1/oauth2/token`, {
    method: "POST",
    headers: {
      "Authorization": `Basic ${auth}`,
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: "grant_type=client_credentials",
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`Failed to obtain PayPal access token: ${errorText}`);
  }

  const data = await response.json();
  return data.access_token;
}

Deno.serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const PAYPAL_CLIENT_ID = Deno.env.get("PAYPAL_CLIENT_ID");
    const PAYPAL_CLIENT_SECRET = Deno.env.get("PAYPAL_CLIENT_SECRET");
    const PAYPAL_API_BASE = Deno.env.get("PAYPAL_API_BASE") || "https://api-m.sandbox.paypal.com";

    const SUPABASE_URL = Deno.env.get("SUPABASE_URL") || "";
    const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || "";

    if (!PAYPAL_CLIENT_ID || !PAYPAL_CLIENT_SECRET) {
      throw new Error("PayPal credentials (PAYPAL_CLIENT_ID or PAYPAL_CLIENT_SECRET) are not set.");
    }

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
    const body = await req.json();
    const { action } = body;

    // Get Access Token
    const accessToken = await getPayPalAccessToken(PAYPAL_CLIENT_ID, PAYPAL_CLIENT_SECRET, PAYPAL_API_BASE);

    if (action === "create-order") {
      const { amount } = body;
      if (!amount) throw new Error("Amount is required for creating an order.");

      const res = await fetch(`${PAYPAL_API_BASE}/v2/checkout/orders`, {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${accessToken}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          intent: "CAPTURE",
          purchase_units: [{
            amount: {
              currency_code: "EUR",
              value: parseFloat(amount).toFixed(2),
            },
          }],
          application_context: {
            brand_name: "SpaceRent Kosovo",
            user_action: "PAY_NOW",
            landing_page: "BILLING", // Instructs PayPal to show the credit card form directly
            shipping_preference: "NO_SHIPPING",
          },
        }),
      });

      if (!res.ok) {
        const errorText = await res.text();
        throw new Error(`PayPal create order failed: ${errorText}`);
      }

      const order = await res.json();
      const approvalUrl = order.links.find((l: any) => l.rel === "approve")?.href;

      return new Response(JSON.stringify({ orderId: order.id, approvalUrl }), {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });

    } else if (action === "capture-order") {
      const { orderId, bookingId } = body;
      if (!orderId || !bookingId) throw new Error("orderId and bookingId are required.");

      const res = await fetch(`${PAYPAL_API_BASE}/v2/checkout/orders/${orderId}/capture`, {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${accessToken}`,
          "Content-Type": "application/json",
        },
      });

      if (!res.ok) {
        const errorText = await res.text();
        throw new Error(`PayPal capture order failed: ${errorText}`);
      }

      const capture = await res.json();

      if (capture.status === "COMPLETED") {
        // Retrieve transaction amount
        const capturedAmount = capture.purchase_units?.[0]?.payments?.captures?.[0]?.amount?.value || "0.00";

        // 1. Update Booking Payment status (Paid)
        const { error: bookingError } = await supabase
          .from("bookings")
          .update({
            payment_status: "Paid",
            paypal_order_id: orderId,
            paid_at: new Date().toISOString(),
          })
          .eq("id", bookingId);

        if (bookingError) throw bookingError;

        // 2. Log in payments table
        const { error: paymentError } = await supabase
          .from("payments")
          .insert({
            booking_id: bookingId,
            amount: parseFloat(capturedAmount),
            payment_type: "BookingPayment",
            paypal_order_id: orderId,
            status: "Completed",
          });

        if (paymentError) throw paymentError;

        return new Response(JSON.stringify({ success: true, capture }), {
          status: 200,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      } else {
        throw new Error(`PayPal checkout was not completed. Status: ${capture.status}`);
      }

    } else if (action === "capture-subscription") {
      // Monthly partners subscription fee
      const { orderId, partnerId, amount } = body;
      if (!orderId || !partnerId) throw new Error("orderId and partnerId are required.");

      const subscriptionAmount = amount || 29.00;

      const res = await fetch(`${PAYPAL_API_BASE}/v2/checkout/orders/${orderId}/capture`, {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${accessToken}`,
          "Content-Type": "application/json",
        },
      });

      if (!res.ok) {
        const errorText = await res.text();
        throw new Error(`PayPal subscription capture failed: ${errorText}`);
      }

      const capture = await res.json();

      if (capture.status === "COMPLETED") {
        // Calculate expiration date (30 days from now)
        const expiresAt = new Date();
        expiresAt.setDate(expiresAt.getDate() + 30);

        // 1. Update Partner record
        const { error: partnerError } = await supabase
          .from("partners")
          .update({
            subscription_status: "Active",
            subscription_expires_at: expiresAt.toISOString(),
            paypal_subscription_id: orderId,
          })
          .eq("id", partnerId);

        if (partnerError) throw partnerError;

        // 2. Log in payments table
        const { error: paymentError } = await supabase
          .from("payments")
          .insert({
            partner_id: partnerId,
            amount: subscriptionAmount,
            payment_type: "PartnerSubscription",
            paypal_order_id: orderId,
            status: "Completed",
          });

        if (paymentError) throw paymentError;

        return new Response(JSON.stringify({ success: true, expiresAt: expiresAt.toISOString() }), {
          status: 200,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      } else {
        throw new Error(`PayPal payment not completed. Status: ${capture.status}`);
      }

    } else {
      throw new Error(`Invalid action: ${action}`);
    }

  } catch (error) {
    console.error("PayPal Edge function error:", error);
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
