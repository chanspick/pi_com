// functions/src/__tests__/cache/base_parts_cache.test.ts
// Base Parts 캐시 테스트 - TDD RED 단계
// REQ-CACHE-001: Base_parts 인메모리 캐싱

// 시간 모킹을 위한 설정
jest.useFakeTimers();

// Firebase Admin SDK 모킹 설정
const mockGet = jest.fn();
const mockWhere = jest.fn();
const mockLimit = jest.fn();
const mockCollection = jest.fn();
const mockDoc = jest.fn();

const createChainableMock = () => {
  const chainable: Record<string, jest.Mock> = {};
  chainable.where = jest.fn(() => chainable);
  chainable.limit = jest.fn(() => chainable);
  chainable.orderBy = jest.fn(() => chainable);
  chainable.get = mockGet;
  return chainable;
};

const mockChainable = createChainableMock();

jest.mock('firebase-admin', () => {
  const mockFirestoreInstance = {
    collection: jest.fn((name: string) => {
      if (name === 'base_parts') {
        return {
          doc: jest.fn((id: string) => ({
            get: mockGet,
          })),
          where: mockChainable.where,
          limit: mockChainable.limit,
          orderBy: mockChainable.orderBy,
          get: mockGet,
        };
      }
      return mockChainable;
    }),
  };

  return {
    initializeApp: jest.fn(),
    firestore: Object.assign(
      jest.fn(() => mockFirestoreInstance),
      {
        FieldValue: {
          serverTimestamp: jest.fn(() => 'SERVER_TIMESTAMP'),
        },
      }
    ),
  };
});

describe('Base Parts Cache - REQ-CACHE-001', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    // 캐시 초기화 (모듈 캐시 클리어)
    jest.resetModules();
    // 타이머 초기화
    jest.setSystemTime(new Date('2024-01-15T10:00:00Z'));
  });

  afterEach(() => {
    jest.useRealTimers();
    jest.useFakeTimers();
  });

  describe('getCachedBasePart()', () => {
    it('첫 조회 시 Firestore에서 데이터를 가져와야 한다', async () => {
      // Given: Firestore에 BasePart 데이터
      const basePartId = 'cpu-intel-i9-14900k';
      const mockData = {
        basePartId,
        modelName: 'Intel Core i9-14900K',
        category: 'CPU',
        brand: 'Intel',
        lowestPrice: 650000,
        listingCount: 5,
      };

      mockGet.mockResolvedValue({
        exists: true,
        data: () => mockData,
        id: basePartId,
      });

      // When: getCachedBasePart 호출
      const { getCachedBasePart } = await import('../../cache/base_parts_cache');
      const result = await getCachedBasePart(basePartId);

      // Then: Firestore에서 조회하고 결과 반환
      expect(mockGet).toHaveBeenCalled();
      expect(result).toEqual(mockData);
    });

    it('두 번째 조회 시 캐시에서 데이터를 가져와야 한다', async () => {
      // Given: 첫 조회로 캐시됨
      const basePartId = 'cpu-intel-i9-14900k';
      const mockData = {
        basePartId,
        modelName: 'Intel Core i9-14900K',
      };

      mockGet.mockResolvedValue({
        exists: true,
        data: () => mockData,
        id: basePartId,
      });

      const { getCachedBasePart } = await import('../../cache/base_parts_cache');

      // 첫 조회
      await getCachedBasePart(basePartId);
      const firstCallCount = mockGet.mock.calls.length;

      // When: 두 번째 조회
      const result = await getCachedBasePart(basePartId);

      // Then: Firestore 호출 횟수가 증가하지 않음 (캐시 히트)
      expect(mockGet.mock.calls.length).toBe(firstCallCount);
      expect(result).toEqual(mockData);
    });

    it('캐시 TTL(1시간) 만료 후 Firestore에서 다시 조회해야 한다', async () => {
      // Given: 데이터가 캐시됨
      const basePartId = 'cpu-intel-i9-14900k';
      const mockData = {
        basePartId,
        modelName: 'Intel Core i9-14900K',
      };

      mockGet.mockResolvedValue({
        exists: true,
        data: () => mockData,
        id: basePartId,
      });

      const { getCachedBasePart } = await import('../../cache/base_parts_cache');

      // 첫 조회
      await getCachedBasePart(basePartId);
      const firstCallCount = mockGet.mock.calls.length;

      // When: 1시간 후
      jest.advanceTimersByTime(60 * 60 * 1000 + 1000); // 1시간 + 1초

      // 다시 조회
      await getCachedBasePart(basePartId);

      // Then: Firestore에서 다시 조회
      expect(mockGet.mock.calls.length).toBeGreaterThan(firstCallCount);
    });

    it('존재하지 않는 BasePart는 null을 반환해야 한다', async () => {
      // Given: 존재하지 않는 BasePart
      mockGet.mockResolvedValue({
        exists: false,
      });

      const { getCachedBasePart } = await import('../../cache/base_parts_cache');
      const result = await getCachedBasePart('non-existent-part');

      // Then
      expect(result).toBeNull();
    });
  });

  describe('getCachedBasePartsByCategory()', () => {
    it('카테고리별로 BaseParts를 조회해야 한다', async () => {
      // Given: CPU 카테고리의 BaseParts
      const mockDocs = [
        { id: 'cpu-1', data: () => ({ modelName: 'i9-14900K', category: 'CPU' }) },
        { id: 'cpu-2', data: () => ({ modelName: 'i7-14700K', category: 'CPU' }) },
      ];

      mockGet.mockResolvedValue({
        docs: mockDocs,
        empty: false,
        size: 2,
      });

      // When
      const { getCachedBasePartsByCategory } = await import('../../cache/base_parts_cache');
      const result = await getCachedBasePartsByCategory('CPU');

      // Then
      expect(result.length).toBe(2);
      expect(mockChainable.where).toHaveBeenCalledWith('category', '==', 'CPU');
    });

    it('두 번째 조회 시 캐시에서 가져와야 한다', async () => {
      // Given: 첫 조회
      const mockDocs = [
        { id: 'gpu-1', data: () => ({ modelName: 'RTX 4090', category: 'GPU' }) },
      ];

      mockGet.mockResolvedValue({
        docs: mockDocs,
        empty: false,
        size: 1,
      });

      const { getCachedBasePartsByCategory } = await import('../../cache/base_parts_cache');

      await getCachedBasePartsByCategory('GPU');
      const firstCallCount = mockGet.mock.calls.length;

      // When: 두 번째 조회
      const result = await getCachedBasePartsByCategory('GPU');

      // Then: 캐시 히트
      expect(mockGet.mock.calls.length).toBe(firstCallCount);
      expect(result.length).toBe(1);
    });

    it('빈 카테고리는 빈 배열을 반환해야 한다', async () => {
      // Given
      mockGet.mockResolvedValue({
        docs: [],
        empty: true,
        size: 0,
      });

      const { getCachedBasePartsByCategory } = await import('../../cache/base_parts_cache');
      const result = await getCachedBasePartsByCategory('EMPTY_CATEGORY');

      // Then
      expect(result).toEqual([]);
    });
  });

  describe('invalidateBasePartCache()', () => {
    it('특정 BasePart 캐시를 무효화해야 한다', async () => {
      // Given: 캐시에 데이터가 있음
      const basePartId = 'cpu-intel-i9-14900k';
      const mockData = { basePartId, modelName: 'i9-14900K' };

      mockGet.mockResolvedValue({
        exists: true,
        data: () => mockData,
        id: basePartId,
      });

      const { getCachedBasePart, invalidateBasePartCache } = await import('../../cache/base_parts_cache');

      // 캐시에 저장
      await getCachedBasePart(basePartId);
      const callsAfterFirstGet = mockGet.mock.calls.length;

      // When: 캐시 무효화
      invalidateBasePartCache(basePartId);

      // 다시 조회
      await getCachedBasePart(basePartId);

      // Then: Firestore에서 다시 조회해야 함
      expect(mockGet.mock.calls.length).toBeGreaterThan(callsAfterFirstGet);
    });

    it('전체 캐시를 무효화할 수 있어야 한다', async () => {
      // Given: 여러 BasePart가 캐시에 있음
      mockGet.mockResolvedValue({
        exists: true,
        data: () => ({ modelName: 'Test Part' }),
        id: 'test-part',
      });

      const { getCachedBasePart, invalidateBasePartCache, getCacheStats } = await import('../../cache/base_parts_cache');

      await getCachedBasePart('part-1');
      await getCachedBasePart('part-2');

      // When: 전체 캐시 무효화
      invalidateBasePartCache(); // 파라미터 없으면 전체 무효화

      // Then: 캐시가 비어있어야 함
      const stats = getCacheStats();
      expect(stats.size).toBe(0);
    });

    it('특정 BasePart 무효화 시 관련 카테고리 캐시도 무효화해야 한다', async () => {
      // Given: BasePart와 카테고리 모두 캐시에 있음
      const basePartId = 'cpu-intel-i9-14900k';

      // 개별 BasePart 조회 모킹
      mockGet.mockResolvedValueOnce({
        exists: true,
        data: () => ({ modelName: 'i9-14900K', category: 'CPU' }),
        id: basePartId,
      });

      // 카테고리 조회 모킹
      mockGet.mockResolvedValueOnce({
        docs: [{ id: basePartId, data: () => ({ modelName: 'i9-14900K', category: 'CPU' }) }],
        empty: false,
        size: 1,
      });

      const { getCachedBasePart, getCachedBasePartsByCategory, invalidateBasePartCache, getCacheStats } = await import('../../cache/base_parts_cache');

      // 캐시에 저장
      await getCachedBasePart(basePartId);
      await getCachedBasePartsByCategory('CPU');

      const statsBeforeInvalidate = getCacheStats();
      expect(statsBeforeInvalidate.size).toBe(2); // basePart + category

      // When: 특정 BasePart 무효화 (카테고리 캐시도 같이 무효화됨)
      invalidateBasePartCache(basePartId);

      // Then: 개별 캐시만 남음 (카테고리 캐시는 무효화됨)
      const statsAfterInvalidate = getCacheStats();
      expect(statsAfterInvalidate.size).toBe(0); // 둘 다 무효화됨
    });

    it('특정 BasePart 무효화 시 카테고리 캐시가 없어도 정상 작동해야 한다', async () => {
      // Given: BasePart만 캐시에 있음 (카테고리 캐시 없음)
      mockGet.mockResolvedValueOnce({
        exists: true,
        data: () => ({ modelName: 'i9-14900K' }),
        id: 'part-1',
      });

      mockGet.mockResolvedValueOnce({
        exists: true,
        data: () => ({ modelName: 'RTX 4090' }),
        id: 'part-2',
      });

      const { getCachedBasePart, invalidateBasePartCache, getCacheStats } = await import('../../cache/base_parts_cache');

      // 캐시에 BasePart만 저장 (카테고리 없음)
      await getCachedBasePart('part-1');
      await getCachedBasePart('part-2');

      const statsBeforeInvalidate = getCacheStats();
      expect(statsBeforeInvalidate.size).toBe(2);

      // When: part-1만 무효화 (카테고리 캐시는 없음)
      invalidateBasePartCache('part-1');

      // Then: part-2만 남아있어야 함
      const statsAfterInvalidate = getCacheStats();
      expect(statsAfterInvalidate.size).toBe(1);
    });
  });

  describe('getCacheStats()', () => {
    it('캐시 통계를 반환해야 한다', async () => {
      // Given: 캐시에 데이터 추가
      mockGet.mockResolvedValue({
        exists: true,
        data: () => ({ modelName: 'Test Part' }),
        id: 'test-part',
      });

      const { getCachedBasePart, getCacheStats } = await import('../../cache/base_parts_cache');

      // 첫 조회 (캐시 미스)
      await getCachedBasePart('part-1');
      // 두 번째 조회 (캐시 히트)
      await getCachedBasePart('part-1');
      // 다른 파트 조회 (캐시 미스)
      await getCachedBasePart('part-2');

      // When
      const stats = getCacheStats();

      // Then
      expect(stats.size).toBe(2); // 2개의 캐시 엔트리
      expect(stats.hitRate).toBeGreaterThanOrEqual(0);
      expect(stats.hitRate).toBeLessThanOrEqual(1);
    });

    it('빈 캐시의 hitRate는 0이어야 한다', async () => {
      // Given: 빈 캐시
      const { getCacheStats, invalidateBasePartCache } = await import('../../cache/base_parts_cache');
      invalidateBasePartCache(); // 캐시 초기화

      // When
      const stats = getCacheStats();

      // Then
      expect(stats.size).toBe(0);
      expect(stats.hitRate).toBe(0);
    });
  });

  describe('캐시 무결성', () => {
    it('동시 요청 시 중복 Firestore 호출을 방지해야 한다', async () => {
      // Given: 느린 Firestore 응답
      const basePartId = 'cpu-intel-i9-14900k';
      let resolveGet: (value: any) => void;
      const getPromise = new Promise((resolve) => {
        resolveGet = resolve;
      });

      mockGet.mockReturnValue(getPromise);

      const { getCachedBasePart } = await import('../../cache/base_parts_cache');

      // When: 동시에 여러 요청
      const promise1 = getCachedBasePart(basePartId);
      const promise2 = getCachedBasePart(basePartId);
      const promise3 = getCachedBasePart(basePartId);

      // Firestore 응답
      resolveGet!({
        exists: true,
        data: () => ({ modelName: 'Test' }),
        id: basePartId,
      });

      await Promise.all([promise1, promise2, promise3]);

      // Then: Firestore는 한 번만 호출되어야 함
      expect(mockGet).toHaveBeenCalledTimes(1);
    });

    it('카테고리별 동시 요청 시 중복 Firestore 호출을 방지해야 한다', async () => {
      // Given: 느린 Firestore 응답
      let resolveGet: (value: any) => void;
      const getPromise = new Promise((resolve) => {
        resolveGet = resolve;
      });

      mockGet.mockReturnValue(getPromise);

      const { getCachedBasePartsByCategory } = await import('../../cache/base_parts_cache');

      // When: 동시에 여러 카테고리 요청
      const promise1 = getCachedBasePartsByCategory('CPU');
      const promise2 = getCachedBasePartsByCategory('CPU');

      // Firestore 응답
      resolveGet!({
        docs: [{ id: 'cpu-1', data: () => ({ modelName: 'i9' }) }],
        empty: false,
        size: 1,
      });

      await Promise.all([promise1, promise2]);

      // Then: Firestore는 한 번만 호출되어야 함
      expect(mockGet).toHaveBeenCalledTimes(1);
    });
  });

  describe('warmUpCache()', () => {
    it('여러 카테고리를 미리 로드해야 한다', async () => {
      // Given
      mockGet.mockResolvedValue({
        docs: [{ id: 'part1', data: () => ({ modelName: 'Test' }) }],
        empty: false,
        size: 1,
      });

      // When
      const { warmUpCache } = await import('../../cache/base_parts_cache');
      await warmUpCache(['CPU', 'GPU', 'RAM']);

      // Then
      expect(mockChainable.where).toHaveBeenCalledTimes(3);
    });
  });

  describe('cleanupExpiredCache()', () => {
    it('만료된 캐시 엔트리를 정리해야 한다', async () => {
      // Given: 캐시에 데이터 추가
      mockGet.mockResolvedValue({
        exists: true,
        data: () => ({ modelName: 'Test Part' }),
        id: 'test-part',
      });

      const { getCachedBasePart, cleanupExpiredCache } = await import('../../cache/base_parts_cache');
      await getCachedBasePart('part-1');

      // 캐시가 1시간 후에 만료됨 - 1시간 1초 후로 이동
      jest.advanceTimersByTime(60 * 60 * 1000 + 1000);

      // When
      const removed = cleanupExpiredCache();

      // Then - 만료된 항목이 제거됨
      expect(removed).toBeGreaterThanOrEqual(1);
    });

    it('만료되지 않은 캐시 엔트리는 유지해야 한다', async () => {
      // Given: 캐시에 데이터 추가
      mockGet.mockResolvedValue({
        exists: true,
        data: () => ({ modelName: 'Test Part' }),
        id: 'test-part',
      });

      const { getCachedBasePart, cleanupExpiredCache, getCacheStats } = await import('../../cache/base_parts_cache');
      await getCachedBasePart('part-1');

      // 30분만 경과 (만료되지 않음)
      jest.advanceTimersByTime(30 * 60 * 1000);

      // When
      const removed = cleanupExpiredCache();

      // Then - 아무것도 제거되지 않음
      expect(removed).toBe(0);
      const stats = getCacheStats();
      expect(stats.size).toBe(1);
    });

    it('빈 캐시에서 정리를 실행해도 오류가 없어야 한다', async () => {
      // Given: 빈 캐시
      const { cleanupExpiredCache, invalidateBasePartCache } = await import('../../cache/base_parts_cache');
      invalidateBasePartCache(); // 캐시 초기화

      // When
      const removed = cleanupExpiredCache();

      // Then
      expect(removed).toBe(0);
    });
  });

  describe('updateCacheOnWrite()', () => {
    it('캐시를 직접 갱신해야 한다', async () => {
      // Given
      const { updateCacheOnWrite, getCacheStats, invalidateBasePartCache } = await import('../../cache/base_parts_cache');
      invalidateBasePartCache(); // 캐시 초기화

      // When
      updateCacheOnWrite('part-1', { modelName: 'Updated Part', category: 'CPU' });

      // Then
      const stats = getCacheStats();
      expect(stats.size).toBe(1);
    });

    it('카테고리 없는 데이터도 캐시에 저장해야 한다', async () => {
      // Given
      const { updateCacheOnWrite, getCacheStats, invalidateBasePartCache } = await import('../../cache/base_parts_cache');
      invalidateBasePartCache(); // 캐시 초기화

      // When - 카테고리 없는 데이터
      updateCacheOnWrite('part-1', { modelName: 'Updated Part' });

      // Then
      const stats = getCacheStats();
      expect(stats.size).toBe(1);
    });

    it('null 또는 undefined 카테고리는 무시해야 한다', async () => {
      // Given
      const { updateCacheOnWrite, getCacheStats, invalidateBasePartCache } = await import('../../cache/base_parts_cache');
      invalidateBasePartCache(); // 캐시 초기화

      // When - null 카테고리
      updateCacheOnWrite('part-1', { modelName: 'Part 1', category: null });
      updateCacheOnWrite('part-2', { modelName: 'Part 2', category: undefined });

      // Then
      const stats = getCacheStats();
      expect(stats.size).toBe(2);
    });
  });
});
