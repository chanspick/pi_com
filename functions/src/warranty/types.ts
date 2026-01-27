/**
 * Warranty System Types v2
 * QR 기반 AS 보증 시스템 타입 정의
 *
 * v2 변경사항:
 * - 풀세트(조립PC) 지원: transactionType, items, bundleName
 * - 벤치마크 기반 스코어: benchmarkScores, conditionGrade, conditionScore (1-100)
 * - 스코어 기반 기본 AS: baseWarrantyMonths
 * - 원가 관리: purchaseCost, profitMargin
 * - 보증서 PDF: warrantyPdfUrl
 */

import * as admin from "firebase-admin";

// ============================================================================
// Verification Transaction (검증 거래)
// ============================================================================

export type TransactionStatus =
  | "registered"      // 거래 등록됨
  | "qrGenerated"     // QR 코드 생성됨
  | "reportIssued"    // 검증 레포트 발행됨
  | "delivered"       // 고객에게 전달됨
  | "warrantyActive"; // 보증 활성화됨

export type TransactionType = "single" | "bundle";

export type ConditionGrade = "S" | "A" | "B" | "C" | "D";

// 벤치마크 점수 구조
export interface BenchmarkScores {
  cpu?: number;        // PassMark 점수
  gpu?: number;        // 3DMark 점수
  storage?: number;    // 읽기/쓰기 속도 (MB/s)
  memory?: number;     // 메모리 대역폭
  overall?: number;    // 종합 점수 (자동 계산)
}

// 풀세트 내 개별 부품
export interface TransactionItem {
  itemId: string;
  partCategory: string;
  brand: string;
  modelName: string;
  serialNumber?: string | null;
  benchmarkScore?: number;     // 해당 부품의 벤치마크 점수
  conditionScore: number;      // 1-100
  purchaseCost: number;        // 매입원가
  photoUrls: string[];
}

export interface VerificationTransaction {
  transactionId: string;       // VTX-YYYYMMDD-XXXXX
  qrCode: string;              // UUID (QR 고유값)

  // 🆕 거래 타입
  transactionType: TransactionType;  // 'single' | 'bundle'

  // 단일 부품용 (transactionType === 'single')
  partCategory?: string | null;      // CPU, GPU, Mainboard 등
  brand?: string | null;
  modelName?: string | null;
  serialNumber?: string | null;
  photoUrls: string[];

  // 🆕 풀세트용 (transactionType === 'bundle')
  items?: TransactionItem[];
  bundleName?: string | null;        // "게이밍 PC 세트" 등

  // 검수 정보
  inspectorId: string;
  inspectorName: string;
  inspectedAt: admin.firestore.Timestamp;
  inspectionNote: string;
  inspectionPhotoUrls: string[];

  // 🆕 벤치마크 기반 스코어
  benchmarkScores?: BenchmarkScores;
  conditionGrade: ConditionGrade;    // 자동 산정된 등급 (S/A/B/C/D)
  conditionScore: number;            // 1-100 (자동 산정, 기존 1-10에서 변경)

  // 🆕 가격 정보
  purchaseCost: number;              // 매입원가
  salePrice: number;                 // 판매가
  profitMargin?: number;             // 마진율 (자동 계산)

  // 🆕 기본 보증 (스코어 기반 자동 결정)
  baseWarrantyMonths: number;        // 스코어에 따라 자동 결정

  // B2B 거래 정보
  buyerCompanyName?: string | null;
  buyerContactName?: string | null;
  buyerContactPhone?: string | null;
  saleDate: admin.firestore.Timestamp;

  // 문서 정보
  verificationReportUrl?: string | null;
  warrantyPdfUrl?: string | null;    // 🆕 보증서 PDF
  qrCodeImageUrl?: string | null;

  // 상태
  status: TransactionStatus;
  warrantyId?: string | null;

  // 타임스탬프
  createdAt: admin.firestore.Timestamp;
  updatedAt: admin.firestore.Timestamp;
}

// ============================================================================
// Warranty (AS 보증) - v2
// ============================================================================

export type WarrantyPlan = "1year" | "2year";

export type WarrantyStatus =
  | "pending"    // 결제 대기
  | "active"     // 활성화 (보증 유효)
  | "expired"    // 만료됨
  | "claimed"    // AS 신청됨 (처리 중)
  | "completed"; // AS 완료됨

export interface Warranty {
  warrantyId: string;          // WRT-YYYYMMDD-XXXXX
  transactionId: string;
  qrCode: string;

  // 🆕 기본 보증 (스코어 기반 자동 결정)
  baseWarrantyMonths: number;       // 스코어에 따라 자동 결정
  baseWarrantyEndDate: admin.firestore.Timestamp;

  // 🆕 추가 보증 (고객 결제)
  additionalWarrantyMonths?: number;   // 추가 구매한 개월 수 (12 or 24)
  additionalWarrantyPrice?: number;    // 추가 결제 금액
  additionalWarrantyPaidAt?: admin.firestore.Timestamp;

  // 최종 보증 정보
  totalWarrantyMonths: number;         // 기본 + 추가
  totalWarrantyEndDate: admin.firestore.Timestamp;

  // 기존 보증 정보 (호환성 유지)
  warrantyPlan?: WarrantyPlan;
  warrantyPeriodMonths?: number; // deprecated, use totalWarrantyMonths
  startDate: admin.firestore.Timestamp;
  endDate: admin.firestore.Timestamp;  // alias for totalWarrantyEndDate

  // 결제 정보 (추가 보증용)
  warrantyPrice?: number;      // deprecated
  warrantyRate?: number;       // deprecated
  paymentMethod?: string;      // kakaopay, tosspay
  paymentKey?: string;
  paidAt?: admin.firestore.Timestamp;

  // 고객 정보
  customerName: string;
  customerPhone: string;
  customerEmail?: string | null;

  // 상태
  status: WarrantyStatus;
  serviceRequestIds: string[];

  // 타임스탬프
  createdAt: admin.firestore.Timestamp;
  updatedAt: admin.firestore.Timestamp;
}

// ============================================================================
// Service Request (AS 요청)
// ============================================================================

export type ServiceType = "repair" | "replacement" | "inspection";

export type ServiceRequestStatus =
  | "pending"         // 신청됨
  | "reviewing"       // 검토 중
  | "approved"        // 승인됨
  | "rejected"        // 거부됨
  | "itemShipping"    // 부품 발송 중
  | "itemReceived"    // 부품 수령됨
  | "repairing"       // 수리 중
  | "repaired"        // 수리 완료
  | "returnShipping"  // 반송 중
  | "completed";      // 완료

export interface ServiceRequest {
  requestId: string;           // SVC-YYYYMMDD-XXXXX
  warrantyId: string;
  transactionId: string;

  // 신청 정보
  serviceType: ServiceType;
  issueDescription: string;
  issuePhotoUrls: string[];

  // 고객 정보
  customerName: string;
  customerPhone: string;
  shippingAddress: string;

  // 처리 정보
  status: ServiceRequestStatus;
  handlerId?: string;
  handlerNote?: string;

  // 배송 정보
  inboundTrackingNumber?: string;
  outboundTrackingNumber?: string;

  // 타임스탬프
  requestedAt: admin.firestore.Timestamp;
  completedAt?: admin.firestore.Timestamp;
  createdAt: admin.firestore.Timestamp;
  updatedAt: admin.firestore.Timestamp;
}

// ============================================================================
// API Request/Response Types - v2
// ============================================================================

// 풀세트 부품 아이템 요청
export interface TransactionItemRequest {
  partCategory: string;
  brand: string;
  modelName: string;
  serialNumber?: string;
  benchmarkScore?: number;
  purchaseCost: number;
  photoUrls?: string[];
}

export interface CreateTransactionRequest {
  // 🆕 거래 타입
  transactionType: TransactionType;  // 'single' | 'bundle'

  // 단일 부품용 (transactionType === 'single')
  partCategory?: string;
  brand?: string;
  modelName?: string;
  serialNumber?: string;
  benchmarkScore?: number;     // 단일 부품의 벤치마크 점수
  photoUrls?: string[];

  // 🆕 풀세트용 (transactionType === 'bundle')
  bundleName?: string;
  items?: TransactionItemRequest[];

  // 🆕 벤치마크 점수 (개별 입력)
  benchmarkScores?: {
    cpu?: number;
    gpu?: number;
    storage?: number;
    memory?: number;
  };

  // 🆕 가격 정보
  purchaseCost: number;        // 총 매입원가
  salePrice: number;           // 판매가

  // 검수 정보
  inspectorId: string;
  inspectorName: string;
  inspectionNote?: string;
  inspectionPhotoUrls?: string[];

  // B2B 거래 정보
  buyerCompanyName?: string;
  buyerContactName?: string;
  buyerContactPhone?: string;
}

// 거래 등록 응답 (v2)
export interface CreateTransactionResponse {
  success: boolean;
  transactionId: string;
  qrCode: string;
  conditionScore: number;      // 자동 산정 (1-100)
  conditionGrade: ConditionGrade;  // 자동 산정 (S/A/B/C/D)
  baseWarrantyMonths: number;  // 스코어 기반 자동 결정
  message?: string;
}

// 기존 보증 결제 요청 (호환성 유지)
export interface WarrantyPaymentRequest {
  qrCode: string;
  warrantyPlan: WarrantyPlan;
  customerName: string;
  customerPhone: string;
  customerEmail?: string;
  paymentMethod: "kakaopay" | "tosspay";
}

export interface WarrantyPaymentPrepareResponse {
  warrantyId: string;
  transactionId: string;
  warrantyPrice: number;
  // 결제 SDK 응답
  tid?: string;           // 카카오페이
  paymentKey?: string;    // 토스페이
  redirectUrl: string;
}

// 🆕 추가 보증 결제 요청 (v2)
export interface AdditionalWarrantyPaymentRequest {
  qrCode: string;
  additionalMonths: 12 | 24;   // 추가 구매할 개월 수
  customerName: string;
  customerPhone: string;
  customerEmail?: string;
  paymentMethod: "kakaopay" | "tosspay";
}

// 🆕 추가 보증 결제 응답 (v2)
export interface AdditionalWarrantyPaymentResponse {
  warrantyId: string;
  baseWarrantyMonths: number;
  additionalWarrantyMonths: number;
  totalWarrantyMonths: number;
  additionalPrice: number;     // 판매가 * rate
  // 결제 SDK 응답
  tid?: string;
  paymentKey?: string;
  redirectUrl: string;
}

export interface ServiceRequestCreate {
  warrantyId: string;
  serviceType: ServiceType;
  issueDescription: string;
  issuePhotoUrls?: string[];
  customerName: string;
  customerPhone: string;
  shippingAddress: string;
}

// ============================================================================
// Warranty Rate Configuration (v2)
// ============================================================================

// 기존 보증 요금 (호환성 유지)
export const WARRANTY_RATES: Record<WarrantyPlan, { months: number; rate: number }> = {
  "1year": { months: 12, rate: 0.10 },
  "2year": { months: 24, rate: 0.20 },
};

// 🆕 추가 보증 요금률 (v2)
export const ADDITIONAL_WARRANTY_RATES: Record<12 | 24, { months: number; rate: number }> = {
  12: { months: 12, rate: 0.10 },  // +1년: 판매가의 10%
  24: { months: 24, rate: 0.20 },  // +2년: 판매가의 20%
};

// ============================================================================
// 등급별 기준 (conditionScore 1-100) - v2
// ============================================================================

export interface GradeConfig {
  min: number;
  max: number;
  baseWarrantyMonths: number;
  label: string;
  labelKo: string;
}

export const GRADE_THRESHOLDS: Record<ConditionGrade, GradeConfig> = {
  S: { min: 90, max: 100, baseWarrantyMonths: 24, label: "Excellent", labelKo: "최상급" },
  A: { min: 80, max: 89, baseWarrantyMonths: 18, label: "Very Good", labelKo: "우수" },
  B: { min: 70, max: 79, baseWarrantyMonths: 12, label: "Good", labelKo: "양호" },
  C: { min: 60, max: 69, baseWarrantyMonths: 6, label: "Fair", labelKo: "보통" },
  D: { min: 0, max: 59, baseWarrantyMonths: 3, label: "Poor", labelKo: "불량" },
};

// ============================================================================
// 부품 카테고리별 벤치마크 기준 - v2
// ============================================================================

export interface BenchmarkConfig {
  maxScore: number;       // 100점 기준 벤치마크
  minScore: number;       // 50점 기준 벤치마크
  unit: string;
}

export const BENCHMARK_CONFIG: Record<string, BenchmarkConfig> = {
  cpu: { maxScore: 40000, minScore: 10000, unit: "PassMark" },
  gpu: { maxScore: 20000, minScore: 5000, unit: "3DMark" },
  storage: { maxScore: 7000, minScore: 500, unit: "MB/s" },
  memory: { maxScore: 50000, minScore: 20000, unit: "MB/s" },
};

// ============================================================================
// ID Generation Helpers
// ============================================================================

export function generateTransactionId(): string {
  const date = new Date();
  const dateStr = date.toISOString().slice(0, 10).replace(/-/g, "");
  const random = Math.random().toString(36).substring(2, 7).toUpperCase();
  return `VTX-${dateStr}-${random}`;
}

export function generateWarrantyId(): string {
  const date = new Date();
  const dateStr = date.toISOString().slice(0, 10).replace(/-/g, "");
  const random = Math.random().toString(36).substring(2, 7).toUpperCase();
  return `WRT-${dateStr}-${random}`;
}

export function generateServiceRequestId(): string {
  const date = new Date();
  const dateStr = date.toISOString().slice(0, 10).replace(/-/g, "");
  const random = Math.random().toString(36).substring(2, 7).toUpperCase();
  return `SVC-${dateStr}-${random}`;
}

export function generateQRCode(): string {
  // UUID v4 형식
  return "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".replace(/[xy]/g, (c) => {
    const r = Math.random() * 16 | 0;
    const v = c === "x" ? r : (r & 0x3 | 0x8);
    return v.toString(16);
  });
}
