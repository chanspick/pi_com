"use client";

import { useState } from "react";
import Link from "next/link";
import Image from "next/image";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import { Separator } from "@/components/ui/separator";
import { PriceHistoryChart } from "@/components/parts/price-history-chart";
import { usePriceHistory } from "@/hooks/use-price-history";
import { useListingsByBasePart } from "@/hooks/use-listings-by-part";
import { useCreatePriceAlert } from "@/hooks/use-price-alerts";
import { useAuth } from "@/hooks/use-auth";
import { formatPrice, formatRelativeTime, getCategoryLabel } from "@/lib/utils";
import {
  ArrowLeft,
  Bell,
  TrendingUp,
  TrendingDown,
  Minus,
  ImageIcon,
  Package,
  ArrowUpDown,
} from "lucide-react";
import type { BasePartRow, ListingWithBasePart } from "@/lib/supabase/queries";
const specLabels: Record<string, string> = {
  cores: "코어 수",
  threads: "스레드 수",
  base_clock: "기본 클럭",
  boost_clock: "부스트 클럭",
  tdp: "TDP",
  socket: "소켓",
  chipset: "칩셋",
  memory_type: "메모리 타입",
  memory_speed: "메모리 속도",
  capacity: "용량",
  speed: "속도",
  interface: "인터페이스",
  form_factor: "폼팩터",
  vram: "VRAM",
  wattage: "출력",
  efficiency: "효율 등급",
  fan_size: "팬 크기",
  type: "유형",
};

const sortOptions = [
  { value: "newest", label: "최신순" },
  { value: "price_asc", label: "낮은 가격순" },
  { value: "price_desc", label: "높은 가격순" },
];

interface PartDetailContentProps {
  part: BasePartRow;
}

export function PartDetailContent({ part }: PartDetailContentProps) {
  const [sort, setSort] = useState("newest");
  const { user } = useAuth();
  const { data: history, isLoading: historyLoading } = usePriceHistory(part.id, 90);
  const { data: listingsData, isLoading: listingsLoading } = useListingsByBasePart(part.id, sort);
  const createAlert = useCreatePriceAlert();
  const specs = part.specs as Record<string, string> | null;
  const listings = listingsData?.listings ?? [];

  // Price trend calculation
  let trend: "up" | "down" | "stable" = "stable";
  let trendPercent = 0;
  if (history && history.length >= 2) {
    const recent = history[history.length - 1].price;
    const weekAgo = history[Math.max(0, history.length - 8)]?.price ?? recent;
    if (weekAgo > 0) {
      trendPercent = Math.round(((recent - weekAgo) / weekAgo) * 100);
      trend = trendPercent > 0 ? "up" : trendPercent < 0 ? "down" : "stable";
    }
  }
  return (
    <div className="container mx-auto max-w-7xl px-4 py-6">
      {/* Breadcrumb */}
      <div className="mb-6">
        <Link
          href="/parts"
          className="inline-flex items-center gap-1 text-[13px] text-muted-foreground hover:text-foreground transition-colors"
        >
          <ArrowLeft className="h-3.5 w-3.5" />
          부품 시세로
        </Link>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
        {/* Left: Part info */}
        <div className="space-y-5">
          <div className="rounded-xl border bg-card p-5">
            {/* Image */}
            <div className="relative aspect-square bg-muted rounded-lg overflow-hidden mb-4">
              {part.image_url ? (
                <Image
                  src={part.image_url}
                  alt={part.name}
                  fill
                  className="object-contain p-6"
                  sizes="300px"
                  priority
                />
              ) : (
                <div className="absolute inset-0 flex items-center justify-center text-muted-foreground">
                  <ImageIcon className="h-12 w-12" />
                </div>
              )}
            </div>

            <Badge variant="secondary" className="text-[12px] font-semibold mb-2">
              {getCategoryLabel(part.category)}
            </Badge>
            {part.brand && (
              <p className="text-[13px] text-muted-foreground">{part.brand}</p>
            )}
            <h1 className="text-[20px] font-bold leading-tight mt-1">{part.name}</h1>

            <Separator className="my-4" />
            {/* Price info */}
            <div className="space-y-3">
              <div className="flex items-center justify-between">
                <span className="text-[13px] text-muted-foreground">최저가</span>
                <span className="text-[18px] font-bold text-primary">
                  {part.lowest_price > 0 ? formatPrice(part.lowest_price) : "-"}
                </span>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-[13px] text-muted-foreground">평균 시세</span>
                <span className="text-[15px] font-semibold">
                  {part.average_price > 0 ? formatPrice(part.average_price) : "-"}
                </span>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-[13px] text-muted-foreground">매물 수</span>
                <span className="text-[15px] font-semibold">{part.listing_count}개</span>
              </div>
              {trendPercent !== 0 && (
                <div className="flex items-center justify-between">
                  <span className="text-[13px] text-muted-foreground">주간 변동</span>
                  <div className="flex items-center gap-1">
                    {trend === "up" ? (
                      <TrendingUp className="h-3.5 w-3.5 text-[hsl(var(--destructive))]" />
                    ) : trend === "down" ? (
                      <TrendingDown className="h-3.5 w-3.5 text-[hsl(var(--success))]" />
                    ) : (
                      <Minus className="h-3.5 w-3.5 text-muted-foreground" />
                    )}
                    <span className={
                      trend === "up" ? "text-[14px] font-semibold text-[hsl(var(--destructive))]" :
                      trend === "down" ? "text-[14px] font-semibold text-[hsl(var(--success))]" :
                      "text-[14px] font-semibold text-muted-foreground"
                    }>
                      {trendPercent > 0 ? "+" : ""}{trendPercent}%
                    </span>
                  </div>
                </div>
              )}
            </div>

            <Separator className="my-4" />

            {/* 가격 알림 버튼 */}
            <Button
              variant="outline"
              className="w-full gap-2"
              onClick={() => {
                if (!user) {
                  alert("로그인이 필요합니다.");
                  return;
                }
                const input = prompt(
                  "알림 받을 목표 가격을 입력하세요 (원)",
                  part.lowest_price > 0 ? String(part.lowest_price) : ""
                );
                if (!input) return;
                const targetPrice = Number(input.replace(/[^0-9]/g, ""));
                if (!targetPrice || targetPrice <= 0) {
                  alert("올바른 가격을 입력해주세요.");
                  return;
                }
                createAlert.mutate(
                  {
                    user_id: user.id,
                    base_part_id: part.id,
                    target_price: targetPrice,
                    part_name: part.name,
                    price_at_creation: part.lowest_price > 0 ? part.lowest_price : undefined,
                  },
                  {
                    onSuccess: () => alert(`${formatPrice(targetPrice)} 이하일 때 알림을 받습니다.`),
                    onError: () => alert("알림 설정에 실패했습니다."),
                  }
                );
              }}
              disabled={createAlert.isPending}
            >
              <Bell className="h-4 w-4" />
              {createAlert.isPending ? "설정 중..." : "가격 알림 설정"}
            </Button>
          </div>
          {/* Specs table */}
          {specs && Object.keys(specs).length > 0 && (
            <div className="rounded-xl border bg-card overflow-hidden">
              <div className="px-4 py-3 border-b">
                <h2 className="text-[15px] font-bold">사양 정보</h2>
              </div>
              <table className="w-full text-[13px]">
                <tbody>
                  {Object.entries(specs).map(([key, val]) => (
                    <tr key={key} className="border-b last:border-0">
                      <td className="px-4 py-2.5 font-medium bg-muted/30 w-28">
                        {specLabels[key] ?? key}
                      </td>
                      <td className="px-4 py-2.5">{String(val)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>

        {/* Right: Chart + Listings */}
        <div className="md:col-span-2 space-y-5">
          {/* Price chart */}
          <div className="rounded-xl border bg-card p-5">
            <h2 className="text-[18px] font-bold mb-4">가격 추이</h2>
            {historyLoading ? (
              <Skeleton className="h-[280px] w-full rounded-lg" />
            ) : (
              <PriceHistoryChart
                history={history ?? []}
                currentPrice={part.lowest_price > 0 ? part.lowest_price : undefined}
              />
            )}
          </div>
          {/* Listings section */}
          <div className="rounded-xl border bg-card overflow-hidden">
            <div className="px-5 py-4 border-b flex items-center justify-between">
              <div className="flex items-center gap-2">
                <Package className="h-4 w-4 text-muted-foreground" />
                <h2 className="text-[16px] font-bold">
                  판매중인 매물 <span className="text-primary ml-1">{listingsData?.count ?? 0}</span>
                </h2>
              </div>
              <div className="flex items-center gap-1">
                <ArrowUpDown className="h-3.5 w-3.5 text-muted-foreground" />
                <select
                  value={sort}
                  onChange={(e) => setSort(e.target.value)}
                  className="text-[12px] bg-transparent border-none outline-none cursor-pointer text-muted-foreground hover:text-foreground"
                >
                  {sortOptions.map((o) => (
                    <option key={o.value} value={o.value}>{o.label}</option>
                  ))}
                </select>
              </div>
            </div>

            {listingsLoading ? (
              <div className="p-5 space-y-3">
                {[1, 2, 3].map((i) => (
                  <Skeleton key={i} className="h-20 w-full rounded-lg" />
                ))}
              </div>
            ) : listings.length === 0 ? (
              <div className="flex flex-col items-center justify-center py-12 text-muted-foreground">
                <Package className="h-8 w-8 mb-2 opacity-40" />
                <p className="text-[13px]">현재 판매중인 매물이 없습니다</p>
              </div>
            ) : (
              <div className="divide-y">
                {listings.map((listing: ListingWithBasePart) => (
                  <Link
                    key={listing.id}
                    href={"/listings/" + listing.id}
                    className="flex items-center gap-4 px-5 py-3.5 hover:bg-muted/50 transition-colors"
                  >                    <div className="relative w-16 h-16 rounded-lg bg-muted overflow-hidden shrink-0">
                      {listing.images?.[0] ? (
                        <Image
                          src={listing.images[0]}
                          alt={listing.title}
                          fill
                          className="object-cover"
                          sizes="64px"
                        />
                      ) : (
                        <div className="flex items-center justify-center h-full">
                          <ImageIcon className="h-5 w-5 text-muted-foreground/50" />
                        </div>
                      )}
                    </div>
                    <div className="flex-1 min-w-0">
                      <p className="text-[14px] font-medium truncate">{listing.title}</p>
                      <div className="flex items-center gap-2 mt-0.5">
                        {listing.condition_score != null && (
                          <Badge variant="outline" className="text-[11px] px-1.5 py-0">
                            상태 {listing.condition_score}/10
                          </Badge>
                        )}
                        <span className="text-[11px] text-muted-foreground">
                          {formatRelativeTime(listing.created_at)}
                        </span>
                      </div>
                    </div>
                    <div className="text-right shrink-0">
                      <p className="text-[15px] font-bold">{formatPrice(listing.price)}</p>
                    </div>
                  </Link>
                ))}
              </div>
            )}
          </div>

          {/* Description */}
          {part.description && (
            <div className="rounded-xl border bg-card p-5">
              <h2 className="text-[15px] font-bold mb-2">설명</h2>
              <p className="text-[14px] text-muted-foreground leading-relaxed whitespace-pre-wrap">
                {part.description}
              </p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
