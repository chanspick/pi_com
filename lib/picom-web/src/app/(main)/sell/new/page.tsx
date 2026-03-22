"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import Image from "next/image";
import {
  ArrowLeft,
  ArrowRight,
  Check,
  ImagePlus,
  X,
  Loader2,
} from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent } from "@/components/ui/card";
import { Slider } from "@/components/ui/slider";
import { useAuth } from "@/hooks/use-auth";
import { useCreateSellRequest } from "@/hooks/use-sell-requests";
import { uploadImages, BUCKETS } from "@/lib/supabase/storage";
import {
  categoryLabels,
  getCategoryLabel,
  formatPrice,
} from "@/lib/utils";

// 카테고리 아이콘 매핑
const categoryIcons: Record<string, string> = {
  cpu: "🔲",
  gpu: "🎮",
  ram: "💾",
  ssd: "💿",
  mainboard: "🔧",
  power: "⚡",
  case: "🖥️",
  cooler: "❄️",
};

// 스텝 제목
const stepTitles = [
  "카테고리 선택",
  "부품 정보",
  "사진 업로드",
  "가격/확인",
];

interface FormData {
  category: string;
  title: string;
  description: string;
  conditionScore: number;
  isSecondhand: boolean;
  hasWarranty: boolean;
  warrantyMonthsLeft: number;
  images: File[];
  imagePreviewUrls: string[];
  desiredPrice: string;
}

const initialFormData: FormData = {
  category: "",
  title: "",
  description: "",
  conditionScore: 7,
  isSecondhand: true,
  hasWarranty: false,
  warrantyMonthsLeft: 0,
  images: [],
  imagePreviewUrls: [],
  desiredPrice: "",
};

export default function SellNewPage() {
  const router = useRouter();
  const { user, loading: authLoading } = useAuth();
  const createMutation = useCreateSellRequest();

  const [step, setStep] = useState(1);
  const [formData, setFormData] = useState<FormData>(initialFormData);
  const [isUploading, setIsUploading] = useState(false);
  const [uploadProgress, setUploadProgress] = useState({ completed: 0, total: 0 });

  // 로그인 필요
  if (!authLoading && !user) {
    router.push("/login");
    return null;
  }

  // 로딩 상태
  if (authLoading) {
    return (
      <div className="mx-auto max-w-2xl px-4 py-8">
        <div className="flex items-center justify-center py-20">
          <Loader2 className="h-8 w-8 animate-spin text-muted-foreground" />
        </div>
      </div>
    );
  }

  // 다음 스텝 진행 가능 여부
  const canProceed = (): boolean => {
    switch (step) {
      case 1:
        return formData.category !== "";
      case 2:
        return formData.title.trim().length > 0;
      case 3:
        return true; // 사진은 선택사항
      case 4:
        return true;
      default:
        return false;
    }
  };

  // 이미지 추가 핸들러
  const handleImageAdd = (e: React.ChangeEvent<HTMLInputElement>) => {
    const files = e.target.files;
    if (!files) return;

    const newFiles = Array.from(files);
    const remainingSlots = 5 - formData.images.length;
    const filesToAdd = newFiles.slice(0, remainingSlots);

    const newPreviewUrls = filesToAdd.map((file) =>
      URL.createObjectURL(file)
    );

    setFormData((prev) => ({
      ...prev,
      images: [...prev.images, ...filesToAdd],
      imagePreviewUrls: [...prev.imagePreviewUrls, ...newPreviewUrls],
    }));

    // input 초기화
    e.target.value = "";
  };

  // 이미지 삭제 핸들러
  const handleImageRemove = (index: number) => {
    URL.revokeObjectURL(formData.imagePreviewUrls[index]);
    setFormData((prev) => ({
      ...prev,
      images: prev.images.filter((_, i) => i !== index),
      imagePreviewUrls: prev.imagePreviewUrls.filter((_, i) => i !== index),
    }));
  };

  // 제출 핸들러
  const handleSubmit = async () => {
    if (!user) return;

    try {
      setIsUploading(true);

      // 이미지 업로드
      let imageUrls: string[] = [];
      if (formData.images.length > 0) {
        const basePath = `${user.id}/${Date.now()}`;
        const results = await uploadImages(
          BUCKETS.SELL_IMAGES,
          formData.images,
          basePath,
          (completed, total) => setUploadProgress({ completed, total })
        );
        imageUrls = results.map((r) => r.url);
      }

      // 판매 신청 생성
      const desiredPrice = formData.desiredPrice
        ? parseInt(formData.desiredPrice.replace(/[^0-9]/g, ""), 10)
        : undefined;

      await createMutation.mutateAsync({
        user_id: user.id,
        category: formData.category,
        title: formData.title,
        description: formData.description || undefined,
        desired_price: desiredPrice || undefined,
        images: imageUrls,
        specs: { condition_score: formData.conditionScore },
        is_secondhand: formData.isSecondhand,
        has_warranty: formData.hasWarranty,
        warranty_months_left: formData.hasWarranty
          ? formData.warrantyMonthsLeft
          : undefined,
      });

      router.push("/my/sell-requests?success=true");
    } catch {
      alert("판매 신청 중 오류가 발생했습니다. 다시 시도해 주세요.");
    } finally {
      setIsUploading(false);
    }
  };

  return (
    <div className="mx-auto max-w-2xl px-4 py-8">
      {/* 헤더 */}
      <div className="mb-6 flex items-center gap-3">
        <Link href="/my">
          <Button variant="ghost" size="icon">
            <ArrowLeft className="h-5 w-5" />
          </Button>
        </Link>
        <h1 className="text-xl font-bold">판매 신청</h1>
      </div>

      {/* 진행 표시 */}
      <div className="mb-8">
        <div className="flex items-center justify-between mb-2">
          {stepTitles.map((title, i) => (
            <div
              key={title}
              className="flex flex-col items-center gap-1"
            >
              <div
                className={`flex h-8 w-8 items-center justify-center rounded-full text-sm font-medium transition-colors ${
                  i + 1 <= step
                    ? "bg-primary text-primary-foreground"
                    : "bg-muted text-muted-foreground"
                }`}
              >
                {i + 1 < step ? (
                  <Check className="h-4 w-4" />
                ) : (
                  i + 1
                )}
              </div>
              <span
                className={`text-[11px] ${
                  i + 1 <= step
                    ? "text-foreground font-medium"
                    : "text-muted-foreground"
                }`}
              >
                {title}
              </span>
            </div>
          ))}
        </div>
        <div className="relative h-1 bg-muted rounded-full overflow-hidden">
          <div
            className="absolute inset-y-0 left-0 bg-primary rounded-full transition-all duration-300"
            style={{ width: `${((step - 1) / 3) * 100}%` }}
          />
        </div>
      </div>

      {/* Step 1: 카테고리 선택 */}
      {step === 1 && (
        <div>
          <h2 className="text-lg font-semibold mb-4">
            판매할 부품의 카테고리를 선택하세요
          </h2>
          <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
            {Object.entries(categoryLabels).map(([key, label]) => (
              <button
                key={key}
                type="button"
                onClick={() =>
                  setFormData((prev) => ({ ...prev, category: key }))
                }
                className={`flex flex-col items-center gap-2 rounded-[10px] border-2 p-4 transition-all hover:border-primary/50 ${
                  formData.category === key
                    ? "border-primary bg-primary/5 shadow-sm"
                    : "border-border"
                }`}
              >
                <span className="text-2xl">{categoryIcons[key]}</span>
                <span className="text-sm font-medium">{label}</span>
              </button>
            ))}
          </div>
        </div>
      )}

      {/* Step 2: 부품 정보 */}
      {step === 2 && (
        <div className="space-y-6">
          <h2 className="text-lg font-semibold">부품 정보를 입력하세요</h2>

          {/* 제목 */}
          <div className="space-y-2">
            <label className="text-sm font-medium" htmlFor="title">
              제품명 <span className="text-destructive">*</span>
            </label>
            <Input
              id="title"
              placeholder="예: RTX 4070 SUPER 12GB"
              value={formData.title}
              onChange={(e) =>
                setFormData((prev) => ({
                  ...prev,
                  title: e.target.value,
                }))
              }
            />
          </div>

          {/* 설명 */}
          <div className="space-y-2">
            <label className="text-sm font-medium" htmlFor="description">
              상세 설명
            </label>
            <textarea
              id="description"
              placeholder="제품의 상태, 사용 기간, 특이사항 등을 입력하세요"
              className="w-full min-h-[120px] rounded-[10px] border border-input bg-transparent px-3 py-2 text-sm placeholder:text-muted-foreground focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 outline-none resize-none"
              value={formData.description}
              onChange={(e) =>
                setFormData((prev) => ({
                  ...prev,
                  description: e.target.value,
                }))
              }
            />
          </div>

          {/* 상태 점수 */}
          <div className="space-y-3">
            <div className="flex items-center justify-between">
              <label className="text-sm font-medium">
                상태 점수
              </label>
              <span className="text-sm font-bold text-primary">
                {formData.conditionScore}점 / 10점
              </span>
            </div>
            <Slider
              value={[formData.conditionScore]}
              onValueChange={(value) =>
                setFormData((prev) => ({
                  ...prev,
                  conditionScore: (value as number[])[0],
                }))
              }
              min={1}
              max={10}
            />
            <div className="flex justify-between text-[11px] text-muted-foreground">
              <span>사용감 많음</span>
              <span>거의 새것</span>
            </div>
          </div>

          {/* 중고 여부 */}
          <div className="flex items-center justify-between rounded-[10px] border p-4">
            <div>
              <p className="text-sm font-medium">중고 제품인가요?</p>
              <p className="text-[12px] text-muted-foreground">
                새 제품인 경우 비활성화하세요
              </p>
            </div>
            <button
              type="button"
              onClick={() =>
                setFormData((prev) => ({
                  ...prev,
                  isSecondhand: !prev.isSecondhand,
                }))
              }
              className={`relative h-6 w-11 rounded-full transition-colors ${
                formData.isSecondhand ? "bg-primary" : "bg-muted"
              }`}
              role="switch"
              aria-checked={formData.isSecondhand}
              aria-label="중고 제품 여부"
            >
              <span
                className={`absolute top-0.5 left-0.5 h-5 w-5 rounded-full bg-white shadow transition-transform ${
                  formData.isSecondhand ? "translate-x-5" : "translate-x-0"
                }`}
              />
            </button>
          </div>

          {/* 보증 여부 */}
          <div className="space-y-3">
            <div className="flex items-center justify-between rounded-[10px] border p-4">
              <div>
                <p className="text-sm font-medium">보증 기간이 남아있나요?</p>
                <p className="text-[12px] text-muted-foreground">
                  제조사 보증 기간이 남아있는 경우 활성화하세요
                </p>
              </div>
              <button
                type="button"
                onClick={() =>
                  setFormData((prev) => ({
                    ...prev,
                    hasWarranty: !prev.hasWarranty,
                    warrantyMonthsLeft: !prev.hasWarranty
                      ? prev.warrantyMonthsLeft
                      : 0,
                  }))
                }
                className={`relative h-6 w-11 rounded-full transition-colors ${
                  formData.hasWarranty ? "bg-primary" : "bg-muted"
                }`}
                role="switch"
                aria-checked={formData.hasWarranty}
                aria-label="보증 기간 여부"
              >
                <span
                  className={`absolute top-0.5 left-0.5 h-5 w-5 rounded-full bg-white shadow transition-transform ${
                    formData.hasWarranty ? "translate-x-5" : "translate-x-0"
                  }`}
                />
              </button>
            </div>

            {formData.hasWarranty && (
              <div className="space-y-2 pl-4">
                <label
                  className="text-sm font-medium"
                  htmlFor="warrantyMonths"
                >
                  남은 보증 기간 (개월)
                </label>
                <Input
                  id="warrantyMonths"
                  type="number"
                  min={0}
                  max={120}
                  placeholder="예: 12"
                  value={
                    formData.warrantyMonthsLeft > 0
                      ? formData.warrantyMonthsLeft
                      : ""
                  }
                  onChange={(e) =>
                    setFormData((prev) => ({
                      ...prev,
                      warrantyMonthsLeft: parseInt(e.target.value, 10) || 0,
                    }))
                  }
                />
              </div>
            )}
          </div>
        </div>
      )}

      {/* Step 3: 사진 업로드 */}
      {step === 3 && (
        <div className="space-y-4">
          <h2 className="text-lg font-semibold">사진을 업로드하세요</h2>
          <p className="text-sm text-muted-foreground">
            최대 5장까지 업로드할 수 있습니다. 깨끗하고 밝은 사진이
            판매에 도움됩니다.
          </p>

          {/* 이미지 그리드 */}
          <div className="grid grid-cols-3 gap-3 sm:grid-cols-5">
            {/* 업로드 버튼 */}
            {formData.images.length < 5 && (
              <label
                className="flex aspect-square cursor-pointer flex-col items-center justify-center gap-1 rounded-[10px] border-2 border-dashed border-border bg-muted/30 transition-colors hover:border-primary/50 hover:bg-muted/50"
                htmlFor="image-upload"
              >
                <ImagePlus className="h-6 w-6 text-muted-foreground" />
                <span className="text-[11px] text-muted-foreground">
                  {formData.images.length}/5
                </span>
                <input
                  id="image-upload"
                  type="file"
                  accept="image/*"
                  multiple
                  className="hidden"
                  onChange={handleImageAdd}
                />
              </label>
            )}

            {/* 미리보기 이미지 */}
            {formData.imagePreviewUrls.map((url, index) => (
              <div key={url} className="relative aspect-square">
                <Image
                  src={url}
                  alt={`업로드 이미지 ${index + 1}`}
                  fill
                  className="rounded-[10px] object-cover"
                  sizes="(max-width: 640px) 33vw, 20vw"
                />
                {index === 0 && (
                  <Badge
                    variant="default"
                    className="absolute left-1 top-1 text-[10px] px-1.5"
                  >
                    대표
                  </Badge>
                )}
                <button
                  type="button"
                  onClick={() => handleImageRemove(index)}
                  className="absolute -right-1.5 -top-1.5 flex h-5 w-5 items-center justify-center rounded-full bg-destructive text-white shadow-sm"
                  aria-label={`이미지 ${index + 1} 삭제`}
                >
                  <X className="h-3 w-3" />
                </button>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Step 4: 가격/확인 */}
      {step === 4 && (
        <div className="space-y-6">
          <h2 className="text-lg font-semibold">희망 가격과 내용을 확인하세요</h2>

          {/* 희망 가격 */}
          <div className="space-y-2">
            <label className="text-sm font-medium" htmlFor="desiredPrice">
              희망 판매 가격
            </label>
            <div className="relative">
              <Input
                id="desiredPrice"
                type="text"
                inputMode="numeric"
                placeholder="0"
                className="pr-8"
                value={formData.desiredPrice}
                onChange={(e) => {
                  // 숫자만 입력 허용, 콤마 포맷
                  const raw = e.target.value.replace(/[^0-9]/g, "");
                  const formatted = raw
                    ? new Intl.NumberFormat("ko-KR").format(parseInt(raw, 10))
                    : "";
                  setFormData((prev) => ({
                    ...prev,
                    desiredPrice: formatted,
                  }));
                }}
              />
              <span className="absolute right-3 top-1/2 -translate-y-1/2 text-sm text-muted-foreground">
                원
              </span>
            </div>
            <p className="text-[12px] text-muted-foreground">
              입력하지 않으면 검수 후 적정 가격이 산정됩니다.
            </p>
          </div>

          {/* 미리보기 카드 */}
          <Card>
            <CardContent className="space-y-4">
              <h3 className="text-sm font-semibold text-muted-foreground">
                신청 내용 미리보기
              </h3>

              {/* 이미지 미리보기 */}
              {formData.imagePreviewUrls.length > 0 && (
                <div className="flex gap-2 overflow-x-auto pb-2">
                  {formData.imagePreviewUrls.map((url, i) => (
                    <div
                      key={url}
                      className="relative h-20 w-20 shrink-0 rounded-lg overflow-hidden"
                    >
                      <Image
                        src={url}
                        alt={`미리보기 ${i + 1}`}
                        fill
                        className="object-cover"
                        sizes="80px"
                      />
                    </div>
                  ))}
                </div>
              )}

              <div className="space-y-2">
                <div className="flex items-center gap-2">
                  <Badge variant="secondary">
                    {getCategoryLabel(formData.category)}
                  </Badge>
                  {formData.isSecondhand && (
                    <Badge variant="outline">중고</Badge>
                  )}
                  {formData.hasWarranty && (
                    <Badge variant="default">
                      보증 {formData.warrantyMonthsLeft}개월
                    </Badge>
                  )}
                </div>

                <h4 className="text-base font-bold">{formData.title}</h4>

                {formData.description && (
                  <p className="text-sm text-muted-foreground line-clamp-3">
                    {formData.description}
                  </p>
                )}

                <div className="flex items-center gap-4 text-sm">
                  <span className="text-muted-foreground">
                    상태: {formData.conditionScore}점/10
                  </span>
                </div>

                {formData.desiredPrice && (
                  <p className="text-lg font-bold text-primary">
                    {formatPrice(
                      parseInt(
                        formData.desiredPrice.replace(/[^0-9]/g, ""),
                        10
                      )
                    )}
                  </p>
                )}
              </div>
            </CardContent>
          </Card>
        </div>
      )}

      {/* 하단 네비게이션 */}
      <div className="mt-8 flex items-center gap-3">
        {step > 1 && (
          <Button
            variant="outline"
            className="flex-1"
            onClick={() => setStep((s) => s - 1)}
            disabled={isUploading}
          >
            <ArrowLeft className="h-4 w-4" />
            이전
          </Button>
        )}

        {step < 4 ? (
          <Button
            className="flex-1"
            onClick={() => setStep((s) => s + 1)}
            disabled={!canProceed()}
          >
            다음
            <ArrowRight className="h-4 w-4" />
          </Button>
        ) : (
          <Button
            className="flex-1"
            onClick={handleSubmit}
            disabled={isUploading || createMutation.isPending}
          >
            {isUploading ? (
              <>
                <Loader2 className="h-4 w-4 animate-spin" />
                업로드 중 ({uploadProgress.completed}/{uploadProgress.total})
              </>
            ) : createMutation.isPending ? (
              <>
                <Loader2 className="h-4 w-4 animate-spin" />
                신청 중...
              </>
            ) : (
              <>
                <Check className="h-4 w-4" />
                판매 신청하기
              </>
            )}
          </Button>
        )}
      </div>
    </div>
  );
}
