/**
 * Admin Bulk Operations - 일괄 처리 기능
 *
 * 기능:
 * - 일괄 송장 생성
 * - 일괄 상태 업데이트
 */

import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import {generateInvoiceFromOrder} from "../invoice/invoice_generator";

// 타입 정의
interface BulkGenerateInvoicesRequest {
  orderIds: string[];
}

interface BulkUpdateStatusRequest {
  orderIds: string[];
  newStatus: string;
}

interface BulkOperationResult {
  success: string[];
  failed: Array<{orderId: string; error: string}>;
  totalProcessed: number;
  successCount: number;
  failedCount: number;
}

/**
 * 일괄 송장 생성
 *
 * 여러 주문에 대해 송장을 일괄 생성합니다.
 * 이미 송장이 있는 주문은 건너뜁니다.
 */
export const bulkGenerateInvoices = functions
  .region("asia-northeast3")
  .https.onCall(async (data: BulkGenerateInvoicesRequest, context) => {
    // 인증 확인
    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "Authentication required");
    }

    // 관리자 권한 확인
    const userDoc = await admin.firestore().collection("users").doc(context.auth.uid).get();
    if (!userDoc.exists || userDoc.data()?.isAdmin !== true) {
      throw new functions.https.HttpsError("permission-denied", "Admin access required");
    }

    const {orderIds} = data;

    if (!orderIds || !Array.isArray(orderIds) || orderIds.length === 0) {
      throw new functions.https.HttpsError("invalid-argument", "orderIds array is required");
    }

    if (orderIds.length > 50) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Maximum 50 orders can be processed at once"
      );
    }

    console.log(`Bulk invoice generation started for ${orderIds.length} orders`);

    const result: BulkOperationResult = {
      success: [],
      failed: [],
      totalProcessed: orderIds.length,
      successCount: 0,
      failedCount: 0,
    };

    // 순차 처리 (동시 처리 시 Rate Limit 이슈 방지)
    for (const orderId of orderIds) {
      try {
        const invoiceResult = await generateInvoiceFromOrder(orderId);
        result.success.push(orderId);
        result.successCount++;
        console.log(`Invoice generated for order ${orderId}: ${invoiceResult.invoiceNumber}`);
      } catch (error: any) {
        result.failed.push({orderId, error: error.message});
        result.failedCount++;
        console.error(`Failed to generate invoice for order ${orderId}:`, error.message);
      }
    }

    console.log(
      `Bulk invoice generation completed: ${result.successCount} success, ${result.failedCount} failed`
    );

    return result;
  });

/**
 * 일괄 상태 업데이트
 *
 * 여러 주문의 상태를 일괄 변경합니다.
 */
export const bulkUpdateStatus = functions
  .region("asia-northeast3")
  .https.onCall(async (data: BulkUpdateStatusRequest, context) => {
    // 인증 확인
    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "Authentication required");
    }

    // 관리자 권한 확인
    const userDoc = await admin.firestore().collection("users").doc(context.auth.uid).get();
    if (!userDoc.exists || userDoc.data()?.isAdmin !== true) {
      throw new functions.https.HttpsError("permission-denied", "Admin access required");
    }

    const {orderIds, newStatus} = data;

    if (!orderIds || !Array.isArray(orderIds) || orderIds.length === 0) {
      throw new functions.https.HttpsError("invalid-argument", "orderIds array is required");
    }

    if (!newStatus) {
      throw new functions.https.HttpsError("invalid-argument", "newStatus is required");
    }

    // 유효한 상태 값 확인
    const validStatuses = [
      "pending",
      "processing",
      "shipped",
      "delivered",
      "confirmed",
      "cancelled",
    ];

    if (!validStatuses.includes(newStatus)) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        `Invalid status. Must be one of: ${validStatuses.join(", ")}`
      );
    }

    if (orderIds.length > 100) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Maximum 100 orders can be processed at once"
      );
    }

    console.log(`Bulk status update started for ${orderIds.length} orders -> ${newStatus}`);

    const db = admin.firestore();
    const result: BulkOperationResult = {
      success: [],
      failed: [],
      totalProcessed: orderIds.length,
      successCount: 0,
      failedCount: 0,
    };

    // 상태별 타임스탬프 필드 결정
    const timestampField = getTimestampField(newStatus);

    // Batch 처리 (최대 500개까지 한 번에 처리 가능)
    const batch = db.batch();
    const now = admin.firestore.Timestamp.now();

    for (const orderId of orderIds) {
      try {
        const orderRef = db.collection("orders").doc(orderId);
        const orderDoc = await orderRef.get();

        if (!orderDoc.exists) {
          result.failed.push({orderId, error: "Order not found"});
          result.failedCount++;
          continue;
        }

        const updateData: {[key: string]: any} = {
          status: newStatus,
          updatedAt: now,
        };

        if (timestampField) {
          updateData[timestampField] = now;
        }

        batch.update(orderRef, updateData);
        result.success.push(orderId);
        result.successCount++;
      } catch (error: any) {
        result.failed.push({orderId, error: error.message});
        result.failedCount++;
        console.error(`Failed to update status for order ${orderId}:`, error.message);
      }
    }

    // Batch commit
    if (result.successCount > 0) {
      await batch.commit();
    }

    console.log(
      `Bulk status update completed: ${result.successCount} success, ${result.failedCount} failed`
    );

    return result;
  });

/**
 * 상태에 따른 타임스탬프 필드 결정
 */
function getTimestampField(status: string): string | null {
  switch (status) {
    case "shipped":
      return "shippedAt";
    case "delivered":
      return "deliveredAt";
    case "confirmed":
      return "confirmedAt";
    case "cancelled":
      return "cancelledAt";
    default:
      return null;
  }
}
