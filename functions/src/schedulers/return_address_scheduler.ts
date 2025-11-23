// functions/src/schedulers/return_address_scheduler.ts

import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";

const db = admin.firestore();

/**
 * 반품 주소 입력 마감 알림 스케줄러
 * 매일 11:00 (KST) 실행하여 환불 요청 후 반품 주소 미입력 알림 발송
 */
export const checkReturnAddressDeadline = functions
  .region("asia-northeast3")
  .pubsub.schedule("0 11 * * *") // 매일 11:00
  .timeZone("Asia/Seoul")
  .onRun(async () => {
    console.log("Return address deadline scheduler started");

    const today = new Date();
    today.setHours(0, 0, 0, 0);

    try {
      // refundRequests 컬렉션에서 승인된 환불 조회
      const refundsSnapshot = await db
        .collection("refundRequests")
        .where("status", "==", "approved")
        .get();

      console.log(`Found ${refundsSnapshot.size} approved refund requests`);

      const notifications: Promise<any>[] = [];

      for (const doc of refundsSnapshot.docs) {
        const refund = doc.data();
        const approvedAt = refund.approvedAt?.toDate();

        if (!approvedAt) {
          console.warn(`Refund ${doc.id} has no approvedAt timestamp`);
          continue;
        }

        // 반품 송장 정보가 이미 입력된 경우 스킵
        if (refund.trackingNumber && refund.courierCompany) {
          continue;
        }

        const daysSinceApproval = Math.floor(
          (today.getTime() - approvedAt.getTime()) / (1000 * 60 * 60 * 24)
        );

        const userId = refund.userId;
        const refundId = doc.id;
        const orderId = refund.orderId;
        const partName = "주문 상품"; // TODO: Order에서 실제 상품명 가져오기

        // 환불 승인 후 2일차: 반품 주소 입력 알림
        if (daysSinceApproval === 2) {
          notifications.push(
            sendNotification({
              userId,
              type: "returnShippingRequired",
              title: "반품 송장 정보 입력 요청",
              message: `${partName}의 환불이 승인되었습니다. 반품을 위해 택배 송장 정보를 입력해주세요. (승인 후 3일 이내)`,
              relatedRefundId: refundId,
              relatedOrderId: orderId,
            })
          );
          console.log(
            `2-day return address reminder sent for Refund ${refundId}`
          );
        }

        // 환불 승인 후 3일차: 반품 주소 입력 마감 경고
        if (daysSinceApproval === 3) {
          notifications.push(
            sendNotification({
              userId,
              type: "returnAddressExpiring",
              title: "⚠️ 반품 송장 정보 입력 마감 임박",
              message: `${partName}의 반품 송장 정보를 오늘 중으로 입력해주세요. 기한 내 미입력 시 환불이 취소될 수 있습니다.`,
              relatedRefundId: refundId,
              relatedOrderId: orderId,
            })
          );
          console.log(
            `3-day deadline warning sent for Refund ${refundId}`
          );
        }

        // 환불 승인 후 4일차 이상: 환불 자동 취소 (선택적)
        if (daysSinceApproval >= 4 && refund.status === "approved") {
          // NOTE: 자동 취소 정책은 비즈니스 요구사항에 따라 결정
          // 현재는 알림만 발송하고 수동 처리
          notifications.push(
            sendNotification({
              userId,
              type: "returnAddressExpiring",
              title: "🚨 반품 송장 미입력으로 환불 취소 예정",
              message: `${partName}의 반품 송장 정보가 기한 내 입력되지 않았습니다. 환불이 취소될 수 있으니 고객센터로 문의해주세요.`,
              relatedRefundId: refundId,
              relatedOrderId: orderId,
            })
          );

          console.log(
            `Expiry warning sent for Refund ${refundId} (${daysSinceApproval} days)`
          );
        }
      }

      await Promise.all(notifications);
      console.log(`Sent ${notifications.length} return address notifications`);
    } catch (error) {
      console.error("Error in return address deadline scheduler:", error);
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
