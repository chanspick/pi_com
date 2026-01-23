// functions/src/schedulers/settlement_scheduler.ts

import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";

const db = admin.firestore();

// 배치 처리 제한 - 한 번에 처리할 최대 문서 수
export const BATCH_SIZE = 100;

/**
 * 배송완료 주문 쿼리 함수 (테스트 가능)
 * 배치 limit이 적용된 쿼리 실행
 */
export async function queryDeliveredOrdersWithLimit() {
  const snapshot = await db
    .collection("orders")
    .where("status", "==", "delivered")
    .limit(BATCH_SIZE)
    .get();
  console.log(`Processing ${snapshot.size} documents (batch size: ${BATCH_SIZE})`);
  return snapshot;
}

/**
 * 정산 및 구매확정 알림 스케줄러
 * 매일 10:00 (KST) 실행하여 구매확정/정산 관련 알림 발송
 */
export const checkSettlementNotifications = functions
  .region("asia-northeast3")
  .pubsub.schedule("0 10 * * *") // 매일 10:00
  .timeZone("Asia/Seoul")
  .onRun(async () => {
    console.log("Settlement notifications scheduler started");

    const today = new Date();
    today.setHours(0, 0, 0, 0);

    try {
      // Orders 컬렉션에서 배송완료 상태인 주문 조회 (배치 limit 적용)
      const ordersSnapshot = await queryDeliveredOrdersWithLimit();

      console.log(`Found ${ordersSnapshot.size} delivered orders (batch size: ${BATCH_SIZE})`);

      const notifications: Promise<any>[] = [];
      const autoConfirmUpdates: Promise<any>[] = [];

      for (const doc of ordersSnapshot.docs) {
        const order = doc.data();
        const deliveredAt = order.deliveredAt?.toDate();

        if (!deliveredAt) {
          console.warn(`Order ${doc.id} has no deliveredAt timestamp`);
          continue;
        }

        const daysSinceDelivery = Math.floor(
          (today.getTime() - deliveredAt.getTime()) / (1000 * 60 * 60 * 24)
        );

        const userId = order.userId;
        const sellerId = order.sellerId;
        const orderId = doc.id;
        const totalAmount = order.totalPrice + (order.shippingFee || 0);
        const partName =
          order.items && order.items.length > 0
            ? order.items.length === 1
              ? order.items[0].partName
              : `${order.items[0].partName} 외 ${order.items.length - 1}건`
            : "주문 상품";

        // 5일차: 구매확정 요청 알림
        if (daysSinceDelivery === 5) {
          notifications.push(
            sendNotification({
              userId,
              type: "purchaseConfirmReminder",
              title: "구매확정 요청",
              message: `${partName} 배송이 완료된 지 5일이 지났습니다. 상품에 이상이 없으시면 구매확정을 부탁드립니다.`,
              relatedOrderId: orderId,
            })
          );
          console.log(
            `5-day purchase confirm reminder sent for Order ${orderId}`
          );
        }

        // 7일차: 자동 구매확정 + 정산 대기 알림
        if (daysSinceDelivery === 7 && order.status === "delivered") {
          // 자동 구매확정 처리
          autoConfirmUpdates.push(
            db
              .collection("orders")
              .doc(orderId)
              .update({
                status: "confirmed",
                confirmedAt: admin.firestore.FieldValue.serverTimestamp(),
                autoConfirmed: true,
              })
          );

          // 구매자에게 자동 구매확정 알림
          notifications.push(
            sendNotification({
              userId,
              type: "purchaseAutoConfirmed",
              title: "구매가 자동 확정되었습니다",
              message: `${partName}의 구매가 자동으로 확정되었습니다. 이용해 주셔서 감사합니다.`,
              relatedOrderId: orderId,
            })
          );

          // 판매자에게 정산 대기 알림
          notifications.push(
            sendNotification({
              userId: sellerId,
              type: "settlementPending",
              title: "정산 대기 중",
              message: `${partName} 판매대금이 정산 대기 중입니다. 곧 정산이 완료됩니다.`,
              relatedOrderId: orderId,
            })
          );

          console.log(`Auto-confirmed and settlement pending for Order ${orderId}`);
        }

        // 10일차: 정산 완료 알림 (구매확정 후 3일)
        if (daysSinceDelivery === 10 && order.status === "confirmed") {
          // NOTE: 실제 정산 처리 로직은 별도 시스템에서 처리
          // 여기서는 알림만 발송

          // 판매자에게 정산 완료 알림
          notifications.push(
            sendNotification({
              userId: sellerId,
              type: "settlementCompleted",
              title: "정산 완료",
              message: `${partName} 판매대금 ${totalAmount.toLocaleString()}원이 정산되었습니다.`,
              relatedOrderId: orderId,
            })
          );

          // 주문 상태 업데이트 (settled)
          autoConfirmUpdates.push(
            db
              .collection("orders")
              .doc(orderId)
              .update({
                status: "settled",
                settledAt: admin.firestore.FieldValue.serverTimestamp(),
              })
          );

          console.log(`Settlement completed notification sent for Order ${orderId}`);
        }
      }

      // 모든 업데이트 및 알림 발송
      await Promise.all([...notifications, ...autoConfirmUpdates]);
      console.log(
        `Sent ${notifications.length} notifications, ${autoConfirmUpdates.length} auto-updates`
      );
    } catch (error) {
      console.error("Error in settlement notifications scheduler:", error);
    }

    return null;
  });

/**
 * Firestore에 알림 문서 생성
 */
async function sendNotification(params: {
  userId: string;
  type: string;
  title: string;
  message: string;
  relatedDragonBallId?: string;
  relatedListingId?: string;
  relatedOrderId?: string;
  relatedRefundId?: string;
}) {
  const notification = {
    userId: params.userId,
    type: params.type,
    title: params.title,
    message: params.message,
    isRead: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    ...(params.relatedDragonBallId && {
      relatedDragonBallId: params.relatedDragonBallId,
    }),
    ...(params.relatedListingId && {
      relatedListingId: params.relatedListingId,
    }),
    ...(params.relatedOrderId && { relatedOrderId: params.relatedOrderId }),
    ...(params.relatedRefundId && { relatedRefundId: params.relatedRefundId }),
  };

  await db.collection("notifications").add(notification);
}
