// functions/src/__tests__/payment/payment_transaction.test.ts
// 결제 트랜잭션 연동 테스트 - TDD GREEN 단계

import {
  processPaymentWithTransaction,
  cancelPaymentWithTransaction,
  PaymentApproveParams,
  PaymentCancelParams,
} from '../../payment/payment_transaction';

// Firebase Admin SDK 모킹
const mockRunTransaction = jest.fn();
const mockCollection = jest.fn();
const mockDoc = jest.fn();

jest.mock('firebase-admin', () => ({
  initializeApp: jest.fn(),
  firestore: jest.fn(() => ({
    collection: mockCollection,
    runTransaction: mockRunTransaction,
  })),
}));

// admin.firestore.FieldValue 모킹
const mockAdmin = require('firebase-admin');
mockAdmin.firestore.FieldValue = {
  serverTimestamp: jest.fn(() => 'SERVER_TIMESTAMP'),
};

describe('PaymentTransaction', () => {
  beforeEach(() => {
    jest.clearAllMocks();

    // collection().doc() 체인 모킹
    mockCollection.mockReturnValue({
      doc: mockDoc,
    });
    mockDoc.mockReturnValue({});
  });

  describe('processPaymentWithTransaction', () => {
    const validParams: PaymentApproveParams = {
      orderId: 'order_123',
      listingId: 'listing_456',
      paymentKey: 'payment_key_789',
      amount: 100000,
      userId: 'user_abc',
    };

    it('결제 승인 시 주문과 매물 상태를 원자적으로 업데이트해야 한다', async () => {
      // Given: 유효한 주문과 매물이 존재
      const mockOrderDoc = {
        exists: true,
        data: () => ({
          status: 'pending_payment',
          listingId: 'listing_456',
          totalPrice: 100000,
        }),
      };
      const mockListingDoc = {
        exists: true,
        data: () => ({
          status: 'available',
          price: 100000,
        }),
      };

      const mockTransaction = {
        get: jest.fn()
          .mockResolvedValueOnce(mockOrderDoc)
          .mockResolvedValueOnce(mockListingDoc),
        update: jest.fn(),
      };

      mockRunTransaction.mockImplementation(async (callback: Function) => {
        return callback(mockTransaction);
      });

      // When: 결제 승인 트랜잭션 실행
      const result = await processPaymentWithTransaction(validParams);

      // Then: 트랜잭션이 성공하고 주문/매물 상태가 업데이트됨
      expect(result.success).toBe(true);
      expect(result.orderId).toBe('order_123');
      expect(mockRunTransaction).toHaveBeenCalledTimes(1);
      expect(mockTransaction.update).toHaveBeenCalledTimes(2);
    });

    it('이미 완료된 결제에 대해 중복 처리를 방지해야 한다', async () => {
      // Given: 이미 결제가 완료된 주문
      const mockOrderDoc = {
        exists: true,
        data: () => ({
          status: 'paid', // 이미 결제 완료
          listingId: 'listing_456',
        }),
      };

      const mockTransaction = {
        get: jest.fn().mockResolvedValueOnce(mockOrderDoc),
        update: jest.fn(),
      };

      mockRunTransaction.mockImplementation(async (callback: Function) => {
        return callback(mockTransaction);
      });

      // When & Then: 중복 결제 시도 시 에러
      await expect(processPaymentWithTransaction(validParams))
        .rejects.toThrow('Order already processed');
    });

    it('매물이 이미 판매된 경우 결제를 거부해야 한다', async () => {
      // Given: 매물이 이미 sold 상태
      const mockOrderDoc = {
        exists: true,
        data: () => ({
          status: 'pending_payment',
          listingId: 'listing_456',
          totalPrice: 100000,
        }),
      };
      const mockListingDoc = {
        exists: true,
        data: () => ({
          status: 'sold', // 이미 판매됨
        }),
      };

      const mockTransaction = {
        get: jest.fn()
          .mockResolvedValueOnce(mockOrderDoc)
          .mockResolvedValueOnce(mockListingDoc),
        update: jest.fn(),
      };

      mockRunTransaction.mockImplementation(async (callback: Function) => {
        return callback(mockTransaction);
      });

      // When & Then: 매물이 이미 판매된 경우 에러
      await expect(processPaymentWithTransaction(validParams))
        .rejects.toThrow('Listing is not available');
    });

    it('존재하지 않는 주문에 대해 에러를 반환해야 한다', async () => {
      // Given: 주문이 존재하지 않음
      const mockOrderDoc = {
        exists: false,
      };

      const mockTransaction = {
        get: jest.fn().mockResolvedValueOnce(mockOrderDoc),
        update: jest.fn(),
      };

      mockRunTransaction.mockImplementation(async (callback: Function) => {
        return callback(mockTransaction);
      });

      // When & Then: 주문이 없으면 에러
      await expect(processPaymentWithTransaction(validParams))
        .rejects.toThrow('Order not found');
    });

    it('결제 금액이 주문 금액과 일치하지 않으면 에러를 반환해야 한다', async () => {
      // Given: 결제 금액 불일치
      const mockOrderDoc = {
        exists: true,
        data: () => ({
          status: 'pending_payment',
          listingId: 'listing_456',
          totalPrice: 150000, // 주문 금액: 150,000원
        }),
      };
      const mockListingDoc = {
        exists: true,
        data: () => ({
          status: 'available',
        }),
      };

      const mockTransaction = {
        get: jest.fn()
          .mockResolvedValueOnce(mockOrderDoc)
          .mockResolvedValueOnce(mockListingDoc),
        update: jest.fn(),
      };

      mockRunTransaction.mockImplementation(async (callback: Function) => {
        return callback(mockTransaction);
      });

      // When & Then: 금액 불일치 시 에러
      await expect(processPaymentWithTransaction({
        ...validParams,
        amount: 100000, // 결제 시도 금액: 100,000원
      })).rejects.toThrow('Payment amount mismatch');
    });
  });

  describe('cancelPaymentWithTransaction', () => {
    const validCancelParams: PaymentCancelParams = {
      orderId: 'order_123',
      listingId: 'listing_456',
      paymentKey: 'payment_key_789',
      cancelReason: '고객 요청',
      cancelAmount: 100000,
    };

    it('결제 취소 시 주문과 매물 상태를 원자적으로 롤백해야 한다', async () => {
      // Given: 결제 완료된 주문이 존재
      const mockOrderDoc = {
        exists: true,
        data: () => ({
          status: 'paid',
          listingId: 'listing_456',
          totalPrice: 100000,
        }),
      };
      const mockListingDoc = {
        exists: true,
        data: () => ({
          status: 'reserved', // 예약됨 상태
        }),
      };

      const mockTransaction = {
        get: jest.fn()
          .mockResolvedValueOnce(mockOrderDoc)
          .mockResolvedValueOnce(mockListingDoc),
        update: jest.fn(),
      };

      mockRunTransaction.mockImplementation(async (callback: Function) => {
        return callback(mockTransaction);
      });

      // When: 결제 취소 트랜잭션 실행
      const result = await cancelPaymentWithTransaction(validCancelParams);

      // Then: 트랜잭션이 성공하고 주문/매물 상태가 롤백됨
      expect(result.success).toBe(true);
      expect(result.orderId).toBe('order_123');
      expect(mockRunTransaction).toHaveBeenCalledTimes(1);
      expect(mockTransaction.update).toHaveBeenCalledTimes(2);
    });

    it('이미 취소된 주문에 대해 중복 취소를 방지해야 한다', async () => {
      // Given: 이미 취소된 주문
      const mockOrderDoc = {
        exists: true,
        data: () => ({
          status: 'cancelled', // 이미 취소됨
          listingId: 'listing_456',
        }),
      };

      const mockTransaction = {
        get: jest.fn().mockResolvedValueOnce(mockOrderDoc),
        update: jest.fn(),
      };

      mockRunTransaction.mockImplementation(async (callback: Function) => {
        return callback(mockTransaction);
      });

      // When & Then: 중복 취소 시도 시 에러
      await expect(cancelPaymentWithTransaction(validCancelParams))
        .rejects.toThrow('Order already cancelled');
    });

    it('존재하지 않는 주문 취소 시 에러를 반환해야 한다', async () => {
      // Given: 주문이 존재하지 않음
      const mockOrderDoc = {
        exists: false,
      };

      const mockTransaction = {
        get: jest.fn().mockResolvedValueOnce(mockOrderDoc),
        update: jest.fn(),
      };

      mockRunTransaction.mockImplementation(async (callback: Function) => {
        return callback(mockTransaction);
      });

      // When & Then: 주문이 없으면 에러
      await expect(cancelPaymentWithTransaction(validCancelParams))
        .rejects.toThrow('Order not found');
    });

    it('취소 불가능한 상태의 주문에 대해 에러를 반환해야 한다', async () => {
      // Given: 배송 완료된 주문 (취소 불가)
      const mockOrderDoc = {
        exists: true,
        data: () => ({
          status: 'delivered', // 배송 완료
          listingId: 'listing_456',
        }),
      };

      const mockTransaction = {
        get: jest.fn().mockResolvedValueOnce(mockOrderDoc),
        update: jest.fn(),
      };

      mockRunTransaction.mockImplementation(async (callback: Function) => {
        return callback(mockTransaction);
      });

      // When & Then: 배송 완료된 주문은 취소 불가
      await expect(cancelPaymentWithTransaction(validCancelParams))
        .rejects.toThrow('Order cannot be cancelled in current status');
    });
  });
});
