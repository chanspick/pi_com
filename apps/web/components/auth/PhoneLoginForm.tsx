"use client";

import { useState, useRef, useEffect } from "react";
import { RecaptchaVerifier } from "firebase/auth";
import {
  initRecaptcha,
  sendPhoneVerification,
  confirmPhoneCode,
} from "@/lib/auth/phone";
import { Button } from "@/components/ui/button";
import { Loader2 } from "lucide-react";

export function PhoneLoginForm() {
  const [phone, setPhone] = useState("");
  const [code, setCode] = useState("");
  const [step, setStep] = useState<"phone" | "code">("phone");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const recaptchaRef = useRef<RecaptchaVerifier | null>(null);

  useEffect(() => {
    // reCAPTCHA 초기화는 컴포넌트 마운트 시 한 번만
    return () => {
      if (recaptchaRef.current) {
        recaptchaRef.current.clear();
        recaptchaRef.current = null;
      }
    };
  }, []);

  const handleSendCode = async () => {
    if (!phone) return;
    setLoading(true);
    setError("");

    try {
      if (!recaptchaRef.current) {
        recaptchaRef.current = initRecaptcha("recaptcha-container");
      }
      await sendPhoneVerification(phone, recaptchaRef.current);
      setStep("code");
    } catch (err: any) {
      setError(err.message || "인증 코드 발송에 실패했습니다.");
      // reCAPTCHA 리셋
      if (recaptchaRef.current) {
        recaptchaRef.current.clear();
        recaptchaRef.current = null;
      }
    } finally {
      setLoading(false);
    }
  };

  const handleConfirmCode = async () => {
    if (!code) return;
    setLoading(true);
    setError("");

    try {
      await confirmPhoneCode(code);
      // 로그인 성공 - AuthContext가 자동 감지
    } catch (err: any) {
      setError("인증 코드가 올바르지 않습니다.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="space-y-3">
      {step === "phone" ? (
        <>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              전화번호
            </label>
            <input
              type="tel"
              value={phone}
              onChange={(e) => setPhone(e.target.value)}
              className="w-full border rounded-lg px-3 py-2"
              placeholder="010-1234-5678"
            />
          </div>
          <Button
            onClick={handleSendCode}
            disabled={!phone || loading}
            className="w-full"
          >
            {loading ? (
              <><Loader2 className="h-4 w-4 animate-spin mr-2" />발송 중...</>
            ) : (
              "인증 코드 발송"
            )}
          </Button>
        </>
      ) : (
        <>
          <p className="text-sm text-gray-500">
            {phone}로 발송된 인증 코드를 입력해주세요.
          </p>
          <div>
            <input
              type="text"
              value={code}
              onChange={(e) => setCode(e.target.value)}
              className="w-full border rounded-lg px-3 py-2 text-center text-lg tracking-widest"
              placeholder="000000"
              maxLength={6}
            />
          </div>
          <Button
            onClick={handleConfirmCode}
            disabled={code.length < 6 || loading}
            className="w-full"
          >
            {loading ? (
              <><Loader2 className="h-4 w-4 animate-spin mr-2" />확인 중...</>
            ) : (
              "확인"
            )}
          </Button>
          <button
            onClick={() => { setStep("phone"); setCode(""); }}
            className="text-sm text-gray-500 hover:text-gray-700 w-full text-center"
          >
            다시 발송
          </button>
        </>
      )}

      {error && (
        <p className="text-sm text-red-600 text-center">{error}</p>
      )}

      <div id="recaptcha-container" />
    </div>
  );
}
