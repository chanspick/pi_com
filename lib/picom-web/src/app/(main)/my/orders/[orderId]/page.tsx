"use client";

import Link from "next/link";
import Image from "next/image";
import { useParams } from "next/navigation";
import {
  ArrowLeft,
  Package,
  Truck,
  ImageIcon,
  CheckCircle2,
  XCircle,
  Clock,
  CreditCard,
  MapPin,
} from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { Separator } from "@/components/ui/separator";
import { Skeleton } from "@/components/ui/skeleton";
import { useAuth } from "@/hooks/use-auth";
import { useOrderDetail, useCancelOrder } from "@/hooks/use-orders";
import { formatPrice, formatDate, getCategoryLabel } from "@/lib/utils";
import { useState } from "react";

// 주문 상태 한글 라벨
const orderStatusLabels: Record<string, string> = {
  pending: "결제대기",
  confirmed: "결제완료",
  shipping: "배송중",
  delivered: "배송완료",
  cancelled: "취소됨",
  refunded: "환불됨",
};

// 배송 상태 한글 라벨
const shippingStatusLabels: Record<string, string> = {
  preparing: "배송 준비중",
  shipped: "발송완료",
  in_transit: "배송중",
  delivered: "배송완료",
  returned: "반송됨",
};

// 주문 상태별 배지 색상
function getOrderStatusVariant(
  status: string
): "default" | "secondary" | "destructive" | "outline" {
  switch (status) {
    case "pending":
      return "outline";
    case "confirmed":
      return "default";
    case "shipping":
      return "default";
    case "delivered":
      return "secondary";
    case "cancelled":
    case "refunded":
      return "destructive";
    default:
      return "secondary";
  }
}

// 타임라인 아이콘
function getTimelineIcon(step: string, isActive: boolean) {
  const baseClass = `h-5 w-5 ${isActive ? "text-primary" : "text-muted-foreground"}`;
  switch (step) {
    case "created":
      return <Clock className={baseClass} />;
    case "confirmed":
      return <CreditCard className={baseClass} />;
    case "shipped":
      return <Truck className={baseClass} />;
    case "delivered":
      return <CheckCircle2 className={baseClass} />;
    case "cancelled":
      return <XCircle className={baseClass} />;
    default:
      return <Package className={baseClass} />;
  }
}

export default function OrderDetailPage() {
  const params = useParams();
  const orderId = params.orderId as string;
  const { user, loading: authLoading } = useAuth();
  const { order, isLoading } = useOrderDetail(orderId);
  const cancelMutation = useCancelOrder();
  const [showCancelConfirm, setShowCancelConfirm] = useState(false);

  const handleCancel = () => {
    if (!user?.id || !orderId) return;
    cancelMutation.mutate(
      { orderId, userId: user.id },
      {
        onSuccess: () => setShowCancelConfirm(false),
      }
    );
  };

  // 로딩 상태
  if (authLoading || isLoading) {
    return (
      <div className="mx-auto max-w-3xl px-4 py-8">
        <div className="mb-6 flex items-center gap-3">
          <Skeleton className="h-9 w-9 rounded-lg" />
          <Skeleton className="h-7 w-28" />
        </div>
        <div className="space-y-4">
          <Skeleton className="h-32 w-full rounded-xl" />
          <Skeleton className="h-48 w-full rounded-xl" />
          <Skeleton className="h-32 w-full rounded-xl" />
        </div>
      </div>
    );
  }

  // 로그인 필요
  if (!user) {
    return (
      <div className="mx-auto max-w-3xl px-4 py-8">
        <div className="flex flex-col items-center justify-center gap-4 py-20">
          <Package className="h-12 w-12 text-muted-foreground" />
          <p className="text-muted-foreground">
            로그인이 필요한 서비스입니다.
          </p>
          <Link href="/login">
            <Button>로그인</Button>
          </Link>
        </div>
      </div>
    );
  }

  // 주문을 찾을 수 없음
  if (!order) {
    return (
      <div className="mx-auto max-w-3xl px-4 py-8">
        <div className="flex flex-col items-center justify-center gap-4 py-20">
          <Package className="h-12 w-12 text-muted-foreground" />
          <p className="text-muted-foreground">
            주문 정보를 찾을 수 없습니다.
          </p>
          <Link href="/my/orders">
            <Button>주문내역으로 돌아가기</Button>
          </Link>
        </div>
      </div>
    );
  }

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const listing = (order as any).listings as Record<string, unknown> | null;
  const imageUrl = (listing?.images as string[] | null)?.[0];
  const title = (listing?.title as string) ?? "삭제된 상품";
  const category = (listing?.category as string) ?? "";
  const statusLabel = orderStatusLabels[order.status] ?? order.status;
  const statusVariant = getOrderStatusVariant(order.status);
  const shippingAddress = order.shipping_address as Record<string, unknown> | null;

  // 타임라인 데이터 구성
  const timelineSteps = [
    {
      key: "created",
      label: "주문 생성",
      date: order.created_at,
      isActive: true,
    },
    {
      key: "confirmed",
      label: "결제 완료",
      date: order.confirmed_at,
      isActive: !!order.confirmed_at,
    },
    {
      key: "shipped",
      label: "배송 시작",
      date: order.shipped_at,
      isActive: !!order.shipped_at,
    },
    {
      key: "delivered",
      label: "배송 완료",
      date: order.delivered_at,
      isActive: !!order.delivered_at,
    },
  ];

  // 취소된 경우 취소 타임라인 추가
  if (order.cancelled_at) {
    timelineSteps.push({
      key: "cancelled",
      label: "주문 취소",
      date: order.cancelled_at,
      isActive: true,
    });
  }

  return (
    <div className="mx-auto max-w-3xl px-4 py-8">
      {/* 헤더 */}
      <div className="mb-6 flex items-center gap-3">
        <Link href="/my/orders">
          <Button variant="ghost" size="icon">
            <ArrowLeft className="h-5 w-5" />
          </Button>
        </Link>
        <h1 className="text-xl font-bold">주문 상세</h1>
      </div>

      {/* 주문 상태 카드 */}
      <Card className="mb-4 p-5">
        <div className="flex items-center justify-between mb-3">
          <Badge variant={statusVariant} className="text-xs">
            {statusLabel}
          </Badge>
          <span className="text-[12px] text-muted-foreground">
            주문번호: {order.id.slice(0, 8).toUpperCase()}
          </span>
        </div>
        <p className="text-[12px] text-muted-foreground">
          주문일시: {formatDate(order.created_at)}
        </p>
      </Card>

      {/* 상품 정보 */}
      <Card className="mb-4 p-5">
        <h2 className="text-[14px] font-semibold mb-3">상품 정보</h2>
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
          <div className="flex flex-col justify-center gap-1 min-w-0">
            {category && (
              <Badge
                variant="secondary"
                className="w-fit text-[10px] font-semibold"
              >
                {getCategoryLabel(category)}
              </Badge>
            )}
            <h3 className="text-[14px] font-semibold leading-snug truncate">
              {title}
            </h3>
            <span className="text-[16px] font-bold">
              {formatPrice(listing?.price as number ?? order.total_amount)}
            </span>
          </div>
        </div>
      </Card>

      {/* 배송 정보 */}
      <Card className="mb-4 p-5">
        <h2 className="text-[14px] font-semibold mb-3 flex items-center gap-2">
          <MapPin className="h-4 w-4" />
          배송 정보
        </h2>
        {shippingAddress ? (
          <div className="space-y-1.5 text-[13px]">
            {shippingAddress.recipient_name ? (
              <p>
                <span className="text-muted-foreground">받는분: </span>
                {String(shippingAddress.recipient_name)}
              </p>
            ) : null}
            {shippingAddress.phone ? (
              <p>
                <span className="text-muted-foreground">연락처: </span>
                {String(shippingAddress.phone)}
              </p>
            ) : null}
            {(shippingAddress.address_line1 || shippingAddress.postal_code) ? (
              <p>
                <span className="text-muted-foreground">주소: </span>
                {shippingAddress.postal_code ? `(${String(shippingAddress.postal_code)}) ` : null}
                {String(shippingAddress.address_line1)}
                {shippingAddress.address_line2
                  ? ` ${String(shippingAddress.address_line2)}`
                  : null}
              </p>
            ) : null}
          </div>
        ) : (
          <p className="text-[13px] text-muted-foreground">
            배송지 정보가 없습니다.
          </p>
        )}

        {/* 배송 상태 */}
        {order.shipping_status && (
          <>
            <Separator className="my-3" />
            <div className="flex items-center gap-2 text-[13px]">
              <Truck className="h-4 w-4 text-muted-foreground" />
              <span className="text-muted-foreground">배송상태:</span>
              <span className="font-medium">
                {shippingStatusLabels[order.shipping_status] ??
                  order.shipping_status}
              </span>
            </div>
          </>
        )}

        {/* 운송장 번호 */}
        {order.tracking_number && (
          <div className="mt-2 flex items-center gap-2 text-[13px]">
            <Package className="h-4 w-4 text-muted-foreground" />
            <span className="text-muted-foreground">운송장번호:</span>
            <span className="font-mono font-medium">
              {order.tracking_number}
            </span>
          </div>
        )}
      </Card>

      {/* 결제 정보 */}
      <Card className="mb-4 p-5">
        <h2 className="text-[14px] font-semibold mb-3 flex items-center gap-2">
          <CreditCard className="h-4 w-4" />
          결제 정보
        </h2>
        <div className="space-y-2 text-[13px]">
          <div className="flex justify-between">
            <span className="text-muted-foreground">상품금액</span>
            <span>
              {formatPrice(order.total_amount - (order.shipping_fee ?? 0))}
            </span>
          </div>
          <div className="flex justify-between">
            <span className="text-muted-foreground">배송비</span>
            <span>
              {order.shipping_fee
                ? formatPrice(order.shipping_fee)
                : "무료"}
            </span>
          </div>
          <Separator />
          <div className="flex justify-between font-semibold text-[14px]">
            <span>총 결제금액</span>
            <span className="text-primary">
              {formatPrice(order.total_amount)}
            </span>
          </div>
        </div>
      </Card>

      {/* 주문 타임라인 */}
      <Card className="mb-4 p-5">
        <h2 className="text-[14px] font-semibold mb-4">주문 진행 상태</h2>
        <div className="space-y-0">
          {timelineSteps.map((step, idx) => (
            <div key={step.key} className="flex gap-3">
              {/* 아이콘 + 연결선 */}
              <div className="flex flex-col items-center">
                <div
                  className={`flex h-8 w-8 items-center justify-center rounded-full border-2 ${
                    step.isActive
                      ? "border-primary bg-primary/10"
                      : "border-muted bg-muted"
                  }`}
                >
                  {getTimelineIcon(step.key, step.isActive)}
                </div>
                {idx < timelineSteps.length - 1 && (
                  <div
                    className={`w-0.5 flex-1 min-h-6 ${
                      timelineSteps[idx + 1]?.isActive
                        ? "bg-primary"
                        : "bg-muted"
                    }`}
                  />
                )}
              </div>
              {/* 내용 */}
              <div className="pb-4">
                <p
                  className={`text-[13px] font-medium ${
                    step.isActive
                      ? "text-foreground"
                      : "text-muted-foreground"
                  }`}
                >
                  {step.label}
                </p>
                {step.date && (
                  <p className="text-[11px] text-muted-foreground">
                    {formatDate(step.date)}
                  </p>
                )}
              </div>
            </div>
          ))}
        </div>
      </Card>

      {/* 액션 버튼 */}
      <div className="space-y-3">
        {/* 결제대기 상태: 주문 취소 가능 */}
        {order.status === "pending" && (
          <>
            {showCancelConfirm ? (
              <Card className="p-4">
                <p className="text-[13px] text-center mb-3">
                  정말 주문을 취소하시겠습니까?
                </p>
                <div className="flex gap-2">
                  <Button
                    variant="outline"
                    className="flex-1"
                    onClick={() => setShowCancelConfirm(false)}
                  >
                    아니오
                  </Button>
                  <Button
                    variant="destructive"
                    className="flex-1"
                    onClick={handleCancel}
                    disabled={cancelMutation.isPending}
                  >
                    {cancelMutation.isPending ? "취소 중..." : "주문 취소"}
                  </Button>
                </div>
              </Card>
            ) : (
              <Button
                variant="outline"
                className="w-full"
                onClick={() => setShowCancelConfirm(true)}
              >
                주문 취소
              </Button>
            )}
          </>
        )}

        {/* 배송완료 상태: 환불 요청 */}
        {order.status === "delivered" && (
          <Link href={`/my/orders/${orderId}/refund`}>
            <Button variant="outline" className="w-full">
              환불 요청
            </Button>
          </Link>
        )}
      </div>

      {/* 비고 */}
      {order.notes && (
        <Card className="mt-4 p-5">
          <h2 className="text-[14px] font-semibold mb-2">비고</h2>
          <p className="text-[13px] text-muted-foreground whitespace-pre-wrap">
            {order.notes}
          </p>
        </Card>
      )}
    </div>
  );
}
