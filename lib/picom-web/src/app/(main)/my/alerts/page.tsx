"use client";

import Link from "next/link";
import { BellRing, ArrowLeft, Trash2 } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import { useAuth } from "@/hooks/use-auth";
import {
  usePriceAlerts,
  useTogglePriceAlert,
  useDeletePriceAlert,
} from "@/hooks/use-price-alerts";
import { formatPrice, formatRelativeTime } from "@/lib/utils";

export default function AlertsPage() {
  const { user, loading: authLoading } = useAuth();
  const { alerts, isLoading } = usePriceAlerts(user?.id);
  const toggleMutation = useTogglePriceAlert();
  const deleteMutation = useDeletePriceAlert();

  const handleToggle = (alertId: string, currentActive: boolean) => {
    if (!user?.id) return;
    toggleMutation.mutate({
      alertId,
      isActive: !currentActive,
      userId: user.id,
    });
  };

  const handleDelete = (alertId: string) => {
    if (!user?.id) return;
    deleteMutation.mutate({ alertId, userId: user.id });
  };

  // 로딩 상태
  if (authLoading || isLoading) {
    return (
      <div className="mx-auto max-w-2xl px-4 py-8">
        <div className="mb-6 flex items-center gap-3">
          <Skeleton className="h-9 w-9 rounded-lg" />
          <Skeleton className="h-7 w-28" />
        </div>
        <div className="space-y-3">
          {Array.from({ length: 4 }).map((_, i) => (
            <div key={i} className="rounded-xl border bg-card p-4">
              <div className="flex items-center justify-between">
                <div className="space-y-2">
                  <Skeleton className="h-4 w-40" />
                  <Skeleton className="h-5 w-28" />
                  <Skeleton className="h-3 w-20" />
                </div>
                <div className="flex items-center gap-2">
                  <Skeleton className="h-6 w-14 rounded-full" />
                  <Skeleton className="h-8 w-8 rounded-lg" />
                </div>
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
      <div className="mx-auto max-w-2xl px-4 py-8">
        <div className="flex flex-col items-center justify-center gap-4 py-20">
          <BellRing className="h-12 w-12 text-muted-foreground" />
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
    <div className="mx-auto max-w-2xl px-4 py-8">
      {/* 헤더 */}
      <div className="mb-6 flex items-center gap-3">
        <Link href="/my">
          <Button variant="ghost" size="icon">
            <ArrowLeft className="h-5 w-5" />
          </Button>
        </Link>
        <h1 className="text-xl font-bold">가격 알림</h1>
        {alerts.length > 0 && (
          <span className="text-sm text-muted-foreground">
            {alerts.length}개
          </span>
        )}
      </div>

      {/* 빈 상태 */}
      {alerts.length === 0 ? (
        <div className="flex flex-col items-center justify-center gap-4 py-20">
          <BellRing className="h-12 w-12 text-muted-foreground" />
          <p className="text-muted-foreground">
            설정된 가격 알림이 없습니다
          </p>
          <Link href="/parts">
            <Button>부품 시세 보기</Button>
          </Link>
        </div>
      ) : (
        /* 알림 목록 */
        <div className="space-y-3">
          {alerts.map((alert) => (
            <div
              key={alert.id}
              className={`rounded-xl border bg-card p-4 transition-all ${
                alert.is_active
                  ? "border-border"
                  : "border-border/50 opacity-60"
              }`}
            >
              <div className="flex items-center justify-between gap-4">
                {/* 알림 정보 */}
                <div className="min-w-0 flex-1">
                  <div className="flex items-center gap-2 mb-1">
                    <h3 className="text-sm font-semibold truncate">
                      {alert.part_name ?? "알 수 없는 부품"}
                    </h3>
                    <Badge
                      variant={alert.is_active ? "default" : "secondary"}
                      className={`text-[11px] shrink-0 ${
                        alert.is_active
                          ? "bg-green-500/10 text-green-600 border-green-500/20 hover:bg-green-500/20"
                          : ""
                      }`}
                    >
                      {alert.is_active ? "활성" : "비활성"}
                    </Badge>
                  </div>
                  <p className="text-base font-bold">
                    목표가 {formatPrice(alert.target_price)}
                  </p>
                  {alert.price_at_creation != null && (
                    <p className="mt-0.5 text-xs text-muted-foreground">
                      설정 시 가격: {formatPrice(alert.price_at_creation)}
                    </p>
                  )}
                  <p className="mt-1 text-xs text-muted-foreground">
                    {formatRelativeTime(alert.created_at)}
                  </p>
                </div>

                {/* 액션 버튼 */}
                <div className="flex items-center gap-2 shrink-0">
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() => handleToggle(alert.id, alert.is_active)}
                    disabled={toggleMutation.isPending}
                  >
                    {alert.is_active ? "비활성화" : "활성화"}
                  </Button>
                  <Button
                    variant="ghost"
                    size="icon"
                    onClick={() => handleDelete(alert.id)}
                    disabled={deleteMutation.isPending}
                    className="text-muted-foreground hover:text-destructive"
                    aria-label="알림 삭제"
                  >
                    <Trash2 className="h-4 w-4" />
                  </Button>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
