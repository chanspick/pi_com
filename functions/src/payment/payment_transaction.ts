// functions/src/payment/payment_transaction.ts

import * as admin from "firebase-admin";

/**
 * 결제 트랜잭션 파라미터
 */
interface PaymentTransactionParams {
  orderId: string;
  listingId: string;
  buyerId: string;
  sellerId: string;
  amount: number;
}

/**
 * 결제 트랜잭션 결과
 */
interface PaymentTransactionResult {
  success: boolean;
  message: string;
  data?: {
    orderId: string;
    status: string;
  };
}

/**
 * 결제를 Firestore 트랜잭션 내에서 원자적으로 처리합니다.
 * 주문 생성/업데이트와 상품 상태 변경이 모두 성공하거나 모두 롤백됩니다.
 *
 * 트랜잭션 흐름:
 * 1. 주문 및 상품 문서 조회
 * 2. 상품 유효성 검증 (존재 여부, 판매 상태)
 * 3. 원자적 업데이트 (주문 상태, 상품 상태)
 *
 * @param params 결제 트랜잭션 파라미터
 * @returns 트랜잭션 결과
 */
export async function processPaymentWithTransaction(
  params: PaymentTransactionParams
): Promise<PaymentTransactionResult> {
  const db = admin.firestore();
  const orderRef = db.collection("orders").doc(params.orderId);
  const listingRef = db.collection("listings").doc(params.listingId);

  console.log(`[Payment Transaction] 결제 트랜잭션 시작: orderId=${params.orderId}, listingId=${params.listingId}, amount=${params.amount}`);

  try {
    const result = await db.runTransaction(async (transaction) => {
      // 1. Read all documents first (Firestore 트랜잭션 규칙: 모든 읽기는 쓰기 전에)
      const orderDoc = await transaction.get(orderRef);
      const listingDoc = await transaction.get(listingRef);

      // 2. Validate listing
      if (!listingDoc.exists) {
        console.error(`[Payment Transaction] 상품을 찾을 수 없음: listingId=${params.listingId}`);
        throw new Error("상품을 찾을 수 없습니다.");
      }

      const listingData = listingDoc.data();
      if (listingData?.status === "sold") {
        console.error(`[Payment Transaction] 이미 판매된 상품: listingId=${params.listingId}`);
        throw new Error("이미 판매된 상품입니다.");
      }

      if (listingData?.status !== "available") {
        console.error(`[Payment Transaction] 구매 불가 상품 상태: status=${listingData?.status}`);
        throw new Error(`구매할 수 없는 상품입니다. (상태: ${listingData?.status})`);
      }

      // 가격 검증
      if (listingData?.price !== params.amount) {
        console.error(`[Payment Transaction] 가격 불일치: expected=${listingData?.price}, actual=${params.amount}`);
        throw new Error("상품 가격이 변경되었습니다. 다시 시도해주세요.");
      }

      // 3. Write operations
      // 주문 업데이트
      if (orderDoc.exists) {
        transaction.update(orderRef, {
          status: "paid",
          paidAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      } else {
        transaction.set(orderRef, {
          orderId: params.orderId,
          listingId: params.listingId,
          buyerId: params.buyerId,
          sellerId: params.sellerId,
          amount: params.amount,
          status: "paid",
          paidAt: admin.firestore.FieldValue.serverTimestamp(),
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }

      // 상품 상태 업데이트
      transaction.update(listingRef, {
        status: "sold",
        soldAt: admin.firestore.FieldValue.serverTimestamp(),
        buyerId: params.buyerId,
        orderId: params.orderId,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(`[Payment Transaction] 트랜잭션 쓰기 완료: orderId=${params.orderId}`);
      return { orderId: params.orderId, status: "paid" };
    });

    console.log(`[Payment Transaction] 결제 트랜잭션 성공: orderId=${result.orderId}`);

    return {
      success: true,
      message: "결제가 성공적으로 처리되었습니다.",
      data: result,
    };
  } catch (error: any) {
    console.error(`[Payment Transaction] 결제 트랜잭션 실패: ${error.message}`);

    return {
      success: false,
      message: error.message || "결제 처리 중 오류가 발생했습니다.",
    };
  }
}

/**
 * 결제 취소를 Firestore 트랜잭션 내에서 원자적으로 처리합니다.
 * 주문 취소와 상품 상태 복원이 모두 성공하거나 모두 롤백됩니다.
 *
 * @param orderId 취소할 주문 ID
 * @param cancelReason 취소 사유
 * @returns 트랜잭션 결과
 */
export async function cancelPaymentWithTransaction(
  orderId: string,
  cancelReason: string
): Promise<PaymentTransactionResult> {
  const db = admin.firestore();
  const orderRef = db.collection("orders").doc(orderId);

  console.log(`[Payment Transaction] 결제 취소 트랜잭션 시작: orderId=${orderId}`);

  try {
    const result = await db.runTransaction(async (transaction) => {
      // 1. Read order document
      const orderDoc = await transaction.get(orderRef);

      if (!orderDoc.exists) {
        throw new Error("주문을 찾을 수 없습니다.");
      }

      const orderData = orderDoc.data();
      if (!orderData) {
        throw new Error("주문 데이터가 없습니다.");
      }

      // 2. Validate order status
      if (orderData.status === "cancelled") {
        throw new Error("이미 취소된 주문입니다.");
      }

      // 3. Read listing document
      const listingRef = db.collection("listings").doc(orderData.listingId);
      const listingDoc = await transaction.get(listingRef);

      // 4. Update order status
      transaction.update(orderRef, {
        status: "cancelled",
        cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
        cancelReason: cancelReason,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // 5. Restore listing status if it exists
      if (listingDoc.exists) {
        transaction.update(listingRef, {
          status: "available",
          soldAt: admin.firestore.FieldValue.delete(),
          buyerId: admin.firestore.FieldValue.delete(),
          orderId: admin.firestore.FieldValue.delete(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }

      console.log(`[Payment Transaction] 결제 취소 트랜잭션 쓰기 완료: orderId=${orderId}`);
      return { orderId: orderId, status: "cancelled" };
    });

    console.log(`[Payment Transaction] 결제 취소 트랜잭션 성공: orderId=${result.orderId}`);

    return {
      success: true,
      message: "주문이 성공적으로 취소되었습니다.",
      data: result,
    };
  } catch (error: any) {
    console.error(`[Payment Transaction] 결제 취소 트랜잭션 실패: ${error.message}`);

    return {
      success: false,
      message: error.message || "주문 취소 처리 중 오류가 발생했습니다.",
    };
  }
}
