"use client";

import { useEffect, useState, Suspense } from "react";
import { useSearchParams, useRouter } from "next/navigation";
import { approveWarrantyPayment } from "@/lib/api/warranty";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { CheckCircle, XCircle, Loader2 } from "lucide-react";

function PaymentCallbackContent() {
  const searchParams = useSearchParams();
  const router = useRouter();

  const [status, setStatus] = useState<"loading" | "success" | "error">("loading");
  const [errorMessage, setErrorMessage] = useState<string>("");

  const warrantyId = searchParams.get("warrantyId");
  const result = searchParams.get("result");
  const pgToken = searchParams.get("pg_token"); // 카카오페이
  const paymentKey = searchParams.get("paymentKey"); // 토스페이
  const orderId = searchParams.get("orderId");
  const amount = searchParams.get("amount");

  useEffect(() => {
    const processPayment = async () => {
      if (!warrantyId) {
        setStatus("error");
        setErrorMessage("보증 정보가 없습니다.");
        return;
      }

      // 취소 또는 실패
      if (result === "cancel" || result === "fail") {
        setStatus("error");
        setErrorMessage(
          result === "cancel" ? "결제가 취소되었습니다." : "결제에 실패했습니다."
        );
        return;
      }

      try {
        // 결제 승인 요청
        await approveWarrantyPayment({
          warrantyId,
          pgToken: pgToken || undefined,
          paymentKey: paymentKey || undefined,
          orderId: orderId || undefined,
          amount: amount ? parseInt(amount, 10) : undefined,
        });

        setStatus("success");
      } catch (err: any) {
        setStatus("error");
        setErrorMessage(err.message || "결제 처리 중 오류가 발생했습니다.");
      }
    };

    processPayment();
  }, [warrantyId, result, pgToken, paymentKey, orderId, amount]);

  if (status === "loading") {
    return (
      <div className="flex flex-col items-center justify-center min-h-[60vh]">
        <Loader2 className="h-12 w-12 animate-spin text-blue-600" />
        <p className="mt-4 text-lg font-medium">결제 처리 중...</p>
        <p className="mt-2 text-gray-500">잠시만 기다려주세요.</p>
      </div>
    );
  }

  if (status === "success") {
    return (
      <div className="container mx-auto px-4 py-12 max-w-md">
        <Card>
          <CardContent className="p-8 text-center">
            <CheckCircle className="h-16 w-16 text-green-500 mx-auto" />
            <h1 className="mt-4 text-2xl font-bold">결제 완료!</h1>
            <p className="mt-2 text-gray-500">
              AS 보증 서비스가 활성화되었습니다.
            </p>
            <div className="mt-6 space-y-3">
              <Button
                className="w-full"
                onClick={() => router.push(`/warranty/service/${warrantyId}`)}
              >
                보증 정보 확인
              </Button>
              <Button variant="outline" className="w-full" onClick={() => router.push("/")}>
                홈으로
              </Button>
            </div>
          </CardContent>
        </Card>
      </div>
    );
  }

  return (
    <div className="container mx-auto px-4 py-12 max-w-md">
      <Card>
        <CardContent className="p-8 text-center">
          <XCircle className="h-16 w-16 text-red-500 mx-auto" />
          <h1 className="mt-4 text-2xl font-bold">결제 실패</h1>
          <p className="mt-2 text-gray-500">{errorMessage}</p>
          <div className="mt-6 space-y-3">
            <Button className="w-full" onClick={() => router.back()}>
              다시 시도
            </Button>
            <Button variant="outline" className="w-full" onClick={() => router.push("/")}>
              홈으로
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

export default function PaymentCallbackPage() {
  return (
    <Suspense
      fallback={
        <div className="flex flex-col items-center justify-center min-h-[60vh]">
          <Loader2 className="h-12 w-12 animate-spin text-blue-600" />
        </div>
      }
    >
      <PaymentCallbackContent />
    </Suspense>
  );
}
