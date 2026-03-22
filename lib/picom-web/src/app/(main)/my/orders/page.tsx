"use client";

import Link from "next/link";
import Image from "next/image";
import {
  ArrowLeft,
  Package,
  ImageIcon,
  ChevronRight,
} from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import { Tabs, TabsList, TabsTrigger, TabsContent } from "@/components/ui/tabs";
import { useAuth } from "@/hooks/use-auth";
import { useOrders } from "@/hooks/use-orders";
import { formatPrice, formatDate } from "@/lib/utils";
import { useState } from "react";
import type { OrderWithListing } from "@/lib/supabase/queries";

// 주문 상태 한글 라벨
const orderStatusLabels: Record<string, string> = {
  pending: "결제대기",
  confirmed: "결제완료",
  shipping: "배송중",
  delivered: "배송완료",
  cancelled: "취소됨",
  refunded: "환불됨",
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

// 탭 필터와 실제 status 매핑
const TAB_STATUS_MAP: Record<string, string | undefined> = {
  all: undefined,
  active: undefined, // 진행중: pending + confirmed
  shipping: "shipping",
  done: "delivered",
  cancel: undefined, // 취소/환불: cancelled + refunded
};

function filterOrdersByTab(
  orders: OrderWithListing[],
  tab: string
): OrderWithListing[] {
  switch (tab) {
    case "active":
      return orders.filter(
        (o) => o.status === "pending" || o.status === "confirmed"
      );
    case "shipping":
      return orders.filter((o) => o.status === "shipping");
    case "done":
      return orders.filter((o) => o.status === "delivered");
    case "cancel":
      return orders.filter(
        (o) => o.status === "cancelled" || o.status === "refunded"
      );
    default:
      return orders;
  }
}

export default function OrdersPage() {
  const { user, loading: authLoading } = useAuth();
  const { orders, isLoading } = useOrders(user?.id);
  const [activeTab, setActiveTab] = useState("all");

  const filteredOrders = filterOrdersByTab(orders, activeTab);

  // 로딩 상태
  if (authLoading || isLoading) {
    return (
      <div className="mx-auto max-w-3xl px-4 py-8">
        <div className="mb-6 flex items-center gap-3">
          <Skeleton className="h-9 w-9 rounded-lg" />
          <Skeleton className="h-7 w-28" />
        </div>
        <Skeleton className="mb-6 h-10 w-full rounded-lg" />
        <div className="space-y-3">
          {Array.from({ length: 4 }).map((_, i) => (
            <div
              key={i}
              className="flex gap-4 rounded-xl border bg-card p-4"
            >
              <Skeleton className="h-20 w-20 shrink-0 rounded-lg" />
              <div className="flex-1 space-y-2">
                <Skeleton className="h-3 w-20" />
                <Skeleton className="h-4 w-48" />
                <Skeleton className="h-5 w-24" />
                <Skeleton className="h-3 w-32" />
              </div>
            </div>
          ))}
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

  return (
    <div className="mx-auto max-w-3xl px-4 py-8">
      {/* 헤더 */}
      <div className="mb-6 flex items-center gap-3">
        <Link href="/my">
          <Button variant="ghost" size="icon">
            <ArrowLeft className="h-5 w-5" />
          </Button>
        </Link>
        <h1 className="text-xl font-bold">주문내역</h1>
      </div>

      {/* 상태 필터 탭 */}
      <Tabs
        defaultValue="all"
        onValueChange={(val) => setActiveTab(val as string)}
      >
        <TabsList className="mb-6 w-full">
          <TabsTrigger value="all">전체</TabsTrigger>
          <TabsTrigger value="active">진행중</TabsTrigger>
          <TabsTrigger value="shipping">배송중</TabsTrigger>
          <TabsTrigger value="done">완료</TabsTrigger>
          <TabsTrigger value="cancel">취소/환불</TabsTrigger>
        </TabsList>

        {/* 각 탭의 내용은 동일한 filteredOrders로 렌더링 */}
        {["all", "active", "shipping", "done", "cancel"].map((tab) => (
          <TabsContent key={tab} value={tab}>
            {activeTab === tab && (
              <OrderList orders={filteredOrders} />
            )}
          </TabsContent>
        ))}
      </Tabs>
    </div>
  );
}

function OrderList({ orders }: { orders: OrderWithListing[] }) {
  if (orders.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center gap-4 py-20">
        <Package className="h-12 w-12 text-muted-foreground" />
        <p className="text-muted-foreground">주문내역이 없습니다</p>
        <Link href="/listings">
          <Button>매물 둘러보기</Button>
        </Link>
      </div>
    );
  }

  return (
    <div className="space-y-3">
      {orders.map((order) => {
        const listing = order.listings;
        const imageUrl = listing?.images?.[0];
        const title = listing?.title ?? "삭제된 상품";
        const price = order.total_amount;
        const statusLabel =
          orderStatusLabels[order.status] ?? order.status;
        const statusVariant = getOrderStatusVariant(order.status);

        return (
          <Link
            key={order.id}
            href={`/my/orders/${order.id}`}
            className="flex gap-4 rounded-xl border bg-card p-4 transition-all hover:border-primary/30 hover:shadow-sm"
          >
            {/* 상품 이미지 */}
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

            {/* 주문 정보 */}
            <div className="flex flex-1 flex-col justify-center gap-1.5 min-w-0">
              <div className="flex items-center gap-2">
                <Badge variant={statusVariant} className="text-[10px]">
                  {statusLabel}
                </Badge>
                <span className="text-[11px] text-muted-foreground">
                  {formatDate(order.created_at)}
                </span>
              </div>
              <h3 className="text-[14px] font-semibold leading-snug truncate">
                {title}
              </h3>
              <span className="text-[16px] font-bold text-foreground">
                {formatPrice(price)}
              </span>
            </div>

            {/* 상세보기 화살표 */}
            <div className="flex items-center">
              <ChevronRight className="h-5 w-5 text-muted-foreground" />
            </div>
          </Link>
        );
      })}
    </div>
  );
}
