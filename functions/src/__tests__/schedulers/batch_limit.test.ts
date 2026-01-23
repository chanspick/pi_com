// functions/src/__tests__/schedulers/batch_limit.test.ts
// 스케줄러 배치 limit 테스트 - TDD RED 단계

// 상수 정의
const BATCH_SIZE = 100;

// Firebase Admin SDK 모킹
const mockGet = jest.fn();
const mockWhere = jest.fn();
const mockLimit = jest.fn();
const mockCollection = jest.fn();

jest.mock('firebase-admin', () => ({
  initializeApp: jest.fn(),
  firestore: jest.fn(() => ({
    collection: mockCollection,
  })),
}));

// admin.firestore.FieldValue 모킹
const mockAdmin = require('firebase-admin');
mockAdmin.firestore.FieldValue = {
  serverTimestamp: jest.fn(() => 'SERVER_TIMESTAMP'),
};

describe('Scheduler Batch Limit', () => {
  beforeEach(() => {
    jest.clearAllMocks();

    // 체인 모킹 설정
    mockCollection.mockReturnValue({
      where: mockWhere,
    });
    mockWhere.mockReturnValue({
      where: mockWhere,
      limit: mockLimit,
      get: mockGet,
    });
    mockLimit.mockReturnValue({
      get: mockGet,
    });
  });

  describe('storage_scheduler', () => {
    it('dragonBalls 쿼리에 BATCH_SIZE limit이 적용되어야 한다', async () => {
      // Given: 빈 결과 반환
      mockGet.mockResolvedValue({
        size: 0,
        empty: true,
        docs: [],
      });

      // When: 스케줄러 쿼리 함수 호출 (storage_scheduler의 쿼리 로직)
      const { queryDragonBallsWithLimit } = await import('../../schedulers/storage_scheduler');
      await queryDragonBallsWithLimit();

      // Then: limit(BATCH_SIZE)가 호출되어야 함
      expect(mockLimit).toHaveBeenCalledWith(BATCH_SIZE);
    });
  });

  describe('settlement_scheduler', () => {
    it('orders 쿼리에 BATCH_SIZE limit이 적용되어야 한다', async () => {
      // Given: 빈 결과 반환
      mockGet.mockResolvedValue({
        size: 0,
        empty: true,
        docs: [],
      });

      // When: 스케줄러 쿼리 함수 호출 (settlement_scheduler의 쿼리 로직)
      const { queryDeliveredOrdersWithLimit } = await import('../../schedulers/settlement_scheduler');
      await queryDeliveredOrdersWithLimit();

      // Then: limit(BATCH_SIZE)가 호출되어야 함
      expect(mockLimit).toHaveBeenCalledWith(BATCH_SIZE);
    });
  });

  describe('approval_deadline_scheduler', () => {
    it('refundRequests 쿼리에 BATCH_SIZE limit이 적용되어야 한다', async () => {
      // Given: 빈 결과 반환
      mockGet.mockResolvedValue({
        size: 0,
        empty: true,
        docs: [],
      });

      // When: 스케줄러 쿼리 함수 호출 (approval_deadline_scheduler의 쿼리 로직)
      const { queryPendingRefundsWithLimit } = await import('../../refund/approval_deadline_scheduler');
      await queryPendingRefundsWithLimit();

      // Then: limit(BATCH_SIZE)가 호출되어야 함
      expect(mockLimit).toHaveBeenCalledWith(BATCH_SIZE);
    });
  });

  describe('BATCH_SIZE 상수', () => {
    it('모든 스케줄러에서 동일한 BATCH_SIZE(100)를 사용해야 한다', async () => {
      // 각 스케줄러의 BATCH_SIZE 상수 확인
      const storageScheduler = await import('../../schedulers/storage_scheduler');
      const settlementScheduler = await import('../../schedulers/settlement_scheduler');
      const approvalDeadlineScheduler = await import('../../refund/approval_deadline_scheduler');

      expect(storageScheduler.BATCH_SIZE).toBe(100);
      expect(settlementScheduler.BATCH_SIZE).toBe(100);
      expect(approvalDeadlineScheduler.BATCH_SIZE).toBe(100);
    });
  });
});
