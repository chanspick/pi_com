import { Suspense } from "react";
import type { Metadata } from "next";
import { ListingFilters } from "@/components/listings/listing-filters";
import { ListingGrid } from "@/components/listings/listing-grid";

export const metadata: Metadata = {
  title: "매물 목록 - PiCom",
  description: "검증된 중고 PC 부품을 합리적인 가격에 만나보세요. CPU, GPU, RAM, SSD 등 다양한 부품을 거래할 수 있습니다.",
};

export default function ListingsPage() {
  return (
    <div className="container mx-auto max-w-7xl px-4 py-8">
      <div className="mb-6">
        <h1 className="text-[24px] font-bold mb-1">매물 목록</h1>
        <p className="text-[14px] text-muted-foreground">
          검증된 중고 PC 부품을 합리적인 가격에 거래하세요
        </p>
      </div>

      <Suspense fallback={null}>
        <ListingFilters />
      </Suspense>

      <div className="mt-6">
        <Suspense fallback={null}>
          <ListingGrid />
        </Suspense>
      </div>
    </div>
  );
}
