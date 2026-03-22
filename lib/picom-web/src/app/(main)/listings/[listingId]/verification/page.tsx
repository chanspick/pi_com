import { createClient } from "@/lib/supabase/server";
import { fetchListingById } from "@/lib/supabase/queries";
import { fetchVerificationResult } from "@/lib/supabase/queries";
import { notFound } from "next/navigation";
import Link from "next/link";
import type { Metadata } from "next";
import type { Json } from "@/types/database.types";
import { Badge } from "@/components/ui/badge";
import { Separator } from "@/components/ui/separator";

interface Props {
  params: Promise<{ listingId: string }>;
}

// 등급 설정
const gradeConfig: Record<
  string,
  { label: string; color: string; bgColor: string; warranty: string }
> = {
  S: {
    label: "검증완료",
    color: "text-emerald-700 dark:text-emerald-400",
    bgColor: "bg-emerald-500/10 border-emerald-500/20",
    warranty: "24개월",
  },
  A: {
    label: "우수",
    color: "text-blue-700 dark:text-blue-400",
    bgColor: "bg-blue-500/10 border-blue-500/20",
    warranty: "18개월",
  },
  B: {
    label: "양호",
    color: "text-sky-700 dark:text-sky-400",
    bgColor: "bg-sky-500/10 border-sky-500/20",
    warranty: "12개월",
  },
  C: {
    label: "보통",
    color: "text-orange-700 dark:text-orange-400",
    bgColor: "bg-orange-500/10 border-orange-500/20",
    warranty: "6개월",
  },
  D: {
    label: "주의",
    color: "text-red-700 dark:text-red-400",
    bgColor: "bg-red-500/10 border-red-500/20",
    warranty: "3개월",
  },
};

// 점수에 따른 프로그레스 바 색상
function getScoreColor(score: number): string {
  if (score >= 90) return "bg-emerald-500";
  if (score >= 75) return "bg-blue-500";
  if (score >= 60) return "bg-sky-500";
  if (score >= 40) return "bg-orange-500";
  return "bg-red-500";
}

// 벤치마크 항목 한글 라벨
const benchmarkLabels: Record<string, string> = {
  cpu: "CPU 점수",
  gpu: "GPU 점수",
  storage: "스토리지 점수",
  memory: "메모리 점수",
  overall: "종합 점수",
};

// 날짜 포맷
function formatDate(dateStr: string): string {
  return new Date(dateStr).toLocaleDateString("ko-KR", {
    year: "numeric",
    month: "long",
    day: "numeric",
  });
}

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { listingId } = await params;
  const supabase = await createClient();
  const { listing } = await fetchListingById(supabase, listingId);

  if (!listing) {
    return { title: "매물을 찾을 수 없습니다 - PiCom" };
  }

  const title = listing.base_parts?.name ?? listing.title;
  return {
    title: `${title} 검증 결과 - PiCom`,
    description: `${title}의 PiCom 검증 결과를 확인하세요.`,
  };
}

export default async function VerificationResultPage({ params }: Props) {
  const { listingId } = await params;
  const supabase = await createClient();

  const [{ listing }, { result }] = await Promise.all([
    fetchListingById(supabase, listingId),
    fetchVerificationResult(supabase, listingId),
  ]);

  if (!listing) {
    notFound();
  }

  const partName = listing.base_parts?.name ?? listing.title;

  // 검증 결과가 없는 경우
  if (!result) {
    return (
      <div className="container mx-auto max-w-3xl px-4 py-10">
        <div className="mb-6">
          <Link
            href={`/listings/${listingId}`}
            className="inline-flex items-center gap-1 text-[13px] text-muted-foreground hover:text-foreground transition-colors"
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              width="14"
              height="14"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth="2"
              strokeLinecap="round"
              strokeLinejoin="round"
            >
              <path d="m15 18-6-6 6-6" />
            </svg>
            매물 상세로
          </Link>
        </div>
        <div className="rounded-xl border bg-card p-8 text-center">
          <div className="mx-auto mb-4 flex h-16 w-16 items-center justify-center rounded-full bg-muted">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              width="28"
              height="28"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth="2"
              strokeLinecap="round"
              strokeLinejoin="round"
              className="text-muted-foreground"
            >
              <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10" />
            </svg>
          </div>
          <h1 className="text-[18px] font-bold mb-2">검증 결과가 아직 없습니다</h1>
          <p className="text-[14px] text-muted-foreground">
            이 매물은 아직 PiCom 검증이 진행되지 않았습니다.
          </p>
        </div>
      </div>
    );
  }

  const grade = gradeConfig[result.condition_grade] ?? gradeConfig["C"];
  const benchmarks = (result.benchmark_scores ?? {}) as Record<string, number>;
  const tempData = (result.temperature_data ?? {}) as Record<string, number | string>;
  const photos = result.inspection_photo_urls ?? [];

  return (
    <div className="container mx-auto max-w-3xl px-4 py-10">
      {/* 뒤로 가기 */}
      <div className="mb-6">
        <Link
          href={`/listings/${listingId}`}
          className="inline-flex items-center gap-1 text-[13px] text-muted-foreground hover:text-foreground transition-colors"
        >
          <svg
            xmlns="http://www.w3.org/2000/svg"
            width="14"
            height="14"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
          >
            <path d="m15 18-6-6 6-6" />
          </svg>
          매물 상세로
        </Link>
      </div>

      {/* 검증 결과 카드 */}
      <div className="rounded-xl border bg-card overflow-hidden">
        {/* 헤더: 등급 + 점수 */}
        <div className="p-6 border-b">
          <div className="flex items-center justify-between mb-4">
            <div>
              <p className="text-[13px] text-muted-foreground mb-1">검증 대상</p>
              <h1 className="text-[20px] font-bold">{partName}</h1>
            </div>
            <Badge className={`text-[14px] px-3 py-1 font-bold ${grade.bgColor} ${grade.color}`}>
              {result.condition_grade}등급 - {grade.label}
            </Badge>
          </div>

          {/* 상태 점수 */}
          <div className="space-y-2">
            <div className="flex items-center justify-between">
              <span className="text-[13px] font-medium">상태 점수</span>
              <span className="text-[20px] font-extrabold">
                {result.condition_score}
                <span className="text-[13px] font-normal text-muted-foreground">/100</span>
              </span>
            </div>
            <div className="h-3 w-full rounded-full bg-muted overflow-hidden">
              <div
                className={`h-full rounded-full transition-all ${getScoreColor(result.condition_score)}`}
                style={{ width: `${result.condition_score}%` }}
              />
            </div>
          </div>

          {/* 보증 기간 */}
          <div className="mt-4 flex items-center gap-2 text-[13px]">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              width="16"
              height="16"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth="2"
              strokeLinecap="round"
              strokeLinejoin="round"
              className="text-emerald-600"
            >
              <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10" />
            </svg>
            <span className="text-muted-foreground">등급별 보증기간:</span>
            <span className="font-semibold">{grade.warranty}</span>
          </div>
        </div>

        {/* 벤치마크 점수 */}
        {Object.keys(benchmarks).length > 0 && (
          <div className="p-6 border-b">
            <h2 className="text-[15px] font-bold mb-4">벤치마크 점수</h2>
            <div className="space-y-3">
              {Object.entries(benchmarks).map(([key, value]) => (
                <div key={key} className="flex items-center justify-between text-[13px]">
                  <span className="text-muted-foreground">
                    {benchmarkLabels[key] ?? key}
                  </span>
                  <span className="font-semibold">{String(value)}</span>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* 온도 데이터 */}
        {Object.keys(tempData).length > 0 && (
          <div className="p-6 border-b">
            <h2 className="text-[15px] font-bold mb-4">온도 데이터</h2>
            <div className="space-y-3">
              {Object.entries(tempData).map(([key, value]) => (
                <div key={key} className="flex items-center justify-between text-[13px]">
                  <span className="text-muted-foreground">{key}</span>
                  <span className="font-semibold">
                    {typeof value === "number" ? `${value}°C` : String(value)}
                  </span>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* 팬 상태 */}
        {result.fan_status && (
          <div className="p-6 border-b">
            <h2 className="text-[15px] font-bold mb-2">팬 상태</h2>
            <p className="text-[13px] text-muted-foreground">{result.fan_status}</p>
          </div>
        )}

        {/* 검수자 정보 */}
        <div className="p-6 border-b">
          <h2 className="text-[15px] font-bold mb-3">검수 정보</h2>
          <div className="grid grid-cols-2 gap-3 text-[13px]">
            {result.inspector_name && (
              <div>
                <span className="text-muted-foreground">검수자</span>
                <p className="font-medium mt-0.5">{result.inspector_name}</p>
              </div>
            )}
            {result.inspected_at && (
              <div>
                <span className="text-muted-foreground">검수일</span>
                <p className="font-medium mt-0.5">{formatDate(result.inspected_at)}</p>
              </div>
            )}
          </div>
        </div>

        {/* 검수 사진 */}
        {photos.length > 0 && (
          <div className="p-6 border-b">
            <h2 className="text-[15px] font-bold mb-4">검수 사진</h2>
            <div className="grid grid-cols-2 sm:grid-cols-3 gap-3">
              {photos.map((url, idx) => (
                <div
                  key={idx}
                  className="aspect-square rounded-lg border overflow-hidden bg-muted"
                >
                  {/* eslint-disable-next-line @next/next/no-img-element */}
                  <img
                    src={url}
                    alt={`검수 사진 ${idx + 1}`}
                    className="h-full w-full object-cover"
                  />
                </div>
              ))}
            </div>
          </div>
        )}

        {/* 검수 노트 */}
        {result.inspection_note && (
          <div className="p-6">
            <h2 className="text-[15px] font-bold mb-2">검수 소견</h2>
            <p className="text-[13px] text-muted-foreground leading-relaxed whitespace-pre-wrap">
              {result.inspection_note}
            </p>
          </div>
        )}
      </div>
    </div>
  );
}
