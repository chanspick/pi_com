// functions/src/refund/approval_deadline_scheduler.ts

import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import { getAdminUserIds } from "../config/admin";

const db = admin.firestore();

/**
 * 환불 승인 기한 알림 스케줄러
 * 매일 09:00 (KST) 실행하여 승인 기한이 임박하거나 경과한 환불에 대해 알림
 *
 * 정책: 환불 신청 후 1~2영업일 이내 승인/거부 필요
 */
export const notifyRefundApprovalDeadline = functions
  .region("asia-northeast3")
  .pubsub.schedule("0 9 * * *") // 매일 09:00
  .timeZone("Asia/Seoul")
  .onRun(async () => {
    console.log("환불 승인 기한 알림 스케줄러 시작");

    const today = new Date();
    today.setHours(0, 0, 0, 0);

    try {
      // 승인 대기 중인 환불 조회
      const refundsSnapshot = await db
        .collection("refundRequests")
        .where("status", "==", "pending")
        .get();

      console.log(`승인 대기 중인 환불 ${refundsSnapshot.size}건 발견`);

      const notifications: Promise<any>[] = [];

      for (const doc of refundsSnapshot.docs) {
        const refund = doc.data();
        const requestedAt = refund.requestedAt?.toDate();

        if (!requestedAt) {
          console.warn(`환불 ${doc.id}의 requestedAt이 없습니다`);
          continue;
        }

        // 주말 제외한 영업일 계산
        const businessDaysSinceRequest = calculateBusinessDays(
          requestedAt,
          today
        );

        // [수정됨] userId 변수 삭제 (사용하지 않음)
        const sellerId = refund.sellerId;
        const orderId = refund.orderId;
        const refundId = doc.id;

        // 1영업일 경과: 판매자에게 승인 요청 알림
        if (businessDaysSinceRequest === 1) {
          notifications.push(
            sendNotification({
              userId: sellerId,
              type: "refundApprovalRequired",
              title: "환불 승인 요청",
              message: `구매자가 환불을 신청했습니다. 환불 사유를 확인하고 승인 또는 거부해주세요. (신청일: ${formatDate(requestedAt)})`,
              relatedOrderId: orderId,
              relatedRefundId: refundId,
            })
          );

          console.log(`환불 승인 요청 알림 발송: ${refundId} (1영업일 경과)`);
        }

        // 2영업일 경과: 긴급 알림
        if (businessDaysSinceRequest === 2) {
          notifications.push(
            sendNotification({
              userId: sellerId,
              type: "refundApprovalUrgent",
              title: "⚠️ 환불 승인 기한 임박",
              message: `환불 승인 기한이 오늘까지입니다. 즉시 승인 또는 거부 처리를 해주세요. (신청일: ${formatDate(requestedAt)})`,
              relatedOrderId: orderId,
              relatedRefundId: refundId,
            })
          );

          // 관리자에게도 알림
          notifications.push(
            sendAdminNotification({
              type: "refundApprovalOverdue",
              title: "⚠️ 환불 승인 기한 임박",
              message: `판매자 ${sellerId}의 환불 승인이 지연되고 있습니다. 주문: ${orderId}`,
              relatedOrderId: orderId,
              relatedRefundId: refundId,
            })
          );

          console.log(`환불 승인 긴급 알림 발송: ${refundId} (2영업일 경과)`);
        }

        // 3영업일 이상 경과: 자동 승인 고려 (선택적)
        if (businessDaysSinceRequest >= 3) {
          // TODO: 비즈니스 정책에 따라 자동 승인 처리 가능
          // 현재는 관리자에게 알림만 발송

          notifications.push(
            sendAdminNotification({
              type: "refundApprovalOverdue",
              title: "🚨 환불 승인 기한 초과",
              message: `환불 ${refundId}의 승인 기한이 ${businessDaysSinceRequest}영업일 초과했습니다. 수동 처리가 필요합니다.`,
              relatedOrderId: orderId,
              relatedRefundId: refundId,
            })
          );

          console.log(
            `환불 승인 기한 초과 알림 발송: ${refundId} (${businessDaysSinceRequest}영업일 경과)`
          );
        }
      }

      await Promise.all(notifications);
      console.log(`${notifications.length}건의 환불 승인 알림 발송 완료`);
    } catch (error) {
      console.error("환불 승인 기한 알림 스케줄러 오류:", error);
    }

    return null;
  });

/**
 * 영업일 계산 (주말 제외)
 */
function calculateBusinessDays(startDate: Date, endDate: Date): number {
  let count = 0;
  const current = new Date(startDate);

  while (current <= endDate) {
    const dayOfWeek = current.getDay();
    // 주말(토요일=6, 일요일=0) 제외
    if (dayOfWeek !== 0 && dayOfWeek !== 6) {
      count++;
    }
    current.setDate(current.getDate() + 1);
  }

  return count - 1; // 시작일 제외
}

/**
 * 날짜 포맷팅
 */
function formatDate(date: Date): string {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, "0");
  const day = String(date.getDate()).padStart(2, "0");
  return `${year}-${month}-${day}`;
}

/**
 * 사용자에게 알림 발송
 */
async function sendNotification(params: {
  userId: string;
  type: string;
  title: string;
  message: string;
  relatedOrderId?: string;
  relatedRefundId?: string;
}) {
  await db.collection("notifications").add({
    userId: params.userId,
    type: params.type,
    title: params.title,
    message: params.message,
    relatedOrderId: params.relatedOrderId,
    relatedRefundId: params.relatedRefundId,
    isRead: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}

/**
 * 관리자에게 알림 발송
 * Firebase config에서 관리자 UID 목록을 가져옵니다.
 */
async function sendAdminNotification(params: {
  type: string;
  title: string;
  message: string;
  relatedOrderId?: string;
  relatedRefundId?: string;
}) {
  const adminUserIds = getAdminUserIds();

  if (adminUserIds.length === 0) {
    console.warn("[sendAdminNotification] 관리자 UID가 설정되지 않아 알림을 발송하지 않습니다.");
    return;
  }

  const promises = adminUserIds.map((adminId) =>
    sendNotification({
      userId: adminId,
      type: params.type,
      title: params.title,
      message: params.message,
      relatedOrderId: params.relatedOrderId,
      relatedRefundId: params.relatedRefundId,
    })
  );

  await Promise.all(promises);
}