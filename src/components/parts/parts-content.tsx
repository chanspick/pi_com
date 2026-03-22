"use client";

import { useState } from "react";
import { useSearchParams, useRouter } from "next/navigation";
import { Input } from "@/components/ui/input";
import { Skeleton } from "@/components/ui/skeleton";
import { Search, PackageOpen, Cpu, Monitor, MemoryStick, HardDrive, CircuitBoard, Plug, Box, Fan } from "lucide-react";
import { useBaseParts } from "@/hooks/use-base-parts";
import { BasePartCard } from "@/components/parts/base-part-card";
import { cn } from "@/lib/utils";

const categories = [
  { value: "cpu", label: "CPU", icon: Cpu },
  { value: "gpu", label: "GPU", icon: Monitor },
  { value: "ram", label: "RAM", icon: MemoryStick },
  { value: "ssd", label: "SSD", icon: HardDrive },
  { value: "mainboard", label: "메인보드", icon: CircuitBoard },
  { value: "power", label: "파워", icon: Plug },
  { value: "case", label: "케이스", icon: Box },
  { value: "cooler", label: "쿨러", icon: Fan },
];

function CardSkeleton() {
  return (
    <div className="rounded-xl border bg-card overflow-hidden">
      <Skeleton className="aspect-[4/3] w-full" />
      <div className="p-3.5 space-y-2">
        <Skeleton className="h-3 w-16" />
        <Skeleton className="h-4 w-full" />
        <div className="flex justify-between">
          <Skeleton className="h-4 w-20" />
          <Skeleton className="h-3 w-12" />
        </div>
      </div>
    </div>
  );
}

export function PartsContent() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const activeCategory = searchParams.get("category") ?? "cpu";
  const [search, setSearch] = useState("");

  const { data, isLoading } = useBaseParts(activeCategory, search || undefined);
  const parts = data?.parts ?? [];
  const totalCount = data?.count ?? 0;

  function handleCategoryChange(cat: string) {
    const params = new URLSearchParams();
    params.set("category", cat);
    router.push("/parts?" + params.toString());
    setSearch("");
  }

  return (
    <div>
      {/* Category tabs */}
      <div className="flex gap-1.5 overflow-x-auto pb-3 mb-5 -mx-1 px-1">
        {categories.map((cat) => {
          const Icon = cat.icon;
          const isActive = activeCategory === cat.value;
          return (
            <button
              key={cat.value}
              onClick={() => handleCategoryChange(cat.value)}
              className={cn(
                "flex items-center gap-1.5 px-4 py-2 rounded-lg text-[13px] font-medium whitespace-nowrap transition-all border",
                isActive
                  ? "bg-primary text-primary-foreground border-primary shadow-[0_1px_3px_rgba(37,99,235,0.3)]"
                  : "bg-card text-muted-foreground border-border hover:border-primary/30 hover:text-foreground"
              )}
            >
              <Icon className="h-3.5 w-3.5" />
              {cat.label}
            </button>
          );
        })}
      </div>

      {/* Search */}
      <div className="relative mb-5 max-w-sm">
        <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
        <Input
          placeholder="모델명, 브랜드로 검색"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          className="pl-9 h-10 rounded-lg border-[1.5px]"
        />
      </div>

      {/* Count */}
      {!isLoading && (
        <div className="flex items-center gap-2 mb-4">
          <span className="text-[14px] text-muted-foreground">
            총 <span className="font-semibold text-foreground">{totalCount}</span>개
          </span>
        </div>
      )}

      {/* Grid */}
      {isLoading ? (
        <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 gap-4">
          {Array.from({ length: 8 }).map((_, i) => (
            <CardSkeleton key={i} />
          ))}
        </div>
      ) : parts.length === 0 ? (
        <div className="flex flex-col items-center justify-center py-20 text-center">
          <div className="w-16 h-16 rounded-2xl bg-muted flex items-center justify-center mb-4">
            <PackageOpen className="h-8 w-8 text-muted-foreground" />
          </div>
          <h3 className="text-[16px] font-semibold mb-1">부품이 없습니다</h3>
          <p className="text-[13px] text-muted-foreground">
            다른 카테고리를 확인해보세요
          </p>
        </div>
      ) : (
        <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 gap-4">
          {parts.map((part) => (
            <BasePartCard key={part.id} part={part} />
          ))}
        </div>
      )}
    </div>
  );
}
