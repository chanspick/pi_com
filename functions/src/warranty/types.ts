/**
 * Warranty System Types
 * QR 기반 AS 보증 시스템 타입 정의
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

export interface VerificationTransaction {
  transactionId: string;       // VTX-YYYYMMDD-XXXXX
  qrCode: string;              // UUID (QR 고유값)

  // 부품 정보
  partCategory: string;        // CPU, GPU, Mainboard 등
  brand: string;
  modelName: string;
  serialNumber?: string | null;
  photoUrls: string[];

  // 검수 정보
  inspectorId: string;
  inspectorName: string;
  inspectedAt: admin.firestore.Timestamp;
  inspectionNote: string;
  conditionScore: number;      // 1-10
  inspectionPhotoUrls: string[];

  // B2B 거래 정보
  buyerCompanyName?: string | null;
  buyerContactName?: string | null;
  buyerContactPhone?: string | null;
  salePrice: number;
  saleDate: admin.firestore.Timestamp;

  // 문서 정보
  verificationReportUrl?: string | null;
  qrCodeImageUrl?: string | null;

  // 상태
  status: TransactionStatus;
  warrantyId?: string | null;

  // 타임스탬프
  createdAt: admin.firestore.Timestamp;
  updatedAt: admin.firestore.Timestamp;
}

// ============================================================================
// Warranty (AS 보증)
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

  // 보증 정보
  warrantyPlan: WarrantyPlan;
  warrantyPeriodMonths: number; // 12 or 24
  startDate: admin.firestore.Timestamp;
  endDate: admin.firestore.Timestamp;

  // 결제 정보
  warrantyPrice: number;       // salePrice * rate
  warrantyRate: number;        // 0.1 or 0.2 (차후 알고리즘용)
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
// API Request/Response Types
// ============================================================================

export interface CreateTransactionRequest {
  // 부품 정보
  partCategory: string;
  brand: string;
  modelName: string;
  serialNumber?: string;
  photoUrls?: string[];

  // 검수 정보
  inspectorId: string;
  inspectorName: string;
  inspectionNote: string;
  conditionScore: number;
  inspectionPhotoUrls?: string[];

  // B2B 거래 정보
  buyerCompanyName?: string;
  buyerContactName?: string;
  buyerContactPhone?: string;
  salePrice: number;
}

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
// Warranty Rate Configuration
// ============================================================================

export const WARRANTY_RATES: Record<WarrantyPlan, { months: number; rate: number }> = {
  "1year": { months: 12, rate: 0.10 },
  "2year": { months: 24, rate: 0.20 },
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
