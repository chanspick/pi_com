import { NextRequest, NextResponse } from "next/server";
import { createAdminClient } from "@/lib/supabase/admin";

const TOSS_SECRET_KEY = process.env.TOSS_SECRET_KEY!;
const TOSS_CONFIRM_URL = "https://api.tosspayments.com/v1/payments/confirm";

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { paymentKey, orderId, amount } = body;

    if (!paymentKey || !orderId || !amount) {
      return NextResponse.json(
        { error: "paymentKey, orderId, amount 모두 필수입니다." },
        { status: 400 }
      );
    }

    // 1. 토스페이먼츠 결제 승인 API 호출
    const encryptedSecretKey = btoa(TOSS_SECRET_KEY + ":");
    const tossResponse = await fetch(TOSS_CONFIRM_URL, {
      method: "POST",
      headers: {
        Authorization: `Basic ${encryptedSecretKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ paymentKey, orderId, amount }),
    });

    const tossData = await tossResponse.json();

    if (!tossResponse.ok) {
      return NextResponse.json(
        { error: tossData.message ?? "결제 승인에 실패했습니다.", code: tossData.code },
        { status: tossResponse.status }
      );
    }

    // 2. Supabase 업데이트 (admin client — RLS 우회)
    const supabase = createAdminClient();

    // 2-a. toss_payments 레코드 업데이트
    await supabase
      .from("toss_payments")
      .update({
        payment_key: paymentKey,
        status: "approved",
        method: tossData.method ?? null,
        approved_at: tossData.approvedAt ?? new Date().toISOString(),
        receipt_url: tossData.receipt?.url ?? null,
        raw_data: tossData,
      })
      .eq("order_id", orderId);

    // 2-b. 주문 상태 confirmed로 변경
    const { data: orderData } = await supabase
      .from("orders")
      .update({ status: "confirmed", confirmed_at: new Date().toISOString() })
      .eq("id", orderId)
      .select("listing_id, seller_id")
      .single();

    if (orderData) {
      // 2-c. 매물 상태 reserved로 변경
      await supabase
        .from("listings")
        .update({ status: "reserved" })
        .eq("id", orderData.listing_id);

      // 2-d. 판매자에게 알림 전송
      await supabase.from("notifications").insert({
        user_id: orderData.seller_id,
        title: "새 주문이 접수되었습니다",
        body: `주문번호 ${orderId.slice(0, 8).toUpperCase()} — 결제가 완료되어 배송 준비가 필요합니다.`,
        type: "order",
        related_order_id: orderId,
        related_listing_id: orderData.listing_id,
      });

      // 2-e. 장바구니에서 해당 상품 제거 (buyer_id 필요 → orders에서 추출)
      const { data: fullOrder } = await supabase
        .from("orders")
        .select("buyer_id")
        .eq("id", orderId)
        .single();

      if (fullOrder) {
        await supabase
          .from("cart_items")
          .delete()
          .eq("user_id", fullOrder.buyer_id)
          .eq("listing_id", orderData.listing_id);
      }
    }

    return NextResponse.json({ success: true, payment: tossData });
  } catch (err) {
    console.error("Payment confirm error:", err);
    return NextResponse.json(
      { error: "서버 오류가 발생했습니다." },
      { status: 500 }
    );
  }
}
