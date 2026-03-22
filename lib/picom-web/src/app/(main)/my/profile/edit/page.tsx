"use client";

import { useEffect, useState, useRef } from "react";
import { useRouter } from "next/navigation";
import { useAuth } from "@/hooks/use-auth";
import { useProfile, useUpdateProfile } from "@/hooks/use-profile";
import { Avatar, AvatarImage, AvatarFallback } from "@/components/ui/avatar";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Card, CardHeader, CardTitle, CardContent } from "@/components/ui/card";
import { Separator } from "@/components/ui/separator";
import { Skeleton } from "@/components/ui/skeleton";
import { ArrowLeft, Camera, Loader2, Check } from "lucide-react";
import { uploadImage, BUCKETS } from "@/lib/supabase/storage";

export default function ProfileEditPage() {
  const router = useRouter();
  const { user, loading: authLoading } = useAuth();
  const { profile, isLoading: profileLoading } = useProfile(user?.id);
  const updateProfileMutation = useUpdateProfile();

  const fileInputRef = useRef<HTMLInputElement>(null);

  // 폼 상태
  const [displayName, setDisplayName] = useState("");
  const [avatarUrl, setAvatarUrl] = useState<string | null>(null);
  const [avatarPreview, setAvatarPreview] = useState<string | null>(null);
  const [isUploading, setIsUploading] = useState(false);
  const [saveSuccess, setSaveSuccess] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  // 프로필 데이터 로드 시 폼 초기화
  useEffect(() => {
    if (profile) {
      setDisplayName(
        profile.display_name || user?.user_metadata?.full_name || ""
      );
      setAvatarUrl(profile.avatar_url || user?.user_metadata?.avatar_url || null);
    } else if (user && !profileLoading) {
      setDisplayName(user.user_metadata?.full_name || user.email?.split("@")[0] || "");
      setAvatarUrl(user.user_metadata?.avatar_url || null);
    }
  }, [profile, user, profileLoading]);

  // 비로그인 사용자 리다이렉트
  useEffect(() => {
    if (!authLoading && !user) {
      router.replace("/login");
    }
  }, [authLoading, user, router]);

  // 아바타 파일 선택 핸들러
  const handleAvatarChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file || !user) return;

    // 미리보기
    const previewUrl = URL.createObjectURL(file);
    setAvatarPreview(previewUrl);

    // 업로드
    setIsUploading(true);
    setErrorMessage(null);
    try {
      const result = await uploadImage(
        BUCKETS.PROFILE_AVATARS,
        file,
        user.id,
        { compress: true, maxWidth: 400, quality: 0.85 }
      );
      setAvatarUrl(result.url);
    } catch (err) {
      setErrorMessage(
        err instanceof Error ? err.message : "아바타 업로드에 실패했습니다."
      );
      setAvatarPreview(null);
    } finally {
      setIsUploading(false);
    }
  };

  // 저장 핸들러
  const handleSave = async () => {
    if (!user) return;

    setErrorMessage(null);
    setSaveSuccess(false);

    const updates: { display_name?: string; avatar_url?: string } = {};

    const trimmedName = displayName.trim();
    if (trimmedName && trimmedName !== profile?.display_name) {
      updates.display_name = trimmedName;
    }

    if (avatarUrl && avatarUrl !== profile?.avatar_url) {
      updates.avatar_url = avatarUrl;
    }

    if (Object.keys(updates).length === 0) {
      // 변경사항 없음
      router.push("/my");
      return;
    }

    try {
      await updateProfileMutation.mutateAsync({
        userId: user.id,
        updates,
      });
      setSaveSuccess(true);
      setTimeout(() => {
        router.push("/my");
      }, 800);
    } catch (err) {
      setErrorMessage(
        err instanceof Error ? err.message : "프로필 저장에 실패했습니다."
      );
    }
  };

  // 로딩 중
  if (authLoading || !user) {
    return (
      <div className="container mx-auto max-w-lg px-4 py-8 space-y-6">
        <Skeleton className="h-8 w-32" />
        <Card>
          <CardContent className="space-y-6 pt-2">
            <div className="flex justify-center">
              <Skeleton className="h-24 w-24 rounded-full" />
            </div>
            <Skeleton className="h-10 w-full" />
            <Skeleton className="h-10 w-full" />
          </CardContent>
        </Card>
      </div>
    );
  }

  const currentAvatar = avatarPreview || avatarUrl;
  const currentName =
    displayName ||
    user.user_metadata?.full_name ||
    user.email?.split("@")[0] ||
    "U";
  const isSaving = updateProfileMutation.isPending;

  return (
    <div className="container mx-auto max-w-lg px-4 py-8 space-y-6">
      {/* 헤더 */}
      <div className="flex items-center gap-3">
        <Button
          variant="ghost"
          size="icon"
          onClick={() => router.push("/my")}
          aria-label="뒤로 가기"
        >
          <ArrowLeft className="h-5 w-5" />
        </Button>
        <h1 className="text-xl font-bold">프로필 수정</h1>
      </div>

      <Card>
        <CardContent className="space-y-6 pt-2">
          {/* 아바타 수정 */}
          <div className="flex flex-col items-center gap-3">
            <div className="relative">
              <Avatar className="h-24 w-24 text-3xl">
                <AvatarImage
                  src={currentAvatar ?? undefined}
                  alt={currentName}
                />
                <AvatarFallback className="bg-primary/10 text-primary text-2xl font-bold">
                  {currentName[0]?.toUpperCase() || "U"}
                </AvatarFallback>
              </Avatar>
              <button
                type="button"
                className="absolute bottom-0 right-0 w-8 h-8 rounded-full bg-primary text-primary-foreground flex items-center justify-center shadow-md hover:bg-primary/90 transition-colors disabled:opacity-50"
                onClick={() => fileInputRef.current?.click()}
                disabled={isUploading}
                aria-label="아바타 변경"
              >
                {isUploading ? (
                  <Loader2 className="h-4 w-4 animate-spin" />
                ) : (
                  <Camera className="h-4 w-4" />
                )}
              </button>
              <input
                ref={fileInputRef}
                type="file"
                accept="image/jpeg,image/png,image/webp"
                className="hidden"
                onChange={handleAvatarChange}
              />
            </div>
            {isUploading && (
              <p className="text-xs text-muted-foreground">
                이미지 업로드 중...
              </p>
            )}
          </div>

          <Separator />

          {/* 닉네임 */}
          <div className="space-y-2">
            <label
              htmlFor="displayName"
              className="text-sm font-medium text-foreground"
            >
              닉네임
            </label>
            <Input
              id="displayName"
              value={displayName}
              onChange={(e) => setDisplayName(e.target.value)}
              placeholder="닉네임을 입력하세요"
              maxLength={30}
              className="h-10"
            />
            <p className="text-xs text-muted-foreground">
              다른 사용자에게 표시되는 이름입니다. (최대 30자)
            </p>
          </div>

          {/* 이메일 (읽기 전용) */}
          <div className="space-y-2">
            <label className="text-sm font-medium text-foreground">
              이메일
            </label>
            <Input
              value={user.email || ""}
              disabled
              className="h-10 bg-muted/50"
            />
            <p className="text-xs text-muted-foreground">
              이메일은 변경할 수 없습니다.
            </p>
          </div>

          {/* 에러 메시지 */}
          {errorMessage && (
            <div className="rounded-lg bg-destructive/10 text-destructive text-sm p-3">
              {errorMessage}
            </div>
          )}

          {/* 성공 메시지 */}
          {saveSuccess && (
            <div className="rounded-lg bg-green-50 dark:bg-green-900/20 text-green-700 dark:text-green-400 text-sm p-3 flex items-center gap-2">
              <Check className="h-4 w-4" />
              프로필이 저장되었습니다.
            </div>
          )}

          {/* 버튼 */}
          <div className="flex gap-3 pt-2">
            <Button
              variant="outline"
              className="flex-1"
              onClick={() => router.push("/my")}
              disabled={isSaving}
            >
              취소
            </Button>
            <Button
              className="flex-1"
              onClick={handleSave}
              disabled={isSaving || isUploading}
            >
              {isSaving ? (
                <>
                  <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                  저장 중...
                </>
              ) : (
                "저장"
              )}
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
