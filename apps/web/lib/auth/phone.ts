/**
 * 전화번호 인증 (Firebase Phone Auth)
 */

import {
  RecaptchaVerifier,
  signInWithPhoneNumber,
  ConfirmationResult,
} from "firebase/auth";
import { auth } from "@/lib/firebase/config";

let confirmationResult: ConfirmationResult | null = null;

/**
 * reCAPTCHA 인증기 초기화
 */
export function initRecaptcha(buttonId: string): RecaptchaVerifier {
  const verifier = new RecaptchaVerifier(auth, buttonId, {
    size: "invisible",
  });
  return verifier;
}

/**
 * 전화번호로 인증 코드 발송
 */
export async function sendPhoneVerification(
  phoneNumber: string,
  recaptchaVerifier: RecaptchaVerifier
): Promise<void> {
  // 한국 전화번호 형식 변환 (010-xxxx-xxxx → +8210xxxxxxxx)
  const formatted = formatKoreanPhone(phoneNumber);
  confirmationResult = await signInWithPhoneNumber(auth, formatted, recaptchaVerifier);
}

/**
 * 인증 코드 확인 및 로그인
 */
export async function confirmPhoneCode(code: string): Promise<void> {
  if (!confirmationResult) {
    throw new Error("인증 코드를 먼저 요청해주세요.");
  }
  await confirmationResult.confirm(code);
  confirmationResult = null;
}

/**
 * 한국 전화번호를 국제 형식으로 변환
 */
function formatKoreanPhone(phone: string): string {
  const digits = phone.replace(/[^0-9]/g, "");
  if (digits.startsWith("010")) {
    return "+82" + digits.substring(1);
  }
  if (digits.startsWith("82")) {
    return "+" + digits;
  }
  return "+82" + digits;
}
