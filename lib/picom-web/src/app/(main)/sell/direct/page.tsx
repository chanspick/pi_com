"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import Image from "next/image";
import {
  ArrowLeft,
  ImagePlus,
  X,
  Loader2,
  Check,
  ShieldCheck,
} from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent } from "@/components/ui/card";
import { Slider } from "@/components/ui/slider";
import { useAuth } from "@/hooks/use-auth";
import { createClient } from "@/lib/supabase/client";
import { createListing } from "@/lib/supabase/queries";
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

// 상태 라벨
const conditionOptions = [
  { value: "new", label: "미개봉" },
  { value: "like_new", label: "거의 새것" },
  { value: "excellent", label: "상태 좋음" },
  { value: "good", label: "상태 양호" },
  { value: "fair", label: "사용감 있음" },
];

interface FormData {
  category: string;
  title: string;
  description: string;
  condition: string;
  conditionScore: number;
  price: string;
  originalPrice: string;
  images: File[];
  imagePreviewUrls: string[];
}

const initialFormData: FormData = {
  category: "",
  title: "",
  description: "",
  condition: "good",
  conditionScore: 7,
  price: "",
  originalPrice: "",
  images: [],
  imagePreviewUrls: [],
};

export default function SellDirectPage() {
  const router = useRouter();
  const { user, loading: authLoading } = useAuth();

  const [formData, setFormData] = useState<FormData>(initialFormData);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [uploadProgress, setUploadProgress] = useState({ completed: 0, total: 0 });
  const [errorMessage, setErrorMessage] = useState("");

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

  // 가격 파싱 유틸
  const parsePrice = (value: string): number => {
    return parseInt(value.replace(/[^0-9]/g, ""), 10) || 0;
  };

  // 가격 입력 포맷
  const formatPriceInput = (raw: string): string => {
    const digits = raw.replace(/[^0-9]/g, "");
    return digits
      ? new Intl.NumberFormat("ko-KR").format(parseInt(digits, 10))
      : "";
  };

  // 제출 가능 여부
  const canSubmit =
    formData.category !== "" &&
    formData.title.trim().length > 0 &&
    parsePrice(formData.price) > 0;

  // 제출 핸들러
  const handleSubmit = async () => {
    if (!user || !canSubmit) return;

    try {
      setIsSubmitting(true);
      setErrorMessage("");

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

      const price = parsePrice(formData.price);
      const originalPrice = parsePrice(formData.originalPrice);

      const supabase = createClient();
      const { listing, error } = await createListing(supabase, {
        seller_id: user.id,
        title: formData.title,
        price,
        category: formData.category,
        description: formData.description || undefined,
        original_price: originalPrice > 0 ? originalPrice : undefined,
        condition: formData.condition || undefined,
        condition_score: formData.conditionScore,
        images: imageUrls,
      });

      if (error) {
        throw error;
      }

      if (listing) {
        router.push(`/listings/${listing.id}`);
      }
    } catch (err) {
      setErrorMessage(
        "매물 등록 중 오류가 발생했습니다. 다시 시도해 주세요."
      );
    } finally {
      setIsSubmitting(false);
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
        <h1 className="text-xl font-bold">매물 직접 등록</h1>
      </div>

      {/* 인증 판매자 안내 */}
      <div className="mb-6 rounded-[10px] border border-emerald-500/20 bg-emerald-500/5 p-4 flex items-start gap-3">
        <ShieldCheck className="h-5 w-5 text-emerald-600 shrink-0 mt-0.5" />
        <div>
          <p className="text-[13px] font-semibold text-emerald-700 dark:text-emerald-400">
            인증 판매자 전용
          </p>
          <p className="text-[12px] text-muted-foreground mt-0.5">
            이 기능은 인증된 판매자만 사용할 수 있습니다. 등록된 매물은 즉시
            마켓에 노출됩니다.
          </p>
        </div>
      </div>

      {/* 폼 */}
      <div className="space-y-8">
        {/* 카테고리 선택 */}
        <div className="space-y-3">
          <label className="text-sm font-medium">
            카테고리 <span className="text-destructive">*</span>
          </label>
          <div className="grid grid-cols-4 gap-2">
            {Object.entries(categoryLabels).map(([key, label]) => (
              <button
                key={key}
                type="button"
                onClick={() =>
                  setFormData((prev) => ({ ...prev, category: key }))
                }
                className={`flex flex-col items-center gap-1.5 rounded-[10px] border-2 p-3 transition-all hover:border-primary/50 ${
                  formData.category === key
                    ? "border-primary bg-primary/5 shadow-sm"
                    : "border-border"
                }`}
              >
                <span className="text-xl">{categoryIcons[key]}</span>
                <span className="text-[12px] font-medium">{label}</span>
              </button>
            ))}
          </div>
        </div>

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
              setFormData((prev) => ({ ...prev, title: e.target.value }))
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

        {/* 상태 선택 */}
        <div className="space-y-3">
          <label className="text-sm font-medium">상태</label>
          <div className="flex flex-wrap gap-2">
            {conditionOptions.map((opt) => (
              <button
                key={opt.value}
                type="button"
                onClick={() =>
                  setFormData((prev) => ({ ...prev, condition: opt.value }))
                }
                className={`rounded-full border px-3 py-1.5 text-[12px] font-medium transition-all ${
                  formData.condition === opt.value
                    ? "border-primary bg-primary/10 text-primary"
                    : "border-border text-muted-foreground hover:border-primary/50"
                }`}
              >
                {opt.label}
              </button>
            ))}
          </div>
        </div>

        {/* 상태 점수 */}
        <div className="space-y-3">
          <div className="flex items-center justify-between">
            <label className="text-sm font-medium">상태 점수</label>
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

        {/* 가격 */}
        <div className="grid grid-cols-2 gap-4">
          <div className="space-y-2">
            <label className="text-sm font-medium" htmlFor="price">
              판매 가격 <span className="text-destructive">*</span>
            </label>
            <div className="relative">
              <Input
                id="price"
                type="text"
                inputMode="numeric"
                placeholder="0"
                className="pr-8"
                value={formData.price}
                onChange={(e) =>
                  setFormData((prev) => ({
                    ...prev,
                    price: formatPriceInput(e.target.value),
                  }))
                }
              />
              <span className="absolute right-3 top-1/2 -translate-y-1/2 text-sm text-muted-foreground">
                원
              </span>
            </div>
          </div>
          <div className="space-y-2">
            <label className="text-sm font-medium" htmlFor="originalPrice">
              정가 (선택)
            </label>
            <div className="relative">
              <Input
                id="originalPrice"
                type="text"
                inputMode="numeric"
                placeholder="0"
                className="pr-8"
                value={formData.originalPrice}
                onChange={(e) =>
                  setFormData((prev) => ({
                    ...prev,
                    originalPrice: formatPriceInput(e.target.value),
                  }))
                }
              />
              <span className="absolute right-3 top-1/2 -translate-y-1/2 text-sm text-muted-foreground">
                원
              </span>
            </div>
          </div>
        </div>

        {/* 사진 업로드 */}
        <div className="space-y-3">
          <label className="text-sm font-medium">
            사진 (최대 5장)
          </label>
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

        {/* 에러 메시지 */}
        {errorMessage && (
          <div className="rounded-[10px] border border-red-500/20 bg-red-500/5 p-3">
            <p className="text-[13px] text-red-600 dark:text-red-400">
              {errorMessage}
            </p>
          </div>
        )}

        {/* 제출 버튼 */}
        <Button
          className="w-full h-12 text-[15px] font-semibold"
          onClick={handleSubmit}
          disabled={!canSubmit || isSubmitting}
        >
          {isSubmitting ? (
            <>
              <Loader2 className="h-4 w-4 animate-spin" />
              {uploadProgress.total > 0
                ? `이미지 업로드 중 (${uploadProgress.completed}/${uploadProgress.total})`
                : "등록 중..."}
            </>
          ) : (
            <>
              <Check className="h-4 w-4" />
              매물 등록하기
            </>
          )}
        </Button>
      </div>
    </div>
  );
}
