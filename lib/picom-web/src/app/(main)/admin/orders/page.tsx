"use client";

import { createClient } from "@/lib/supabase/client";
import {
  fetchAllOrders,
  updateOrderAdmin,
  type OrderWithListing,
} from "@/lib/supabase/queries";
import { formatDate, formatPrice } from "@/lib/utils";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Skeleton } from "@/components/ui/skeleton";
import { Tabs, TabsList, TabsTrigger, TabsContent } from "@/components/ui/tabs";
import { Truck, Package } from "lucide-react";
import { useEffect, useState, useCallback } from "react";

// 주문 상태 라벨과 배지 variant 매핑
const orderStatusMap: Record<
  string,
  { label: string; variant: "default" | "secondary" | "destructive" | "outline" }
> = {
  pending: { label: "결제대기", variant: "secondary" },
  confirmed: { label: "결제완료", variant: "default" },
  shipping: { label: "배송중", variant: "outline" },
  delivered: { label: "배송완료", variant: "default" },
  cancelled: { label: "취소", variant: "destructive" },
  refunded: { label: "환불", variant: "destructive" },
};

// 필터 탭 목록
const filterTabs = [
  { value: "all", label: "전체" },
  { value: "pending", label: "결제대기" },
  { value: "confirmed", label: "결제완료" },
  { value: "shipping", label: "배송중" },
  { value: "delivered", label: "배송완료" },
  { value: "cancelled", label: "취소" },
];

export default function AdminOrdersPage() {
  const supabase = createClient();
  const [orders, setOrders] = useState<OrderWithListing[]>([]);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState("all");
  const [trackingInputId, setTrackingInputId] = useState<string | null>(null);
  const [trackingNumber, setTrackingNumber] = useState("");
  const [updating, setUpdating] = useState<string | null>(null);

  const loadOrders = useCallback(
    async (status?: string) => {
      setLoading(true);
      const { orders: data } = await fetchAllOrders(
        supabase,
        status === "all" ? undefined : status
      );
      setOrders(data);
      setLoading(false);
    },
    [supabase]
  );

  useEffect(() => {
    loadOrders(activeTab);
  }, [activeTab, loadOrders]);

  // 배송 상태 업데이트
  async function handleShippingUpdate(orderId: string, newStatus: string) {
    setUpdating(orderId);
    await updateOrderAdmin(supabase, orderId, {
      status: newStatus,
      shipping_status: newStatus === "shipping" ? "shipped" : newStatus === "delivered" ? "delivered" : undefined,
    });
    setUpdating(null);
    loadOrders(activeTab);
  }

  // 운송장 번호 저장
  async function handleTrackingSave(orderId: string) {
    if (!trackingNumber.trim()) return;
    setUpdating(orderId);
    await updateOrderAdmin(supabase, orderId, {
      tracking_number: trackingNumber.trim(),
      status: "shipping",
      shipping_status: "shipped",
    });
    setTrackingInputId(null);
    setTrackingNumber("");
    setUpdating(null);
    loadOrders(activeTab);
  }

  function getStatusBadge(status: string) {
    const config = orderStatusMap[status] ?? {
      label: status,
      variant: "secondary" as const,
    };
    return <Badge variant={config.variant}>{config.label}</Badge>;
  }

  return (
    <div>
      <h1 className="text-xl font-bold mb-4">주문 관리</h1>

      <Tabs
        value={activeTab}
        onValueChange={(val) => setActiveTab(val as string)}
      >
        <TabsList className="mb-4 flex-wrap">
          {filterTabs.map((tab) => (
            <TabsTrigger key={tab.value} value={tab.value}>
              {tab.label}
            </TabsTrigger>
          ))}
        </TabsList>

        {filterTabs.map((tab) => (
          <TabsContent key={tab.value} value={tab.value}>
            {loading ? (
              <div className="space-y-3">
                {Array.from({ length: 5 }).map((_, i) => (
                  <Skeleton key={i} className="h-24 w-full" />
                ))}
              </div>
            ) : orders.length === 0 ? (
              <p className="text-center text-muted-foreground py-8">
                해당 상태의 주문이 없습니다.
              </p>
            ) : (
              <div className="space-y-3">
                {orders.map((order) => (
                  <Card key={order.id}>
                    <CardContent className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
                      <div className="flex-1 min-w-0">
                        <div className="flex items-center gap-2 mb-1">
                          {getStatusBadge(order.status)}
                          <span className="text-xs text-muted-foreground">
                            #{order.id.slice(0, 8)}
                          </span>
                        </div>
                        <p className="font-medium truncate">
                          {order.listings?.title ?? "상품 정보 없음"}
                        </p>
                        <div className="flex flex-wrap items-center gap-3 text-xs text-muted-foreground mt-1">
                          <span>구매자: {order.buyer_id.slice(0, 8)}...</span>
                          <span>{formatPrice(order.total_amount)}</span>
                          <span>{formatDate(order.created_at)}</span>
                        </div>
                        {order.tracking_number && (
                          <p className="mt-1 text-xs text-muted-foreground">
                            운송장: {order.tracking_number}
                          </p>
                        )}
                      </div>

                      {/* 액션 버튼 영역 */}
                      <div className="flex flex-wrap items-center gap-2 shrink-0">
                        {order.status === "confirmed" && (
                          <Button
                            size="sm"
                            variant="outline"
                            disabled={updating === order.id}
                            onClick={() => {
                              setTrackingInputId(
                                trackingInputId === order.id
                                  ? null
                                  : order.id
                              );
                              setTrackingNumber(
                                order.tracking_number ?? ""
                              );
                            }}
                          >
                            <Truck className="size-3.5 mr-1" />
                            배송 처리
                          </Button>
                        )}
                        {order.status === "shipping" && (
                          <Button
                            size="sm"
                            disabled={updating === order.id}
                            onClick={() =>
                              handleShippingUpdate(order.id, "delivered")
                            }
                          >
                            <Package className="size-3.5 mr-1" />
                            배송 완료
                          </Button>
                        )}
                      </div>
                    </CardContent>

                    {/* 운송장 입력 영역 */}
                    {trackingInputId === order.id && (
                      <div className="px-4 pb-4 flex gap-2">
                        <Input
                          placeholder="운송장 번호 입력..."
                          value={trackingNumber}
                          onChange={(e) => setTrackingNumber(e.target.value)}
                          className="flex-1"
                        />
                        <Button
                          size="sm"
                          disabled={
                            updating === order.id || !trackingNumber.trim()
                          }
                          onClick={() => handleTrackingSave(order.id)}
                        >
                          저장
                        </Button>
                      </div>
                    )}
                  </Card>
                ))}
              </div>
            )}
          </TabsContent>
        ))}
      </Tabs>
    </div>
  );
}
