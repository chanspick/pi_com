// functions/src/schedulers/storage_scheduler.ts

import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";

const db = admin.firestore();

/**
 * 보관 서비스 알림 스케줄러
 * 매일 09:00 (KST) 실행하여 보관 기간별 알림 발송
 */
export const checkStorageNotifications = functions
  .region("asia-northeast3")
  .pubsub.schedule("0 9 * * *") // 매일 09:00
  .timeZone("Asia/Seoul")
  .onRun(async () => {
    console.log("Storage notifications scheduler started");

    const today = new Date();
    today.setHours(0, 0, 0, 0);

    try {
      // DragonBall 컬렉션에서 active 상태인 보관 아이템 조회
      const dragonBallsSnapshot = await db
        .collection("dragonBalls")
        .where("status", "in", ["active", "rental"])
        .get();

      console.log(`Found ${dragonBallsSnapshot.size} active storage items`);

      const notifications: Promise<any>[] = [];

      for (const doc of dragonBallsSnapshot.docs) {
        const dragonBall = doc.data();
        const createdAt = dragonBall.createdAt.toDate();
        const daysSinceCreation = Math.floor(
          (today.getTime() - createdAt.getTime()) / (1000 * 60 * 60 * 24)
        );

        const userId = dragonBall.userId;
        const dragonBallId = doc.id;
        const partName = dragonBall.partName || "보관 부품";
        const storageType = dragonBall.storageType || "general";

        // 7일차: 보관 서비스 이용 안내 (일반 보관만)
        if (daysSinceCreation === 7 && storageType === "general") {
          notifications.push(
            sendNotification({
              userId,
              type: "storageReminder",
              title: "보관 중인 부품 안내",
              message: `${partName}이(가) 보관된 지 7일이 지났습니다. 언제든지 출고 또는 판매 등록이 가능합니다.`,
              relatedDragonBallId: dragonBallId,
            })
          );
          console.log(
            `7-day reminder sent for DragonBall ${dragonBallId} (${partName})`
          );
        }

        // 50일차: 위탁 전환 예정 안내 (일반 보관만)
        if (daysSinceCreation === 50 && storageType === "general") {
          notifications.push(
            sendNotification({
              userId,
              type: "storageWarning",
              title: "⚠️ 보관 부품 위탁 전환 예정 안내",
              message: `${partName}의 보관 기간이 50일에 도달했습니다. 60일 후에는 자동으로 위탁 판매로 전환됩니다. 출고를 원하시면 빠른 시일 내에 신청해주세요.`,
              relatedDragonBallId: dragonBallId,
            })
          );
          console.log(
            `50-day warning sent for DragonBall ${dragonBallId} (${partName})`
          );
        }

        // 55일차: 위탁 전환 임박 안내 (일반 보관만)
        if (daysSinceCreation === 55 && storageType === "general") {
          notifications.push(
            sendNotification({
              userId,
              type: "storageUrgent",
              title: "🚨 보관 부품 위탁 전환 임박 (5일 남음)",
              message: `${partName}의 위탁 전환까지 5일 남았습니다. 출고를 원하시면 지금 신청해주세요.`,
              relatedDragonBallId: dragonBallId,
            })
          );
          console.log(
            `55-day urgent sent for DragonBall ${dragonBallId} (${partName})`
          );
        }

        // 58일차: 위탁 전환 최종 안내 (일반 보관만)
        if (daysSinceCreation === 58 && storageType === "general") {
          notifications.push(
            sendNotification({
              userId,
              type: "storageFinalWarning",
              title: "🚨 보관 부품 위탁 전환 최종 안내 (2일 남음)",
              message: `${partName}의 위탁 전환까지 2일 남았습니다. 내일까지 출고 신청이 없으면 자동으로 위탁 판매로 전환됩니다.`,
              relatedDragonBallId: dragonBallId,
            })
          );
          console.log(
            `58-day final warning sent for DragonBall ${dragonBallId} (${partName})`
          );
        }

        // 60일차: 위탁 전환 완료 (자동 전환 로직은 별도 처리)
        if (daysSinceCreation === 60 && storageType === "general") {
          // NOTE: 실제 위탁 전환 로직은 dragon_ball_repository_impl.dart의
          // convertToConsignment() 메서드에서 처리됩니다.
          // 여기서는 알림만 발송합니다.
          notifications.push(
            sendNotification({
              userId,
              type: "consignmentConverted",
              title: "보관 부품 위탁 판매 전환 완료",
              message: `${partName}이(가) 위탁 판매로 전환되었습니다. 판매가 완료되면 수수료를 제외한 금액이 정산됩니다.`,
              relatedDragonBallId: dragonBallId,
            })
          );
          console.log(
            `60-day conversion notification sent for DragonBall ${dragonBallId} (${partName})`
          );
        }
      }

      await Promise.all(notifications);
      console.log(`Sent ${notifications.length} storage notifications`);
    } catch (error) {
      console.error("Error in storage notifications scheduler:", error);
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
