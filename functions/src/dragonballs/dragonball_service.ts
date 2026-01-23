// functions/src/dragonballs/dragonball_service.ts
// DragonBall 서비스 - REQ-OPT-001: DragonBalls 쿼리 최적화
// Hybrid 접근법: 기존 collectionGroup 호환성 유지 + 루트 컬렉션 우선 사용

import * as admin from "firebase-admin";

// Firestore 인스턴스
const getDb = () => admin.firestore();

// 타입 정의
interface DragonBallData {
  userId: string;
  partName?: string;
  status?: string;
  createdAt?: admin.firestore.FieldValue | admin.firestore.Timestamp;
  expiresAt?: admin.firestore.Timestamp;
  [key: string]: any;
}

interface SaveOptions {
  alsoSaveToSubcollection?: boolean;
}

interface QueryOptions {
  limit?: number;
  orderBy?: string;
  orderDirection?: "asc" | "desc";
}

interface QueryFilters {
  userId?: string;
  status?: string;
  [key: string]: any;
}

interface SaveResult {
  success: boolean;
  id?: string;
  error?: string;
}

interface MigrationResult {
  success: boolean;
  migratedId?: string;
  skipped?: boolean;
  error?: string;
}

interface BatchMigrationResult {
  success: boolean;
  processed: number;
  skipped: number;
  failed: number;
  errors: string[];
}

/**
 * 신규 DragonBall을 루트 컬렉션에 저장
 * REQ-OPT-001: 신규 DragonBall은 루트 컬렉션에 저장하여 쿼리 최적화
 *
 * @param data - DragonBall 데이터
 * @param options - 저장 옵션 (서브컬렉션에도 저장할지 여부)
 * @returns 저장 결과
 */
export async function saveDragonBallToRoot(
  data: DragonBallData,
  options: SaveOptions = {}
): Promise<SaveResult> {
  try {
    const db = getDb();

    // 타임스탬프 추가
    const dataWithTimestamp = {
      ...data,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    // 루트 컬렉션에 저장
    const docRef = await db.collection("dragonBalls").add(dataWithTimestamp);

    // 옵션: 서브컬렉션에도 저장 (이중 저장으로 호환성 유지)
    if (options.alsoSaveToSubcollection && data.userId) {
      await db
        .collection("users")
        .doc(data.userId)
        .collection("dragonBalls")
        .doc(docRef.id)
        .set(dataWithTimestamp);
    }

    return {
      success: true,
      id: docRef.id,
    };
  } catch (error: any) {
    console.error("Error saving DragonBall to root:", error);
    return {
      success: false,
      error: error.message || "Unknown error",
    };
  }
}

/**
 * 루트 컬렉션에서 DragonBalls 조회
 * REQ-OPT-001: collectionGroup 대신 루트 컬렉션에서 조회하여 성능 최적화
 *
 * @param filters - 조회 필터 (userId, status 등)
 * @param options - 쿼리 옵션 (limit, orderBy 등)
 * @returns DragonBall 문서 배열
 */
export async function queryDragonBallsFromRoot(
  filters: QueryFilters,
  options: QueryOptions = {}
): Promise<Array<{ id: string; data: DragonBallData }>> {
  try {
    const db = getDb();
    let query: admin.firestore.Query = db.collection("dragonBalls");

    // 필터 적용
    if (filters.userId) {
      query = query.where("userId", "==", filters.userId);
    }
    if (filters.status) {
      query = query.where("status", "==", filters.status);
    }

    // 추가 필터 적용 (예약어 제외)
    const reservedKeys = ["userId", "status"];
    for (const [key, value] of Object.entries(filters)) {
      if (!reservedKeys.includes(key) && value !== undefined) {
        query = query.where(key, "==", value);
      }
    }

    // 정렬 적용
    if (options.orderBy) {
      query = query.orderBy(options.orderBy, options.orderDirection || "desc");
    }

    // limit 적용
    if (options.limit) {
      query = query.limit(options.limit);
    }

    const snapshot = await query.get();

    if (snapshot.empty) {
      return [];
    }

    return snapshot.docs.map((doc) => ({
      id: doc.id,
      data: doc.data() as DragonBallData,
    }));
  } catch (error: any) {
    console.error("Error querying DragonBalls from root:", error);
    return [];
  }
}

/**
 * 서브컬렉션의 DragonBall을 루트 컬렉션으로 마이그레이션
 * 점진적 마이그레이션을 위한 헬퍼 함수
 *
 * @param userId - 사용자 ID
 * @param dragonBallId - DragonBall 문서 ID
 * @returns 마이그레이션 결과
 */
export async function migrateDragonBallToRoot(
  userId: string,
  dragonBallId: string
): Promise<MigrationResult> {
  try {
    const db = getDb();

    // 1. 루트에 이미 존재하는지 확인
    const rootDoc = await db.collection("dragonBalls").doc(dragonBallId).get();

    if (rootDoc.exists) {
      return {
        success: true,
        skipped: true,
        migratedId: dragonBallId,
      };
    }

    // 2. 서브컬렉션에서 데이터 조회
    const subDoc = await db
      .collection("users")
      .doc(userId)
      .collection("dragonBalls")
      .doc(dragonBallId)
      .get();

    if (!subDoc.exists) {
      return {
        success: false,
        error: `DragonBall ${dragonBallId} not found in subcollection`,
      };
    }

    // 3. 루트 컬렉션에 복사
    const data = subDoc.data() as DragonBallData;
    await db.collection("dragonBalls").doc(dragonBallId).set({
      ...data,
      userId, // userId가 없을 경우를 대비해 명시적으로 추가
      migratedAt: admin.firestore.FieldValue.serverTimestamp(),
      migratedFrom: `users/${userId}/dragonBalls/${dragonBallId}`,
    });

    return {
      success: true,
      migratedId: dragonBallId,
    };
  } catch (error: any) {
    console.error("Error migrating DragonBall to root:", error);
    return {
      success: false,
      error: error.message || "Unknown error",
    };
  }
}

/**
 * 서브컬렉션의 DragonBalls를 일괄 마이그레이션
 * 기존 collectionGroup 데이터를 루트 컬렉션으로 이동
 *
 * @param options - 배치 옵션
 * @returns 일괄 마이그레이션 결과
 */
export async function batchMigrateDragonBalls(options: {
  batchSize?: number;
  statusFilter?: string;
} = {}): Promise<BatchMigrationResult> {
  const batchSize = options.batchSize || 100;
  let processed = 0;
  let skipped = 0;
  let failed = 0;
  const errors: string[] = [];

  try {
    const db = getDb();

    // collectionGroup으로 모든 DragonBalls 조회
    let query: admin.firestore.Query = db
      .collectionGroup("dragonBalls")
      .limit(batchSize);

    if (options.statusFilter) {
      query = query.where("status", "==", options.statusFilter);
    }

    const snapshot = await query.get();

    if (snapshot.empty) {
      return {
        success: true,
        processed: 0,
        skipped: 0,
        failed: 0,
        errors: [],
      };
    }

    // 배치 처리
    const batch = db.batch();

    for (const doc of snapshot.docs) {
      try {
        // 경로에서 userId 추출: users/{userId}/dragonBalls/{dragonBallId}
        const pathParts = doc.ref.path.split("/");
        const userId = pathParts[1]; // users 다음 요소가 userId

        // 루트에 이미 존재하는지 확인
        const rootDoc = await db.collection("dragonBalls").doc(doc.id).get();

        if (rootDoc.exists) {
          skipped++;
          continue;
        }

        // 루트 컬렉션에 복사
        const data = doc.data();
        const rootRef = db.collection("dragonBalls").doc(doc.id);

        batch.set(rootRef, {
          ...data,
          userId,
          migratedAt: admin.firestore.FieldValue.serverTimestamp(),
          migratedFrom: doc.ref.path,
        });

        processed++;
      } catch (docError: any) {
        failed++;
        errors.push(`Error processing ${doc.id}: ${docError.message}`);
      }
    }

    // 배치 커밋
    if (processed > 0) {
      await batch.commit();
    }

    return {
      success: true,
      processed,
      skipped,
      failed,
      errors,
    };
  } catch (error: any) {
    console.error("Error in batch migration:", error);
    return {
      success: false,
      processed,
      skipped,
      failed,
      errors: [...errors, error.message || "Unknown error"],
    };
  }
}

/**
 * DragonBall 상태 업데이트 (루트 컬렉션 우선)
 *
 * @param dragonBallId - DragonBall 문서 ID
 * @param status - 새 상태
 * @param additionalData - 추가 데이터
 * @returns 업데이트 결과
 */
export async function updateDragonBallStatus(
  dragonBallId: string,
  status: string,
  additionalData: Record<string, any> = {}
): Promise<SaveResult> {
  try {
    const db = getDb();

    await db.collection("dragonBalls").doc(dragonBallId).update({
      status,
      ...additionalData,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      success: true,
      id: dragonBallId,
    };
  } catch (error: any) {
    console.error("Error updating DragonBall status:", error);
    return {
      success: false,
      error: error.message || "Unknown error",
    };
  }
}
