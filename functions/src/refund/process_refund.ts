// functions/src/refund/process_refund.ts

import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import { cancelKakaoPayment } from "./kakao_pay_cancel";

const db = admin.firestore();

/**
 * 환불 완료 처리 Cloud Function
 * Trigger: HTTPS Callable Function (관리자 또는 시스템 호출)
 *
 * 환불 검수가 합격한 후 호출되어 실제 결제 취소 및 환불 완료 처리를 수행합니다.
 */
export const processRefundCompletion = functions
  .region("asia-northeast3")
  .https.onCall(async (data, context) => {
    // 인증 확인
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "사용자 인증이 필요합니다."
      );
    }

    const { refundId } = data;

    if (!refundId) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "refundId가 필요합니다."
      );
    }

    try {
      // 1. 환불 요청 조회
      const refundDoc = await db
        .collection("refundRequests")
        .doc(refundId)
        .get();
      if (!refundDoc.exists) {
        throw new functions.https.HttpsError(
          "not-found",
          "환불 요청을 찾을 수 없습니다."
        );
      }

      const refundData = refundDoc.data()!;
      const orderId = refundData.orderId;
      const userId = refundData.userId;
      const sellerId = refundData.sellerId;
      const refundAmount = refundData.refundAmount;

      // 2. 검수 합격 상태 확인
      if (refundData.status !== "inspectionPass") {
        throw new functions.https.HttpsError(
          "failed-precondition",
          `검수 합격 상태만 환불 처리가 가능합니다. 현재 상태: ${refundData.status}`
        );
      }

      console.log(`환불 처리 시작: ${refundId}, 주문: ${orderId}, 금액: ${refundAmount}원`);

      // 3. 환불 처리 중 상태로 업데이트
      await db.collection("refundRequests").doc(refundId).update({
        status: "refundProcessing",
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // 4. 카카오페이 결제 취소
      console.log(`카카오페이 결제 취소 요청 - 주문: ${orderId}, 금액: ${refundAmount}원`);
      const cancelResult = await cancelKakaoPayment(orderId, refundAmount);

      // 5. 환불 완료 상태로 업데이트
      await db.collection("refundRequests").doc(refundId).update({
        status: "refundCompleted",
        refundCompletedAt: admin.firestore.FieldValue.serverTimestamp(),
        kakaoPayCancelTid: cancelResult.tid,
        kakaoPayCancelAid: cancelResult.aid,
        kakaoPa yRefundResponse: cancelResult,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // 6. 주문 상태 업데이트
      await db.collection("orders").doc(orderId).update({
        status: "refundCompleted",
        refundCompletedAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // 7. 구매자에게 환불 완료 알림
      await db.collection("notifications").add({
        userId: userId,
        type: "refundCompleted",
        title: "환불이 완료되었습니다",
        message: `환불 금액 ${refundAmount.toLocaleString()}원이 결제 수단으로 환불되었습니다. 카드사에 따라 2~5영업일이 소요될 수 있습니다.`,
        relatedOrderId: orderId,
        relatedRefundId: refundId,
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // 8. 판매자에게 환불 완료 알림
      await db.collection("notifications").add({
        userId: sellerId,
        type: "sellerRefundCompleted",
        title: "구매자 환불이 완료되었습니다",
        message: `주문 ${orderId}의 환불이 완료되었습니다. 환불 금액: ${refundAmount.toLocaleString()}원`,
        relatedOrderId: orderId,
        relatedRefundId: refundId,
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(`환불 완료 처리 성공: ${refundId}`);

      return {
        success: true,
        refundId: refundId,
        refundAmount: refundAmount,
        kakaoPayCancelTid: cancelResult.tid,
        message: "환불이 성공적으로 처리되었습니다.",
      };
    } catch (error: any) {
      console.error("환불 처리 실패:", error);

      // 환불 실패 상태로 업데이트
      try {
        await db.collection("refundRequests").doc(refundId).update({
          status: "inspectionPass", // 다시 검수 합격 상태로 되돌림 (재시도 가능)
          refundError: {
            message: error.message,
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
          },
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      } catch (updateError) {
        console.error("환불 실패 상태 업데이트 실패:", updateError);
      }

      throw new functions.https.HttpsError(
        "internal",
        `환불 처리 실패: ${error.message}`
      );
    }
  });

/**
 * 환불 검수 자동 승인 스케줄러
 * 매일 02:00 (KST) 실행하여 검수 기한(3영업일)이 지난 환불을 자동 승인
 *
 * 참고: 실제로는 관리자가 수동으로 검수하는 것이 안전하지만,
 * 기한이 지난 경우 자동 처리하여 고객 경험을 개선합니다.
 */
export const autoApproveRefundInspection = functions
  .region("asia-northeast3")
  .pubsub.schedule("0 2 * * *") // 매일 02:00
  .timeZone("Asia/Seoul")
  .onRun(async () => {
    console.log("환불 검수 자동 승인 스케줄러 시작");

    const today = new Date();
    today.setHours(0, 0, 0, 0);

    try {
      // 검수 대기 중인 환불 조회
      const refundsSnapshot = await db
        .collection("refundRequests")
        .where("status", "in", ["itemReceived", "inspectionInProgress"])
        .get();

      console.log(`검수 대기 중인 환불 ${refundsSnapshot.size}건 발견`);

      const approvalPromises: Promise<any>[] = [];

      for (const doc of refundsSnapshot.docs) {
        const refund = doc.data();
        const itemReceivedAt = refund.itemReceivedAt?.toDate();

        if (!itemReceivedAt) {
          console.warn(`환불 ${doc.id}의 itemReceivedAt이 없습니다`);
          continue;
        }

        // 검수 기한(3영업일) 확인
        const daysSinceReceived = Math.floor(
          (today.getTime() - itemReceivedAt.getTime()) / (1000 * 60 * 60 * 24)
        );

        // 3일 이상 지난 경우 자동 합격 처리
        if (daysSinceReceived >= 3) {
          console.log(
            `환불 자동 승인: ${doc.id} (검수 대기 ${daysSinceReceived}일 경과)`
          );

          approvalPromises.push(
            db.collection("refundRequests").doc(doc.id).update({
              status: "inspectionPass",
              inspectionCompletedAt:
                admin.firestore.FieldValue.serverTimestamp(),
              inspectionNote: `자동 검수 합격 (기한 경과: ${daysSinceReceived}일)`,
              inspectorId: "system",
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            })
          );

          // 구매자에게 검수 합격 알림
          approvalPromises.push(
            db.collection("notifications").add({
              userId: refund.userId,
              type: "refundInspectionPass",
              title: "환불 검수 합격",
              message:
                "반품 물품 검수가 완료되었습니다. 환불 처리가 진행됩니다.",
              relatedOrderId: refund.orderId,
              relatedRefundId: doc.id,
              isRead: false,
              createdAt: admin.firestore.FieldValue.serverTimestamp(),
            })
          );
        }
      }

      await Promise.all(approvalPromises);
      const autoApprovedCount = approvalPromises.length / 2; // 업데이트 + 알림 = 2개씩
      console.log(`${autoApprovedCount}건의 환불 자동 승인 완료`);
    } catch (error) {
      console.error("환불 검수 자동 승인 스케줄러 오류:", error);
    }

    return null;
  });

/**
 * 환불 검수 기한 경고 알림 스케줄러
 * 매일 10:00 (KST) 실행하여 검수 기한이 임박한 환불에 대해 관리자에게 알림
 */
export const notifyPendingInspections = functions
  .region("asia-northeast3")
  .pubsub.schedule("0 10 * * *") // 매일 10:00
  .timeZone("Asia/Seoul")
  .onRun(async () => {
    console.log("환불 검수 기한 경고 스케줄러 시작");

    const today = new Date();
    today.setHours(0, 0, 0, 0);

    try {
      // 검수 대기 중인 환불 조회
      const refundsSnapshot = await db
        .collection("refundRequests")
        .where("status", "in", ["itemReceived", "inspectionInProgress"])
        .get();

      console.log(`검수 대기 중인 환불 ${refundsSnapshot.size}건 발견`);

      const notifications: Promise<any>[] = [];

      for (const doc of refundsSnapshot.docs) {
        const refund = doc.data();
        const itemReceivedAt = refund.itemReceivedAt?.toDate();

        if (!itemReceivedAt) continue;

        const daysSinceReceived = Math.floor(
          (today.getTime() - itemReceivedAt.getTime()) / (1000 * 60 * 60 * 24)
        );

        // 2일차: 검수 기한 임박 알림 (3일 중 2일 경과)
        if (daysSinceReceived === 2) {
          notifications.push(
            sendAdminNotification({
              type: "refundInspectionUrgent",
              title: "⚠️ 환불 검수 기한 임박",
              message: `환불 ${doc.id}의 검수 기한이 내일까지입니다. 즉시 검수를 진행해주세요.`,
              relatedRefundId: doc.id,
              relatedOrderId: refund.orderId,
            })
          );

          console.log(`검수 기한 경고 발송: ${doc.id} (2일 경과)`);
        }
      }

      await Promise.all(notifications);
      console.log(`${notifications.length}건의 검수 기한 경고 알림 발송 완료`);
    } catch (error) {
      console.error("환불 검수 기한 경고 스케줄러 오류:", error);
    }

    return null;
  });

/**
 * 관리자에게 알림 발송
 * TODO: 실제 관리자 UID로 교체 필요
 */
async function sendAdminNotification(params: {
  type: string;
  title: string;
  message: string;
  relatedRefundId?: string;
  relatedOrderId?: string;
}) {
  // TODO: 실제 관리자 UID 설정 필요
  const adminUserIds = ["ADMIN_UID_1", "ADMIN_UID_2"]; // 환경 변수로 관리 권장

  const promises = adminUserIds.map((adminId) =>
    db.collection("notifications").add({
      userId: adminId,
      type: params.type,
      title: params.title,
      message: params.message,
      relatedRefundId: params.relatedRefundId,
      relatedOrderId: params.relatedOrderId,
      isRead: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    })
  );

  await Promise.all(promises);
}
