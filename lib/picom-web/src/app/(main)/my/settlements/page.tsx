"use client";

import { useState, useMemo } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { useEffect } from "react";
import {
  ArrowLeft,
  Wallet,
  Receipt,
  TrendingUp,
  Calendar,
} from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { Separator } from "@/components/ui/separator";
import { Skeleton } from "@/components/ui/skeleton";
import { Tabs, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { useAuth } from "@/hooks/use-auth";
import { useSettlements } from "@/hooks/use-settlements";
import { formatPrice, formatDate } from "@/lib/utils";
import type { SettlementRow } from "@/lib/supabase/queries";

// 정산 상태 한글 라벨
const settlementStatusLabels: Record<string, string> = {
  pending: "대기중",
  processing: "처리중",
  completed: "완료",
};

// 정산 상태별 배지 variant
function getSettlementStatusVariant(
  status: string
): "default" | "secondary" | "destructive" | "outline" {
  switch (status) {
    case "pending":
      return "outline";
    case "processing":
      return "default";
    case "completed":
      return "secondary";
    default:
      return "outline";
  }
}

// 정산 카드 컴포넌트
function SettlementCard({ settlement }: { settlement: SettlementRow }) {
  const statusLabel =
    settlementStatusLabels[settlement.status] ?? settlement.status;
  const statusVariant = getSettlementStatusVariant(settlement.status);

  return (
    <Card className="p-4">
      <div className="flex items-center justify-between mb-3">
        <Badge variant={statusVariant} className="text-[11px]">
          {statusLabel}
        </Badge>
        <span className="text-[11px] text-muted-foreground">
          {formatDate(settlement.created_at)}
        </span>
      </div>

      <div className="space-y-2 text-[13px]">
        <div className="flex justify-between">
          <span className="text-muted-foreground flex items-center gap-1.5">
            <Receipt className="h-3.5 w-3.5" />
            주문번호
          </span>
          <span className="font-mono text-[12px]">
            {settlement.order_id.slice(0, 8).toUpperCase()}
          </span>
        </div>

        <div className="flex justify-between">
          <span className="text-muted-foreground">판매금액</span>
          <span>{formatPrice(settlement.amount)}</span>
        </div>

        <div className="flex justify-between">
          <span className="text-muted-foreground">수수료</span>
          <span className="text-destructive">
            -{formatPrice(settlement.fee)}
          </span>
        </div>

        <Separator />

        <div className="flex justify-between font-semibold">
          <span>정산금액</span>
          <span className="text-primary">
            {formatPrice(settlement.net_amount)}
          </span>
        </div>
      </div>

      {settlement.settled_at && (
        <div className="mt-3 flex items-center gap-1.5 text-[11px] text-muted-foreground">
          <Calendar className="h-3 w-3" />
          정산일: {formatDate(settlement.settled_at)}
        </div>
      )}
    </Card>
  );
}

// 스켈레톤 로딩
function SettlementsSkeleton() {
  return (
    <div className="space-y-3">
      {Array.from({ length: 3 }).map((_, i) => (
        <Card key={i} className="p-4">
          <div className="flex items-center justify-between mb-3">
            <Skeleton className="h-5 w-16" />
            <Skeleton className="h-4 w-24" />
          </div>
          <div className="space-y-2">
            <Skeleton className="h-4 w-full" />
            <Skeleton className="h-4 w-3/4" />
            <Skeleton className="h-4 w-2/3" />
          </div>
        </Card>
      ))}
    </div>
  );
}

type StatusFilter = "all" | "pending" | "processing" | "completed";

export default function SettlementsPage() {
  const router = useRouter();
  const { user, loading: authLoading } = useAuth();
  const [statusFilter, setStatusFilter] = useState<StatusFilter>("all");

  // 정산 조회 (필터에 따라 status 전달)
  const queryStatus = statusFilter === "all" ? undefined : statusFilter;
  const { settlements, isLoading } = useSettlements(user?.id, queryStatus);

  // 비로그인 사용자 리다이렉트
  useEffect(() => {
    if (!authLoading && !user) {
      router.replace("/login");
    }
  }, [authLoading, user, router]);

  // 요약 통계 (전체 데이터 기준으로 계산)
  const summary = useMemo(() => {
    return {
      totalAmount: settlements.reduce((sum, s) => sum + s.amount, 0),
      totalFee: settlements.reduce((sum, s) => sum + s.fee, 0),
      totalNetAmount: settlements.reduce((sum, s) => sum + s.net_amount, 0),
      count: settlements.length,
    };
  }, [settlements]);

  // 로딩 상태
  if (authLoading || !user) {
    return (
      <div className="mx-auto max-w-3xl px-4 py-8">
        <div className="mb-6 flex items-center gap-3">
          <Skeleton className="h-9 w-9 rounded-lg" />
          <Skeleton className="h-7 w-24" />
        </div>
        <div className="space-y-4">
          <Skeleton className="h-24 w-full rounded-xl" />
          <Skeleton className="h-10 w-full rounded-lg" />
          <SettlementsSkeleton />
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
        <h1 className="text-xl font-bold">정산 내역</h1>
      </div>

      {/* 요약 카드 */}
      <Card className="mb-4 p-5">
        <div className="grid grid-cols-3 gap-4 text-center">
          <div>
            <div className="flex items-center justify-center gap-1.5 mb-1">
              <Wallet className="h-4 w-4 text-muted-foreground" />
              <span className="text-[11px] text-muted-foreground">총 판매</span>
            </div>
            <p className="text-[15px] font-bold">
              {formatPrice(summary.totalAmount)}
            </p>
          </div>
          <div>
            <div className="flex items-center justify-center gap-1.5 mb-1">
              <Receipt className="h-4 w-4 text-muted-foreground" />
              <span className="text-[11px] text-muted-foreground">총 수수료</span>
            </div>
            <p className="text-[15px] font-bold text-destructive">
              {formatPrice(summary.totalFee)}
            </p>
          </div>
          <div>
            <div className="flex items-center justify-center gap-1.5 mb-1">
              <TrendingUp className="h-4 w-4 text-muted-foreground" />
              <span className="text-[11px] text-muted-foreground">순 정산</span>
            </div>
            <p className="text-[15px] font-bold text-primary">
              {formatPrice(summary.totalNetAmount)}
            </p>
          </div>
        </div>
      </Card>

      {/* 상태 필터 탭 */}
      <Tabs
        value={statusFilter}
        onValueChange={(v) => setStatusFilter(v as StatusFilter)}
        className="mb-4"
      >
        <TabsList className="w-full grid grid-cols-4">
          <TabsTrigger value="all">전체</TabsTrigger>
          <TabsTrigger value="pending">대기중</TabsTrigger>
          <TabsTrigger value="processing">처리중</TabsTrigger>
          <TabsTrigger value="completed">완료</TabsTrigger>
        </TabsList>
      </Tabs>

      {/* 정산 목록 */}
      {isLoading ? (
        <SettlementsSkeleton />
      ) : settlements.length === 0 ? (
        <Card className="p-6">
          <div className="flex flex-col items-center gap-4 py-8">
            <Wallet className="h-12 w-12 text-muted-foreground" />
            <p className="text-muted-foreground text-[14px]">
              정산 내역이 없습니다
            </p>
          </div>
        </Card>
      ) : (
        <div className="space-y-3">
          {settlements.map((settlement) => (
            <SettlementCard key={settlement.id} settlement={settlement} />
          ))}
        </div>
      )}
    </div>
  );
}
