/**
 * 카카오 OAuth 웹 인증
 */

import { signInWithCustomToken } from "firebase/auth";
import { auth } from "@/lib/firebase/config";

const API_URL = process.env.NEXT_PUBLIC_API_URL || "https://asia-northeast3-picom-team.cloudfunctions.net/api";
const KAKAO_CLIENT_ID = process.env.NEXT_PUBLIC_KAKAO_REST_API_KEY || "";

/**
 * 카카오 로그인 페이지로 리다이렉트
 */
export function redirectToKakaoLogin(redirectPath?: string) {
  const redirectUri = `${window.location.origin}/auth/kakao/callback`;

  // 로그인 후 돌아갈 경로를 state에 저장
  const state = redirectPath ? encodeURIComponent(redirectPath) : "";

  const kakaoAuthUrl =
    `https://kauth.kakao.com/oauth/authorize` +
    `?client_id=${KAKAO_CLIENT_ID}` +
    `&redirect_uri=${encodeURIComponent(redirectUri)}` +
    `&response_type=code` +
    (state ? `&state=${state}` : "");

  window.location.href = kakaoAuthUrl;
}

/**
 * 카카오 authorization code로 Firebase 로그인
 */
export async function loginWithKakaoCode(code: string): Promise<void> {
  const redirectUri = `${window.location.origin}/auth/kakao/callback`;

  // 백엔드에서 code → access_token → custom token 교환
  const response = await fetch(`${API_URL}/auth/kakao/token`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ code, redirectUri }),
  });

  if (!response.ok) {
    const error = await response.json();
    throw new Error(error.message || "Kakao login failed");
  }

  const data = await response.json();

  // Firebase Custom Token으로 로그인
  await signInWithCustomToken(auth, data.customToken);
}
