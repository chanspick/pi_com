/**
 * Warranty API Client
 */

import {
  VerificationTransaction,
  Warranty,
  ServiceRequest,
  WarrantyPlan,
  ServiceType,
} from "@/types/warranty";

const API_URL = process.env.NEXT_PUBLIC_API_URL || "https://asia-northeast3-picom-team.cloudfunctions.net/api";

interface ApiResponse<T> {
  success?: boolean;
  error?: string;
  message?: string;
  data?: T;
}

async function fetchApi<T>(
  endpoint: string,
  options?: RequestInit
): Promise<T> {
  const url = `${API_URL}${endpoint}`;

  const response = await fetch(url, {
    ...options,
    headers: {
      "Content-Type": "application/json",
      ...options?.headers,
    },
  });

  const data = await response.json();

  if (!response.ok) {
    throw new Error(data.error || data.message || "API request failed");
  }

  return data;
}

// ============================================================================
// Transaction API
// ============================================================================

export async function getTransactionByQR(
  qrCode: string
): Promise<VerificationTransaction> {
  return fetchApi<VerificationTransaction>(`/warranty/transaction/${qrCode}`);
}

// ============================================================================
// Warranty API
// ============================================================================

export interface PreparePaymentRequest {
  qrCode: string;
  warrantyPlan: WarrantyPlan;
  customerName: string;
  customerPhone: string;
  customerEmail?: string;
  paymentMethod: "kakaopay" | "tosspay";
}

export interface PreparePaymentResponse {
  success: boolean;
  warrantyId: string;
  transactionId: string;
  warrantyPrice: number;
  warrantyPlan: WarrantyPlan;
  tid?: string;
  redirectUrl?: string;
}

export async function prepareWarrantyPayment(
  data: PreparePaymentRequest
): Promise<PreparePaymentResponse> {
  return fetchApi<PreparePaymentResponse>("/warranty/payment/prepare", {
    method: "POST",
    body: JSON.stringify(data),
  });
}

export interface ApprovePaymentRequest {
  warrantyId: string;
  pgToken?: string; // 카카오페이
  paymentKey?: string; // 토스페이
  orderId?: string;
  amount?: number;
}

export async function approveWarrantyPayment(
  data: ApprovePaymentRequest
): Promise<{ success: boolean; warrantyId: string; status: string }> {
  return fetchApi("/warranty/payment/approve", {
    method: "POST",
    body: JSON.stringify(data),
  });
}

export interface WarrantyWithTransaction {
  warranty: Warranty;
  transaction: {
    transactionType?: "single" | "bundle";
    partCategory?: string;
    brand?: string;
    modelName?: string;
    bundleName?: string;
    items?: Array<{
      itemId: string;
      partCategory: string;
      brand: string;
      modelName: string;
      conditionScore: number;
      benchmarkScore?: number;
    }>;
    salePrice: number;
    conditionScore: number;
    conditionGrade?: "S" | "A" | "B" | "C" | "D";
    benchmarkScores?: {
      cpu?: number;
      gpu?: number;
      storage?: number;
      memory?: number;
      overall?: number;
    };
    baseWarrantyMonths?: number;
    photoUrls: string[];
  } | null;
}

export async function getWarranty(
  warrantyId: string
): Promise<WarrantyWithTransaction> {
  return fetchApi<WarrantyWithTransaction>(`/warranty/${warrantyId}`);
}

// ============================================================================
// Warranty Activation API (v2)
// ============================================================================

export interface ActivateWarrantyRequest {
  qrCode: string;
  customerName: string;
  customerPhone: string;
  customerEmail?: string;
}

export interface ActivateWarrantyResponse {
  success: boolean;
  warrantyId: string;
  baseWarrantyMonths: number;
  totalWarrantyMonths: number;
  baseWarrantyEndDate: string;
  message?: string;
}

export async function activateWarranty(
  data: ActivateWarrantyRequest
): Promise<ActivateWarrantyResponse> {
  return fetchApi<ActivateWarrantyResponse>("/warranty/activate", {
    method: "POST",
    body: JSON.stringify(data),
  });
}

// ============================================================================
// Additional Warranty API (v2)
// ============================================================================

export interface PrepareAdditionalWarrantyRequest {
  qrCode: string;
  additionalMonths: 12 | 24;
  customerName: string;
  customerPhone: string;
  customerEmail?: string;
  paymentMethod: "kakaopay" | "tosspay";
}

export interface PrepareAdditionalWarrantyResponse {
  warrantyId: string;
  baseWarrantyMonths: number;
  additionalWarrantyMonths: number;
  totalWarrantyMonths: number;
  additionalPrice: number;
  tid?: string;
  paymentKey?: string;
  redirectUrl: string;
}

export async function prepareAdditionalWarrantyPayment(
  data: PrepareAdditionalWarrantyRequest
): Promise<PrepareAdditionalWarrantyResponse> {
  return fetchApi<PrepareAdditionalWarrantyResponse>("/warranty/payment/additional", {
    method: "POST",
    body: JSON.stringify(data),
  });
}

export interface ApproveAdditionalPaymentRequest {
  warrantyId: string;
  pgToken?: string;
  paymentKey?: string;
  orderId?: string;
  amount?: number;
}

export interface ApproveAdditionalPaymentResponse {
  success: boolean;
  warrantyId: string;
  baseWarrantyMonths: number;
  additionalWarrantyMonths: number;
  totalWarrantyMonths: number;
  totalWarrantyEndDate: string;
}

export async function approveAdditionalWarrantyPayment(
  data: ApproveAdditionalPaymentRequest
): Promise<ApproveAdditionalPaymentResponse> {
  return fetchApi<ApproveAdditionalPaymentResponse>("/warranty/payment/additional/approve", {
    method: "POST",
    body: JSON.stringify(data),
  });
}

// ============================================================================
// Service Request API
// ============================================================================

export interface CreateServiceRequestData {
  warrantyId: string;
  serviceType: ServiceType;
  issueDescription: string;
  issuePhotoUrls?: string[];
  customerName: string;
  customerPhone: string;
  shippingAddress: string;
}

export async function createServiceRequest(
  data: CreateServiceRequestData
): Promise<{ success: boolean; requestId: string; warrantyId: string; status: string }> {
  return fetchApi("/warranty/service-request", {
    method: "POST",
    body: JSON.stringify(data),
  });
}

export async function getServiceRequest(
  requestId: string
): Promise<ServiceRequest> {
  return fetchApi<ServiceRequest>(`/warranty/service-request/${requestId}`);
}

export async function getServiceHistory(
  warrantyId: string
): Promise<{ warrantyId: string; requests: ServiceRequest[]; count: number }> {
  return fetchApi(`/warranty/service-history/${warrantyId}`);
}

// ============================================================================
// User-Warranty API (v3)
// ============================================================================

async function fetchApiWithAuth<T>(
  endpoint: string,
  idToken: string,
  options?: RequestInit
): Promise<T> {
  return fetchApi<T>(endpoint, {
    ...options,
    headers: {
      ...options?.headers,
      Authorization: `Bearer ${idToken}`,
    },
  });
}

export async function linkUserToWarranty(
  qrCode: string,
  idToken: string
): Promise<{ success: boolean; qrCode: string; transactionId: string; warrantyId: string | null }> {
  return fetchApiWithAuth("/warranty/link-user", idToken, {
    method: "POST",
    body: JSON.stringify({ qrCode }),
  });
}

export interface MyWarrantyItem {
  transactionId: string;
  qrCode: string;
  transactionType: "single" | "bundle";
  partCategory?: string;
  brand?: string;
  modelName?: string;
  bundleName?: string;
  items?: Array<{ partCategory: string; brand: string; modelName: string }>;
  conditionScore: number;
  conditionGrade?: string;
  baseWarrantyMonths: number;
  salePrice: number;
  saleDate: string;
  warrantyPdfUrl?: string;
  qrCodeImageUrl?: string;
  warrantyId: string | null;
  warrantyStatus: string | null;
  totalWarrantyMonths: number;
  totalWarrantyEndDate: string | null;
}

export async function getMyWarranties(
  idToken: string
): Promise<{ warranties: MyWarrantyItem[]; count: number }> {
  return fetchApiWithAuth("/warranty/my-warranties", idToken);
}
