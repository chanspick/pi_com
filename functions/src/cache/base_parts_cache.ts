// functions/src/cache/base_parts_cache.ts
// Base Parts 인메모리 캐시 - REQ-CACHE-001
// 시스템은 항상 base_parts 조회 시 캐시를 우선 확인해야 한다

import * as admin from "firebase-admin";

// 캐시 엔트리 타입
interface CacheEntry {
  data: any;
  expiresAt: number;
}

// 캐시 저장소
const cache = new Map<string, CacheEntry>();

// 진행 중인 요청 저장 (동시 요청 중복 방지)
const pendingRequests = new Map<string, Promise<any>>();

// 캐시 TTL: 1시간 (밀리초)
const CACHE_TTL = 60 * 60 * 1000;

// 캐시 통계
let cacheHits = 0;
let cacheMisses = 0;

// Firestore 인스턴스
const getDb = () => admin.firestore();

// 현재 시간 (테스트 모킹 지원)
const getCurrentTime = () => Date.now();

/**
 * 캐시 키 생성
 */
function getCacheKey(type: string, id: string): string {
  return `${type}:${id}`;
}

/**
 * 캐시에서 데이터 조회
 */
function getFromCache(key: string): any | null {
  const entry = cache.get(key);

  if (!entry) {
    return null;
  }

  // TTL 만료 확인
  if (getCurrentTime() > entry.expiresAt) {
    cache.delete(key);
    return null;
  }

  return entry.data;
}

/**
 * 캐시에 데이터 저장
 */
function setToCache(key: string, data: any): void {
  cache.set(key, {
    data,
    expiresAt: getCurrentTime() + CACHE_TTL,
  });
}

/**
 * BasePart 단일 조회 (캐시 우선)
 * REQ-CACHE-001: 시스템은 항상 base_parts 조회 시 캐시를 우선 확인해야 한다
 *
 * @param basePartId - BasePart 문서 ID
 * @returns BasePart 데이터 또는 null
 */
export async function getCachedBasePart(basePartId: string): Promise<any | null> {
  const cacheKey = getCacheKey("basePart", basePartId);

  // 1. 캐시 확인
  const cachedData = getFromCache(cacheKey);
  if (cachedData !== null) {
    cacheHits++;
    return cachedData;
  }

  // 2. 동시 요청 중복 방지
  const pendingRequest = pendingRequests.get(cacheKey);
  if (pendingRequest) {
    return pendingRequest;
  }

  // 3. Firestore에서 조회
  const fetchPromise = (async () => {
    try {
      cacheMisses++;
      const db = getDb();
      const doc = await db.collection("base_parts").doc(basePartId).get();

      if (!doc.exists) {
        // 존재하지 않는 경우도 캐시 (null로)
        setToCache(cacheKey, null);
        return null;
      }

      const data = doc.data();
      setToCache(cacheKey, data);
      return data;
    } finally {
      // 완료 후 pending 제거
      pendingRequests.delete(cacheKey);
    }
  })();

  // pending 요청 등록
  pendingRequests.set(cacheKey, fetchPromise);

  return fetchPromise;
}

/**
 * 카테고리별 BaseParts 조회 (캐시 우선)
 *
 * @param category - 카테고리 (CPU, GPU, RAM 등)
 * @returns BasePart 배열
 */
export async function getCachedBasePartsByCategory(category: string): Promise<any[]> {
  const cacheKey = getCacheKey("category", category);

  // 1. 캐시 확인
  const cachedData = getFromCache(cacheKey);
  if (cachedData !== null) {
    cacheHits++;
    return cachedData;
  }

  // 2. 동시 요청 중복 방지
  const pendingRequest = pendingRequests.get(cacheKey);
  if (pendingRequest) {
    return pendingRequest;
  }

  // 3. Firestore에서 조회
  const fetchPromise = (async () => {
    try {
      cacheMisses++;
      const db = getDb();
      const snapshot = await db
        .collection("base_parts")
        .where("category", "==", category)
        .get();

      if (snapshot.empty) {
        setToCache(cacheKey, []);
        return [];
      }

      const results = snapshot.docs.map((doc) => ({
        basePartId: doc.id,
        ...doc.data(),
      }));

      setToCache(cacheKey, results);
      return results;
    } finally {
      pendingRequests.delete(cacheKey);
    }
  })();

  pendingRequests.set(cacheKey, fetchPromise);

  return fetchPromise;
}

/**
 * 캐시 무효화
 *
 * @param basePartId - 특정 BasePart ID (없으면 전체 캐시 무효화)
 */
export function invalidateBasePartCache(basePartId?: string): void {
  if (basePartId) {
    // 특정 BasePart만 무효화
    const cacheKey = getCacheKey("basePart", basePartId);
    cache.delete(cacheKey);

    // 해당 BasePart가 포함된 카테고리 캐시도 무효화
    // (카테고리 캐시는 전체 무효화 - 특정 카테고리를 알 수 없으므로)
    for (const key of cache.keys()) {
      if (key.startsWith("category:")) {
        cache.delete(key);
      }
    }
  } else {
    // 전체 캐시 무효화
    cache.clear();
    // 통계 초기화
    cacheHits = 0;
    cacheMisses = 0;
  }
}

/**
 * 캐시 통계 조회
 *
 * @returns 캐시 크기와 히트율
 */
export function getCacheStats(): { size: number; hitRate: number } {
  const totalRequests = cacheHits + cacheMisses;
  const hitRate = totalRequests > 0 ? cacheHits / totalRequests : 0;

  return {
    size: cache.size,
    hitRate,
  };
}

/**
 * 캐시 워밍업 - 자주 조회되는 카테고리 미리 로드
 *
 * @param categories - 미리 로드할 카테고리 배열
 */
export async function warmUpCache(categories: string[]): Promise<void> {
  const promises = categories.map((category) =>
    getCachedBasePartsByCategory(category)
  );
  await Promise.all(promises);
  console.log(`Cache warmed up for categories: ${categories.join(", ")}`);
}

/**
 * 캐시 정리 - 만료된 엔트리 제거
 * 주기적으로 호출하여 메모리 관리
 */
export function cleanupExpiredCache(): number {
  const now = getCurrentTime();
  let removed = 0;

  for (const [key, entry] of cache.entries()) {
    if (now > entry.expiresAt) {
      cache.delete(key);
      removed++;
    }
  }

  if (removed > 0) {
    console.log(`Cleaned up ${removed} expired cache entries`);
  }

  return removed;
}

/**
 * BasePart 업데이트 시 캐시 갱신
 * Firestore 트리거에서 호출
 *
 * @param basePartId - BasePart 문서 ID
 * @param newData - 새 데이터
 */
export function updateCacheOnWrite(basePartId: string, newData: any): void {
  const cacheKey = getCacheKey("basePart", basePartId);
  setToCache(cacheKey, newData);

  // 카테고리 캐시도 무효화 (새 데이터가 포함된 카테고리)
  if (newData?.category) {
    const categoryKey = getCacheKey("category", newData.category);
    cache.delete(categoryKey);
  }
}
