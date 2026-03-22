"use client";

import { useEffect, useState } from "react";
import { useSearchParams } from "next/navigation";
import Link from "next/link";
import Image from "next/image";
import {
  CheckCircle2,
  Package,
  ShoppingBag,
  ImageIcon,
  Loader2,
  AlertCircle,
} from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Separator } from "@/components/ui/separator";
import { Skeleton } from "@/components/ui/skeleton";
import { Badge } from "@/components/ui/badge";
import { useAuth } from "@/hooks/use-auth";
import { createClient } from "@/lib/supabase/client";
import { fetchOrderById } from "@/lib/supabase/queries";
import { formatPrice, getCategoryLabel, formatDate } from "@/lib/utils";

export default function CheckoutSuccessPage() {
  const searchParams = useSearchParams();
  const { user, loading: authLoading } = useAuth();
  const supabase = createClient();

  const orderId = searchParams.get("orderId");
  const paymentKey = searchParams.get("paymentKey");
  const amount = searchParams.get("amount");

  const [order, setOrder] = useState<Record<string, unknown> | null>(null);
  const [loading, setLoading] = useState(true);
  const [confirmError, setConfirmError] = useState<string | null>(null);

  // 결제 승인 + 주문 정보 로드
  useEffect(() => {
    async function confirmAndLoad() {
      if (!orderId || !user) return;

      setLoading(true);
      try {
        // 1. 서버 API로 결제 승인 요청 (paymentKey가 있는 경우)
        if (paymentKey && amount) {
          const res = await fetch("/api/payments/confirm", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({
              paymentKey,
              orderId,
              amount: Number(amount),
            }),
          });

          if (!res.ok) {
            const data = await res.json();
            setConfirmError(data.error ?? "결제 승인에 실패했습니다.");
          }
        }

        // 2. 주문 정보 가져오기 (승인 결과와 무관하게)
        const { order: orderData } = await fetchOrderById(supabase, orderId);
        if (orderData) {
          setOrder(orderData as Record<string, unknown>);
        }
      } catch {
        // 네트워크 오류 등
      } finally {
        setLoading(false);
      }
    }

    if (user && !authLoading) {
      confirmAndLoad();
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [orderId, paymentKey, amount, user, authLoading]);

  // 로딩 상태
  if (authLoading || loading) {
    return (
      <div className="mx-auto max-w-3xl px-4 py-8">
        <div className="flex flex-col items-center gap-4 py-10">
          <Loader2 className="h-10 w-10 animate-spin text-primary" />
          <p className="text-[15px] text-muted-foreground">
            결제를 처리하고 있습니다...
          </p>
        </div>
        <div className="space-y-4">
          <Skeleton className="h-40 rounded-xl" />
          <Skeleton className="h-24 rounded-xl" />
        </div>
      </div>
    );
  }

  if (!order) {
    return (
      <div className="mx-auto max-w-3xl px-4 py-8">
        <div className="flex flex-col items-center justify-center gap-4 py-20">
          <Package className="h-12 w-12 text-muted-foreground" />
          <p className="text-muted-foreground">주문 정보를 찾을 수 없습니다.</p>
          <Link href="/listings">
            <Button>매물 둘러보기</Button>
          </Link>
        </div>
      </div>
    );
  }

  const listing = order.listings as Record<string, unknown> | null;
  const imageUrl = listing ? (listing.images as string[] | null)?.[0] : null;
  const title = (listing?.title as string) ?? "상품";
  const category = (listing?.category as string) ?? "";
  const totalAmount = (order.total_amount as number) ?? 0;
  const shippingFee = (order.shipping_fee as number) ?? 0;
  const itemPrice = totalAmount - shippingFee;
  const shippingAddress = order.shipping_address as Record<string, unknown> | null;

  return (
    <div className="mx-auto max-w-3xl px-4 py-8">
      {/* 성공 헤더 */}
      <div className="flex flex-col items-center gap-3 py-6">
        <div className="flex h-16 w-16 items-center justify-center rounded-full bg-green-100 dark:bg-green-900/30">
          <CheckCircle2 className="h-8 w-8 text-green-600 dark:text-green-400" />
        </div>
        <h1 className="text-[22px] font-bold">결제가 완료되었습니다</h1>
        <p className="text-[14px] text-muted-foreground">
          주문번호: {orderId?.slice(0, 8).toUpperCase()}
        </p>
      </div>

      {/* 승인 실패 경고 */}
      {confirmError && (
        <div className="mb-4 flex items-start gap-2 rounded-lg border border-amber-300 bg-amber-50 p-3 text-[13px] text-amber-800 dark:border-amber-700 dark:bg-amber-900/20 dark:text-amber-200">
          <AlertCircle className="h-4 w-4 mt-0.5 shrink-0" />
          <div>
            <p className="font-medium">결제 승인 확인 중 문제가 발생했습니다.</p>
            <p className="mt-0.5">{confirmError} — 고객센터(02-6402-0025)로 문의해 주세요.</p>
          </div>
        </div>
      )}

      <div className="space-y-4">
        {/* 주문 상품 */}
        <Card>
          <CardContent>
            <h2 className="text-[15px] font-semibold mb-3 flex items-center gap-2">
              <Package className="h-4 w-4" />
              주문 상품
            </h2>
            <div className="flex gap-4">
              <div className="relative h-20 w-20 shrink-0 overflow-hidden rounded-lg bg-muted">
                {imageUrl ? (
                  <Image
                    src={imageUrl}
                    alt={title}
                    fill
                    className="object-cover"
                    sizes="80px"
                  />
                ) : (
                  <div className="flex h-full w-full items-center justify-center text-muted-foreground">
                    <ImageIcon className="h-5 w-5" />
                  </div>
                )}
              </div>
              <div className="flex flex-1 flex-col justify-center gap-1 min-w-0">
                {category && (
                  <Badge variant="secondary" className="w-fit text-[10px] font-semibold">
                    {getCategoryLabel(category)}
                  </Badge>
                )}
                <p className="text-[14px] font-semibold leading-snug truncate">{title}</p>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* 결제 정보 */}
        <Card>
          <CardContent>
            <h2 className="text-[15px] font-semibold mb-3">결제 정보</h2>
            <div className="space-y-2 text-[14px]">
              <div className="flex justify-between">
                <span className="text-muted-foreground">상품 금액</span>
                <span>{formatPrice(itemPrice)}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-muted-foreground">배송비</span>
                <span>{formatPrice(shippingFee)}</span>
              </div>
              <Separator />
              <div className="flex justify-between text-[16px] font-bold pt-1">
                <span>총 결제 금액</span>
                <span className="text-primary">{formatPrice(totalAmount)}</span>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* 배송지 */}
        {shippingAddress && (
          <Card>
            <CardContent>
              <h2 className="text-[15px] font-semibold mb-3">배송지 정보</h2>
              <div className="text-[14px] space-y-1">
                <p className="font-medium">{shippingAddress.recipient_name as string}</p>
                <p className="text-muted-foreground">{shippingAddress.phone as string}</p>
                <p className="text-foreground">
                  ({shippingAddress.postal_code as string}){" "}
                  {shippingAddress.address_line1 as string}
                  {shippingAddress.address_line2
                    ? ` ${String(shippingAddress.address_line2)}`
                    : null}
                </p>
              </div>
            </CardContent>
          </Card>
        )}

        {/* 주문일 */}
        <div className="text-center text-[13px] text-muted-foreground">
          주문일시: {formatDate(order.created_at as string)}
        </div>

        {/* 버튼 */}
        <div className="flex gap-3">
          <Link href="/my/orders" className="flex-1">
            <Button className="w-full h-12 text-base font-semibold" size="lg">
              <ShoppingBag className="h-4 w-4 mr-2" />
              주문내역 보기
            </Button>
          </Link>
          <Link href="/listings" className="flex-1">
            <Button variant="outline" className="w-full h-12 text-base font-semibold" size="lg">
              쇼핑 계속하기
            </Button>
          </Link>
        </div>
      </div>
    </div>
  );
}
