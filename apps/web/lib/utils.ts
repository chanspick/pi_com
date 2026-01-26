/**
 * Utility Functions
 */

import { type ClassValue, clsx } from "clsx";
import { twMerge } from "tailwind-merge";

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

export function formatCurrency(amount: number): string {
  return new Intl.NumberFormat("ko-KR", {
    style: "currency",
    currency: "KRW",
    maximumFractionDigits: 0,
  }).format(amount);
}

// Firestore timestamp 또는 일반 Date/string 처리
type DateInput = string | Date | { _seconds: number; _nanoseconds: number } | { seconds: number; nanoseconds: number };

function parseDate(date: DateInput): Date {
  if (date instanceof Date) return date;
  if (typeof date === "string") return new Date(date);
  // Firestore timestamp object
  if ("_seconds" in date) return new Date(date._seconds * 1000);
  if ("seconds" in date) return new Date(date.seconds * 1000);
  return new Date();
}

export function formatDate(date: DateInput): string {
  const d = parseDate(date);
  return new Intl.DateTimeFormat("ko-KR", {
    year: "numeric",
    month: "long",
    day: "numeric",
  }).format(d);
}

export function formatDateShort(date: DateInput): string {
  const d = parseDate(date);
  return new Intl.DateTimeFormat("ko-KR", {
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).format(d);
}

export function formatPhoneNumber(phone: string): string {
  const cleaned = phone.replace(/\D/g, "");
  if (cleaned.length === 11) {
    return `${cleaned.slice(0, 3)}-${cleaned.slice(3, 7)}-${cleaned.slice(7)}`;
  }
  if (cleaned.length === 10) {
    return `${cleaned.slice(0, 3)}-${cleaned.slice(3, 6)}-${cleaned.slice(6)}`;
  }
  return phone;
}

export function getDaysRemaining(endDate: DateInput): number {
  const end = parseDate(endDate);
  const now = new Date();
  const diff = end.getTime() - now.getTime();
  return Math.ceil(diff / (1000 * 60 * 60 * 24));
}

export function getConditionLabel(score: number): string {
  if (score >= 9) return "최상";
  if (score >= 7) return "상";
  if (score >= 5) return "중상";
  if (score >= 3) return "중";
  return "하";
}

export function getConditionColor(score: number): string {
  if (score >= 8) return "text-green-600";
  if (score >= 6) return "text-blue-600";
  if (score >= 4) return "text-yellow-600";
  return "text-red-600";
}

export function getStatusLabel(status: string): string {
  const labels: Record<string, string> = {
    // Transaction status
    registered: "등록됨",
    qrGenerated: "QR 생성됨",
    reportIssued: "레포트 발행됨",
    delivered: "전달됨",
    warrantyActive: "보증 활성화",
    // Warranty status
    pending: "결제 대기",
    active: "보증 유효",
    expired: "만료됨",
    claimed: "AS 신청됨",
    completed: "완료됨",
    // Service request status
    reviewing: "검토 중",
    approved: "승인됨",
    rejected: "거부됨",
    itemShipping: "부품 발송 중",
    itemReceived: "부품 수령됨",
    repairing: "수리 중",
    repaired: "수리 완료",
    returnShipping: "반송 중",
  };
  return labels[status] || status;
}

export function getServiceTypeLabel(type: string): string {
  const labels: Record<string, string> = {
    repair: "수리",
    replacement: "교환",
    inspection: "점검",
  };
  return labels[type] || type;
}
