/**
 * Warranty System Types
 */

export type TransactionStatus =
  | "registered"
  | "qrGenerated"
  | "reportIssued"
  | "delivered"
  | "warrantyActive";

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

export interface VerificationTransaction {
  transactionId: string;
  qrCode: string;
  partCategory: string;
  brand: string;
  modelName: string;
  serialNumber?: string;
  photoUrls: string[];
  inspectorName: string;
  inspectedAt: string;
  inspectionNote: string;
  conditionScore: number;
  inspectionPhotoUrls: string[];
  salePrice: number;
  saleDate: string;
  status: TransactionStatus;
  warrantyId?: string;
  verificationReportUrl?: string;
  qrCodeImageUrl?: string;
}

export interface Warranty {
  warrantyId: string;
  transactionId: string;
  qrCode: string;
  warrantyPlan: WarrantyPlan;
  warrantyPeriodMonths: number;
  startDate: string;
  endDate: string;
  warrantyPrice: number;
  warrantyRate: number;
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
  issuePhotoUrls: string[];
  customerName: string;
  customerPhone: string;
  shippingAddress: string;
  status: ServiceRequestStatus;
  handlerId?: string;
  handlerNote?: string;
  inboundTrackingNumber?: string;
  outboundTrackingNumber?: string;
  requestedAt: string;
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
