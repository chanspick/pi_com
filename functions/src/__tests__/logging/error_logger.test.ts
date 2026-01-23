// functions/src/__tests__/logging/error_logger.test.ts
// 에러 모니터링 시스템 테스트 - TDD RED 단계

import {
  logError,
  markErrorResolved,
  queryErrors,
  getErrorStats,
  ErrorSeverity,
  ErrorQueryFilters,
  TimeRange,
} from '../../logging/error_logger';

// Firebase Admin SDK 모킹
const mockAdd = jest.fn();
const mockGet = jest.fn();
const mockDoc = jest.fn();
const mockUpdate = jest.fn();
const mockCollection = jest.fn();
const mockWhere = jest.fn();
const mockOrderBy = jest.fn();
const mockLimit = jest.fn();

jest.mock('firebase-admin', () => ({
  initializeApp: jest.fn(),
  firestore: jest.fn(() => ({
    collection: mockCollection,
  })),
}));

// admin.firestore.Timestamp 모킹
const mockAdmin = require('firebase-admin');
mockAdmin.firestore.Timestamp = {
  now: jest.fn(() => ({ toDate: () => new Date('2024-01-15T10:00:00Z') })),
  fromDate: jest.fn((date: Date) => ({ toDate: () => date })),
};
mockAdmin.firestore.FieldValue = {
  serverTimestamp: jest.fn(() => 'SERVER_TIMESTAMP'),
};

describe('ErrorLogger', () => {
  beforeEach(() => {
    jest.clearAllMocks();

    // Firestore 체인 모킹 설정
    mockCollection.mockReturnValue({
      add: mockAdd,
      doc: mockDoc,
      where: mockWhere,
      orderBy: mockOrderBy,
      limit: mockLimit,
      get: mockGet,
    });

    mockWhere.mockReturnValue({
      where: mockWhere,
      orderBy: mockOrderBy,
      limit: mockLimit,
      get: mockGet,
    });

    mockOrderBy.mockReturnValue({
      limit: mockLimit,
      get: mockGet,
      where: mockWhere,
      orderBy: mockOrderBy,
    });

    mockLimit.mockReturnValue({
      get: mockGet,
    });

    mockDoc.mockReturnValue({
      get: mockGet,
      update: mockUpdate,
    });
  });

  describe('logError', () => {
    it('critical 심각도의 에러를 errorLogs 컬렉션에 기록해야 한다', async () => {
      // Given: critical 심각도 에러 (결제 API 장애)
      const error = new Error('Payment API connection failed');
      const severity: ErrorSeverity = 'critical';
      const source = 'payment/kakaopay';
      const context = {
        paymentKey: 'pk_123',
        orderId: 'order_456',
        endpoint: '/v1/payment/approve',
      };

      mockAdd.mockResolvedValueOnce({ id: 'error_log_001' });

      // When: 에러 로깅
      const logId = await logError(error, severity, source, context);

      // Then: errorLogs 컬렉션에 기록됨
      expect(mockCollection).toHaveBeenCalledWith('errorLogs');
      expect(mockAdd).toHaveBeenCalledTimes(1);
      expect(mockAdd).toHaveBeenCalledWith(
        expect.objectContaining({
          severity: 'critical',
          source: 'payment/kakaopay',
          message: 'Payment API connection failed',
          context: expect.objectContaining({
            paymentKey: 'pk_123',
            orderId: 'order_456',
          }),
          resolved: false,
        })
      );
      expect(logId).toBe('error_log_001');
    });

    it('high 심각도의 에러를 기록해야 한다', async () => {
      // Given: high 심각도 에러 (트랜잭션 실패)
      const error = new Error('Transaction rollback failed');
      const severity: ErrorSeverity = 'high';
      const source = 'firestore/transaction';
      const context = { orderId: 'order_789' };

      mockAdd.mockResolvedValueOnce({ id: 'error_log_002' });

      // When: 에러 로깅
      const logId = await logError(error, severity, source, context);

      // Then: high 심각도로 기록됨
      expect(mockAdd).toHaveBeenCalledWith(
        expect.objectContaining({
          severity: 'high',
          source: 'firestore/transaction',
        })
      );
      expect(logId).toBe('error_log_002');
    });

    it('medium 심각도의 에러를 기록해야 한다', async () => {
      // Given: medium 심각도 에러 (스케줄러 오류)
      const error = new Error('Scheduler timeout exceeded');
      const severity: ErrorSeverity = 'medium';
      const source = 'scheduler/settlement';
      const context = { scheduledTime: '2024-01-15T00:00:00Z' };

      mockAdd.mockResolvedValueOnce({ id: 'error_log_003' });

      // When: 에러 로깅
      const logId = await logError(error, severity, source, context);

      // Then: medium 심각도로 기록됨
      expect(mockAdd).toHaveBeenCalledWith(
        expect.objectContaining({
          severity: 'medium',
          source: 'scheduler/settlement',
        })
      );
      expect(logId).toBe('error_log_003');
    });

    it('low 심각도의 에러를 기록해야 한다', async () => {
      // Given: low 심각도 에러 (로깅 실패)
      const error = new Error('Failed to write audit log');
      const severity: ErrorSeverity = 'low';
      const source = 'logging/audit';
      const context = { attemptCount: 3 };

      mockAdd.mockResolvedValueOnce({ id: 'error_log_004' });

      // When: 에러 로깅
      const logId = await logError(error, severity, source, context);

      // Then: low 심각도로 기록됨
      expect(mockAdd).toHaveBeenCalledWith(
        expect.objectContaining({
          severity: 'low',
          source: 'logging/audit',
        })
      );
      expect(logId).toBe('error_log_004');
    });

    it('Error 객체의 스택 트레이스를 기록해야 한다', async () => {
      // Given: 스택 트레이스가 있는 에러
      const error = new Error('Test error with stack');
      const severity: ErrorSeverity = 'high';
      const source = 'test/module';

      mockAdd.mockResolvedValueOnce({ id: 'error_log_005' });

      // When: 에러 로깅
      await logError(error, severity, source);

      // Then: 스택 트레이스가 기록됨
      expect(mockAdd).toHaveBeenCalledWith(
        expect.objectContaining({
          stack: expect.stringContaining('Error: Test error with stack'),
        })
      );
    });

    it('문자열 에러 메시지를 처리해야 한다', async () => {
      // Given: 문자열 에러
      const errorMessage = 'Simple error message';
      const severity: ErrorSeverity = 'medium';
      const source = 'api/handler';

      mockAdd.mockResolvedValueOnce({ id: 'error_log_006' });

      // When: 문자열 에러 로깅
      const logId = await logError(errorMessage, severity, source);

      // Then: 문자열이 메시지로 기록됨
      expect(mockAdd).toHaveBeenCalledWith(
        expect.objectContaining({
          message: 'Simple error message',
          stack: undefined,
        })
      );
      expect(logId).toBe('error_log_006');
    });

    it('컨텍스트 없이 에러를 기록할 수 있어야 한다', async () => {
      // Given: 컨텍스트 없는 에러
      const error = new Error('Context-less error');
      const severity: ErrorSeverity = 'low';
      const source = 'unknown';

      mockAdd.mockResolvedValueOnce({ id: 'error_log_007' });

      // When: 컨텍스트 없이 로깅
      const logId = await logError(error, severity, source);

      // Then: 빈 컨텍스트로 기록됨
      expect(mockAdd).toHaveBeenCalledWith(
        expect.objectContaining({
          context: {},
        })
      );
      expect(logId).toBe('error_log_007');
    });

    it('Firestore 오류 시 예외를 전파해야 한다', async () => {
      // Given: Firestore 오류 발생
      mockAdd.mockRejectedValueOnce(new Error('Firestore write failed'));

      const error = new Error('Test error');
      const severity: ErrorSeverity = 'high';
      const source = 'test';

      // When & Then: 예외가 전파됨
      await expect(logError(error, severity, source)).rejects.toThrow('Firestore write failed');
    });
  });

  describe('markErrorResolved', () => {
    it('에러를 해결됨으로 표시해야 한다', async () => {
      // Given: 해결할 에러 ID
      const errorId = 'error_log_001';
      const resolvedBy = 'admin_001';

      mockUpdate.mockResolvedValueOnce(undefined);

      // When: 에러 해결 표시
      await markErrorResolved(errorId, resolvedBy);

      // Then: resolved 필드가 업데이트됨
      expect(mockDoc).toHaveBeenCalledWith('error_log_001');
      expect(mockUpdate).toHaveBeenCalledWith(
        expect.objectContaining({
          resolved: true,
          resolvedBy: 'admin_001',
        })
      );
    });

    it('해결 시간을 기록해야 한다', async () => {
      // Given: 해결할 에러
      const errorId = 'error_log_002';
      const resolvedBy = 'admin_002';

      mockUpdate.mockResolvedValueOnce(undefined);

      // When: 에러 해결 표시
      await markErrorResolved(errorId, resolvedBy);

      // Then: resolvedAt 타임스탬프가 기록됨
      expect(mockUpdate).toHaveBeenCalledWith(
        expect.objectContaining({
          resolvedAt: expect.anything(),
        })
      );
    });

    it('존재하지 않는 에러 ID에 대해 오류를 발생시켜야 한다', async () => {
      // Given: 존재하지 않는 에러 ID
      const errorId = 'nonexistent_error';
      const resolvedBy = 'admin_001';

      mockUpdate.mockRejectedValueOnce(new Error('Document not found'));

      // When & Then: 오류 발생
      await expect(markErrorResolved(errorId, resolvedBy)).rejects.toThrow('Document not found');
    });
  });

  describe('queryErrors', () => {
    it('심각도별로 에러를 조회해야 한다', async () => {
      // Given: 심각도 필터
      const filters: ErrorQueryFilters = {
        severity: 'critical',
        limit: 10,
      };

      const mockDocs = [
        {
          id: 'error_1',
          data: () => ({
            severity: 'critical',
            source: 'payment/kakaopay',
            message: 'Payment failed',
            context: {},
            timestamp: { toDate: () => new Date() },
            resolved: false,
          }),
        },
      ];

      mockGet.mockResolvedValueOnce({
        docs: mockDocs,
        empty: false,
      });

      // When: 에러 조회
      const result = await queryErrors(filters);

      // Then: 필터된 결과 반환
      expect(mockWhere).toHaveBeenCalledWith('severity', '==', 'critical');
      expect(result).toHaveLength(1);
      expect(result[0].severity).toBe('critical');
    });

    it('소스별로 에러를 조회해야 한다', async () => {
      // Given: 소스 필터
      const filters: ErrorQueryFilters = {
        source: 'scheduler/settlement',
        limit: 20,
      };

      const mockDocs = [
        {
          id: 'error_1',
          data: () => ({
            severity: 'medium',
            source: 'scheduler/settlement',
            message: 'Scheduler error',
            context: {},
            timestamp: { toDate: () => new Date() },
            resolved: false,
          }),
        },
      ];

      mockGet.mockResolvedValueOnce({
        docs: mockDocs,
        empty: false,
      });

      // When: 에러 조회
      const result = await queryErrors(filters);

      // Then: 소스 필터 적용
      expect(mockWhere).toHaveBeenCalledWith('source', '==', 'scheduler/settlement');
      expect(result).toHaveLength(1);
    });

    it('해결 상태별로 에러를 조회해야 한다', async () => {
      // Given: 미해결 에러만 조회
      const filters: ErrorQueryFilters = {
        resolved: false,
        limit: 50,
      };

      const mockDocs = [
        {
          id: 'error_1',
          data: () => ({
            severity: 'high',
            source: 'api/handler',
            message: 'Unresolved error',
            context: {},
            timestamp: { toDate: () => new Date() },
            resolved: false,
          }),
        },
      ];

      mockGet.mockResolvedValueOnce({
        docs: mockDocs,
        empty: false,
      });

      // When: 에러 조회
      const result = await queryErrors(filters);

      // Then: resolved 필터 적용
      expect(mockWhere).toHaveBeenCalledWith('resolved', '==', false);
      expect(result).toHaveLength(1);
    });

    it('날짜 범위로 에러를 조회해야 한다', async () => {
      // Given: 날짜 범위 필터
      const startDate = new Date('2024-01-01');
      const endDate = new Date('2024-01-31');
      const filters: ErrorQueryFilters = {
        startDate,
        endDate,
        limit: 100,
      };

      mockGet.mockResolvedValueOnce({
        docs: [],
        empty: true,
      });

      // When: 에러 조회
      await queryErrors(filters);

      // Then: 날짜 범위 필터 적용
      expect(mockWhere).toHaveBeenCalledWith('timestamp', '>=', expect.anything());
      expect(mockWhere).toHaveBeenCalledWith('timestamp', '<=', expect.anything());
    });

    it('결과가 없을 때 빈 배열을 반환해야 한다', async () => {
      // Given: 빈 결과
      const filters: ErrorQueryFilters = {
        severity: 'critical',
        limit: 10,
      };

      mockGet.mockResolvedValueOnce({
        docs: [],
        empty: true,
      });

      // When: 에러 조회
      const result = await queryErrors(filters);

      // Then: 빈 배열 반환
      expect(result).toEqual([]);
    });

    it('timestamp 기준 내림차순으로 정렬해야 한다', async () => {
      // Given: 기본 조회 요청
      const filters: ErrorQueryFilters = {
        limit: 10,
      };

      mockGet.mockResolvedValueOnce({
        docs: [],
        empty: true,
      });

      // When: 에러 조회
      await queryErrors(filters);

      // Then: 내림차순 정렬 적용
      expect(mockOrderBy).toHaveBeenCalledWith('timestamp', 'desc');
    });

    it('limit 없이 조회할 수 있어야 한다', async () => {
      // Given: limit 없는 필터
      const filters: ErrorQueryFilters = {
        severity: 'high',
      };

      const mockDocs = [
        {
          id: 'error_1',
          data: () => ({
            severity: 'high',
            source: 'api/handler',
            message: 'Test error',
            context: {},
            timestamp: { toDate: () => new Date() },
            resolved: false,
          }),
        },
      ];

      mockGet.mockResolvedValueOnce({
        docs: mockDocs,
        empty: false,
      });

      // When: limit 없이 조회
      const result = await queryErrors(filters);

      // Then: limit 호출 안됨
      expect(mockLimit).not.toHaveBeenCalled();
      expect(result).toHaveLength(1);
    });
  });

  describe('getErrorStats', () => {
    it('시간 범위 내 에러 통계를 반환해야 한다', async () => {
      // Given: 시간 범위
      const timeRange: TimeRange = {
        start: new Date('2024-01-01'),
        end: new Date('2024-01-31'),
      };

      const mockDocs = [
        {
          data: () => ({
            severity: 'critical',
            resolved: false,
            timestamp: { toDate: () => new Date('2024-01-10') },
          }),
        },
        {
          data: () => ({
            severity: 'critical',
            resolved: true,
            timestamp: { toDate: () => new Date('2024-01-15') },
          }),
        },
        {
          data: () => ({
            severity: 'high',
            resolved: false,
            timestamp: { toDate: () => new Date('2024-01-20') },
          }),
        },
        {
          data: () => ({
            severity: 'medium',
            resolved: true,
            timestamp: { toDate: () => new Date('2024-01-25') },
          }),
        },
        {
          data: () => ({
            severity: 'low',
            resolved: false,
            timestamp: { toDate: () => new Date('2024-01-28') },
          }),
        },
      ];

      mockGet.mockResolvedValueOnce({
        docs: mockDocs,
        empty: false,
      });

      // When: 에러 통계 조회
      const stats = await getErrorStats(timeRange);

      // Then: 통계 반환
      expect(stats.total).toBe(5);
      expect(stats.bySeverity.critical).toBe(2);
      expect(stats.bySeverity.high).toBe(1);
      expect(stats.bySeverity.medium).toBe(1);
      expect(stats.bySeverity.low).toBe(1);
      expect(stats.resolved).toBe(2);
      expect(stats.unresolved).toBe(3);
    });

    it('에러가 없을 때 0 값을 반환해야 한다', async () => {
      // Given: 에러가 없는 시간 범위
      const timeRange: TimeRange = {
        start: new Date('2024-02-01'),
        end: new Date('2024-02-28'),
      };

      mockGet.mockResolvedValueOnce({
        docs: [],
        empty: true,
      });

      // When: 에러 통계 조회
      const stats = await getErrorStats(timeRange);

      // Then: 모든 값이 0
      expect(stats.total).toBe(0);
      expect(stats.bySeverity.critical).toBe(0);
      expect(stats.bySeverity.high).toBe(0);
      expect(stats.bySeverity.medium).toBe(0);
      expect(stats.bySeverity.low).toBe(0);
      expect(stats.resolved).toBe(0);
      expect(stats.unresolved).toBe(0);
    });

    it('시간 범위 필터를 적용해야 한다', async () => {
      // Given: 시간 범위
      const timeRange: TimeRange = {
        start: new Date('2024-01-01'),
        end: new Date('2024-01-31'),
      };

      mockGet.mockResolvedValueOnce({
        docs: [],
        empty: true,
      });

      // When: 에러 통계 조회
      await getErrorStats(timeRange);

      // Then: 시간 범위 필터 적용
      expect(mockWhere).toHaveBeenCalledWith('timestamp', '>=', expect.anything());
      expect(mockWhere).toHaveBeenCalledWith('timestamp', '<=', expect.anything());
    });

    it('알 수 없는 심각도는 무시해야 한다', async () => {
      // Given: 알 수 없는 심각도를 가진 에러 데이터
      const timeRange: TimeRange = {
        start: new Date('2024-01-01'),
        end: new Date('2024-01-31'),
      };

      const mockDocs = [
        {
          data: () => ({
            severity: 'critical',
            resolved: false,
            timestamp: { toDate: () => new Date('2024-01-10') },
          }),
        },
        {
          data: () => ({
            severity: 'unknown_severity', // 알 수 없는 심각도
            resolved: true,
            timestamp: { toDate: () => new Date('2024-01-15') },
          }),
        },
      ];

      mockGet.mockResolvedValueOnce({
        docs: mockDocs,
        empty: false,
      });

      // When: 에러 통계 조회
      const stats = await getErrorStats(timeRange);

      // Then: 알 수 없는 심각도는 카운트되지 않음
      expect(stats.total).toBe(2);
      expect(stats.bySeverity.critical).toBe(1);
      expect(stats.bySeverity.high).toBe(0);
      expect(stats.bySeverity.medium).toBe(0);
      expect(stats.bySeverity.low).toBe(0);
      expect(stats.resolved).toBe(1);
      expect(stats.unresolved).toBe(1);
    });
  });
});
