import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";

admin.initializeApp();

// ============================================================================
// 타입 정의
// ============================================================================

interface ListingData {
  basePartId: string;
  status: string;
  price: number;
  [key: string]: any;
}

interface BasePartStats {
  lowestPrice: number;
  averagePrice: number;
  listingCount: number;
}

interface PriceAlertData {
  userId: string;
  basePartId: string;
  partName: string;
  targetPrice: number;
  isActive: boolean;
  triggeredAt?: admin.firestore.Timestamp;
  lastCheckedAt?: admin.firestore.Timestamp;
}

interface DragonBallData {
  userId: string;
  partName: string;
  expiresAt: admin.firestore.Timestamp;
  status: string;
  [key: string]: any;
}

function generateCpuKeywords(part: Record<string, any>): string[] {
  const keywords = new Set<string>();
  if (part.basePartId) {
    part.basePartId.split("-").forEach((k: string) => keywords.add(k.toLowerCase()));
  }
  if (part.brand) keywords.add(part.brand.toLowerCase());
  if (part.modelName) {
    part.modelName.split(/\s+/).forEach((k: string) => keywords.add(k.toLowerCase()));
  }
  if (part.generation) keywords.add(part.generation.toLowerCase());
  if (part.codename) keywords.add(part.codename.toLowerCase());
  if (part.cores) keywords.add(`${part.cores}코어`);
  if (part.socket) keywords.add(part.socket.toLowerCase());
  return Array.from(keywords);
}

function generateGpuKeywords(part: Record<string, any>): string[] {
  const keywords = new Set<string>();
  if (part.basePartId) {
    part.basePartId.split("-").forEach((k: string) => keywords.add(k.toLowerCase()));
  }
  if (part.brand) keywords.add(part.brand.toLowerCase());
  if (part.modelName) {
    part.modelName.split(/\s+/).forEach((k: string) => keywords.add(k.toLowerCase()));
  }
  if (part.chipset?.model) keywords.add(part.chipset.model.toLowerCase());
  if (part.chipset?.series) keywords.add(part.chipset.series.toLowerCase());
  if (part.chipset?.vendor) keywords.add(part.chipset.vendor.toLowerCase());
  if (part.memory?.sizeGb) keywords.add(`${part.memory.sizeGb}gb`);
  return Array.from(keywords);
}

function generateMainboardKeywords(part: Record<string, any>): string[] {
  const keywords = new Set<string>();
  if (part.basePartId) {
    part.basePartId.split("-").forEach((k: string) => keywords.add(k.toLowerCase()));
  }
  if (part.brand) keywords.add(part.brand.toLowerCase());
  if (part.modelName) {
    part.modelName.split(/\s+/).forEach((k: string) => keywords.add(k.toLowerCase()));
  }
  if (part.chipset) keywords.add(part.chipset.toLowerCase());
  if (part.socket) keywords.add(part.socket.toLowerCase());
  if (part.formFactor) keywords.add(part.formFactor.toLowerCase());
  if (part.platform) keywords.add(part.platform.toLowerCase());
  return Array.from(keywords);
}

function generateSimpleKeywords(part: Record<string, any>): string[] {
  const keywords = new Set<string>();
  if (part.basePartId) {
    part.basePartId.split("-").forEach((k: string) => keywords.add(k.toLowerCase()));
  }
  if (part.brand) keywords.add(part.brand.toLowerCase());
  if (part.modelName) {
    part.modelName.split(/\s+/).forEach((k: string) => keywords.add(k.toLowerCase()));
  }
  const category = part.category?.toLowerCase();
  if (category === "ram") {
    if (part.capacity) keywords.add(`${part.capacity}gb`);
    if (part.memoryType) keywords.add(part.memoryType.toLowerCase());
  } else if (category === "ssd") {
    if (part.capacity) {
      keywords.add(`${part.capacity}gb`);
      if (part.capacity >= 1000) {
        keywords.add(`${Math.floor(part.capacity / 1000)}tb`);
      }
    }
  } else if (category === "psu") {
    if (part.wattage) keywords.add(`${part.wattage}w`);
  }
  return Array.from(keywords);
}

function generateSearchKeywords(part: Record<string, any>): string[] {
  const category = part.category?.toLowerCase();
  switch (category) {
    case "cpu": return generateCpuKeywords(part);
    case "gpu": return generateGpuKeywords(part);
    case "mainboard": return generateMainboardKeywords(part);
    case "ram":
    case "ssd":
    case "psu": return generateSimpleKeywords(part);
    default: return generateSimpleKeywords(part);
  }
}

export const addSearchKeywordsToParts = functions.region("asia-northeast3").https.onCall(async (data: any) => {
  const {startAfter, batchSize = 500} = data;
  try {
    let query = admin.firestore().collection("parts").orderBy("partId").limit(batchSize);
    if (startAfter) query = query.startAfter(startAfter);
    const snapshot = await query.get();
    if (snapshot.empty) {
      return {success: true, updatedCount: 0, hasMore: false, message: "더 이상 업데이트할 Part가 없습니다."};
    }
    const batch = admin.firestore().batch();
    let updatedCount = 0;
    snapshot.docs.forEach((doc) => {
      const partData = doc.data();
      const searchKeywords = generateSearchKeywords(partData);
      batch.update(doc.ref, {searchKeywords});
      updatedCount++;
    });
    await batch.commit();
    const lastDoc = snapshot.docs[snapshot.docs.length - 1];
    const lastPartId = lastDoc.data().partId;
    return {success: true, updatedCount, hasMore: snapshot.docs.length === batchSize, lastPartId, message: `${updatedCount}개 Part에 searchKeywords 추가 완료`};
  } catch (error: any) {
    console.error("Error:", error);
    throw new functions.https.HttpsError("internal", error.message);
  }
});

export const searchParts = functions.region("asia-northeast3").https.onCall(async (data: any) => {
  const {category, query} = data;
  if (!category || !query) {
    throw new functions.https.HttpsError("invalid-argument", "category and query required");
  }
  const lowerQuery = query.toLowerCase().trim();
  const snapshot = await admin.firestore().collection("parts").where("category", "==", category).where("searchKeywords", "array-contains", lowerQuery).limit(50).get();
  const results = snapshot.docs.map((doc) => ({partId: doc.id, ...doc.data()}));

  // 🔍 디버그: 검색 결과 확인
  if (results.length > 0) {
    console.log("🔍 searchParts 첫 번째 결과:", JSON.stringify(results[0]));
  }

  return results;
});

export const onPartCreated = functions.region("asia-northeast3").firestore.document("parts/{partId}").onCreate(async (snap: admin.firestore.QueryDocumentSnapshot) => {
  const partData = snap.data();
  const searchKeywords = generateSearchKeywords(partData);
  return snap.ref.update({searchKeywords});
});

// ============================================================================
// A. BasePart listingCount 자동 업데이트
// ============================================================================

/**
 * BasePart의 통계 재계산 함수
 * active listings만 대상으로 lowestPrice, averagePrice, listingCount 업데이트
 */
async function recalculateBasePartStats(basePartId: string): Promise<void> {
  const db = admin.firestore();

  // active listings만 조회
  const activeListingsSnapshot = await db
    .collection("listings")
    .where("basePartId", "==", basePartId)
    .where("status", "==", "available")
    .get();

  if (activeListingsSnapshot.empty) {
    // active listings가 없으면 0으로 설정 (set with merge to create if doesn't exist)
    await db.collection("baseParts").doc(basePartId).set({
      lowestPrice: 0,
      averagePrice: 0,
      listingCount: 0,
    }, {merge: true});
    console.log(`BasePart ${basePartId}: No active listings, stats reset to 0`);
    return;
  }

  // 가격 통계 계산 및 첫 번째 listing에서 기본 정보 가져오기
  const firstListing = activeListingsSnapshot.docs[0].data() as ListingData;
  const prices = activeListingsSnapshot.docs.map((doc) => {
    const data = doc.data() as ListingData;
    return data.price;
  });

  const lowestPrice = Math.min(...prices);
  const averagePrice = prices.reduce((sum, p) => sum + p, 0) / prices.length;
  const listingCount = prices.length;

  const stats: BasePartStats = {
    lowestPrice,
    averagePrice: Math.round(averagePrice * 100) / 100, // 소수점 2자리
    listingCount,
  };

  // BasePart 문서 생성/업데이트 (merge: true로 문서가 없으면 생성)
  const updateData: {[key: string]: any} = {
    basePartId: basePartId,
    modelName: firstListing.modelName || "",
    category: firstListing.category || "",
    brand: firstListing.brand || "",  // ✅ listing에서 brand 가져오기
    lowestPrice: stats.lowestPrice,
    averagePrice: stats.averagePrice,
    listingCount: stats.listingCount,
  };
  await db.collection("baseParts").doc(basePartId).set(updateData, {merge: true});

  console.log(`BasePart ${basePartId} stats updated:`, stats, `brand: ${updateData.brand}`);
}

/**
 * Listing 생성 시 트리거
 */
export const onListingCreated = functions
  .region("asia-northeast3")
  .firestore.document("listings/{listingId}")
  .onCreate(async (snap: admin.firestore.QueryDocumentSnapshot) => {
    const data = snap.data() as ListingData;
    if (data.basePartId && data.status === "available") {
      await recalculateBasePartStats(data.basePartId);
    }
  });

/**
 * Listing 업데이트 시 트리거 (상태 변경 감지)
 */
export const onListingUpdated = functions
  .region("asia-northeast3")
  .firestore.document("listings/{listingId}")
  .onUpdate(async (change: functions.Change<functions.firestore.QueryDocumentSnapshot>) => {
    const before = change.before.data() as ListingData;
    const after = change.after.data() as ListingData;

    // status가 변경된 경우에만 재계산
    if (before.status !== after.status && after.basePartId) {
      await recalculateBasePartStats(after.basePartId);
    }

    // price가 변경된 경우에도 재계산 (available 상태일 때만)
    if (before.price !== after.price && after.status === "available" && after.basePartId) {
      await recalculateBasePartStats(after.basePartId);
    }
  });

/**
 * Listing 삭제 시 트리거
 */
export const onListingDeleted = functions
  .region("asia-northeast3")
  .firestore.document("listings/{listingId}")
  .onDelete(async (snap: admin.firestore.QueryDocumentSnapshot) => {
    const data = snap.data() as ListingData;
    if (data.basePartId) {
      await recalculateBasePartStats(data.basePartId);
    }
  });

// ============================================================================
// B. 가격 알림 자동화
// ============================================================================

/**
 * 매일 오전 10시에 실행되는 가격 알림 체크 스케줄러
 * 활성화된 알림 중 목표가에 도달한 경우 알림 발송
 */
export const checkPriceAlerts = functions
  .region("asia-northeast3")
  .pubsub.schedule("0 10 * * *") // 매일 오전 10시
  .timeZone("Asia/Seoul")
  .onRun(async () => {
    const db = admin.firestore();
    const now = admin.firestore.Timestamp.now();

    console.log("Price alert check started at", now.toDate());

    // 활성화된 알림 조회
    const alertsSnapshot = await db
      .collection("priceAlerts")
      .where("isActive", "==", true)
      .where("triggeredAt", "==", null)
      .get();

    if (alertsSnapshot.empty) {
      console.log("No active price alerts to check");
      return;
    }

    console.log(`Found ${alertsSnapshot.size} active price alerts`);

    const batch = db.batch();
    let triggeredCount = 0;

    for (const alertDoc of alertsSnapshot.docs) {
      const alert = alertDoc.data() as PriceAlertData;

      // BasePart의 현재 최저가 조회
      const basePartDoc = await db.collection("baseParts").doc(alert.basePartId).get();

      if (!basePartDoc.exists) {
        console.log(`BasePart ${alert.basePartId} not found for alert ${alertDoc.id}`);
        continue;
      }

      const basePart = basePartDoc.data();
      const currentLowestPrice = basePart?.lowestPrice || 0;

      // lastCheckedAt 업데이트
      batch.update(alertDoc.ref, {lastCheckedAt: now});

      // 목표가 도달 여부 확인
      if (currentLowestPrice > 0 && currentLowestPrice <= alert.targetPrice) {
        // 알림 발송 (FCM 사용)
        try {
          // 사용자의 FCM 토큰 조회
          const userDoc = await db.collection("users").doc(alert.userId).get();
          const userData = userDoc.data();
          const fcmToken = userData?.fcmToken;

          if (fcmToken) {
            const message = {
              token: fcmToken,
              notification: {
                title: "🎉 가격 알림!",
                body: `${alert.partName}이(가) 목표가 ${alert.targetPrice.toLocaleString()}원에 도달했습니다! (현재 최저가: ${currentLowestPrice.toLocaleString()}원)`,
              },
              data: {
                type: "price_alert",
                basePartId: alert.basePartId,
                alertId: alertDoc.id,
                currentPrice: currentLowestPrice.toString(),
                targetPrice: alert.targetPrice.toString(),
              },
            };

            await admin.messaging().send(message);
            console.log(`Price alert notification sent to user ${alert.userId} for ${alert.partName}`);
          } else {
            console.log(`No FCM token for user ${alert.userId}`);
          }

          // 알림 트리거 상태 업데이트
          batch.update(alertDoc.ref, {
            triggeredAt: now,
            isActive: false, // 알림 발송 후 비활성화
          });

          triggeredCount++;
        } catch (error) {
          console.error(`Failed to send notification for alert ${alertDoc.id}:`, error);
        }
      }
    }

    await batch.commit();
    console.log(`Price alert check completed. ${triggeredCount} alerts triggered out of ${alertsSnapshot.size}`);
  });

// ============================================================================
// C. 드래곤볼 만료 알림 자동화
// ============================================================================

/**
 * 매일 오전 9시에 실행되는 드래곤볼 만료 체크 스케줄러
 * 1. 만료 3일 전 알림 발송
 * 2. 만료된 드래곤볼 자동 배송 처리 (status: stored인 경우)
 */
export const checkDragonBallExpiry = functions
  .region("asia-northeast3")
  .pubsub.schedule("0 9 * * *") // 매일 오전 9시
  .timeZone("Asia/Seoul")
  .onRun(async () => {
    const db = admin.firestore();
    const now = new Date();

    console.log("DragonBall expiry check started at", now);

    // 1. 만료 3일 전 알림 발송
    const threeDaysLater = new Date(now);
    threeDaysLater.setDate(threeDaysLater.getDate() + 3);
    threeDaysLater.setHours(23, 59, 59, 999);

    const threeDaysEarlier = new Date(now);
    threeDaysEarlier.setDate(threeDaysEarlier.getDate() + 3);
    threeDaysEarlier.setHours(0, 0, 0, 0);

    // 만료 3일 전인 드래곤볼 조회 (stored 상태만)
    const expiringSoonSnapshot = await db
      .collectionGroup("dragonBalls")
      .where("status", "==", "stored")
      .where("expiresAt", ">=", admin.firestore.Timestamp.fromDate(threeDaysEarlier))
      .where("expiresAt", "<=", admin.firestore.Timestamp.fromDate(threeDaysLater))
      .get();

    console.log(`Found ${expiringSoonSnapshot.size} DragonBalls expiring in 3 days`);

    for (const dragonBallDoc of expiringSoonSnapshot.docs) {
      const dragonBall = dragonBallDoc.data() as DragonBallData;

      try {
        // 사용자의 FCM 토큰 조회
        const userDoc = await db.collection("users").doc(dragonBall.userId).get();
        const userData = userDoc.data();
        const fcmToken = userData?.fcmToken;

        if (fcmToken) {
          const message = {
            token: fcmToken,
            notification: {
              title: "⚠️ 드래곤볼 만료 임박",
              body: `${dragonBall.partName}의 보관 기간이 3일 후 만료됩니다. 일괄 배송을 신청해주세요!`,
            },
            data: {
              type: "dragonball_expiring",
              dragonBallId: dragonBallDoc.id,
              userId: dragonBall.userId,
              expiresAt: dragonBall.expiresAt.toDate().toISOString(),
            },
          };

          await admin.messaging().send(message);
          console.log(`Expiry warning sent for DragonBall ${dragonBallDoc.id} (user: ${dragonBall.userId})`);
        }
      } catch (error) {
        console.error(`Failed to send expiry warning for DragonBall ${dragonBallDoc.id}:`, error);
      }
    }

    // 2. 만료된 드래곤볼 처리
    const expiredSnapshot = await db
      .collectionGroup("dragonBalls")
      .where("status", "==", "stored")
      .where("expiresAt", "<=", admin.firestore.Timestamp.now())
      .get();

    console.log(`Found ${expiredSnapshot.size} expired DragonBalls`);

    const batch = db.batch();
    let processedCount = 0;

    for (const dragonBallDoc of expiredSnapshot.docs) {
      const dragonBall = dragonBallDoc.data() as DragonBallData;

      try {
        // 만료 알림 발송
        const userDoc = await db.collection("users").doc(dragonBall.userId).get();
        const userData = userDoc.data();
        const fcmToken = userData?.fcmToken;

        if (fcmToken) {
          const message = {
            token: fcmToken,
            notification: {
              title: "📦 드래곤볼 자동 배송",
              body: `${dragonBall.partName}의 보관 기간이 만료되어 기본 배송지로 자동 배송 처리되었습니다.`,
            },
            data: {
              type: "dragonball_auto_shipped",
              dragonBallId: dragonBallDoc.id,
              userId: dragonBall.userId,
            },
          };

          await admin.messaging().send(message);
        }

        // DragonBall 상태를 packing으로 변경
        batch.update(dragonBallDoc.ref, {
          status: "packing",
          shippedAt: admin.firestore.Timestamp.now(),
        });

        processedCount++;
        console.log(`DragonBall ${dragonBallDoc.id} auto-shipped (user: ${dragonBall.userId})`);
      } catch (error) {
        console.error(`Failed to auto-ship DragonBall ${dragonBallDoc.id}:`, error);
      }
    }

    if (processedCount > 0) {
      await batch.commit();
    }

    console.log(
      `DragonBall expiry check completed. ` +
      `${expiringSoonSnapshot.size} warnings sent, ${processedCount} auto-shipped`
    );
  });
