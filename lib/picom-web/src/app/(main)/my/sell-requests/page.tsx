"use client";

import { useState, useEffect } from "react";
import Link from "next/link";
import Image from "next/image";
import { useSearchParams } from "next/navigation";
import {
  ArrowLeft,
  Plus,
  ImageIcon,
  FileText,
  Loader2,
  MessageSquare,
} from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import { Tabs, TabsList, TabsTrigger, TabsContent } from "@/components/ui/tabs";
import { useAuth } from "@/hooks/use-auth";
import { useSellRequests, useCancelSellRequest } from "@/hooks/use-sell-requests";
import {
  getCategoryLabel,
  formatDate,
  formatPrice,
} from "@/lib/utils";

// 상태별 Badge variant와 라벨
type BadgeVariant = "default" | "secondary" | "destructive" | "outline" | "ghost" | "link";

interface StatusConfig {
  label: string;
  variant: BadgeVariant;
  className?: string;
}

const statusConfigMap: Record<string, StatusConfig> = {
  pending: {
    label: "대기중",
    variant: "secondary",
    className: "bg-orange-100 text-orange-700 dark:bg-orange-900/30 dark:text-orange-400",
  },
  reviewing: {
    label: "테스트중",
    variant: "secondary",
    className: "bg-orange-100 text-orange-700 dark:bg-orange-900/30 dark:text-orange-400",
  },
  testing: {
    label: "테스트중",
    variant: "secondary",
    className: "bg-orange-100 text-orange-700 dark:bg-orange-900/30 dark:text-orange-400",
  },
  approved: {
    label: "승인",
    variant: "secondary",
    className: "bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400",
  },
  rejected: {
    label: "반려",
    variant: "destructive",
  },
  completed: {
    label: "판매완료",
    variant: "secondary",
    className: "bg-muted text-muted-foreground",
  },
  sold: {
    label: "판매완료",
    variant: "secondary",
    className: "bg-muted text-muted-foreground",
  },
  cancelled: {
    label: "취소",
    variant: "secondary",
    className: "bg-muted text-muted-foreground",
  },
};

function getStatusConfig(status: string): StatusConfig {
  return (
    statusConfigMap[status] ?? {
      label: status,
      variant: "secondary" as BadgeVariant,
    }
  );
}

// 탭 필터 목록
const filterTabs = [
  { value: "all", label: "전체" },
  { value: "pending", label: "대기중" },
  { value: "reviewing", label: "테스트중" },
  { value: "approved", label: "승인" },
  { value: "rejected", label: "반려" },
];

export default function SellRequestsPage() {
  const { user, loading: authLoading } = useAuth();
  const searchParams = useSearchParams();
  const [statusFilter, setStatusFilter] = useState("all");
  const [showSuccessMessage, setShowSuccessMessage] = useState(false);

  const { sellRequests, isLoading } = useSellRequests(
    user?.id,
    statusFilter === "all" ? undefined : statusFilter
  );
  const cancelMutation = useCancelSellRequest();

  // 성공 메시지 표시
  useEffect(() => {
    if (searchParams.get("success") === "true") {
      setShowSuccessMessage(true);
      const timer = setTimeout(() => setShowSuccessMessage(false), 3000);
      return () => clearTimeout(timer);
    }
  }, [searchParams]);

  const handleCancel = (requestId: string) => {
    if (!user?.id) return;
    if (!confirm("판매 신청을 취소하시겠습니까?")) return;
    cancelMutation.mutate({ requestId, userId: user.id });
  };

  // 로딩 상태
  if (authLoading || isLoading) {
    return (
      <div className="mx-auto max-w-5xl px-4 py-8">
        <div className="mb-6 flex items-center gap-3">
          <Skeleton className="h-9 w-9 rounded-lg" />
          <Skeleton className="h-7 w-32" />
        </div>
        <Skeleton className="h-10 w-full mb-6" />
        <div className="space-y-4">
          {Array.from({ length: 3 }).map((_, i) => (
            <div
              key={i}
              className="flex gap-4 rounded-xl border bg-card p-4"
            >
              <Skeleton className="h-20 w-20 rounded-lg shrink-0" />
              <div className="flex-1 space-y-2">
                <Skeleton className="h-3 w-16" />
                <Skeleton className="h-4 w-full" />
                <Skeleton className="h-3 w-24" />
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
      <div className="mx-auto max-w-5xl px-4 py-8">
        <div className="flex flex-col items-center justify-center gap-4 py-20">
          <FileText className="h-12 w-12 text-muted-foreground" />
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
    <div className="mx-auto max-w-5xl px-4 py-8">
      {/* 성공 메시지 */}
      {showSuccessMessage && (
        <div className="mb-4 rounded-[10px] border border-green-200 bg-green-50 px-4 py-3 text-sm text-green-700 dark:border-green-800 dark:bg-green-900/20 dark:text-green-400">
          판매 신청이 완료되었습니다. 검수 후 결과를 알려드리겠습니다.
        </div>
      )}

      {/* 헤더 */}
      <div className="mb-6 flex items-center justify-between">
        <div className="flex items-center gap-3">
          <Link href="/my">
            <Button variant="ghost" size="icon">
              <ArrowLeft className="h-5 w-5" />
            </Button>
          </Link>
          <h1 className="text-xl font-bold">판매 신청 내역</h1>
          {sellRequests.length > 0 && (
            <span className="text-sm text-muted-foreground">
              {sellRequests.length}건
            </span>
          )}
        </div>
        <Link href="/sell/new">
          <Button size="sm">
            <Plus className="h-4 w-4" />
            새 신청
          </Button>
        </Link>
      </div>

      {/* 상태 필터 탭 */}
      <Tabs
        value={statusFilter}
        onValueChange={(value) => setStatusFilter(value as string)}
        className="mb-6"
      >
        <TabsList className="w-full">
          {filterTabs.map((tab) => (
            <TabsTrigger key={tab.value} value={tab.value}>
              {tab.label}
            </TabsTrigger>
          ))}
        </TabsList>

        {/* 탭 컨텐츠 (모든 탭에 같은 리스트 표시) */}
        {filterTabs.map((tab) => (
          <TabsContent key={tab.value} value={tab.value}>
            {/* 빈 상태 */}
            {sellRequests.length === 0 ? (
              <div className="flex flex-col items-center justify-center gap-4 py-20">
                <FileText className="h-12 w-12 text-muted-foreground" />
                <p className="text-muted-foreground">
                  {statusFilter === "all"
                    ? "판매 신청 내역이 없습니다"
                    : `${filterTabs.find((t) => t.value === statusFilter)?.label ?? ""} 상태의 신청이 없습니다`}
                </p>
                <Link href="/sell/new">
                  <Button>판매 신청하기</Button>
                </Link>
              </div>
            ) : (
              /* 신청 목록 */
              <div className="space-y-3">
                {sellRequests.map((request) => {
                  const statusConfig = getStatusConfig(request.status);
                  const thumbnailUrl = request.images?.[0];

                  return (
                    <div
                      key={request.id}
                      className="flex gap-4 rounded-[10px] border bg-card p-4 hover:border-primary/30 hover:shadow-sm transition-all"
                    >
                      {/* 썸네일 */}
                      <div className="relative h-20 w-20 shrink-0 rounded-lg overflow-hidden bg-muted">
                        {thumbnailUrl ? (
                          <Image
                            src={thumbnailUrl}
                            alt={request.title}
                            fill
                            className="object-cover"
                            sizes="80px"
                          />
                        ) : (
                          <div className="absolute inset-0 flex items-center justify-center text-muted-foreground">
                            <ImageIcon className="h-6 w-6" />
                          </div>
                        )}
                      </div>

                      {/* 정보 */}
                      <div className="flex-1 min-w-0">
                        <div className="flex items-center gap-2 mb-1">
                          <Badge variant="secondary" className="text-[11px]">
                            {getCategoryLabel(request.category)}
                          </Badge>
                          <Badge
                            variant={statusConfig.variant}
                            className={statusConfig.className ?? ""}
                          >
                            {statusConfig.label}
                          </Badge>
                        </div>

                        <h3 className="text-sm font-semibold truncate mb-1">
                          {request.title}
                        </h3>

                        <div className="flex items-center gap-3 text-[12px] text-muted-foreground">
                          {request.desired_price != null && (
                            <span>
                              희망가: {formatPrice(request.desired_price)}
                            </span>
                          )}
                          <span>{formatDate(request.created_at)}</span>
                        </div>

                        {/* 관리자 메모 */}
                        {request.admin_note && (
                          <div className="mt-2 flex items-start gap-1.5 rounded-lg bg-muted/50 px-3 py-2">
                            <MessageSquare className="h-3.5 w-3.5 mt-0.5 shrink-0 text-muted-foreground" />
                            <p className="text-[12px] text-muted-foreground line-clamp-2">
                              {request.admin_note}
                            </p>
                          </div>
                        )}

                        {/* 액션 버튼 */}
                        <div className="mt-2 flex items-center gap-2">
                          {request.listing_id && (
                            <Link href={`/listings/${request.listing_id}`}>
                              <Button variant="outline" size="xs">
                                매물 보기
                              </Button>
                            </Link>
                          )}
                          {request.status === "pending" && (
                            <Button
                              variant="ghost"
                              size="xs"
                              onClick={() => handleCancel(request.id)}
                              disabled={cancelMutation.isPending}
                            >
                              {cancelMutation.isPending ? (
                                <Loader2 className="h-3 w-3 animate-spin" />
                              ) : (
                                "취소"
                              )}
                            </Button>
                          )}
                        </div>
                      </div>
                    </div>
                  );
                })}
              </div>
            )}
          </TabsContent>
        ))}
      </Tabs>
    </div>
  );
}
