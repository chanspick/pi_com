/**
 * Invoice Trigger - 결제 완료 시 자동 송장 생성 트리거
 *
 * 기능:
 * - Firestore 트리거로 결제 완료 감지
 * - 자동 송장 PDF 생성
 * - 구매자에게 알림 발송
 */

import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import {generateInvoiceFromOrder} from "./invoice_generator";

/**
 * 주문 결제 완료 시 자동 송장 생성 트리거
 *
 * 조건:
 * - paymentStatus가 'pending' 또는 'processing'에서 'completed'로 변경될 때
 * - 아직 invoiceId가 없는 경우
 */
export const onPaymentCompleted = functions
  .region("asia-northeast3")
  .firestore.document("orders/{orderId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const orderId = context.params.orderId;

    // 결제 완료 조건 확인
    const wasNotCompleted = before.paymentStatus !== "completed";
    const isNowCompleted = after.paymentStatus === "completed";
    const noExistingInvoice = !after.invoiceId;

    if (wasNotCompleted && isNowCompleted && noExistingInvoice) {
      console.log(`Payment completed for order ${orderId}, generating invoice...`);

      try {
        // 송장 생성
        const result = await generateInvoiceFromOrder(orderId);
        console.log(`Invoice ${result.invoiceNumber} generated for order ${orderId}`);

        // 구매자에게 알림 발송
        if (after.userId) {
          await sendInvoiceNotification(after.userId, orderId, result.invoiceNumber);
        }

        return result;
      } catch (error) {
        console.error(`Failed to generate invoice for order ${orderId}:`, error);
        // 에러가 발생해도 주문 처리에 영향을 주지 않도록 에러를 throw하지 않음
        return null;
      }
    }

    return null;
  });

/**
 * 토스페이먼츠 결제 완료 시 송장 생성 트리거
 *
 * toss_payments 컬렉션의 status가 'DONE'으로 변경될 때
 */
export const onTossPaymentCompleted = functions
  .region("asia-northeast3")
  .firestore.document("toss_payments/{paymentKey}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const paymentKey = context.params.paymentKey;

    // 결제 완료 조건 확인
    const wasNotDone = before.status !== "DONE";
    const isNowDone = after.status === "DONE";

    if (wasNotDone && isNowDone && after.orderId) {
      console.log(`Toss payment ${paymentKey} completed, checking order...`);

      const db = admin.firestore();
      const orderDoc = await db.collection("orders").doc(after.orderId).get();

      if (orderDoc.exists) {
        const order = orderDoc.data()!;

        // 아직 송장이 없는 경우에만 생성
        if (!order.invoiceId) {
          try {
            const result = await generateInvoiceFromOrder(after.orderId);
            console.log(`Invoice ${result.invoiceNumber} generated for toss payment ${paymentKey}`);

            // 구매자에게 알림 발송
            if (order.userId) {
              await sendInvoiceNotification(order.userId, after.orderId, result.invoiceNumber);
            }

            return result;
          } catch (error) {
            console.error(`Failed to generate invoice for order ${after.orderId}:`, error);
            return null;
          }
        }
      }
    }

    return null;
  });

/**
 * 카카오페이 결제 완료 시 송장 생성 트리거
 *
 * payments 컬렉션의 status가 'approved'로 변경될 때
 */
export const onKakaoPaymentApproved = functions
  .region("asia-northeast3")
  .firestore.document("payments/{tid}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const tid = context.params.tid;

    // 결제 승인 조건 확인
    const wasNotApproved = before.status !== "approved";
    const isNowApproved = after.status === "approved";

    if (wasNotApproved && isNowApproved && after.partner_order_id) {
      console.log(`Kakao payment ${tid} approved, checking order...`);

      const db = admin.firestore();
      const orderDoc = await db.collection("orders").doc(after.partner_order_id).get();

      if (orderDoc.exists) {
        const order = orderDoc.data()!;

        // 아직 송장이 없는 경우에만 생성
        if (!order.invoiceId) {
          try {
            const result = await generateInvoiceFromOrder(after.partner_order_id);
            console.log(`Invoice ${result.invoiceNumber} generated for kakao payment ${tid}`);

            // 구매자에게 알림 발송
            if (order.userId) {
              await sendInvoiceNotification(order.userId, after.partner_order_id, result.invoiceNumber);
            }

            return result;
          } catch (error) {
            console.error(`Failed to generate invoice for order ${after.partner_order_id}:`, error);
            return null;
          }
        }
      }
    }

    return null;
  });

/**
 * 송장 생성 알림 발송
 */
async function sendInvoiceNotification(
  userId: string,
  orderId: string,
  invoiceNumber: string
): Promise<void> {
  const db = admin.firestore();

  try {
    // 사용자 FCM 토큰 조회
    const userDoc = await db.collection("users").doc(userId).get();
    const userData = userDoc.data();
    const fcmToken = userData?.fcmToken;

    // 인앱 알림 생성
    await db.collection("notifications").add({
      userId,
      type: "invoice_generated",
      title: "송장이 발행되었습니다",
      body: `주문 ${orderId.substring(0, 8)}...의 송장(${invoiceNumber})이 발행되었습니다.`,
      data: {
        orderId,
        invoiceNumber,
      },
      isRead: false,
      createdAt: admin.firestore.Timestamp.now(),
    });

    // FCM 푸시 알림 발송
    if (fcmToken) {
      const message = {
        token: fcmToken,
        notification: {
          title: "송장 발행 완료",
          body: `주문 ${orderId.substring(0, 8)}...의 송장이 발행되었습니다. 마이페이지에서 확인하세요.`,
        },
        data: {
          type: "invoice_generated",
          orderId,
          invoiceNumber,
        },
      };

      await admin.messaging().send(message);
      console.log(`Invoice notification sent to user ${userId}`);
    }
  } catch (error) {
    console.error(`Failed to send invoice notification to user ${userId}:`, error);
    // 알림 실패는 무시
  }
}
