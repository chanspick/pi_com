"use client";

import { useState } from "react";
import Link from "next/link";
import Image from "next/image";
import { useParams, useRouter } from "next/navigation";
import {
  ArrowLeft,
  Package,
  ImageIcon,
  AlertCircle,
} from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { Separator } from "@/components/ui/separator";
import { Skeleton } from "@/components/ui/skeleton";
import { useAuth } from "@/hooks/use-auth";
import { useOrderDetail } from "@/hooks/use-orders";
import { useRefundByOrder, useCreateRefund } from "@/hooks/use-refunds";
import { formatPrice, getCategoryLabel } from "@/lib/utils";

export default function RefundRequestPage() {
  const params = useParams();
  const router = useRouter();
  const orderId = params.orderId as string;
  const { user, loading: authLoading } = useAuth();
  const { order, isLoading: orderLoading } = useOrderDetail(orderId);
  const { refund: existingRefund, isLoading: refundLoading } = useRefundByOrder(orderId);
  const createRefundMutation = useCreateRefund();

  const [reason, setReason] = useState("");
  const [submitError, setSubmitError] = useState<string | null>(null);

  const handleSubmit = () => {
    if (!user?.id || !order) return;
    setSubmitError(null);

    createRefundMutation.mutate(
      {
        order_id: orderId,
        user_id: user.id,
        amount: order.total_amount,
        reason: reason.trim() || undefined,
      },
      {
        onSuccess: () => {
          router.push(`/my/orders/${orderId}`);
        },
        onError: (err) => {
          setSubmitError(
            err instanceof Error ? err.message : "환불 요청에 실패했습니다."
          );
        },
      }
    );
  };

  // 로딩 상태
  if (authLoading || orderLoading || refundLoading) {
    return (
      <div className="mx-auto max-w-3xl px-4 py-8">
        <div className="mb-6 flex items-center gap-3">
          <Skeleton className="h-9 w-9 rounded-lg" />
          <Skeleton className="h-7 w-28" />
        </div>
        <div className="space-y-4">
          <Skeleton className="h-32 w-full rounded-xl" />
          <Skeleton className="h-48 w-full rounded-xl" />
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

  // 배송완료 상태가 아닌 경우 환불 불가
  if (order.status !== "delivered") {
    return (
      <div className="mx-auto max-w-3xl px-4 py-8">
        <div className="mb-6 flex items-center gap-3">
          <Link href={`/my/orders/${orderId}`}>
            <Button variant="ghost" size="icon">
              <ArrowLeft className="h-5 w-5" />
            </Button>
          </Link>
          <h1 className="text-xl font-bold">환불 요청</h1>
        </div>
        <Card className="p-6">
          <div className="flex flex-col items-center gap-4 py-8">
            <AlertCircle className="h-12 w-12 text-muted-foreground" />
            <p className="text-muted-foreground text-center">
              배송완료 상태의 주문만 환불 요청이 가능합니다.
            </p>
            <Link href={`/my/orders/${orderId}`}>
              <Button variant="outline">주문 상세로 돌아가기</Button>
            </Link>
          </div>
        </Card>
      </div>
    );
  }

  // 이미 환불 요청이 있는 경우
  if (existingRefund) {
    const refundStatusLabels: Record<string, string> = {
      pending: "대기중",
      approved: "승인됨",
      rejected: "거절됨",
      completed: "완료",
    };

    return (
      <div className="mx-auto max-w-3xl px-4 py-8">
        <div className="mb-6 flex items-center gap-3">
          <Link href={`/my/orders/${orderId}`}>
            <Button variant="ghost" size="icon">
              <ArrowLeft className="h-5 w-5" />
            </Button>
          </Link>
          <h1 className="text-xl font-bold">환불 요청</h1>
        </div>
        <Card className="p-6">
          <div className="flex flex-col items-center gap-4 py-8">
            <AlertCircle className="h-12 w-12 text-primary" />
            <p className="font-semibold text-[15px]">
              이미 환불 요청이 진행중입니다.
            </p>
            <Badge variant="secondary" className="text-[12px]">
              {refundStatusLabels[existingRefund.status] ?? existingRefund.status}
            </Badge>
            {existingRefund.reason && (
              <p className="text-[13px] text-muted-foreground text-center max-w-sm">
                사유: {existingRefund.reason}
              </p>
            )}
            <Link href={`/my/orders/${orderId}`}>
              <Button variant="outline">주문 상세로 돌아가기</Button>
            </Link>
          </div>
        </Card>
      </div>
    );
  }

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const listing = (order as any).listings as Record<string, unknown> | null;
  const imageUrl = (listing?.images as string[] | null)?.[0];
  const title = (listing?.title as string) ?? "삭제된 상품";
  const category = (listing?.category as string) ?? "";

  return (
    <div className="mx-auto max-w-3xl px-4 py-8">
      {/* 헤더 */}
      <div className="mb-6 flex items-center gap-3">
        <Link href={`/my/orders/${orderId}`}>
          <Button variant="ghost" size="icon">
            <ArrowLeft className="h-5 w-5" />
          </Button>
        </Link>
        <h1 className="text-xl font-bold">환불 요청</h1>
      </div>

      {/* 상품 정보 요약 */}
      <Card className="mb-4 p-5">
        <h2 className="text-[14px] font-semibold mb-3">주문 상품</h2>
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
              {formatPrice(order.total_amount)}
            </span>
          </div>
        </div>
      </Card>

      {/* 환불 금액 */}
      <Card className="mb-4 p-5">
        <h2 className="text-[14px] font-semibold mb-3">환불 금액</h2>
        <div className="space-y-2 text-[13px]">
          <div className="flex justify-between">
            <span className="text-muted-foreground">결제 금액</span>
            <span>{formatPrice(order.total_amount)}</span>
          </div>
          <Separator />
          <div className="flex justify-between font-semibold text-[14px]">
            <span>환불 예정 금액</span>
            <span className="text-primary">
              {formatPrice(order.total_amount)}
            </span>
          </div>
        </div>
      </Card>

      {/* 환불 사유 */}
      <Card className="mb-6 p-5">
        <h2 className="text-[14px] font-semibold mb-3">환불 사유</h2>
        <textarea
          className="w-full min-h-[120px] rounded-lg border border-input bg-background px-3 py-2 text-[13px] placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring resize-none"
          placeholder="환불 사유를 입력해주세요. (선택)"
          value={reason}
          onChange={(e) => setReason(e.target.value)}
          maxLength={500}
        />
        <p className="mt-1.5 text-[11px] text-muted-foreground text-right">
          {reason.length}/500
        </p>
      </Card>

      {/* 에러 메시지 */}
      {submitError && (
        <div className="mb-4 rounded-lg bg-destructive/10 p-3 text-[13px] text-destructive flex items-center gap-2">
          <AlertCircle className="h-4 w-4 shrink-0" />
          {submitError}
        </div>
      )}

      {/* 환불 요청 버튼 */}
      <Button
        className="w-full"
        size="lg"
        onClick={handleSubmit}
        disabled={createRefundMutation.isPending}
      >
        {createRefundMutation.isPending ? "요청 중..." : "환불 요청"}
      </Button>

      <p className="mt-3 text-[11px] text-muted-foreground text-center leading-relaxed">
        환불 요청 후 관리자 검토를 거쳐 승인됩니다.
        <br />
        승인 후 결제 수단으로 환불이 진행됩니다.
      </p>
    </div>
  );
}
