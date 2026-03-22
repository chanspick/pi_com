import { clsx, type ClassValue } from "clsx"
import { twMerge } from "tailwind-merge"

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}

// 가격 포맷 (1234567 -> "1,234,567원")
export function formatPrice(price: number): string {
  return new Intl.NumberFormat("ko-KR").format(price) + "원";
}

// 간결한 가격 포맷 (12000 -> "1.2만원", 1234567 -> "123.5만원")
export function formatCompactPrice(price: number): string {
  if (price >= 10000) {
    const man = price / 10000;
    return (man % 1 === 0 ? man.toFixed(0) : man.toFixed(1)) + "만원";
  }
  if (price >= 1000) {
    return (price / 1000).toFixed(0) + "천원";
  }
  return price + "원";
}

// 상대 시간 포맷 ("3시간 전", "2일 전", "1주 전")
export function formatRelativeTime(dateStr: string): string {
  const now = new Date();
  const date = new Date(dateStr);
  const diffMs = now.getTime() - date.getTime();
  const diffMin = Math.floor(diffMs / 60000);
  const diffHour = Math.floor(diffMs / 3600000);
  const diffDay = Math.floor(diffMs / 86400000);

  if (diffMin < 1) return "방금 전";
  if (diffMin < 60) return diffMin + "분 전";
  if (diffHour < 24) return diffHour + "시간 전";
  if (diffDay < 7) return diffDay + "일 전";
  if (diffDay < 30) return Math.floor(diffDay / 7) + "주 전";
  if (diffDay < 365) return Math.floor(diffDay / 30) + "개월 전";
  return Math.floor(diffDay / 365) + "년 전";
}

// 날짜 포맷 ("2026.03.21")
export function formatDate(dateStr: string): string {
  const d = new Date(dateStr);
  return d.getFullYear() + "." + String(d.getMonth() + 1).padStart(2, "0") + "." + String(d.getDate()).padStart(2, "0");
}

// 카테고리 한글 라벨
export const categoryLabels: Record<string, string> = {
  cpu: "CPU",
  gpu: "GPU",
  ram: "RAM",
  ssd: "SSD",
  mainboard: "메인보드",
  power: "파워",
  case: "케이스",
  cooler: "쿨러",
};

// 카테고리 영문 -> 한글
export function getCategoryLabel(category: string): string {
  return categoryLabels[category] || category;
}

// 상태 한글 라벨
export const statusLabels: Record<string, string> = {
  active: "판매중",
  sold: "판매완료",
  reserved: "예약중",
  draft: "임시저장",
  expired: "만료",
  deleted: "삭제됨",
};

export function getStatusLabel(status: string): string {
  return statusLabels[status] || status;
}

// 가격 변동률 계산
export function calcPriceChange(current: number, previous: number): { percent: number; direction: "up" | "down" | "same" } {
  if (previous === 0) return { percent: 0, direction: "same" };
  const percent = ((current - previous) / previous) * 100;
  const direction = percent > 0 ? "up" : percent < 0 ? "down" : "same";
  return { percent: Math.abs(Math.round(percent * 10) / 10), direction };
}
