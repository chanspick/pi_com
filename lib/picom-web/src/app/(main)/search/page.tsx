import { Suspense } from "react";
import type { Metadata } from "next";
import { SearchContent } from "@/components/search/search-content";

export const metadata: Metadata = {
  title: "검색 - PiCom",
  description: "중고 PC 부품을 검색하세요. CPU, GPU, RAM, SSD 등 다양한 부품을 찾을 수 있습니다.",
};

export default function SearchPage() {
  return (
    <div className="container mx-auto max-w-7xl px-4 py-8">
      <Suspense fallback={null}>
        <SearchContent />
      </Suspense>
    </div>
  );
}
