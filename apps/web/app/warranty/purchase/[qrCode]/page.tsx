"use client";

import { use, useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { useRouter, useSearchParams } from "next/navigation";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import * as z from "zod";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import {
  getTransactionByQR,
  prepareWarrantyPayment,
  prepareAdditionalWarrantyPayment,
  getWarranty,
} from "@/lib/api/warranty";
import {
  WarrantyPlan,
  WARRANTY_RATES,
  ADDITIONAL_WARRANTY_RATES,
  isBundle,
  getDisplayName,
  getGradeConfig,
} from "@/types/warranty";
import { formatCurrency } from "@/lib/utils";
import { GradeBadge } from "@/components/warranty/GradeBadge";
import { ArrowLeft, Package, Shield, AlertCircle, Loader2, Plus } from "lucide-react";

interface PageProps {
  params: Promise<{ qrCode: string }>;
}

const purchaseSchema = z.object({
  customerName: z.string().min(2, "이름을 입력해주세요"),
  customerPhone: z
    .string()
    .regex(/^01[0-9]-?[0-9]{3,4}-?[0-9]{4}$/, "올바른 연락처를 입력해주세요"),
  customerEmail: z.string().email("올바른 이메일을 입력해주세요").optional().or(z.literal("")),
});

type PurchaseFormData = z.infer<typeof purchaseSchema>;

export default function WarrantyPurchasePage({ params }: PageProps) {
  const { qrCode } = use(params);
  const router = useRouter();
  const searchParams = useSearchParams();

  // 모드: "additional" = 추가 보증 구매, null = 기존 보증 구매 (레거시)
  const mode = searchParams.get("mode");
  const isAdditionalMode = mode === "additional";

  const planParam = searchParams.get("plan") as WarrantyPlan | null;
  const selectedPlan = planParam || "1year";

  const [selectedAdditionalMonths, setSelectedAdditionalMonths] = useState<12 | 24>(12);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [paymentError, setPaymentError] = useState<string | null>(null);

  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<PurchaseFormData>({
    resolver: zodResolver(purchaseSchema),
  });

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
        <Button
          variant="outline"
          className="mt-4"
          onClick={() => router.back()}
        >
          돌아가기
        </Button>
      </div>
    );
  }

  const isBundleType = isBundle(transaction);
  const displayName = getDisplayName(transaction);
  const gradeConfig = getGradeConfig(transaction.conditionGrade);
  const baseWarrantyMonths = transaction.baseWarrantyMonths || gradeConfig.baseWarrantyMonths;

  // 가격 계산
  const rate = WARRANTY_RATES[selectedPlan];
  const warrantyPrice = Math.round(transaction.salePrice * rate.rate);

  // 추가 보증 가격 계산
  const additionalRate = ADDITIONAL_WARRANTY_RATES[selectedAdditionalMonths];
  const additionalPrice = Math.round(transaction.salePrice * additionalRate.rate);

  const handlePayment = async (
    data: PurchaseFormData,
    method: "kakaopay" | "tosspay"
  ) => {
    setIsSubmitting(true);
    setPaymentError(null);

    try {
      if (isAdditionalMode) {
        // 추가 보증 결제
        const result = await prepareAdditionalWarrantyPayment({
          qrCode,
          additionalMonths: selectedAdditionalMonths,
          customerName: data.customerName,
          customerPhone: data.customerPhone,
          customerEmail: data.customerEmail || undefined,
          paymentMethod: method,
        });

        if (result.redirectUrl) {
          window.location.href = result.redirectUrl;
        } else {
          router.push(
            `/warranty/payment/callback?warrantyId=${result.warrantyId}&type=additional&method=${method}`
          );
        }
      } else {
        // 기존 보증 결제 (레거시)
        const result = await prepareWarrantyPayment({
          qrCode,
          warrantyPlan: selectedPlan,
          customerName: data.customerName,
          customerPhone: data.customerPhone,
          customerEmail: data.customerEmail || undefined,
          paymentMethod: method,
        });

        if (result.redirectUrl) {
          window.location.href = result.redirectUrl;
        } else {
          router.push(
            `/warranty/payment/callback?warrantyId=${result.warrantyId}&method=${method}`
          );
        }
      }
    } catch (err: any) {
      setPaymentError(err.message || "결제 준비 중 오류가 발생했습니다");
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="container mx-auto px-4 py-8 max-w-lg">
      {/* 헤더 */}
      <div className="flex items-center gap-3 mb-6">
        <Button
          variant="ghost"
          size="icon"
          onClick={() => router.back()}
        >
          <ArrowLeft className="h-5 w-5" />
        </Button>
        <h1 className="text-xl font-bold">
          {isAdditionalMode ? "추가 보증 구매" : "AS 보증 결제"}
        </h1>
      </div>

      {/* 주문 요약 */}
      <Card className="mb-6">
        <CardContent className="p-4">
          <div className="flex items-start gap-3">
            <Package className="h-10 w-10 text-gray-500" />
            <div className="flex-1">
              <h3 className="font-medium">{displayName}</h3>
              <p className="text-sm text-gray-500">
                {isBundleType
                  ? `${transaction.items?.length || 0}개 부품 구성`
                  : `${transaction.brand} / ${transaction.partCategory}`}
              </p>
            </div>
            {transaction.conditionGrade && (
              <GradeBadge grade={transaction.conditionGrade} size="sm" showLabel={false} />
            )}
          </div>

          {/* 기본 보증 정보 (추가 보증 모드에서 표시) */}
          {isAdditionalMode && (
            <div className="mt-4 pt-4 border-t">
              <div className="flex items-center justify-between text-sm">
                <span className="text-gray-500">현재 기본 보증</span>
                <span className="font-medium text-green-600">{baseWarrantyMonths}개월</span>
              </div>
            </div>
          )}

          {/* 추가 보증 선택 */}
          {isAdditionalMode ? (
            <div className="mt-4 pt-4 border-t">
              <p className="text-sm font-medium mb-3">추가 보증 기간 선택</p>
              <div className="grid grid-cols-2 gap-3">
                <button
                  type="button"
                  className={`p-3 rounded-lg border-2 text-center transition-colors ${
                    selectedAdditionalMonths === 12
                      ? "border-blue-500 bg-blue-50"
                      : "border-gray-200 hover:border-gray-300"
                  }`}
                  onClick={() => setSelectedAdditionalMonths(12)}
                >
                  <Plus className="h-4 w-4 mx-auto mb-1" />
                  <p className="font-medium">+1년</p>
                  <p className="text-sm text-gray-500">
                    {formatCurrency(Math.round(transaction.salePrice * 0.1))}
                  </p>
                </button>
                <button
                  type="button"
                  className={`p-3 rounded-lg border-2 text-center transition-colors ${
                    selectedAdditionalMonths === 24
                      ? "border-blue-500 bg-blue-50"
                      : "border-gray-200 hover:border-gray-300"
                  }`}
                  onClick={() => setSelectedAdditionalMonths(24)}
                >
                  <Plus className="h-4 w-4 mx-auto mb-1" />
                  <p className="font-medium">+2년</p>
                  <p className="text-sm text-gray-500">
                    {formatCurrency(Math.round(transaction.salePrice * 0.2))}
                  </p>
                </button>
              </div>
              <div className="mt-4 p-3 bg-blue-50 rounded-lg">
                <div className="flex items-center justify-between">
                  <span className="text-sm">총 보증 기간</span>
                  <span className="font-bold text-blue-600">
                    {baseWarrantyMonths + selectedAdditionalMonths}개월
                  </span>
                </div>
                <div className="flex items-center justify-between mt-1">
                  <span className="text-sm">추가 결제 금액</span>
                  <span className="font-bold text-blue-600">
                    {formatCurrency(additionalPrice)}
                  </span>
                </div>
              </div>
            </div>
          ) : (
            <div className="mt-4 pt-4 border-t flex items-center justify-between">
              <div className="flex items-center gap-2">
                <Shield className="h-5 w-5 text-blue-600" />
                <span className="font-medium">
                  {selectedPlan === "1year" ? "1년" : "2년"} 보증
                </span>
              </div>
              <span className="text-lg font-bold text-blue-600">
                {formatCurrency(warrantyPrice)}
              </span>
            </div>
          )}
        </CardContent>
      </Card>

      {/* 고객 정보 입력 */}
      <Card className="mb-6">
        <CardHeader>
          <CardTitle className="text-lg">고객 정보</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="space-y-2">
            <Label required>이름</Label>
            <Input
              placeholder="홍길동"
              {...register("customerName")}
              error={errors.customerName?.message}
            />
          </div>
          <div className="space-y-2">
            <Label required>연락처</Label>
            <Input
              placeholder="010-1234-5678"
              {...register("customerPhone")}
              error={errors.customerPhone?.message}
            />
          </div>
          <div className="space-y-2">
            <Label>이메일 (선택)</Label>
            <Input
              type="email"
              placeholder="example@email.com"
              {...register("customerEmail")}
              error={errors.customerEmail?.message}
            />
          </div>
        </CardContent>
      </Card>

      {/* 결제 수단 */}
      <Card>
        <CardHeader>
          <CardTitle className="text-lg">결제 수단</CardTitle>
        </CardHeader>
        <CardContent className="space-y-3">
          {paymentError && (
            <div className="p-3 bg-red-50 text-red-500 rounded-lg text-sm mb-4">
              {paymentError}
            </div>
          )}

          <Button
            variant="kakao"
            className="w-full h-12"
            isLoading={isSubmitting}
            onClick={handleSubmit((data) => handlePayment(data, "kakaopay"))}
          >
            <svg className="h-6 w-6 mr-2" viewBox="0 0 24 24" fill="currentColor">
              <path d="M12 3C6.477 3 2 6.463 2 10.691c0 2.628 1.624 4.939 4.091 6.315-.139.528-.557 2.138-.639 2.467-.103.407.148.402.313.292.129-.086 2.058-1.376 2.889-1.933a12.82 12.82 0 003.346.442c5.523 0 10-3.463 10-7.691S17.523 3 12 3" />
            </svg>
            카카오페이로 결제
          </Button>

          <Button
            variant="toss"
            className="w-full h-12"
            isLoading={isSubmitting}
            onClick={handleSubmit((data) => handlePayment(data, "tosspay"))}
          >
            <svg className="h-5 w-5 mr-2" viewBox="0 0 24 24" fill="currentColor">
              <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-1 17.93c-3.95-.49-7-3.85-7-7.93 0-.62.08-1.21.21-1.79L9 15v1c0 1.1.9 2 2 2v1.93zm6.9-2.54c-.26-.81-1-1.39-1.9-1.39h-1v-3c0-.55-.45-1-1-1H8v-2h2c.55 0 1-.45 1-1V7h2c1.1 0 2-.9 2-2v-.41c2.93 1.19 5 4.06 5 7.41 0 2.08-.8 3.97-2.1 5.39z" />
            </svg>
            토스페이로 결제
          </Button>

          <p className="text-xs text-center text-gray-500 mt-4">
            결제 완료 후 보증 서비스가 즉시 활성화됩니다
          </p>
        </CardContent>
      </Card>
    </div>
  );
}
