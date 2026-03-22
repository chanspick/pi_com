"use client";

import { useSearchParams, useRouter } from "next/navigation";
import Link from "next/link";
import { XCircle, RotateCcw, Home } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";

export default function CheckoutFailPage() {
  const searchParams = useSearchParams();
  const router = useRouter();

  const errorCode = searchParams.get("code");
  const errorMessage = searchParams.get("message");

  // 에러 코드별 한글 메시지
  const getErrorDescription = (code: string | null): string => {
    switch (code) {
      case "PAY_PROCESS_CANCELED":
        return "결제가 취소되었습니다.";
      case "PAY_PROCESS_ABORTED":
        return "결제 처리 중 문제가 발생했습니다.";
      case "REJECT_CARD_COMPANY":
        return "카드사에서 결제를 거부했습니다. 카드사에 문의해 주세요.";
      case "BELOW_MINIMUM_AMOUNT":
        return "최소 결제 금액 미만입니다.";
      case "EXCEED_MAX_DAILY_PAYMENT_COUNT":
        return "일일 결제 한도를 초과했습니다.";
      default:
        return errorMessage ?? "결제 처리 중 오류가 발생했습니다.";
    }
  };

  return (
    <div className="mx-auto max-w-3xl px-4 py-8">
      {/* 실패 헤더 */}
      <div className="flex flex-col items-center gap-3 py-10">
        <div className="flex h-16 w-16 items-center justify-center rounded-full bg-destructive/10">
          <XCircle className="h-8 w-8 text-destructive" />
        </div>
        <h1 className="text-[22px] font-bold">결제에 실패했습니다</h1>
        <p className="text-[14px] text-muted-foreground text-center max-w-sm">
          {getErrorDescription(errorCode)}
        </p>
      </div>

      {/* 에러 상세 */}
      {errorCode && (
        <Card className="mb-6">
          <CardContent>
            <h2 className="text-[15px] font-semibold mb-2">오류 정보</h2>
            <div className="space-y-1 text-[13px]">
              <div className="flex justify-between">
                <span className="text-muted-foreground">오류 코드</span>
                <span className="font-mono">{errorCode}</span>
              </div>
              {errorMessage && (
                <div className="flex justify-between">
                  <span className="text-muted-foreground">메시지</span>
                  <span className="text-right max-w-[200px]">
                    {errorMessage}
                  </span>
                </div>
              )}
            </div>
          </CardContent>
        </Card>
      )}

      {/* 버튼 */}
      <div className="flex gap-3">
        <Button
          className="flex-1 h-12 text-base font-semibold"
          size="lg"
          onClick={() => router.back()}
        >
          <RotateCcw className="h-4 w-4 mr-2" />
          다시 시도하기
        </Button>
        <Link href="/" className="flex-1">
          <Button
            variant="outline"
            className="w-full h-12 text-base font-semibold"
            size="lg"
          >
            <Home className="h-4 w-4 mr-2" />
            홈으로
          </Button>
        </Link>
      </div>

      {/* 안내 */}
      <div className="mt-6 rounded-lg border bg-muted/30 p-4 text-[13px] text-muted-foreground space-y-1">
        <p className="font-medium text-foreground">도움이 필요하신가요?</p>
        <p>
          결제 문제가 반복되는 경우 다른 결제 수단을 시도하거나, 고객센터로
          문의해 주세요.
        </p>
      </div>
    </div>
  );
}
