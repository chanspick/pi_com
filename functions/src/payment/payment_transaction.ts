// functions/src/payment/payment_transaction.ts
// 결제 트랜잭션 처리 모듈 - 주문과 매물 상태를 원자적으로 업데이트

import * as admin from 'firebase-admin';

/**
 * 결제 승인 요청 파라미터
 */
export interface PaymentApproveParams {
  orderId: string;
  listingId: string;
  paymentKey: string;
  amount: number;
  userId: string;
}

/**
 * 결제 취소 요청 파라미터
 */
export interface PaymentCancelParams {
  orderId: string;
  listingId: string;
  paymentKey: string;
  cancelReason: string;
  cancelAmount: number;
}

/**
 * 트랜잭션 결과
 */
export interface TransactionResult {
  success: boolean;
  orderId: string;
  message?: string;
}

// 취소 가능한 주문 상태 목록
const CANCELLABLE_ORDER_STATUSES = ['paid', 'pending_payment', 'pending_shipping'];

/**
 * 결제 승인 트랜잭션 처리
 * 주문과 매물 상태를 원자적으로 업데이트
 *
 * @param params - 결제 승인 파라미터
 * @returns 트랜잭션 결과
 * @throws Error - 트랜잭션 실패 시
 */
export async function processPaymentWithTransaction(
  params: PaymentApproveParams
): Promise<TransactionResult> {
  const db = admin.firestore();
  const { orderId, listingId, paymentKey, amount, userId } = params;

  const orderRef = db.collection('orders').doc(orderId);
  const listingRef = db.collection('listings').doc(listingId);

  return db.runTransaction(async (transaction) => {
    // 1. 주문 문서 조회
    const orderDoc = await transaction.get(orderRef);
    if (!orderDoc.exists) {
      throw new Error('Order not found');
    }

    const orderData = orderDoc.data()!;

    // 2. 주문 상태 검증 - 이미 결제된 경우 중복 처리 방지
    if (orderData.status === 'paid' || orderData.status === 'confirmed' || orderData.status === 'delivered') {
      throw new Error('Order already processed');
    }

    // 3. 결제 금액 검증
    if (orderData.totalPrice !== amount) {
      throw new Error('Payment amount mismatch');
    }

    // 4. 매물 문서 조회
    const listingDoc = await transaction.get(listingRef);
    if (!listingDoc.exists) {
      throw new Error('Listing not found');
    }

    const listingData = listingDoc.data()!;

    // 5. 매물 상태 검증 - 이미 판매된 경우 거부
    if (listingData.status !== 'available' && listingData.status !== 'reserved') {
      throw new Error('Listing is not available');
    }

    // 6. 주문 상태 업데이트 - paid로 변경
    transaction.update(orderRef, {
      status: 'paid',
      paymentKey: paymentKey,
      paidAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // 7. 매물 상태 업데이트 - sold로 변경
    transaction.update(listingRef, {
      status: 'sold',
      soldAt: admin.firestore.FieldValue.serverTimestamp(),
      buyerId: userId,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log(`[PaymentTransaction] 결제 승인 완료: orderId=${orderId}, listingId=${listingId}`);

    return {
      success: true,
      orderId,
      message: '결제가 성공적으로 완료되었습니다.',
    };
  });
}

/**
 * 결제 취소 트랜잭션 처리
 * 주문과 매물 상태를 원자적으로 롤백
 *
 * @param params - 결제 취소 파라미터
 * @returns 트랜잭션 결과
 * @throws Error - 트랜잭션 실패 시
 */
export async function cancelPaymentWithTransaction(
  params: PaymentCancelParams
): Promise<TransactionResult> {
  const db = admin.firestore();
  const { orderId, listingId, cancelReason, cancelAmount } = params;
  // paymentKey는 취소 시 로깅용으로 사용될 수 있으나 현재 미사용

  const orderRef = db.collection('orders').doc(orderId);
  const listingRef = db.collection('listings').doc(listingId);

  return db.runTransaction(async (transaction) => {
    // 1. 주문 문서 조회
    const orderDoc = await transaction.get(orderRef);
    if (!orderDoc.exists) {
      throw new Error('Order not found');
    }

    const orderData = orderDoc.data()!;

    // 2. 주문 상태 검증 - 이미 취소된 경우 중복 처리 방지
    if (orderData.status === 'cancelled') {
      throw new Error('Order already cancelled');
    }

    // 3. 취소 가능한 상태인지 검증
    if (!CANCELLABLE_ORDER_STATUSES.includes(orderData.status)) {
      throw new Error('Order cannot be cancelled in current status');
    }

    // 4. 매물 문서 조회
    const listingDoc = await transaction.get(listingRef);
    if (!listingDoc.exists) {
      throw new Error('Listing not found');
    }

    // 5. 주문 상태 업데이트 - cancelled로 변경
    transaction.update(orderRef, {
      status: 'cancelled',
      cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
      cancelReason: cancelReason,
      cancelAmount: cancelAmount,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // 6. 매물 상태 업데이트 - available로 복원
    transaction.update(listingRef, {
      status: 'available',
      soldAt: null,
      buyerId: null,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log(`[PaymentTransaction] 결제 취소 완료: orderId=${orderId}, listingId=${listingId}, reason=${cancelReason}`);

    return {
      success: true,
      orderId,
      message: '결제가 성공적으로 취소되었습니다.',
    };
  });
}
