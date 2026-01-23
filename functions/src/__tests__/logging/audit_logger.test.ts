// functions/src/__tests__/logging/audit_logger.test.ts
// 감사 로그 시스템 테스트 - TDD RED 단계

import {
  logAuditEvent,
  queryAuditLogs,
  getAuditLogById,
  AuditAction,
  AuditQueryFilters,
} from '../../logging/audit_logger';

// Firebase Admin SDK 모킹
const mockAdd = jest.fn();
const mockGet = jest.fn();
const mockDoc = jest.fn();
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

describe('AuditLogger', () => {
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
    });
  });

  describe('logAuditEvent', () => {
    it('결제 승인 이벤트를 auditLogs 컬렉션에 기록해야 한다', async () => {
      // Given: 결제 승인 이벤트 데이터
      const eventData = {
        action: 'PAYMENT_APPROVED' as AuditAction,
        userId: 'user_123',
        targetId: 'order_456',
        targetType: 'order',
        details: {
          orderId: 'order_456',
          amount: 150000,
          paymentMethod: 'kakaopay',
        },
      };

      mockAdd.mockResolvedValueOnce({ id: 'audit_log_001' });

      // When: 감사 로그 기록
      const logId = await logAuditEvent(eventData);

      // Then: auditLogs 컬렉션에 기록됨
      expect(mockCollection).toHaveBeenCalledWith('auditLogs');
      expect(mockAdd).toHaveBeenCalledTimes(1);
      expect(mockAdd).toHaveBeenCalledWith(
        expect.objectContaining({
          action: 'PAYMENT_APPROVED',
          userId: 'user_123',
          targetId: 'order_456',
          targetType: 'order',
          details: expect.objectContaining({
            orderId: 'order_456',
            amount: 150000,
            paymentMethod: 'kakaopay',
          }),
        })
      );
      expect(logId).toBe('audit_log_001');
    });

    it('결제 취소 이벤트를 기록해야 한다', async () => {
      // Given: 결제 취소 이벤트 데이터
      const eventData = {
        action: 'PAYMENT_CANCELLED' as AuditAction,
        userId: 'user_123',
        targetId: 'order_789',
        targetType: 'order',
        details: {
          orderId: 'order_789',
          cancelReason: '고객 요청',
        },
      };

      mockAdd.mockResolvedValueOnce({ id: 'audit_log_002' });

      // When: 감사 로그 기록
      const logId = await logAuditEvent(eventData);

      // Then: 취소 이벤트가 기록됨
      expect(mockAdd).toHaveBeenCalledWith(
        expect.objectContaining({
          action: 'PAYMENT_CANCELLED',
          details: expect.objectContaining({
            cancelReason: '고객 요청',
          }),
        })
      );
      expect(logId).toBe('audit_log_002');
    });

    it('환불 신청 이벤트를 기록해야 한다', async () => {
      // Given: 환불 신청 이벤트 데이터
      const eventData = {
        action: 'REFUND_REQUESTED' as AuditAction,
        userId: 'user_456',
        targetId: 'refund_001',
        targetType: 'refund',
        details: {
          orderId: 'order_123',
          refundId: 'refund_001',
          reason: '상품 불량',
        },
      };

      mockAdd.mockResolvedValueOnce({ id: 'audit_log_003' });

      // When: 감사 로그 기록
      const logId = await logAuditEvent(eventData);

      // Then: 환불 신청 이벤트가 기록됨
      expect(mockAdd).toHaveBeenCalledWith(
        expect.objectContaining({
          action: 'REFUND_REQUESTED',
          targetType: 'refund',
        })
      );
      expect(logId).toBe('audit_log_003');
    });

    it('환불 승인 이벤트를 기록해야 한다', async () => {
      // Given: 환불 승인 이벤트 데이터
      const eventData = {
        action: 'REFUND_APPROVED' as AuditAction,
        userId: 'admin_001',
        targetId: 'refund_001',
        targetType: 'refund',
        details: {
          refundId: 'refund_001',
          approvedBy: 'admin_001',
        },
      };

      mockAdd.mockResolvedValueOnce({ id: 'audit_log_004' });

      // When: 감사 로그 기록
      const logId = await logAuditEvent(eventData);

      // Then: 환불 승인 이벤트가 기록됨
      expect(mockAdd).toHaveBeenCalledWith(
        expect.objectContaining({
          action: 'REFUND_APPROVED',
          details: expect.objectContaining({
            approvedBy: 'admin_001',
          }),
        })
      );
      expect(logId).toBe('audit_log_004');
    });

    it('관리자 승인 이벤트를 기록해야 한다', async () => {
      // Given: 관리자 승인 이벤트 데이터
      const eventData = {
        action: 'ADMIN_APPROVED' as AuditAction,
        userId: 'admin_002',
        targetId: 'listing_123',
        targetType: 'listing',
        details: {
          targetId: 'listing_123',
          adminId: 'admin_002',
        },
      };

      mockAdd.mockResolvedValueOnce({ id: 'audit_log_005' });

      // When: 감사 로그 기록
      const logId = await logAuditEvent(eventData);

      // Then: 관리자 승인 이벤트가 기록됨
      expect(mockAdd).toHaveBeenCalledWith(
        expect.objectContaining({
          action: 'ADMIN_APPROVED',
          details: expect.objectContaining({
            adminId: 'admin_002',
          }),
        })
      );
      expect(logId).toBe('audit_log_005');
    });

    it('IP 주소와 User-Agent를 선택적으로 기록해야 한다', async () => {
      // Given: IP와 User-Agent가 포함된 이벤트 데이터
      const eventData = {
        action: 'LISTING_CREATED' as AuditAction,
        userId: 'user_999',
        targetId: 'listing_456',
        targetType: 'listing',
        details: { title: '새 매물' },
        ip: '192.168.1.1',
        userAgent: 'Mozilla/5.0',
      };

      mockAdd.mockResolvedValueOnce({ id: 'audit_log_006' });

      // When: 감사 로그 기록
      const logId = await logAuditEvent(eventData);

      // Then: IP와 User-Agent가 함께 기록됨
      expect(mockAdd).toHaveBeenCalledWith(
        expect.objectContaining({
          ip: '192.168.1.1',
          userAgent: 'Mozilla/5.0',
        })
      );
      expect(logId).toBe('audit_log_006');
    });

    it('Firestore 오류 시 예외를 전파해야 한다', async () => {
      // Given: Firestore 오류 발생
      mockAdd.mockRejectedValueOnce(new Error('Firestore connection failed'));

      const eventData = {
        action: 'PAYMENT_APPROVED' as AuditAction,
        userId: 'user_123',
        targetId: 'order_456',
        targetType: 'order',
        details: {},
      };

      // When & Then: 예외가 전파됨
      await expect(logAuditEvent(eventData)).rejects.toThrow('Firestore connection failed');
    });
  });

  describe('queryAuditLogs', () => {
    it('액션 유형별로 감사 로그를 조회해야 한다', async () => {
      // Given: 필터 조건과 모킹된 결과
      const filters: AuditQueryFilters = {
        action: 'PAYMENT_APPROVED',
        limit: 10,
      };

      const mockDocs = [
        {
          id: 'log_1',
          data: () => ({
            action: 'PAYMENT_APPROVED',
            userId: 'user_1',
            targetId: 'order_1',
            targetType: 'order',
            details: { amount: 10000 },
            timestamp: { toDate: () => new Date() },
          }),
        },
        {
          id: 'log_2',
          data: () => ({
            action: 'PAYMENT_APPROVED',
            userId: 'user_2',
            targetId: 'order_2',
            targetType: 'order',
            details: { amount: 20000 },
            timestamp: { toDate: () => new Date() },
          }),
        },
      ];

      mockGet.mockResolvedValueOnce({
        docs: mockDocs,
        empty: false,
      });

      // When: 감사 로그 조회
      const result = await queryAuditLogs(filters);

      // Then: 필터된 결과 반환
      expect(mockWhere).toHaveBeenCalledWith('action', '==', 'PAYMENT_APPROVED');
      expect(result).toHaveLength(2);
      expect(result[0].action).toBe('PAYMENT_APPROVED');
    });

    it('사용자 ID별로 감사 로그를 조회해야 한다', async () => {
      // Given: 사용자 ID 필터
      const filters: AuditQueryFilters = {
        userId: 'user_123',
        limit: 50,
      };

      const mockDocs = [
        {
          id: 'log_1',
          data: () => ({
            action: 'LISTING_CREATED',
            userId: 'user_123',
            targetId: 'listing_1',
            targetType: 'listing',
            details: {},
            timestamp: { toDate: () => new Date() },
          }),
        },
      ];

      mockGet.mockResolvedValueOnce({
        docs: mockDocs,
        empty: false,
      });

      // When: 감사 로그 조회
      const result = await queryAuditLogs(filters);

      // Then: 사용자별 필터 적용
      expect(mockWhere).toHaveBeenCalledWith('userId', '==', 'user_123');
      expect(result).toHaveLength(1);
    });

    it('날짜 범위로 감사 로그를 조회해야 한다', async () => {
      // Given: 날짜 범위 필터
      const startDate = new Date('2024-01-01');
      const endDate = new Date('2024-01-31');
      const filters: AuditQueryFilters = {
        startDate,
        endDate,
        limit: 100,
      };

      mockGet.mockResolvedValueOnce({
        docs: [],
        empty: true,
      });

      // When: 감사 로그 조회
      await queryAuditLogs(filters);

      // Then: 날짜 범위 필터 적용
      expect(mockWhere).toHaveBeenCalledWith('timestamp', '>=', expect.anything());
      expect(mockWhere).toHaveBeenCalledWith('timestamp', '<=', expect.anything());
    });

    it('대상 ID별로 감사 로그를 조회해야 한다', async () => {
      // Given: 대상 ID 필터
      const filters: AuditQueryFilters = {
        targetId: 'order_456',
        limit: 20,
      };

      const mockDocs = [
        {
          id: 'log_1',
          data: () => ({
            action: 'ORDER_CREATED',
            userId: 'user_1',
            targetId: 'order_456',
            targetType: 'order',
            details: {},
            timestamp: { toDate: () => new Date() },
          }),
        },
      ];

      mockGet.mockResolvedValueOnce({
        docs: mockDocs,
        empty: false,
      });

      // When: 감사 로그 조회
      const result = await queryAuditLogs(filters);

      // Then: 대상 ID 필터 적용
      expect(mockWhere).toHaveBeenCalledWith('targetId', '==', 'order_456');
      expect(result).toHaveLength(1);
    });

    it('결과가 없을 때 빈 배열을 반환해야 한다', async () => {
      // Given: 빈 결과
      const filters: AuditQueryFilters = {
        action: 'ADMIN_APPROVED',
        limit: 10,
      };

      mockGet.mockResolvedValueOnce({
        docs: [],
        empty: true,
      });

      // When: 감사 로그 조회
      const result = await queryAuditLogs(filters);

      // Then: 빈 배열 반환
      expect(result).toEqual([]);
    });

    it('timestamp 기준 내림차순으로 정렬해야 한다', async () => {
      // Given: 기본 조회 요청
      const filters: AuditQueryFilters = {
        limit: 10,
      };

      mockGet.mockResolvedValueOnce({
        docs: [],
        empty: true,
      });

      // When: 감사 로그 조회
      await queryAuditLogs(filters);

      // Then: 내림차순 정렬 적용
      expect(mockOrderBy).toHaveBeenCalledWith('timestamp', 'desc');
    });

    it('limit 없이 조회할 수 있어야 한다', async () => {
      // Given: limit 없는 필터
      const filters: AuditQueryFilters = {
        action: 'ORDER_CREATED',
      };

      const mockDocs = [
        {
          id: 'log_1',
          data: () => ({
            action: 'ORDER_CREATED',
            userId: 'user_1',
            targetId: 'order_1',
            targetType: 'order',
            details: {},
            timestamp: { toDate: () => new Date() },
          }),
        },
      ];

      mockGet.mockResolvedValueOnce({
        docs: mockDocs,
        empty: false,
      });

      // When: limit 없이 조회
      const result = await queryAuditLogs(filters);

      // Then: limit 호출 안됨
      expect(mockLimit).not.toHaveBeenCalled();
      expect(result).toHaveLength(1);
    });
  });

  describe('getAuditLogById', () => {
    it('ID로 감사 로그를 조회해야 한다', async () => {
      // Given: 존재하는 로그 ID
      const mockDocData = {
        action: 'PAYMENT_APPROVED',
        userId: 'user_123',
        targetId: 'order_456',
        targetType: 'order',
        details: { amount: 100000 },
        timestamp: { toDate: () => new Date('2024-01-15T10:00:00Z') },
      };

      mockGet.mockResolvedValueOnce({
        exists: true,
        id: 'audit_log_001',
        data: () => mockDocData,
      });

      // When: ID로 조회
      const result = await getAuditLogById('audit_log_001');

      // Then: 해당 로그 반환
      expect(mockDoc).toHaveBeenCalledWith('audit_log_001');
      expect(result).not.toBeNull();
      expect(result?.action).toBe('PAYMENT_APPROVED');
    });

    it('존재하지 않는 ID에 대해 null을 반환해야 한다', async () => {
      // Given: 존재하지 않는 로그 ID
      mockGet.mockResolvedValueOnce({
        exists: false,
      });

      // When: ID로 조회
      const result = await getAuditLogById('nonexistent_log');

      // Then: null 반환
      expect(result).toBeNull();
    });
  });
});
