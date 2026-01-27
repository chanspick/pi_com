"use client";

import { useEffect, useState } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import { loginWithKakaoCode } from "@/lib/auth/kakao";
import { Loader2, AlertCircle, CheckCircle } from "lucide-react";

export default function KakaoCallbackPage() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const [status, setStatus] = useState<"loading" | "success" | "error">("loading");
  const [errorMessage, setErrorMessage] = useState("");

  useEffect(() => {
    const code = searchParams.get("code");
    const state = searchParams.get("state");
    const error = searchParams.get("error");

    if (error) {
      setStatus("error");
      setErrorMessage("카카오 로그인이 취소되었습니다.");
      return;
    }

    if (!code) {
      setStatus("error");
      setErrorMessage("인증 코드가 없습니다.");
      return;
    }

    loginWithKakaoCode(code)
      .then(() => {
        setStatus("success");
        // state에 저장된 리다이렉트 경로로 이동
        const redirectPath = state ? decodeURIComponent(state) : "/";
        setTimeout(() => router.push(redirectPath), 1000);
      })
      .catch((err) => {
        setStatus("error");
        setErrorMessage(err.message || "로그인에 실패했습니다.");
      });
  }, [searchParams, router]);

  return (
    <div className="flex flex-col items-center justify-center min-h-[60vh]">
      {status === "loading" && (
        <>
          <Loader2 className="h-8 w-8 animate-spin text-[#FEE500]" />
          <p className="mt-4 text-gray-500">카카오 로그인 처리 중...</p>
        </>
      )}

      {status === "success" && (
        <>
          <CheckCircle className="h-12 w-12 text-green-500" />
          <p className="mt-4 text-gray-700 font-medium">로그인 완료!</p>
          <p className="mt-1 text-gray-500 text-sm">잠시 후 이동합니다...</p>
        </>
      )}

      {status === "error" && (
        <>
          <AlertCircle className="h-12 w-12 text-red-500" />
          <p className="mt-4 text-gray-700 font-medium">로그인 실패</p>
          <p className="mt-1 text-gray-500 text-sm">{errorMessage}</p>
          <button
            onClick={() => router.push("/")}
            className="mt-4 text-blue-600 hover:underline text-sm"
          >
            홈으로 돌아가기
          </button>
        </>
      )}
    </div>
  );
}
