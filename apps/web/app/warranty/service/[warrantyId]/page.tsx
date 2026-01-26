"use client";

import { use, useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { useRouter } from "next/navigation";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { ServiceRequestForm } from "@/components/warranty/ServiceRequestForm";
import { ServiceTimeline } from "@/components/warranty/ServiceTimeline";
import { getWarranty, getServiceHistory } from "@/lib/api/warranty";
import { formatDate, formatCurrency, getDaysRemaining } from "@/lib/utils";
import {
  ArrowLeft,
  Shield,
  Calendar,
  Package,
  AlertCircle,
  Loader2,
  CheckCircle,
  Clock,
} from "lucide-react";

interface PageProps {
  params: Promise<{ warrantyId: string }>;
}

export default function ServiceRequestPage({ params }: PageProps) {
  const { warrantyId } = use(params);
  const router = useRouter();
  const [showForm, setShowForm] = useState(false);

  const {
    data: warrantyData,
    isLoading: isLoadingWarranty,
    error: warrantyError,
  } = useQuery({
    queryKey: ["warranty", warrantyId],
    queryFn: () => getWarranty(warrantyId),
  });

  const {
    data: historyData,
    isLoading: isLoadingHistory,
    refetch: refetchHistory,
  } = useQuery({
    queryKey: ["serviceHistory", warrantyId],
    queryFn: () => getServiceHistory(warrantyId),
    enabled: !!warrantyData,
  });

  if (isLoadingWarranty) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[60vh]">
        <Loader2 className="h-8 w-8 animate-spin text-blue-600" />
        <p className="mt-4 text-gray-500">보증 정보를 불러오는 중...</p>
      </div>
    );
  }

  if (warrantyError || !warrantyData) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[60vh] px-4">
        <AlertCircle className="h-12 w-12 text-red-500" />
        <h1 className="mt-4 text-xl font-bold">보증 정보를 찾을 수 없습니다</h1>
        <p className="mt-2 text-gray-500 text-center">
          유효하지 않은 보증 ID이거나 보증 정보가 존재하지 않습니다.
        </p>
        <Button variant="outline" className="mt-4" onClick={() => router.back()}>
          돌아가기
        </Button>
      </div>
    );
  }

  const { warranty, transaction } = warrantyData;
  const daysRemaining = getDaysRemaining(warranty.endDate);
  const isExpired = daysRemaining <= 0;
  const isActive = warranty.status === "active";

  const handleServiceSuccess = (requestId: string) => {
    setShowForm(false);
    refetchHistory();
  };

  return (
    <div className="container mx-auto px-4 py-8 max-w-lg">
      {/* 헤더 */}
      <div className="flex items-center gap-3 mb-6">
        <Button variant="ghost" size="icon" onClick={() => router.back()}>
          <ArrowLeft className="h-5 w-5" />
        </Button>
        <h1 className="text-xl font-bold">AS 서비스</h1>
      </div>

      {/* 보증 정보 */}
      <Card className="mb-6">
        <CardHeader className="pb-3">
          <div className="flex items-center justify-between">
            <CardTitle className="flex items-center gap-2 text-lg">
              <Shield className="h-5 w-5 text-blue-600" />
              보증 정보
            </CardTitle>
            <span
              className={`text-sm font-medium px-2 py-1 rounded ${
                isActive
                  ? "bg-green-100 text-green-700"
                  : isExpired
                  ? "bg-red-100 text-red-700"
                  : "bg-yellow-100 text-yellow-700"
              }`}
            >
              {isActive ? "유효" : isExpired ? "만료" : warranty.status}
            </span>
          </div>
        </CardHeader>
        <CardContent className="space-y-4">
          {/* 부품 정보 */}
          {transaction && (
            <div className="flex items-start gap-3">
              <Package className="h-10 w-10 text-gray-500" />
              <div>
                <h3 className="font-medium">{transaction.modelName}</h3>
                <p className="text-sm text-gray-500">
                  {transaction.brand} / {transaction.partCategory}
                </p>
              </div>
            </div>
          )}

          {/* 보증 기간 */}
          <div className="pt-3 border-t space-y-2">
            <div className="flex items-center gap-2 text-sm">
              <Calendar className="h-4 w-4 text-gray-500" />
              <span>
                보증 기간: {formatDate(warranty.startDate)} ~{" "}
                {formatDate(warranty.endDate)}
              </span>
            </div>
            <div className="flex items-center gap-2 text-sm">
              <Clock className="h-4 w-4 text-gray-500" />
              <span
                className={
                  daysRemaining <= 30
                    ? "text-red-500 font-medium"
                    : ""
                }
              >
                남은 기간: {isExpired ? "만료됨" : `${daysRemaining}일`}
              </span>
            </div>
          </div>

          {/* 보증 상태 경고 */}
          {isExpired && (
            <div className="p-3 bg-red-50 rounded-lg flex items-center gap-2">
              <AlertCircle className="h-5 w-5 text-red-500" />
              <p className="text-sm text-red-500">
                보증 기간이 만료되어 AS 신청이 불가능합니다.
              </p>
            </div>
          )}

          {daysRemaining > 0 && daysRemaining <= 30 && (
            <div className="p-3 bg-yellow-50 rounded-lg flex items-center gap-2">
              <AlertCircle className="h-5 w-5 text-yellow-600" />
              <p className="text-sm text-yellow-700">
                보증 기간이 {daysRemaining}일 남았습니다.
              </p>
            </div>
          )}
        </CardContent>
      </Card>

      {/* AS 신청 폼 또는 버튼 */}
      {isActive && !showForm && (
        <Button className="w-full mb-6" size="lg" onClick={() => setShowForm(true)}>
          AS 신청하기
        </Button>
      )}

      {showForm && (
        <div className="mb-6">
          <ServiceRequestForm
            warrantyId={warrantyId}
            defaultCustomerName={warranty.customerName}
            defaultCustomerPhone={warranty.customerPhone}
            onSuccess={handleServiceSuccess}
          />
          <Button
            variant="outline"
            className="w-full mt-3"
            onClick={() => setShowForm(false)}
          >
            취소
          </Button>
        </div>
      )}

      {/* AS 이력 */}
      <div>
        <h2 className="font-semibold mb-4">AS 신청 내역</h2>
        {isLoadingHistory ? (
          <div className="flex items-center justify-center py-8">
            <Loader2 className="h-6 w-6 animate-spin text-gray-500" />
          </div>
        ) : (
          <ServiceTimeline requests={historyData?.requests || []} />
        )}
      </div>
    </div>
  );
}
