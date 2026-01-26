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

const API_URL = process.env.NEXT_PUBLIC_API_URL || "https://asia-northeast3-picom-app.cloudfunctions.net/api";

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
    partCategory: string;
    brand: string;
    modelName: string;
    salePrice: number;
    conditionScore: number;
    photoUrls: string[];
  } | null;
}

export async function getWarranty(
  warrantyId: string
): Promise<WarrantyWithTransaction> {
  return fetchApi<WarrantyWithTransaction>(`/warranty/${warrantyId}`);
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
