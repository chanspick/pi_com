"use client";

import { use, useState } from "react";
import { useQuery, useMutation } from "@tanstack/react-query";
import { useRouter } from "next/navigation";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { getTransactionByQR, activateWarranty } from "@/lib/api/warranty";
import { getDisplayName, getGradeConfig, isBundle } from "@/types/warranty";
import { GradeBadge } from "@/components/warranty/GradeBadge";
import { BundleItemList } from "@/components/warranty/BundleItemList";
import { Shield, Loader2, CheckCircle, Package } from "lucide-react";

const formSchema = z.object({
  customerName: z.string().min(2, "이름을 입력해주세요"),
  customerPhone: z.string().regex(/^01[0-9]{8,9}$/, "올바른 전화번호를 입력해주세요"),
  customerEmail: z.string().email("올바른 이메일을 입력해주세요").optional().or(z.literal("")),
});

type FormData = z.infer<typeof formSchema>;

interface PageProps {
  params: Promise<{ qrCode: string }>;
}

export default function WarrantyActivatePage({ params }: PageProps) {
  const { qrCode } = use(params);
  const router = useRouter();
  const [isSuccess, setIsSuccess] = useState(false);

  const {
    data: transaction,
    isLoading: isLoadingTransaction,
  } = useQuery({
    queryKey: ["transaction", qrCode],
    queryFn: () => getTransactionByQR(qrCode),
  });

  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<FormData>({
    resolver: zodResolver(formSchema),
  });

  const activateMutation = useMutation({
    mutationFn: (data: FormData) =>
      activateWarranty({
        qrCode,
        customerName: data.customerName,
        customerPhone: data.customerPhone,
        customerEmail: data.customerEmail,
      }),
    onSuccess: () => {
      setIsSuccess(true);
    },
  });

  if (isLoadingTransaction) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[60vh]">
        <Loader2 className="h-8 w-8 animate-spin text-blue-600" />
        <p className="mt-4 text-gray-500">거래 정보를 불러오는 중...</p>
      </div>
    );
  }

  if (!transaction) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[60vh] px-4">
        <p className="text-gray-500">거래 정보를 찾을 수 없습니다.</p>
      </div>
    );
  }

  if (isSuccess) {
    const gradeConfig = getGradeConfig(transaction.conditionGrade);
    const baseWarrantyMonths = transaction.baseWarrantyMonths || gradeConfig.baseWarrantyMonths;

    return (
      <div className="container mx-auto px-4 py-8 max-w-lg">
        <div className="text-center mb-8">
          <CheckCircle className="h-16 w-16 text-green-500 mx-auto" />
          <h1 className="mt-4 text-2xl font-bold">보증이 활성화되었습니다!</h1>
          <p className="mt-2 text-gray-500">
            기본 {baseWarrantyMonths}개월 AS 보증이 시작되었습니다.
          </p>
        </div>

        <div className="bg-green-50 border border-green-200 rounded-xl p-4 mb-6">
          <div className="flex justify-between items-center">
            <span className="text-green-700">기본 보증 기간</span>
            <span className="font-bold text-green-700">{baseWarrantyMonths}개월</span>
          </div>
        </div>

        <div className="space-y-3">
          <Button
            className="w-full"
            size="lg"
            onClick={() => router.push(`/warranty/purchase/${qrCode}?mode=additional`)}
          >
            추가 보증 구매하기
          </Button>
          <Button
            variant="outline"
            className="w-full"
            onClick={() => router.push(`/warranty/${qrCode}`)}
          >
            보증 정보 확인
          </Button>
        </div>
      </div>
    );
  }

  const isBundleType = isBundle(transaction);
  const displayName = getDisplayName(transaction);
  const gradeConfig = getGradeConfig(transaction.conditionGrade);
  const baseWarrantyMonths = transaction.baseWarrantyMonths || gradeConfig.baseWarrantyMonths;

  const onSubmit = (data: FormData) => {
    activateMutation.mutate(data);
  };

  return (
    <div className="container mx-auto px-4 py-8 max-w-lg">
      {/* 헤더 */}
      <div className="text-center mb-6">
        <Shield className="h-12 w-12 text-blue-600 mx-auto" />
        <h1 className="mt-2 text-2xl font-bold">기본 보증 활성화</h1>
        <p className="mt-1 text-gray-500">무료 기본 AS 보증을 활성화합니다</p>
      </div>

      {/* 제품 정보 */}
      <div className="bg-white rounded-xl border p-4 mb-4">
        <div className="flex items-start gap-4">
          <div className="w-12 h-12 bg-blue-50 rounded-lg flex items-center justify-center">
            <Package className="h-6 w-6 text-blue-600" />
          </div>
          <div className="flex-1">
            <h2 className="font-bold text-lg">{displayName}</h2>
            <p className="text-sm text-gray-500">
              {isBundleType
                ? `${transaction.items?.length || 0}개 부품 구성`
                : transaction.partCategory}
            </p>
          </div>
          {transaction.conditionGrade && (
            <GradeBadge grade={transaction.conditionGrade} size="md" />
          )}
        </div>
      </div>

      {/* 풀세트 부품 목록 */}
      {isBundleType && transaction.items && (
        <div className="mb-4">
          <BundleItemList items={transaction.items} />
        </div>
      )}

      {/* 기본 보증 정보 */}
      <div className="bg-gradient-to-r from-green-50 to-blue-50 rounded-xl border p-4 mb-6">
        <div className="text-center">
          <p className="text-sm text-gray-600">기본 AS 보증</p>
          <p className="text-3xl font-bold text-green-600 mt-1">
            {baseWarrantyMonths}개월
          </p>
          <p className="text-xs text-gray-500 mt-1">
            등급 {transaction.conditionGrade} 기준 자동 산정
          </p>
        </div>
      </div>

      {/* 고객 정보 입력 */}
      <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
        <div className="bg-white rounded-xl border p-4">
          <h3 className="font-semibold mb-4">고객 정보</h3>

          <div className="space-y-4">
            <div>
              <Label htmlFor="customerName">이름 *</Label>
              <Input
                id="customerName"
                placeholder="홍길동"
                {...register("customerName")}
              />
              {errors.customerName && (
                <p className="text-red-500 text-xs mt-1">
                  {errors.customerName.message}
                </p>
              )}
            </div>

            <div>
              <Label htmlFor="customerPhone">전화번호 *</Label>
              <Input
                id="customerPhone"
                placeholder="01012345678"
                {...register("customerPhone")}
              />
              {errors.customerPhone && (
                <p className="text-red-500 text-xs mt-1">
                  {errors.customerPhone.message}
                </p>
              )}
            </div>

            <div>
              <Label htmlFor="customerEmail">이메일 (선택)</Label>
              <Input
                id="customerEmail"
                type="email"
                placeholder="email@example.com"
                {...register("customerEmail")}
              />
              {errors.customerEmail && (
                <p className="text-red-500 text-xs mt-1">
                  {errors.customerEmail.message}
                </p>
              )}
            </div>
          </div>
        </div>

        <Button
          type="submit"
          className="w-full"
          size="lg"
          disabled={activateMutation.isPending}
        >
          {activateMutation.isPending ? (
            <>
              <Loader2 className="mr-2 h-4 w-4 animate-spin" />
              처리 중...
            </>
          ) : (
            `기본 보증 활성화 (무료)`
          )}
        </Button>

        {activateMutation.isError && (
          <p className="text-red-500 text-sm text-center">
            활성화 중 오류가 발생했습니다. 다시 시도해주세요.
          </p>
        )}
      </form>
    </div>
  );
}
