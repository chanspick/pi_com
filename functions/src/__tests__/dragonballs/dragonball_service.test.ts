// functions/src/__tests__/dragonballs/dragonball_service.test.ts
// DragonBall 서비스 테스트 - TDD
// REQ-OPT-001: DragonBalls 쿼리 최적화

// Mock 참조 (호이스팅됨)
const mockAdd = jest.fn();
const mockGet = jest.fn();
const mockSet = jest.fn();
const mockUpdate = jest.fn();
const mockWhere = jest.fn();
const mockLimit = jest.fn();
const mockOrderBy = jest.fn();
const mockBatchSet = jest.fn();
const mockBatchCommit = jest.fn();
const mockDoc = jest.fn();
const mockCollection = jest.fn();
const mockCollectionGroup = jest.fn();
const mockBatch = jest.fn();

// Firebase Admin 모킹 (호이스팅됨)
jest.mock('firebase-admin', () => {
  // 체인 가능한 쿼리 참조
  const chainableQuery: any = {};

  // 문서 참조
  const docRef = {
    get: mockGet,
    set: mockSet,
    update: mockUpdate,
  };

  // 초기화
  chainableQuery.where = mockWhere.mockReturnValue(chainableQuery);
  chainableQuery.limit = mockLimit.mockReturnValue(chainableQuery);
  chainableQuery.orderBy = mockOrderBy.mockReturnValue(chainableQuery);
  chainableQuery.get = mockGet;
  chainableQuery.add = mockAdd;
  chainableQuery.doc = mockDoc.mockReturnValue(docRef);

  mockCollection.mockReturnValue(chainableQuery);
  mockCollectionGroup.mockReturnValue(chainableQuery);
  mockBatch.mockReturnValue({
    set: mockBatchSet,
    update: jest.fn(),
    delete: jest.fn(),
    commit: mockBatchCommit.mockResolvedValue(undefined),
  });

  const mockFirestore = {
    collection: mockCollection,
    collectionGroup: mockCollectionGroup,
    batch: mockBatch,
  };

  return {
    initializeApp: jest.fn(),
    firestore: Object.assign(
      jest.fn(() => mockFirestore),
      {
        FieldValue: {
          serverTimestamp: jest.fn(() => 'SERVER_TIMESTAMP'),
        },
        Timestamp: {
          now: jest.fn(() => ({ toMillis: () => Date.now() })),
          fromDate: jest.fn((date: Date) => ({ toDate: () => date })),
        },
      }
    ),
  };
});

describe('DragonBall Service - REQ-OPT-001', () => {
  beforeEach(() => {
    jest.clearAllMocks();

    // 체인 재설정
    const chainableQuery: any = {
      where: mockWhere,
      limit: mockLimit,
      orderBy: mockOrderBy,
      get: mockGet,
      add: mockAdd,
      doc: mockDoc,
    };

    mockWhere.mockReturnValue(chainableQuery);
    mockLimit.mockReturnValue(chainableQuery);
    mockOrderBy.mockReturnValue(chainableQuery);
    mockCollection.mockReturnValue(chainableQuery);
    mockCollectionGroup.mockReturnValue(chainableQuery);

    // 서브컬렉션 체인 지원 (users/{userId}/dragonBalls)
    const subCollectionQuery: any = {
      doc: mockDoc,
      where: mockWhere,
      get: mockGet,
    };

    mockDoc.mockReturnValue({
      get: mockGet,
      set: mockSet,
      update: mockUpdate,
      collection: jest.fn().mockReturnValue(subCollectionQuery),
    });
  });

  describe('saveDragonBallToRoot()', () => {
    it('신규 DragonBall을 루트 컬렉션에 저장해야 한다', async () => {
      // Given
      const dragonBallData = {
        userId: 'user123',
        partName: 'RTX 4090',
        status: 'stored',
      };
      mockAdd.mockResolvedValue({ id: 'newDragonBallId' });

      // When
      const { saveDragonBallToRoot } = await import('../../dragonballs/dragonball_service');
      const result = await saveDragonBallToRoot(dragonBallData);

      // Then
      expect(mockCollection).toHaveBeenCalledWith('dragonBalls');
      expect(mockAdd).toHaveBeenCalled();
      expect(result.success).toBe(true);
      expect(result.id).toBe('newDragonBallId');
    });

    it('저장 실패 시 에러를 반환해야 한다', async () => {
      // Given
      mockAdd.mockRejectedValue(new Error('Firestore error'));

      // When
      const { saveDragonBallToRoot } = await import('../../dragonballs/dragonball_service');
      const result = await saveDragonBallToRoot({ userId: 'user123' });

      // Then
      expect(result.success).toBe(false);
      expect(result.error).toBeDefined();
    });
  });

  describe('queryDragonBallsFromRoot()', () => {
    it('루트 컬렉션에서 DragonBalls를 조회해야 한다', async () => {
      // Given
      const mockDocs = [
        { id: 'db1', data: () => ({ partName: 'RTX 4090', status: 'stored' }) },
        { id: 'db2', data: () => ({ partName: 'i9-14900K', status: 'stored' }) },
      ];
      mockGet.mockResolvedValue({
        docs: mockDocs,
        empty: false,
        size: 2,
      });

      // When
      const { queryDragonBallsFromRoot } = await import('../../dragonballs/dragonball_service');
      const result = await queryDragonBallsFromRoot({ status: 'stored' });

      // Then
      expect(mockCollection).toHaveBeenCalledWith('dragonBalls');
      expect(result.length).toBe(2);
      expect(result[0].id).toBe('db1');
    });

    it('필터 조건으로 조회할 수 있어야 한다', async () => {
      // Given
      mockGet.mockResolvedValue({
        docs: [{ id: 'db1', data: () => ({ userId: 'user123', status: 'stored' }) }],
        empty: false,
        size: 1,
      });

      // When
      const { queryDragonBallsFromRoot } = await import('../../dragonballs/dragonball_service');
      await queryDragonBallsFromRoot({ userId: 'user123', status: 'stored' });

      // Then
      expect(mockWhere).toHaveBeenCalled();
    });

    it('빈 결과일 때 빈 배열을 반환해야 한다', async () => {
      // Given
      mockGet.mockResolvedValue({ docs: [], empty: true, size: 0 });

      // When
      const { queryDragonBallsFromRoot } = await import('../../dragonballs/dragonball_service');
      const result = await queryDragonBallsFromRoot({});

      // Then
      expect(result).toEqual([]);
    });

    it('limit 옵션이 적용되어야 한다', async () => {
      // Given
      mockGet.mockResolvedValue({ docs: [], empty: true, size: 0 });

      // When
      const { queryDragonBallsFromRoot } = await import('../../dragonballs/dragonball_service');
      await queryDragonBallsFromRoot({}, { limit: 50 });

      // Then
      expect(mockLimit).toHaveBeenCalledWith(50);
    });
  });

  describe('migrateDragonBallToRoot()', () => {
    it('서브컬렉션의 DragonBall을 루트로 마이그레이션해야 한다', async () => {
      // Given
      const dragonBallData = { partName: 'RTX 4090', status: 'stored', userId: 'user123' };

      // 루트에 없음
      mockGet.mockResolvedValueOnce({ exists: false });
      // 서브컬렉션에 있음
      mockGet.mockResolvedValueOnce({
        exists: true,
        data: () => dragonBallData,
        id: 'db123',
      });
      mockSet.mockResolvedValue(undefined);

      // When
      const { migrateDragonBallToRoot } = await import('../../dragonballs/dragonball_service');
      const result = await migrateDragonBallToRoot('user123', 'db123');

      // Then
      expect(result.success).toBe(true);
      expect(result.migratedId).toBe('db123');
    });

    it('이미 루트에 존재하는 경우 스킵해야 한다', async () => {
      // Given - 루트에 이미 존재
      mockGet.mockResolvedValue({
        exists: true,
        data: () => ({ partName: 'RTX 4090' }),
      });

      // When
      const { migrateDragonBallToRoot } = await import('../../dragonballs/dragonball_service');
      const result = await migrateDragonBallToRoot('user123', 'db123');

      // Then
      expect(result.success).toBe(true);
      expect(result.skipped).toBe(true);
    });

    it('서브컬렉션에서 찾을 수 없으면 에러를 반환해야 한다', async () => {
      // Given - 루트에 없고, 서브컬렉션에도 없음
      mockGet.mockResolvedValue({ exists: false });

      // When
      const { migrateDragonBallToRoot } = await import('../../dragonballs/dragonball_service');
      const result = await migrateDragonBallToRoot('user123', 'db123');

      // Then
      expect(result.success).toBe(false);
      expect(result.error).toContain('not found');
    });
  });

  describe('batchMigrateDragonBalls()', () => {
    it('여러 DragonBall을 일괄 마이그레이션해야 한다', async () => {
      // Given
      const mockDocs = [
        {
          id: 'db1',
          ref: { path: 'users/user123/dragonBalls/db1' },
          data: () => ({ partName: 'RTX 4090', userId: 'user123' }),
        },
        {
          id: 'db2',
          ref: { path: 'users/user456/dragonBalls/db2' },
          data: () => ({ partName: 'i9-14900K', userId: 'user456' }),
        },
      ];

      mockGet.mockResolvedValueOnce({
        docs: mockDocs,
        empty: false,
        size: 2,
      });
      mockGet.mockResolvedValue({ exists: false });
      mockBatchCommit.mockResolvedValue(undefined);

      // When
      const { batchMigrateDragonBalls } = await import('../../dragonballs/dragonball_service');
      const result = await batchMigrateDragonBalls({ batchSize: 100 });

      // Then
      expect(result.success).toBe(true);
      expect(mockCollectionGroup).toHaveBeenCalledWith('dragonBalls');
    });
  });

  describe('updateDragonBallStatus()', () => {
    it('DragonBall 상태를 업데이트해야 한다', async () => {
      // Given
      mockUpdate.mockResolvedValue(undefined);

      // When
      const { updateDragonBallStatus } = await import('../../dragonballs/dragonball_service');
      const result = await updateDragonBallStatus('db123', 'shipped');

      // Then
      expect(result.success).toBe(true);
      expect(result.id).toBe('db123');
      expect(mockUpdate).toHaveBeenCalled();
    });

    it('업데이트 실패 시 에러를 반환해야 한다', async () => {
      // Given
      mockUpdate.mockRejectedValue(new Error('Update failed'));

      // When
      const { updateDragonBallStatus } = await import('../../dragonballs/dragonball_service');
      const result = await updateDragonBallStatus('db123', 'shipped');

      // Then
      expect(result.success).toBe(false);
      expect(result.error).toBeDefined();
    });

    it('추가 데이터와 함께 상태를 업데이트해야 한다', async () => {
      // Given
      mockUpdate.mockResolvedValue(undefined);

      // When
      const { updateDragonBallStatus } = await import('../../dragonballs/dragonball_service');
      const result = await updateDragonBallStatus('db123', 'shipped', { trackingNumber: '12345' });

      // Then
      expect(result.success).toBe(true);
      expect(mockUpdate).toHaveBeenCalled();
    });
  });

  describe('saveDragonBallToRoot() - 추가 케이스', () => {
    it('서브컬렉션 저장 실패 시에도 루트 저장은 성공해야 한다', async () => {
      // Given
      const dragonBallData = {
        userId: 'user123',
        partName: 'RTX 4090',
        status: 'stored',
      };
      mockAdd.mockResolvedValue({ id: 'newId' });
      mockSet.mockRejectedValue(new Error('Subcollection error'));

      // When
      const { saveDragonBallToRoot } = await import('../../dragonballs/dragonball_service');
      await saveDragonBallToRoot(dragonBallData, { alsoSaveToSubcollection: true });

      // Then - 서브컬렉션 실패해도 루트 저장 시도는 했음
      expect(mockAdd).toHaveBeenCalled();
    });
  });

  describe('queryDragonBallsFromRoot() - 추가 케이스', () => {
    it('orderBy 옵션이 적용되어야 한다', async () => {
      // Given
      mockGet.mockResolvedValue({ docs: [], empty: true, size: 0 });

      // When
      const { queryDragonBallsFromRoot } = await import('../../dragonballs/dragonball_service');
      await queryDragonBallsFromRoot({}, { orderBy: 'createdAt', orderDirection: 'desc' });

      // Then
      expect(mockOrderBy).toHaveBeenCalledWith('createdAt', 'desc');
    });

    it('에러 발생 시 빈 배열을 반환해야 한다', async () => {
      // Given
      mockGet.mockRejectedValue(new Error('Query error'));

      // When
      const { queryDragonBallsFromRoot } = await import('../../dragonballs/dragonball_service');
      const result = await queryDragonBallsFromRoot({ status: 'stored' });

      // Then
      expect(result).toEqual([]);
    });

    it('undefined 값을 가진 필터는 무시해야 한다', async () => {
      // Given
      mockGet.mockResolvedValue({ docs: [], empty: true, size: 0 });

      // When
      const { queryDragonBallsFromRoot } = await import('../../dragonballs/dragonball_service');
      await queryDragonBallsFromRoot({ userId: 'user123', customField: undefined });

      // Then
      // customField가 undefined이므로 where 호출에 포함되지 않아야 함
      expect(mockWhere).toHaveBeenCalledWith('userId', '==', 'user123');
    });

    it('추가 필터 조건이 적용되어야 한다', async () => {
      // Given
      mockGet.mockResolvedValue({ docs: [], empty: true, size: 0 });

      // When
      const { queryDragonBallsFromRoot } = await import('../../dragonballs/dragonball_service');
      await queryDragonBallsFromRoot({ userId: 'user123', partType: 'GPU' });

      // Then
      expect(mockWhere).toHaveBeenCalledWith('userId', '==', 'user123');
      expect(mockWhere).toHaveBeenCalledWith('partType', '==', 'GPU');
    });
  });

  describe('migrateDragonBallToRoot() - 추가 케이스', () => {
    it('마이그레이션 중 에러 발생 시 에러를 반환해야 한다', async () => {
      // Given - 루트에 없고, 서브컬렉션 조회 중 에러
      mockGet.mockResolvedValueOnce({ exists: false });
      mockGet.mockRejectedValueOnce(new Error('Subcollection read error'));

      // When
      const { migrateDragonBallToRoot } = await import('../../dragonballs/dragonball_service');
      const result = await migrateDragonBallToRoot('user123', 'db123');

      // Then
      expect(result.success).toBe(false);
      expect(result.error).toBeDefined();
    });
  });

  describe('batchMigrateDragonBalls() - 추가 케이스', () => {
    it('빈 결과일 때 성공을 반환해야 한다', async () => {
      // Given
      mockGet.mockResolvedValue({
        docs: [],
        empty: true,
        size: 0,
      });

      // When
      const { batchMigrateDragonBalls } = await import('../../dragonballs/dragonball_service');
      const result = await batchMigrateDragonBalls({ batchSize: 100 });

      // Then
      expect(result.success).toBe(true);
      expect(result.processed).toBe(0);
    });

    it('배치 처리 중 개별 문서 오류가 발생해도 계속 처리해야 한다', async () => {
      // Given
      const mockDocs = [
        {
          id: 'db1',
          ref: { path: 'users/user123/dragonBalls/db1' },
          data: () => { throw new Error('Data parsing error'); },
        },
        {
          id: 'db2',
          ref: { path: 'users/user456/dragonBalls/db2' },
          data: () => ({ partName: 'i9-14900K', userId: 'user456' }),
        },
      ];

      mockGet.mockResolvedValueOnce({
        docs: mockDocs,
        empty: false,
        size: 2,
      });
      mockGet.mockResolvedValue({ exists: false });
      mockBatchCommit.mockResolvedValue(undefined);

      // When
      const { batchMigrateDragonBalls } = await import('../../dragonballs/dragonball_service');
      const result = await batchMigrateDragonBalls({});

      // Then
      expect(result.success).toBe(true);
      expect(result.failed).toBeGreaterThan(0);
      expect(result.errors.length).toBeGreaterThan(0);
    });

    it('전체 배치 처리 실패 시 에러를 반환해야 한다', async () => {
      // Given
      mockGet.mockRejectedValue(new Error('Batch query failed'));

      // When
      const { batchMigrateDragonBalls } = await import('../../dragonballs/dragonball_service');
      const result = await batchMigrateDragonBalls({});

      // Then
      expect(result.success).toBe(false);
      expect(result.errors.length).toBeGreaterThan(0);
    });

    it('statusFilter로 필터링된 결과를 마이그레이션해야 한다', async () => {
      // Given
      const mockDocs = [
        {
          id: 'db1',
          ref: { path: 'users/user123/dragonBalls/db1' },
          data: () => ({ partName: 'RTX 4090', status: 'stored' }),
        },
      ];

      mockGet.mockResolvedValueOnce({
        docs: mockDocs,
        empty: false,
        size: 1,
      });
      mockGet.mockResolvedValue({ exists: false });
      mockBatchCommit.mockResolvedValue(undefined);

      // When
      const { batchMigrateDragonBalls } = await import('../../dragonballs/dragonball_service');
      const result = await batchMigrateDragonBalls({ statusFilter: 'stored' });

      // Then
      expect(result.success).toBe(true);
      expect(mockWhere).toHaveBeenCalledWith('status', '==', 'stored');
    });

    it('이미 루트에 존재하는 문서는 스킵해야 한다', async () => {
      // Given
      const mockDocs = [
        {
          id: 'db1',
          ref: { path: 'users/user123/dragonBalls/db1' },
          data: () => ({ partName: 'RTX 4090' }),
        },
      ];

      mockGet.mockResolvedValueOnce({
        docs: mockDocs,
        empty: false,
        size: 1,
      });
      // 루트에 이미 존재
      mockGet.mockResolvedValue({ exists: true });

      // When
      const { batchMigrateDragonBalls } = await import('../../dragonballs/dragonball_service');
      const result = await batchMigrateDragonBalls({});

      // Then
      expect(result.success).toBe(true);
      expect(result.skipped).toBe(1);
    });
  });
});
