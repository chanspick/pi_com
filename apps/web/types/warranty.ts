/**
 * Warranty System Types v2
 */

export type TransactionStatus =
  | "registered"
  | "qrGenerated"
  | "reportIssued"
  | "delivered"
  | "warrantyActive";

export type TransactionType = "single" | "bundle";

export type ConditionGrade = "S" | "A" | "B" | "C" | "D";

export type WarrantyPlan = "1year" | "2year";

export type WarrantyStatus =
  | "pending"
  | "active"
  | "expired"
  | "claimed"
  | "completed";

export type ServiceType = "repair" | "replacement" | "inspection";

export type ServiceRequestStatus =
  | "pending"
  | "reviewing"
  | "approved"
  | "rejected"
  | "itemShipping"
  | "itemReceived"
  | "repairing"
  | "repaired"
  | "returnShipping"
  | "completed";

// 벤치마크 점수 (v2)
export interface BenchmarkScores {
  cpu?: number;
  gpu?: number;
  storage?: number;
  memory?: number;
  overall?: number;
}

// 풀세트 내 개별 부품 (v2)
export interface TransactionItem {
  itemId: string;
  partCategory: string;
  brand: string;
  modelName: string;
  serialNumber?: string;
  benchmarkScore?: number;
  conditionScore: number;
  photoUrls: string[];
}

export interface VerificationTransaction {
  transactionId: string;
  qrCode: string;

  // 거래 타입 (v2)
  transactionType?: TransactionType;

  // 단일 부품 정보
  partCategory?: string;
  brand?: string;
  modelName?: string;
  serialNumber?: string;
  photoUrls: string[];

  // 풀세트 정보 (v2)
  items?: TransactionItem[];
  bundleName?: string;

  // 검수 정보
  inspectorName: string;
  inspectedAt: string;
  inspectionNote: string;
  inspectionPhotoUrls: string[];

  // 스코어 정보 (v2)
  conditionScore: number;
  conditionGrade?: ConditionGrade;
  benchmarkScores?: BenchmarkScores;

  // 기본 보증 (v2)
  baseWarrantyMonths?: number;

  // 거래 정보
  salePrice: number;
  saleDate: string;
  status: TransactionStatus;
  warrantyId?: string;

  // 문서
  verificationReportUrl?: string;
  warrantyPdfUrl?: string;
  qrCodeImageUrl?: string;
}

export interface Warranty {
  warrantyId: string;
  transactionId: string;
  qrCode: string;

  // 기본 보증 (v2)
  baseWarrantyMonths: number;
  baseWarrantyEndDate?: string;

  // 추가 보증 (v2)
  additionalWarrantyMonths?: number;
  additionalWarrantyPrice?: number;

  // 총 보증
  totalWarrantyMonths: number;
  totalWarrantyEndDate?: string;

  // 기존 필드 (호환성)
  warrantyPlan?: WarrantyPlan;
  warrantyPeriodMonths?: number;
  startDate: string;
  endDate: string;
  warrantyPrice?: number;
  warrantyRate?: number;
  paymentMethod?: string;
  customerName: string;
  customerPhone: string;
  customerEmail?: string;
  status: WarrantyStatus;
  serviceRequestIds: string[];
}

export interface ServiceRequest {
  requestId: string;
  warrantyId: string;
  transactionId: string;
  serviceType: ServiceType;
  issueDescription: string;
  issuePhotoUrls?: string[];
  customerName: string;
  customerPhone: string;
  shippingAddress: string;
  status: ServiceRequestStatus;
  handlerId?: string;
  handlerNote?: string;
  inboundTrackingNumber?: string;
  outboundTrackingNumber?: string;
  requestedAt?: string;
  createdAt: string;
  completedAt?: string;
}

export interface WarrantyRateConfig {
  months: number;
  rate: number;
  price?: number;
}

export const WARRANTY_RATES: Record<WarrantyPlan, WarrantyRateConfig> = {
  "1year": { months: 12, rate: 0.1 },
  "2year": { months: 24, rate: 0.2 },
};

// 추가 보증 요금 (v2)
export const ADDITIONAL_WARRANTY_RATES: Record<12 | 24, WarrantyRateConfig> = {
  12: { months: 12, rate: 0.1 },
  24: { months: 24, rate: 0.2 },
};

// 등급별 설정 (v2)
export interface GradeConfig {
  min: number;
  max: number;
  baseWarrantyMonths: number;
  label: string;
  labelKo: string;
  color: string;
  bgColor: string;
}

export const GRADE_THRESHOLDS: Record<ConditionGrade, GradeConfig> = {
  S: {
    min: 90,
    max: 100,
    baseWarrantyMonths: 24,
    label: "Excellent",
    labelKo: "최상급",
    color: "#4f46e5",
    bgColor: "#eef2ff",
  },
  A: {
    min: 80,
    max: 89,
    baseWarrantyMonths: 18,
    label: "Very Good",
    labelKo: "우수",
    color: "#059669",
    bgColor: "#ecfdf5",
  },
  B: {
    min: 70,
    max: 79,
    baseWarrantyMonths: 12,
    label: "Good",
    labelKo: "양호",
    color: "#d97706",
    bgColor: "#fef3c7",
  },
  C: {
    min: 60,
    max: 69,
    baseWarrantyMonths: 6,
    label: "Fair",
    labelKo: "보통",
    color: "#dc2626",
    bgColor: "#fef2f2",
  },
  D: {
    min: 0,
    max: 59,
    baseWarrantyMonths: 3,
    label: "Poor",
    labelKo: "불량",
    color: "#6b7280",
    bgColor: "#f3f4f6",
  },
};

// 헬퍼 함수
export function getGradeConfig(grade: ConditionGrade | undefined): GradeConfig {
  return GRADE_THRESHOLDS[grade || "B"];
}

export function isBundle(transaction: VerificationTransaction): boolean {
  return transaction.transactionType === "bundle";
}

export function getDisplayName(transaction: VerificationTransaction): string {
  if (isBundle(transaction)) {
    return transaction.bundleName || "조립 PC 세트";
  }
  return `${transaction.brand} ${transaction.modelName}`;
}
