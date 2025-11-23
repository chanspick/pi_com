// functions/src/refund/kakao_pay_cancel.ts

import * as admin from "firebase-admin";
import axios from "axios";

const KAKAO_PAY_CANCEL_URL = "https://open-api.kakaopay.com/online/v1/payment/cancel";

/**
 * 카카오페이 결제 취소 API 요청 파라미터
 * 참고: https://developers.kakaopay.com/docs/payment/online/cancellation
 */
interface KakaoPayCancelRequest {
  cid: string;                     // 가맹점 코드 (필수)
  tid: string;                     // 결제 고유번호 (필수)
  cancel_amount: number;           // 취소 금액 (필수)
  cancel_tax_free_amount?: number; // 취소 비과세 금액 (선택)
  cancel_vat_amount?: number;      // 취소 부가세 금액 (선택)
}

/**
 * 카카오페이 결제 취소 API 응답
 */
interface KakaoPayCancelResponse {
  aid: string;                     // 요청 고유번호
  tid: string;                     // 결제 고유번호
  cid: string;                     // 가맹점 코드
  status: string;                  // 결제 상태
  partner_order_id: string;        // 가맹점 주문번호
  partner_user_id: string;         // 가맹점 회원 id
  payment_method_type: string;     // 결제 수단
  amount: {
    total: number;                 // 전체 결제 금액
    tax_free: number;              // 비과세 금액
    vat: number;                   // 부가세 금액
    point: number;                 // 사용한 포인트
    discount: number;              // 할인 금액
  };
  canceled_amount: {
    total: number;                 // 이번 요청으로 취소된 전체 금액
    tax_free: number;              // 이번 요청으로 취소된 비과세 금액
    vat: number;                   // 이번 요청으로 취소된 부가세 금액
    point: number;                 // 이번 요청으로 취소된 포인트 금액
    discount: number;              // 이번 요청으로 취소된 할인 금액
  };
  cancel_available_amount: {
    total: number;                 // 취소 가능 금액
    tax_free: number;              // 취소 가능 비과세 금액
    vat: number;                   // 취소 가능 부가세 금액
    point: number;                 // 취소 가능 포인트 금액
    discount: number;              // 취소 가능 할인 금액
  };
  item_name: string;               // 상품 이름
  item_code: string;               // 상품 코드
  quantity: number;                // 상품 수량
  created_at: string;              // 결제 준비 요청 시각
  approved_at: string;             // 결제 승인 시각
  canceled_at: string;             // 결제 취소 시각
  payload: string;                 // 취소 요청 시 전달한 값
}

/**
 * 카카오페이 결제 취소 처리
 *
 * @param orderId 주문 ID
 * @param cancelAmount 취소 금액
 * @param taxFreeAmount 비과세 금액 (선택)
 * @returns 취소 결과
 */
export async function cancelKakaoPayment(
  orderId: string,
  cancelAmount: number,
  taxFreeAmount: number = 0
): Promise<KakaoPayCancelResponse> {
  const db = admin.firestore();

  try {
    // 1. 주문 정보 조회
    const orderDoc = await db.collection("orders").doc(orderId).get();
    if (!orderDoc.exists) {
      throw new Error(`주문을 찾을 수 없습니다: ${orderId}`);
    }

    const orderData = orderDoc.data();
    if (!orderData) {
      throw new Error(`주문 데이터가 비어있습니다: ${orderId}`);
    }

    // 2. 결제 정보 확인
    const tid = orderData.kakaoPayTid || orderData.tid;
    if (!tid) {
      throw new Error(`카카오페이 거래 고유번호(TID)를 찾을 수 없습니다: ${orderId}`);
    }

    // 3. Admin Key 확인
    const adminKey = process.env.KAKAO_ADMIN_KEY;
    if (!adminKey) {
      throw new Error("KAKAO_ADMIN_KEY 환경 변수가 설정되지 않았습니다");
    }

    // 4. CID 확인 (가맹점 코드)
    const cid = process.env.KAKAO_CID || "TC0ONETIME";

    // 5. 카카오페이 결제 취소 API 요청 데이터
    const cancelRequest: KakaoPayCancelRequest = {
      cid: cid,
      tid: tid,
      cancel_amount: cancelAmount,
    };

    // 비과세 금액이 있는 경우 추가
    if (taxFreeAmount > 0) {
      cancelRequest.cancel_tax_free_amount = taxFreeAmount;
    }

    console.log("카카오페이 결제 취소 요청:", {
      orderId,
      tid,
      cancelAmount,
      taxFreeAmount,
    });

    // 6. 카카오페이 API 호출
    const response = await axios.post<KakaoPayCancelResponse>(
      KAKAO_PAY_CANCEL_URL,
      cancelRequest,
      {
        headers: {
          Authorization: `SECRET_KEY ${adminKey}`,
          "Content-Type": "application/json",
        },
      }
    );

    console.log("카카오페이 결제 취소 성공:", {
      aid: response.data.aid,
      tid: response.data.tid,
      canceled_amount: response.data.canceled_amount,
      canceled_at: response.data.canceled_at,
    });

    // 7. 취소 정보를 orders 컬렉션에 저장
    await db.collection("orders").doc(orderId).update({
      kakaoPayCancelTid: response.data.tid,
      kakaoPayCancelAid: response.data.aid,
      refundApprovedAt: admin.firestore.FieldValue.serverTimestamp(),
      refundAmount: response.data.canceled_amount.total,
      refundStatus: "completed",
      kakaoPayCancelResponse: response.data,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return response.data;
  } catch (error: any) {
    console.error("카카오페이 결제 취소 실패:", error);

    // Axios 에러 상세 처리
    if (axios.isAxiosError(error) && error.response) {
      const errorData = error.response.data;
      const errorCode = errorData?.error_code || "UNKNOWN";
      const errorMsg = errorData?.error_message || error.message;

      console.error("카카오페이 API 에러 응답:", {
        errorCode,
        errorMsg,
        status: error.response.status,
      });

      // 주문 문서에 에러 기록
      await db.collection("orders").doc(orderId).update({
        refundError: {
          code: errorCode,
          message: errorMsg,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
        },
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      throw new Error(`카카오페이 결제 취소 실패 [${errorCode}]: ${errorMsg}`);
    }

    throw error;
  }
}

/**
 * 부분 취소 처리 (여러 상품 중 일부만 환불)
 *
 * @param orderId 주문 ID
 * @param refundItems 환불할 아이템 정보
 * @returns 취소 결과
 */
export async function partialCancelKakaoPayment(
  orderId: string,
  refundItems: Array<{ itemId: string; quantity: number; price: number }>
): Promise<KakaoPayCancelResponse> {
  // 부분 환불 금액 계산
  const cancelAmount = refundItems.reduce(
    (sum, item) => sum + item.quantity * item.price,
    0
  );

  console.log("부분 환불 요청:", {
    orderId,
    refundItems,
    totalCancelAmount: cancelAmount,
  });

  // 카카오페이는 전체/부분 취소 모두 동일한 API 사용
  return await cancelKakaoPayment(orderId, cancelAmount);
}

/**
 * 환불 가능 금액 조회
 *
 * @param orderId 주문 ID
 * @returns 환불 가능 금액 정보
 */
export async function getRefundableAmount(orderId: string): Promise<number> {
  const db = admin.firestore();

  const orderDoc = await db.collection("orders").doc(orderId).get();
  if (!orderDoc.exists) {
    throw new Error(`주문을 찾을 수 없습니다: ${orderId}`);
  }

  const orderData = orderDoc.data()!;
  const totalAmount = orderData.totalPrice + orderData.shippingFee;
  const alreadyRefunded = orderData.refundAmount || 0;

  return totalAmount - alreadyRefunded;
}
