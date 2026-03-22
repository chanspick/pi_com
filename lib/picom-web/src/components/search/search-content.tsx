"use client";

import { useState, useEffect, useCallback } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import { Search, X, Clock, TrendingUp, PackageOpen, Loader2 } from "lucide-react";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { useSearch } from "@/hooks/use-search";
import { BasePartCard } from "@/components/parts/base-part-card";
import { ListingCard } from "@/components/listings/listing-card";

const RECENT_SEARCHES_KEY = "picom-recent-searches";
const MAX_RECENT = 8;

const popularCategories = [
  { value: "cpu", label: "CPU", icon: "⚙️" },
  { value: "gpu", label: "GPU", icon: "🎨" },
  { value: "ram", label: "RAM", icon: "💾" },
  { value: "ssd", label: "SSD", icon: "💿" },
  { value: "mainboard", label: "메인보드", icon: "🖥️" },
  { value: "power", label: "파워", icon: "⚡" },
  { value: "case", label: "케이스", icon: "📦" },
  { value: "cooler", label: "쿨러", icon: "❄️" },
];

function getRecentSearches(): string[] {
  if (typeof window === "undefined") return [];
  try {
    const stored = localStorage.getItem(RECENT_SEARCHES_KEY);
    return stored ? JSON.parse(stored) : [];
  } catch {
    return [];
  }
}

function saveRecentSearch(query: string) {
  const recent = getRecentSearches().filter((s) => s !== query);
  recent.unshift(query);
  localStorage.setItem(
    RECENT_SEARCHES_KEY,
    JSON.stringify(recent.slice(0, MAX_RECENT))
  );
}

function clearRecentSearches() {
  localStorage.removeItem(RECENT_SEARCHES_KEY);
}

export function SearchContent() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const initialQuery = searchParams.get("q") ?? "";

  const [inputValue, setInputValue] = useState(initialQuery);
  const [debouncedQuery, setDebouncedQuery] = useState(initialQuery);
  const [activeTab, setActiveTab] = useState<"parts" | "listings">("parts");
  const [recentSearches, setRecentSearches] = useState<string[]>([]);

  useEffect(() => {
    setRecentSearches(getRecentSearches());
  }, []);

  useEffect(() => {
    const timer = setTimeout(() => {
      setDebouncedQuery(inputValue.trim());
      if (inputValue.trim()) {
        const params = new URLSearchParams();
        params.set("q", inputValue.trim());
        router.replace("/search?" + params.toString(), { scroll: false });
      }
    }, 300);
    return () => clearTimeout(timer);
  }, [inputValue, router]);

  useEffect(() => {
    if (debouncedQuery.length >= 2) {
      saveRecentSearch(debouncedQuery);
      setRecentSearches(getRecentSearches());
    }
  }, [debouncedQuery]);

  const { data, isLoading, error } = useSearch(debouncedQuery);

  const handleCategoryClick = useCallback(
    (category: string) => {
      router.push("/parts?category=" + category);
    },
    [router]
  );

  const handleRecentClick = useCallback((query: string) => {
    setInputValue(query);
  }, []);

  const handleClearRecent = useCallback(() => {
    clearRecentSearches();
    setRecentSearches([]);
  }, []);

  const partsCount = data?.parts?.length ?? 0;
  const listingsCount = data?.listings?.length ?? 0;
  const hasQuery = debouncedQuery.length >= 2;

  return (
    <div className="space-y-6">
      {/* 검색 입력 */}
      <div className="relative">
        <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 h-5 w-5 text-muted-foreground" />
        <Input
          type="text"
          placeholder="부품명, 브랜드, 모델명으로 검색"
          value={inputValue}
          onChange={(e) => setInputValue(e.target.value)}
          className="pl-11 pr-10 h-12 text-[15px] rounded-xl border-[1.5px] focus-visible:ring-primary/20"
          autoFocus
        />
        {inputValue && (
          <button
            onClick={() => setInputValue("")}
            className="absolute right-3.5 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground"
          >
            <X className="h-4 w-4" />
          </button>
        )}
      </div>

      {!hasQuery ? (
        <div className="space-y-8">
          {/* 최근 검색 */}
          {recentSearches.length > 0 && (
            <section>
              <div className="flex items-center justify-between mb-3">
                <h3 className="text-[14px] font-semibold flex items-center gap-1.5">
                  <Clock className="h-4 w-4 text-muted-foreground" />
                  최근 검색
                </h3>
                <Button
                  variant="ghost"
                  size="sm"
                  onClick={handleClearRecent}
                  className="text-[12px] text-muted-foreground h-7"
                >
                  전체 삭제
                </Button>
              </div>
              <div className="flex flex-wrap gap-2">
                {recentSearches.map((term) => (
                  <Badge
                    key={term}
                    variant="secondary"
                    className="cursor-pointer hover:bg-primary/10 text-[13px] px-3 py-1 rounded-lg"
                    onClick={() => handleRecentClick(term)}
                  >
                    {term}
                  </Badge>
                ))}
              </div>
            </section>
          )}

          {/* 인기 카테고리 */}
          <section>
            <h3 className="text-[14px] font-semibold flex items-center gap-1.5 mb-3">
              <TrendingUp className="h-4 w-4 text-muted-foreground" />
              인기 카테고리
            </h3>
            <div className="grid grid-cols-4 sm:grid-cols-8 gap-3">
              {popularCategories.map((cat) => (
                <button
                  key={cat.value}
                  onClick={() => handleCategoryClick(cat.value)}
                  className="flex flex-col items-center gap-1.5 p-3 rounded-xl border bg-card hover:border-primary/30 hover:shadow-sm transition-all"
                >
                  <span className="text-2xl">{cat.icon}</span>
                  <span className="text-[12px] font-medium">{cat.label}</span>
                </button>
              ))}
            </div>
          </section>
        </div>
      ) : (
        <>
          {/* 탭 */}
          <div className="flex items-center gap-2 border-b">
            <button
              onClick={() => setActiveTab("parts")}
              className={
                "px-4 py-2.5 text-[14px] font-medium border-b-2 transition-colors " +
                (activeTab === "parts"
                  ? "border-primary text-primary"
                  : "border-transparent text-muted-foreground hover:text-foreground")
              }
            >
              부품 ({partsCount})
            </button>
            <button
              onClick={() => setActiveTab("listings")}
              className={
                "px-4 py-2.5 text-[14px] font-medium border-b-2 transition-colors " +
                (activeTab === "listings"
                  ? "border-primary text-primary"
                  : "border-transparent text-muted-foreground hover:text-foreground")
              }
            >
              매물 ({listingsCount})
            </button>
          </div>

          {/* 결과 */}
          {isLoading ? (
            <div className="flex items-center justify-center py-20">
              <Loader2 className="h-8 w-8 animate-spin text-primary" />
            </div>
          ) : error ? (
            <div className="text-center py-20 text-destructive">
              <p className="text-[14px]">검색 중 오류가 발생했습니다</p>
            </div>
          ) : activeTab === "parts" ? (
            partsCount > 0 ? (
              <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5 gap-4">
                {data!.parts.map((part) => (
                  <BasePartCard key={part.id} part={part} />
                ))}
              </div>
            ) : (
              <EmptyResult query={debouncedQuery} />
            )
          ) : listingsCount > 0 ? (
            <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 gap-4">
              {data!.listings.map((listing) => (
                <ListingCard key={listing.id} listing={listing} />
              ))}
            </div>
          ) : (
            <EmptyResult query={debouncedQuery} />
          )}
        </>
      )}
    </div>
  );
}

function EmptyResult({ query }: { query: string }) {
  return (
    <div className="flex flex-col items-center justify-center py-20 text-muted-foreground">
      <PackageOpen className="h-12 w-12 mb-3" />
      <p className="text-[14px] font-medium">
        {query} 검색 결과가 없습니다
      </p>
      <p className="text-[13px] mt-1">다른 키워드로 검색해 보세요</p>
    </div>
  );
}
