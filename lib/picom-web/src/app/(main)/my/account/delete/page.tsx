"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { ArrowLeft, AlertTriangle } from "lucide-react";
import { createClient } from "@/lib/supabase/client";
import { useAuth } from "@/hooks/use-auth";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
  Card,
  CardContent,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";

const CONFIRMATION_TEXT = "탈퇴합니다";

export default function AccountDeletePage() {
  const router = useRouter();
  const { user, loading: authLoading, signOut } = useAuth();

  const [reason, setReason] = useState("");
  const [confirmText, setConfirmText] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const isConfirmed = confirmText === CONFIRMATION_TEXT;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!isConfirmed) return;
    if (!user) {
      setError("로그인 상태를 확인할 수 없습니다.");
      return;
    }

    setSubmitting(true);
    setError(null);

    try {
      const supabase = createClient();

      const { error: insertError } = await supabase
        .from("account_deletions")
        .insert({
          user_id: user.id,
          reason: reason.trim() || null,
          requested_at: new Date().toISOString(),
        });

      if (insertError) {
        setError("탈퇴 요청 처리 중 오류가 발생했습니다. 다시 시도해주세요.");
        setSubmitting(false);
        return;
      }

      await signOut();
      router.push("/");
    } catch {
      setError("탈퇴 요청 처리 중 오류가 발생했습니다. 다시 시도해주세요.");
      setSubmitting(false);
    }
  };

  if (authLoading) {
    return (
      <div className="flex min-h-[60vh] items-center justify-center">
        <p className="text-muted-foreground text-sm">로딩 중...</p>
      </div>
    );
  }

  if (!user) {
    router.push("/login");
    return null;
  }

  return (
    <div className="container mx-auto max-w-lg px-4 py-10">
      {/* 뒤로가기 */}
      <Link
        href="/my"
        className="inline-flex items-center gap-1.5 text-sm text-muted-foreground hover:text-foreground mb-6"
      >
        <ArrowLeft className="h-4 w-4" />
        마이페이지로 돌아가기
      </Link>

      <Card>
        <CardHeader>
          <CardTitle className="text-xl font-bold">회원 탈퇴</CardTitle>
        </CardHeader>

        <CardContent>
          <form onSubmit={handleSubmit} className="space-y-6">
            {/* 경고 메시지 */}
            <div className="rounded-lg border border-destructive/30 bg-destructive/5 p-4">
              <div className="flex gap-3">
                <AlertTriangle className="h-5 w-5 text-destructive shrink-0 mt-0.5" />
                <div className="space-y-2 text-sm">
                  <p className="font-semibold text-destructive">
                    회원 탈퇴 시 아래 사항을 확인해주세요
                  </p>
                  <ul className="list-disc pl-4 space-y-1 text-muted-foreground">
                    <li>탈퇴 요청 후 <strong className="text-foreground">30일간 대기 기간</strong>이 적용됩니다.</li>
                    <li>대기 기간이 지나면 <strong className="text-foreground">계정 및 모든 데이터가 영구 삭제</strong>됩니다.</li>
                    <li>삭제된 데이터는 복구할 수 없습니다.</li>
                    <li>진행 중인 거래가 있는 경우, 거래 완료 후 탈퇴해주세요.</li>
                  </ul>
                </div>
              </div>
            </div>

            {/* 탈퇴 사유 */}
            <div className="space-y-2">
              <label
                htmlFor="reason"
                className="text-sm font-medium"
              >
                탈퇴 사유 <span className="text-muted-foreground font-normal">(선택)</span>
              </label>
              <textarea
                id="reason"
                value={reason}
                onChange={(e) => setReason(e.target.value)}
                placeholder="서비스 개선을 위해 탈퇴 사유를 알려주세요"
                rows={4}
                disabled={submitting}
                className="w-full min-w-0 rounded-lg border border-input bg-transparent px-3 py-2 text-sm transition-colors outline-none placeholder:text-muted-foreground focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 disabled:pointer-events-none disabled:cursor-not-allowed disabled:bg-input/50 disabled:opacity-50 resize-none dark:bg-input/30"
                aria-label="탈퇴 사유"
              />
            </div>

            {/* 확인 입력 */}
            <div className="space-y-2">
              <label
                htmlFor="confirm"
                className="text-sm font-medium"
              >
                확인을 위해 <strong className="text-destructive">{CONFIRMATION_TEXT}</strong>를 입력해주세요
              </label>
              <Input
                id="confirm"
                type="text"
                value={confirmText}
                onChange={(e) => setConfirmText(e.target.value)}
                placeholder={CONFIRMATION_TEXT}
                disabled={submitting}
                aria-label="탈퇴 확인 텍스트"
              />
            </div>

            {/* 에러 메시지 */}
            {error && (
              <div className="rounded-lg bg-destructive/10 p-3 text-sm text-destructive">
                {error}
              </div>
            )}

            {/* 버튼 */}
            <div className="flex flex-col-reverse gap-3 sm:flex-row sm:justify-end">
              <Link href="/my">
                <Button
                  type="button"
                  variant="outline"
                  className="w-full sm:w-auto"
                  disabled={submitting}
                >
                  취소
                </Button>
              </Link>
              <Button
                type="submit"
                variant="destructive"
                className="w-full sm:w-auto"
                disabled={!isConfirmed || submitting}
              >
                {submitting ? "처리 중..." : "회원 탈퇴"}
              </Button>
            </div>
          </form>
        </CardContent>
      </Card>
    </div>
  );
}
