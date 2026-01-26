"use client";

import { use, useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { useRouter } from "next/navigation";
import { Button } from "@/components/ui/button";
import {
  PartInfoCard,
  InspectionInfo,
  TransactionInfo,
} from "@/components/warranty/PartInfoCard";
import { WarrantyPlanSelector } from "@/components/warranty/WarrantyPlanSelector";
import { getTransactionByQR } from "@/lib/api/warranty";
import { WarrantyPlan } from "@/types/warranty";
import { Shield, AlertCircle, Loader2, CheckCircle } from "lucide-react";

interface PageProps {
  params: Promise<{ qrCode: string }>;
}

export default function WarrantyLandingPage({ params }: PageProps) {
  const { qrCode } = use(params);
  const router = useRouter();
  const [selectedPlan, setSelectedPlan] = useState<WarrantyPlan>("1year");

  const {
    data: transaction,
    isLoading,
    error,
  } = useQuery({
    queryKey: ["transaction", qrCode],
    queryFn: () => getTransactionByQR(qrCode),
  });

  if (isLoading) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[60vh]">
        <Loader2 className="h-8 w-8 animate-spin text-blue-600" />
        <p className="mt-4 text-gray-500">거래 정보를 불러오는 중...</p>
      </div>
    );
  }

  if (error || !transaction) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[60vh] px-4">
        <AlertCircle className="h-12 w-12 text-red-500" />
        <h1 className="mt-4 text-xl font-bold">거래 정보를 찾을 수 없습니다</h1>
        <p className="mt-2 text-gray-500 text-center">
          유효하지 않은 QR 코드이거나 거래 정보가 존재하지 않습니다.
        </p>
      </div>
    );
  }

  // 이미 보증이 등록된 경우
  if (transaction.warrantyId) {
    return (
      <div className="container mx-auto px-4 py-8 max-w-lg">
        <div className="text-center mb-8">
          <CheckCircle className="h-16 w-16 text-green-500 mx-auto" />
          <h1 className="mt-4 text-2xl font-bold">AS 보증이 등록되어 있습니다</h1>
          <p className="mt-2 text-gray-500">
            이 제품은 이미 AS 보증 서비스에 가입되어 있습니다.
          </p>
        </div>

        <PartInfoCard transaction={transaction} />

        <div className="mt-6 space-y-3">
          <Button
            className="w-full"
            size="lg"
            onClick={() => router.push(`/warranty/service/${transaction.warrantyId}`)}
          >
            AS 신청하기
          </Button>
          <Button
            variant="outline"
            className="w-full"
            onClick={() => router.push(`/warranty/status/${transaction.warrantyId}`)}
          >
            보증 상태 확인
          </Button>
        </div>
      </div>
    );
  }

  const handlePurchase = () => {
    router.push(`/warranty/purchase/${qrCode}?plan=${selectedPlan}`);
  };

  return (
    <div className="container mx-auto px-4 py-8 max-w-lg">
      {/* 헤더 */}
      <div className="text-center mb-6">
        <Shield className="h-12 w-12 text-blue-600 mx-auto" />
        <h1 className="mt-2 text-2xl font-bold">부품 검증 완료</h1>
        <p className="mt-1 text-gray-500">
          PiComputer 인증 검증 부품입니다
        </p>
      </div>

      {/* 부품 정보 */}
      <div className="space-y-4">
        <PartInfoCard transaction={transaction} />
        <InspectionInfo transaction={transaction} />
        <TransactionInfo transaction={transaction} />
      </div>

      {/* 보증 선택 */}
      <div className="mt-6">
        <WarrantyPlanSelector
          salePrice={transaction.salePrice}
          selectedPlan={selectedPlan}
          onPlanChange={setSelectedPlan}
        />
      </div>

      {/* 가입 버튼 */}
      <div className="mt-6">
        <Button className="w-full" size="lg" onClick={handlePurchase}>
          AS 보증 가입하기
        </Button>
        <p className="mt-2 text-xs text-center text-gray-500">
          결제 완료 후 즉시 보증 서비스가 활성화됩니다
        </p>
      </div>
    </div>
  );
}
