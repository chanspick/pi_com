"use client";

import { useState } from "react";
import { createClient } from "@/lib/supabase/client";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Suspense } from "react";
import Link from "next/link";

function SignupForm() {
  const [displayName, setDisplayName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [passwordConfirm, setPasswordConfirm] = useState("");
  const [agreedTerms, setAgreedTerms] = useState(false);
  const [agreedPrivacy, setAgreedPrivacy] = useState(false);
  const [agreedMarketing, setAgreedMarketing] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState(false);
  const [loading, setLoading] = useState(false);

  const allRequired = agreedTerms && agreedPrivacy;
  const allChecked = agreedTerms && agreedPrivacy && agreedMarketing;

  const toggleAll = () => {
    const next = !allChecked;
    setAgreedTerms(next);
    setAgreedPrivacy(next);
    setAgreedMarketing(next);
  };

  const handleGoogleSignup = async () => {
    const supabase = createClient();
    await supabase.auth.signInWithOAuth({
      provider: "google",
      options: {
        redirectTo: `${window.location.origin}/callback`,
      },
    });
  };

  const handleKakaoSignup = async () => {
    const supabase = createClient();
    await supabase.auth.signInWithOAuth({
      provider: "kakao",
      options: {
        redirectTo: `${window.location.origin}/callback`,
      },
    });
  };

  const handleEmailSignup = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);

    // 약관 동의 검사
    if (!allRequired) {
      setError("필수 약관에 동의해주세요.");
      return;
    }

    // 클라이언트 유효성 검사
    if (password.length < 6) {
      setError("비밀번호는 6자 이상이어야 합니다.");
      return;
    }

    if (password !== passwordConfirm) {
      setError("비밀번호가 일치하지 않습니다.");
      return;
    }

    setLoading(true);

    try {
      const supabase = createClient();
      const { error } = await supabase.auth.signUp({
        email,
        password,
        options: {
          data: {
            display_name: displayName,
            agreed_terms: true,
            agreed_privacy: true,
            agreed_marketing: agreedMarketing,
            agreed_at: new Date().toISOString(),
          },
        },
      });

      if (error) {
        if (error.message.includes("already registered")) {
          setError("이미 등록된 이메일입니다.");
        } else {
          setError(error.message);
        }
      } else {
        setSuccess(true);
      }
    } catch {
      setError("회원가입 중 오류가 발생했습니다. 다시 시도해주세요.");
    } finally {
      setLoading(false);
    }
  };

  if (success) {
    return (
      <div className="flex min-h-[60vh] items-center justify-center">
        <Card className="w-full max-w-sm">
          <CardHeader className="text-center">
            <CardTitle className="text-2xl font-bold">이메일 확인</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4 text-center">
            <div className="rounded-[10px] bg-green-50 p-4 text-sm text-green-700 dark:bg-green-900/20 dark:text-green-400">
              인증 이메일을 발송했습니다. 이메일을 확인해주세요.
            </div>
            <p className="text-sm text-muted-foreground">
              <Link
                href="/login"
                className="text-foreground font-medium hover:underline underline-offset-4"
              >
                로그인 페이지로 돌아가기
              </Link>
            </p>
          </CardContent>
        </Card>
      </div>
    );
  }

  return (
    <div className="flex min-h-[60vh] items-center justify-center">
      <Card className="w-full max-w-sm">
        <CardHeader className="text-center">
          <CardTitle className="text-2xl font-bold">PiCom 회원가입</CardTitle>
          <CardDescription>중고 PC 부품 마켓플레이스에 참여하세요</CardDescription>
        </CardHeader>
        <CardContent className="space-y-6">
          {error && (
            <div className="rounded-[10px] bg-destructive/10 p-3 text-sm text-destructive">
              {error}
            </div>
          )}

          {/* 소셜 회원가입 */}
          <div className="space-y-3">
            <Button
              onClick={handleGoogleSignup}
              variant="outline"
              className="w-full"
              size="lg"
            >
              <svg className="mr-2 h-4 w-4" viewBox="0 0 24 24">
                <path
                  d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92a5.06 5.06 0 0 1-2.2 3.32v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.1z"
                  fill="#4285F4"
                />
                <path
                  d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"
                  fill="#34A853"
                />
                <path
                  d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"
                  fill="#FBBC05"
                />
                <path
                  d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"
                  fill="#EA4335"
                />
              </svg>
              Google로 회원가입
            </Button>

            <Button
              onClick={handleKakaoSignup}
              className="w-full bg-[#FEE500] text-[#191919] hover:bg-[#FDD835] border-transparent"
              size="lg"
            >
              <svg className="mr-2 h-4 w-4" viewBox="0 0 24 24" fill="none">
                <path
                  fillRule="evenodd"
                  clipRule="evenodd"
                  d="M12 4C7.029 4 3 7.13 3 10.95c0 2.414 1.605 4.54 4.028 5.74l-.855 3.14a.3.3 0 0 0 .453.331L10.1 17.9c.62.09 1.255.14 1.9.14 4.971 0 9-3.13 9-6.95S16.971 4 12 4z"
                  fill="#191919"
                />
              </svg>
              카카오로 회원가입
            </Button>
          </div>

          {/* 구분선 */}
          <div className="relative">
            <div className="absolute inset-0 flex items-center">
              <span className="w-full border-t" />
            </div>
            <div className="relative flex justify-center text-xs uppercase">
              <span className="bg-card px-2 text-muted-foreground">또는</span>
            </div>
          </div>

          {/* 이메일 회원가입 폼 */}
          <form onSubmit={handleEmailSignup} className="space-y-4">
            <div className="space-y-2">
              <Input
                type="text"
                placeholder="닉네임"
                value={displayName}
                onChange={(e) => setDisplayName(e.target.value)}
                required
                disabled={loading}
                aria-label="닉네임"
              />
            </div>
            <div className="space-y-2">
              <Input
                type="email"
                placeholder="이메일"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
                disabled={loading}
                aria-label="이메일"
              />
            </div>
            <div className="space-y-2">
              <Input
                type="password"
                placeholder="비밀번호 (6자 이상)"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
                minLength={6}
                disabled={loading}
                aria-label="비밀번호"
              />
            </div>
            <div className="space-y-2">
              <Input
                type="password"
                placeholder="비밀번호 확인"
                value={passwordConfirm}
                onChange={(e) => setPasswordConfirm(e.target.value)}
                required
                minLength={6}
                disabled={loading}
                aria-label="비밀번호 확인"
              />
            </div>
            {/* 약관 동의 */}
            <div className="space-y-3 rounded-[10px] border p-4">
              <label className="flex items-center gap-3 cursor-pointer">
                <input
                  type="checkbox"
                  checked={allChecked}
                  onChange={toggleAll}
                  className="h-4 w-4 rounded accent-[#3B82F6]"
                />
                <span className="text-sm font-semibold">전체 동의</span>
              </label>
              <div className="border-t pt-3 space-y-2.5">
                <label className="flex items-center gap-3 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={agreedTerms}
                    onChange={(e) => setAgreedTerms(e.target.checked)}
                    className="h-4 w-4 rounded accent-[#3B82F6]"
                  />
                  <span className="text-sm flex-1">
                    <span className="text-destructive font-medium">[필수]</span>{" "}
                    <Link href="/terms" target="_blank" className="hover:underline underline-offset-4">
                      이용약관
                    </Link>
                    에 동의합니다
                  </span>
                </label>
                <label className="flex items-center gap-3 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={agreedPrivacy}
                    onChange={(e) => setAgreedPrivacy(e.target.checked)}
                    className="h-4 w-4 rounded accent-[#3B82F6]"
                  />
                  <span className="text-sm flex-1">
                    <span className="text-destructive font-medium">[필수]</span>{" "}
                    <Link href="/privacy" target="_blank" className="hover:underline underline-offset-4">
                      개인정보처리방침
                    </Link>
                    에 동의합니다
                  </span>
                </label>
                <label className="flex items-center gap-3 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={agreedMarketing}
                    onChange={(e) => setAgreedMarketing(e.target.checked)}
                    className="h-4 w-4 rounded accent-[#3B82F6]"
                  />
                  <span className="text-sm flex-1">
                    <span className="text-muted-foreground">[선택]</span>{" "}
                    마케팅 정보 수신에 동의합니다
                  </span>
                </label>
              </div>
            </div>

            <Button
              type="submit"
              className="w-full"
              size="lg"
              disabled={loading || !allRequired}
            >
              {loading ? "가입 중..." : "회원가입"}
            </Button>
          </form>

          {/* 링크 */}
          <p className="text-center text-sm text-muted-foreground">
            이미 계정이 있으신가요?{" "}
            <Link
              href="/login"
              className="text-foreground font-medium hover:underline underline-offset-4"
            >
              로그인
            </Link>
          </p>
        </CardContent>
      </Card>
    </div>
  );
}

export default function SignupPage() {
  return (
    <Suspense>
      <SignupForm />
    </Suspense>
  );
}
