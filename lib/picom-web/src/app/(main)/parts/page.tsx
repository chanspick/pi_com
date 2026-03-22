import { Suspense } from "react";
import type { Metadata } from "next";
import { PartsContent } from "@/components/parts/parts-content";

export const metadata: Metadata = {
  title: "부품 시세 - PiCom",
  description: "중고 PC 부품 실시간 시세를 확인하세요. CPU, GPU, RAM, SSD 등 카테고리별 부품 정보와 가격 추이를 제공합니다.",
};

export default function PartsPage() {
  return (
    <div className="container mx-auto max-w-7xl px-4 py-8">
      <div className="mb-6">
        <h1 className="text-[24px] font-bold mb-1">부품 시세</h1>
        <p className="text-[14px] text-muted-foreground">
          카테고리별 중고 부품 시세를 확인하세요
        </p>
      </div>
      <Suspense fallback={null}>
        <PartsContent />
      </Suspense>
    </div>
  );
}
