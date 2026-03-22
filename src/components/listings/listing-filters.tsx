"use client";

import { useRouter, useSearchParams } from "next/navigation";
import { useCallback } from "react";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { X } from "lucide-react";

const categories = [
  { value: "all", label: "전체" },
  { value: "cpu", label: "CPU" },
  { value: "gpu", label: "GPU" },
  { value: "ram", label: "RAM" },
  { value: "ssd", label: "SSD" },
  { value: "mainboard", label: "메인보드" },
  { value: "power", label: "파워" },
  { value: "case", label: "케이스" },
  { value: "cooler", label: "쿨러" },
];

const sortOptions = [
  { value: "newest", label: "최신순" },
  { value: "price_asc", label: "낮은 가격순" },
  { value: "price_desc", label: "높은 가격순" },
  { value: "popular", label: "인기순" },
];

export function ListingFilters() {
  const router = useRouter();
  const searchParams = useSearchParams();

  const currentCategory = searchParams.get("category") ?? "all";
  const currentSort = searchParams.get("sort") ?? "newest";
  const currentMinPrice = searchParams.get("minPrice") ?? "";
  const currentMaxPrice = searchParams.get("maxPrice") ?? "";

  const updateParams = useCallback(
    (updates: Record<string, string | null>) => {
      const params = new URLSearchParams(searchParams.toString());
      Object.entries(updates).forEach(([key, value]) => {
        if (value === null || value === "" || value === "all") {
          params.delete(key);
        } else {
          params.set(key, value);
        }
      });
      const qs = params.toString();
      const url = qs ? "/listings?" + qs : "/listings";
      router.replace(url, { scroll: false });
    },
    [router, searchParams]
  );

  const hasFilters = currentCategory !== "all" || currentMinPrice || currentMaxPrice;

  return (
    <div className="space-y-4">
      <div className="flex flex-wrap items-center gap-3">
        <select
          value={currentCategory}
          onChange={(e) => updateParams({ category: e.target.value })}
          className="h-10 w-[140px] rounded-lg border-[1.5px] border-input bg-transparent px-3 text-[13px] font-medium text-foreground outline-none focus:border-primary/50 focus:ring-2 focus:ring-primary/20 transition-colors"
        >
          {categories.map((cat) => (
            <option key={cat.value} value={cat.value}>
              {cat.label}
            </option>
          ))}
        </select>

        <select
          value={currentSort}
          onChange={(e) => updateParams({ sort: e.target.value })}
          className="h-10 w-[140px] rounded-lg border-[1.5px] border-input bg-transparent px-3 text-[13px] font-medium text-foreground outline-none focus:border-primary/50 focus:ring-2 focus:ring-primary/20 transition-colors"
        >
          {sortOptions.map((opt) => (
            <option key={opt.value} value={opt.value}>
              {opt.label}
            </option>
          ))}
        </select>

        <div className="flex items-center gap-2">
          <Input
            type="number"
            placeholder="최소"
            value={currentMinPrice}
            onChange={(e) => updateParams({ minPrice: e.target.value })}
            className="w-[100px] h-10 rounded-lg border-[1.5px] text-[13px]"
          />
          <span className="text-muted-foreground text-sm">~</span>
          <Input
            type="number"
            placeholder="최대"
            value={currentMaxPrice}
            onChange={(e) => updateParams({ maxPrice: e.target.value })}
            className="w-[100px] h-10 rounded-lg border-[1.5px] text-[13px]"
          />
          <span className="text-[12px] text-muted-foreground">원</span>
        </div>

        {hasFilters && (
          <Button
            variant="ghost"
            size="sm"
            onClick={() =>
              updateParams({ category: null, minPrice: null, maxPrice: null })
            }
            className="text-[12px] text-muted-foreground gap-1"
          >
            <X className="h-3 w-3" />
            필터 초기화
          </Button>
        )}
      </div>
    </div>
  );
}
