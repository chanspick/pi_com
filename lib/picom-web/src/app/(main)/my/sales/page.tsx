"use client";

import Link from "next/link";
import Image from "next/image";
import {
  ArrowLeft,
  Store,
  ImageIcon,
  Eye,
  Heart,
  Trash2,
  Pencil,
} from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import { Tabs, TabsList, TabsTrigger, TabsContent } from "@/components/ui/tabs";
import { Card } from "@/components/ui/card";
import { useAuth } from "@/hooks/use-auth";
import { useMyListings, useDeleteListing } from "@/hooks/use-my-listings";
import {
  formatPrice,
  formatDate,
  getCategoryLabel,
  getStatusLabel,
} from "@/lib/utils";
import { useState } from "react";
import type { ListingRow } from "@/lib/supabase/queries";

// 매물 상태별 배지 색상
function getListingStatusVariant(
  status: string
): "default" | "secondary" | "destructive" | "outline" {
  switch (status) {
    case "active":
      return "default";
    case "reserved":
      return "outline";
    case "sold":
      return "secondary";
    default:
      return "secondary";
  }
}

// 탭별 필터
function filterListingsByTab(
  listings: ListingRow[],
  tab: string
): ListingRow[] {
  switch (tab) {
    case "active":
      return listings.filter((l) => l.status === "active");
    case "reserved":
      return listings.filter((l) => l.status === "reserved");
    case "sold":
      return listings.filter((l) => l.status === "sold");
    default:
      // 전체: 삭제된 매물은 제외
      return listings.filter((l) => l.status !== "deleted");
  }
}

export default function SalesPage() {
  const { user, loading: authLoading } = useAuth();
  const { listings, isLoading } = useMyListings(user?.id);
  const deleteListingMutation = useDeleteListing();
  const [activeTab, setActiveTab] = useState("all");
  const [deletingId, setDeletingId] = useState<string | null>(null);

  // 삭제된 매물 제외한 목록 (통계용)
  const visibleListings = listings.filter((l) => l.status !== "deleted");
  const filteredListings = filterListingsByTab(listings, activeTab);

  // 통계 계산
  const activeCount = visibleListings.filter(
    (l) => l.status === "active"
  ).length;
  const soldCount = visibleListings.filter(
    (l) => l.status === "sold"
  ).length;
  const totalSalesAmount = visibleListings
    .filter((l) => l.status === "sold")
    .reduce((sum, l) => sum + l.price, 0);

  const handleDelete = (listingId: string) => {
    if (!user?.id) return;
    deleteListingMutation.mutate(
      { listingId, userId: user.id },
      {
        onSuccess: () => setDeletingId(null),
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
        {/* 통계 스켈레톤 */}
        <div className="mb-6 grid grid-cols-3 gap-3">
          {Array.from({ length: 3 }).map((_, i) => (
            <Skeleton key={i} className="h-20 rounded-xl" />
          ))}
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
          <Store className="h-12 w-12 text-muted-foreground" />
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
        <h1 className="text-xl font-bold">판매내역</h1>
      </div>

      {/* 판매 통계 */}
      <div className="mb-6 grid grid-cols-3 gap-3">
        <Card className="p-4 text-center">
          <p className="text-[11px] text-muted-foreground mb-1">판매중</p>
          <p className="text-lg font-bold text-primary">{activeCount}건</p>
        </Card>
        <Card className="p-4 text-center">
          <p className="text-[11px] text-muted-foreground mb-1">판매완료</p>
          <p className="text-lg font-bold text-green-600">{soldCount}건</p>
        </Card>
        <Card className="p-4 text-center">
          <p className="text-[11px] text-muted-foreground mb-1">총 판매액</p>
          <p className="text-lg font-bold">{formatPrice(totalSalesAmount)}</p>
        </Card>
      </div>

      {/* 상태 필터 탭 */}
      <Tabs
        defaultValue="all"
        onValueChange={(val) => setActiveTab(val as string)}
      >
        <TabsList className="mb-6 w-full">
          <TabsTrigger value="all">전체</TabsTrigger>
          <TabsTrigger value="active">판매중</TabsTrigger>
          <TabsTrigger value="reserved">예약중</TabsTrigger>
          <TabsTrigger value="sold">판매완료</TabsTrigger>
        </TabsList>

        {["all", "active", "reserved", "sold"].map((tab) => (
          <TabsContent key={tab} value={tab}>
            {activeTab === tab && (
              <ListingList
                listings={filteredListings}
                deletingId={deletingId}
                onDeleteClick={(id) => setDeletingId(id)}
                onDeleteConfirm={handleDelete}
                onDeleteCancel={() => setDeletingId(null)}
                isDeleting={deleteListingMutation.isPending}
              />
            )}
          </TabsContent>
        ))}
      </Tabs>
    </div>
  );
}

function ListingList({
  listings,
  deletingId,
  onDeleteClick,
  onDeleteConfirm,
  onDeleteCancel,
  isDeleting,
}: {
  listings: ListingRow[];
  deletingId: string | null;
  onDeleteClick: (id: string) => void;
  onDeleteConfirm: (id: string) => void;
  onDeleteCancel: () => void;
  isDeleting: boolean;
}) {
  if (listings.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center gap-4 py-20">
        <Store className="h-12 w-12 text-muted-foreground" />
        <p className="text-muted-foreground">등록된 매물이 없습니다</p>
        <Link href="/sell">
          <Button>매물 등록하기</Button>
        </Link>
      </div>
    );
  }

  return (
    <div className="space-y-3">
      {listings.map((listing) => {
        const imageUrl = listing.images?.[0];
        const statusLabel = getStatusLabel(listing.status);
        const statusVariant = getListingStatusVariant(listing.status);
        const isDeleteTarget = deletingId === listing.id;

        return (
          <div
            key={listing.id}
            className="rounded-xl border bg-card overflow-hidden transition-all hover:border-primary/30"
          >
            <div className="flex gap-4 p-4">
              {/* 이미지 */}
              <Link
                href={`/listings/${listing.id}`}
                className="relative h-20 w-20 shrink-0 overflow-hidden rounded-lg bg-muted"
              >
                {imageUrl ? (
                  <Image
                    src={imageUrl}
                    alt={listing.title}
                    fill
                    className="object-cover"
                    sizes="80px"
                  />
                ) : (
                  <div className="flex h-full w-full items-center justify-center text-muted-foreground">
                    <ImageIcon className="h-5 w-5" />
                  </div>
                )}
              </Link>

              {/* 정보 */}
              <div className="flex flex-1 flex-col justify-center gap-1.5 min-w-0">
                <div className="flex items-center gap-2">
                  <Badge
                    variant={statusVariant}
                    className="text-[10px]"
                  >
                    {statusLabel}
                  </Badge>
                  {listing.category && (
                    <Badge
                      variant="secondary"
                      className="text-[10px]"
                    >
                      {getCategoryLabel(listing.category)}
                    </Badge>
                  )}
                </div>
                <Link
                  href={`/listings/${listing.id}`}
                  className="text-[14px] font-semibold leading-snug truncate hover:text-primary transition-colors"
                >
                  {listing.title}
                </Link>
                <span className="text-[16px] font-bold text-foreground">
                  {formatPrice(listing.price)}
                </span>
                {/* 메타 정보 */}
                <div className="flex items-center gap-3 text-[11px] text-muted-foreground">
                  <span className="flex items-center gap-0.5">
                    <Eye className="h-3 w-3" />
                    {listing.view_count}
                  </span>
                  <span className="flex items-center gap-0.5">
                    <Heart className="h-3 w-3" />
                    {listing.favorite_count}
                  </span>
                  <span>{formatDate(listing.created_at)}</span>
                </div>
              </div>

              {/* 액션 버튼 */}
              <div className="flex flex-col items-center justify-center gap-1">
                <Link href={`/sell/edit/${listing.id}`}>
                  <Button
                    variant="ghost"
                    size="icon-sm"
                    aria-label="수정"
                  >
                    <Pencil className="h-4 w-4 text-muted-foreground" />
                  </Button>
                </Link>
                <Button
                  variant="ghost"
                  size="icon-sm"
                  onClick={() => onDeleteClick(listing.id)}
                  aria-label="삭제"
                >
                  <Trash2 className="h-4 w-4 text-muted-foreground" />
                </Button>
              </div>
            </div>

            {/* 삭제 확인 UI */}
            {isDeleteTarget && (
              <div className="border-t bg-muted/50 px-4 py-3">
                <p className="text-[12px] text-center mb-2 text-muted-foreground">
                  이 매물을 삭제하시겠습니까?
                </p>
                <div className="flex gap-2 justify-center">
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={onDeleteCancel}
                  >
                    취소
                  </Button>
                  <Button
                    variant="destructive"
                    size="sm"
                    onClick={() => onDeleteConfirm(listing.id)}
                    disabled={isDeleting}
                  >
                    {isDeleting ? "삭제 중..." : "삭제"}
                  </Button>
                </div>
              </div>
            )}
          </div>
        );
      })}
    </div>
  );
}
