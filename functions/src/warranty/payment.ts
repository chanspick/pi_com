/**
 * Warranty Payment API v2
 * AS 보증 결제 처리
 *
 * v2 변경사항:
 * - 기본 보증 자동 생성 (스코어 기반, 결제 없음)
 * - 추가 보증 결제 (1년 10% / 2년 20%)
 * - 기존 보증 결제 API 호환성 유지
 */

import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import axios from "axios";
import {Router} from "express";
import {
  Warranty,
  VerificationTransaction,
  WarrantyPaymentRequest,
  AdditionalWarrantyPaymentRequest,
  AdditionalWarrantyPaymentResponse,
  WARRANTY_RATES,
  ADDITIONAL_WARRANTY_RATES,
  generateWarrantyId,
} from "./types";

const router = Router();
const db = admin.firestore();

// ============================================================================
// 결제 설정
// ============================================================================

const KAKAO_PAY_API_URL = "https://open-api.kakaopay.com/online/v1/payment";
const TOSS_PAYMENTS_API_URL = "https://api.tosspayments.com/v1/payments";

const getKakaoPayConfig = () => {
  const config = functions.config();
  return {
    adminKey: config.kakaopay?.admin_key || process.env.KAKAO_ADMIN_KEY || "",
    cid: config.kakaopay?.cid || process.env.KAKAO_CID || "TC0ONETIME",
  };
};

const getTossPaymentsConfig = () => {
  const config = functions.config();
  return {
    secretKey: config.tosspayments?.secret_key || process.env.TOSS_SECRET_KEY || "test_gsk_AQ92ymxN34LGgD1yDA5j3ajRKXvd",
  };
};

const WARRANTY_WEB_URL = process.env.WARRANTY_WEB_URL || "https://picom.site";

// ============================================================================
// POST /warranty/activate - 기본 보증 활성화 (v2, 결제 없음)
// ============================================================================

router.post("/activate", async (req, res) => {
  try {
    const {qrCode, customerName, customerPhone, customerEmail} = req.body;

    // 필수 필드 검증
    if (!qrCode || !customerName || !customerPhone) {
      res.status(400).json({
        error: "Missing required fields",
        required: ["qrCode", "customerName", "customerPhone"],
      });
      return;
    }

    // QR 코드로 거래 조회
    const transactionSnapshot = await db
      .collection("verification_transactions")
      .where("qrCode", "==", qrCode)
      .limit(1)
      .get();

    if (transactionSnapshot.empty) {
      res.status(404).json({error: "Transaction not found for the provided QR code"});
      return;
    }

    const transactionDoc = transactionSnapshot.docs[0];
    const transaction = transactionDoc.data() as VerificationTransaction;

    // 이미 보증이 등록된 경우
    if (transaction.warrantyId) {
      const existingWarranty = await db.collection("warranties").doc(transaction.warrantyId).get();
      if (existingWarranty.exists) {
        res.status(200).json({
          success: true,
          message: "Warranty already activated",
          warranty: existingWarranty.data(),
        });
        return;
      }
    }

    const now = admin.firestore.Timestamp.now();
    const warrantyId = generateWarrantyId();

    // 기본 보증 기간 계산
    const baseWarrantyMonths = transaction.baseWarrantyMonths || 12;
    const startDate = new Date();
    const baseEndDate = new Date();
    baseEndDate.setMonth(baseEndDate.getMonth() + baseWarrantyMonths);

    // 기본 보증 생성 (결제 없음)
    // 추가 보증 필드는 생략 (optional 필드이므로 Firestore에 저장하지 않음)
    const warranty = {
      warrantyId,
      transactionId: transaction.transactionId,
      qrCode: qrCode,

      // 기본 보증 (스코어 기반)
      baseWarrantyMonths,
      baseWarrantyEndDate: admin.firestore.Timestamp.fromDate(baseEndDate),

      // 총 보증 (현재는 기본만)
      totalWarrantyMonths: baseWarrantyMonths,
      totalWarrantyEndDate: admin.firestore.Timestamp.fromDate(baseEndDate),

      // 호환성 유지
      warrantyPeriodMonths: baseWarrantyMonths,
      startDate: admin.firestore.Timestamp.fromDate(startDate),
      endDate: admin.firestore.Timestamp.fromDate(baseEndDate),

      // 고객 정보
      customerName,
      customerPhone,
      customerEmail: customerEmail || "",

      // 활성화 (결제 없이)
      status: "active" as const,
      serviceRequestIds: [] as string[],

      createdAt: now,
      updatedAt: now,
    };

    await db.collection("warranties").doc(warrantyId).set(warranty);

    // 거래 문서 업데이트
    await db.collection("verification_transactions").doc(transaction.transactionId).update({
      warrantyId,
      status: "warrantyActive",
      updatedAt: now,
    });

    console.log(`Base warranty activated: ${warrantyId}, ${baseWarrantyMonths} months`);

    res.status(201).json({
      success: true,
      warrantyId,
      baseWarrantyMonths,
      totalWarrantyMonths: baseWarrantyMonths,
      baseWarrantyEndDate: baseEndDate.toISOString(),
      message: "Base warranty activated successfully",
    });
  } catch (error: any) {
    console.error("Warranty activation error:", error);
    res.status(500).json({
      error: "Failed to activate warranty",
      message: error.message,
    });
  }
});

// ============================================================================
// POST /warranty/payment/additional - 추가 보증 결제 준비 (v2)
// ============================================================================

router.post("/payment/additional", async (req, res) => {
  try {
    const data = req.body as AdditionalWarrantyPaymentRequest;

    // 필수 필드 검증
    if (!data.qrCode || !data.additionalMonths || !data.customerName || !data.customerPhone) {
      res.status(400).json({
        error: "Missing required fields",
        required: ["qrCode", "additionalMonths", "customerName", "customerPhone", "paymentMethod"],
      });
      return;
    }

    if (data.additionalMonths !== 12 && data.additionalMonths !== 24) {
      res.status(400).json({
        error: "additionalMonths must be 12 or 24",
      });
      return;
    }

    // QR 코드로 거래 조회
    const transactionSnapshot = await db
      .collection("verification_transactions")
      .where("qrCode", "==", data.qrCode)
      .limit(1)
      .get();

    if (transactionSnapshot.empty) {
      res.status(404).json({error: "Transaction not found for the provided QR code"});
      return;
    }

    const transactionDoc = transactionSnapshot.docs[0];
    const transaction = transactionDoc.data() as VerificationTransaction;

    // 보증이 없으면 먼저 기본 보증 활성화 필요
    if (!transaction.warrantyId) {
      res.status(400).json({
        error: "Base warranty not activated",
        message: "Please activate base warranty first using /warranty/activate",
      });
      return;
    }

    // 기존 보증 조회
    const warrantyDoc = await db.collection("warranties").doc(transaction.warrantyId).get();
    if (!warrantyDoc.exists) {
      res.status(404).json({error: "Warranty not found"});
      return;
    }

    const warranty = warrantyDoc.data() as Warranty;

    // 이미 추가 보증이 있는지 확인
    if (warranty.additionalWarrantyMonths) {
      res.status(400).json({
        error: "Additional warranty already purchased",
        currentAdditionalMonths: warranty.additionalWarrantyMonths,
      });
      return;
    }

    // 추가 보증 요금 계산
    const rateConfig = ADDITIONAL_WARRANTY_RATES[data.additionalMonths];
    const additionalPrice = Math.round(transaction.salePrice * rateConfig.rate);

    // 결제 준비 (카카오페이 또는 토스페이)
    let paymentResult;

    if (data.paymentMethod === "kakaopay") {
      paymentResult = await prepareKakaoPayAdditional(
        warranty.warrantyId,
        transaction,
        additionalPrice,
        data.additionalMonths
      );
    } else if (data.paymentMethod === "tosspay") {
      paymentResult = await prepareTossPayAdditional(
        warranty.warrantyId,
        transaction,
        additionalPrice,
        data.additionalMonths
      );
    } else {
      res.status(400).json({
        error: "Invalid payment method",
        validMethods: ["kakaopay", "tosspay"],
      });
      return;
    }

    // 보증 문서에 결제 대기 정보 업데이트
    const paymentKeyValue = "tid" in paymentResult ? paymentResult.tid : paymentResult.paymentKey;
    await db.collection("warranties").doc(warranty.warrantyId).update({
      paymentKey: paymentKeyValue,
      paymentMethod: data.paymentMethod,
      pendingAdditionalMonths: data.additionalMonths,
      pendingAdditionalPrice: additionalPrice,
      updatedAt: admin.firestore.Timestamp.now(),
    });

    console.log(`Additional warranty payment prepared: ${warranty.warrantyId}, +${data.additionalMonths}mo, ₩${additionalPrice}`);

    const response: AdditionalWarrantyPaymentResponse = {
      warrantyId: warranty.warrantyId,
      baseWarrantyMonths: warranty.baseWarrantyMonths,
      additionalWarrantyMonths: data.additionalMonths,
      totalWarrantyMonths: warranty.baseWarrantyMonths + data.additionalMonths,
      additionalPrice,
      ...paymentResult,
    };

    res.status(200).json(response);
  } catch (error: any) {
    console.error("Additional warranty payment prepare error:", error);
    res.status(500).json({
      error: "Failed to prepare additional warranty payment",
      message: error.message,
    });
  }
});

// ============================================================================
// POST /warranty/payment/additional/approve - 추가 보증 결제 승인 (v2)
// ============================================================================

router.post("/payment/additional/approve", async (req, res) => {
  try {
    const {warrantyId, pgToken, paymentKey, orderId, amount} = req.body;

    if (!warrantyId) {
      res.status(400).json({error: "Missing warrantyId"});
      return;
    }

    const warrantyDoc = await db.collection("warranties").doc(warrantyId).get();

    if (!warrantyDoc.exists) {
      res.status(404).json({error: "Warranty not found"});
      return;
    }

    const warranty = warrantyDoc.data() as Warranty & {
      pendingAdditionalMonths?: number;
      pendingAdditionalPrice?: number;
    };

    if (!warranty.pendingAdditionalMonths) {
      res.status(400).json({
        error: "No pending additional warranty payment",
      });
      return;
    }

    let approvalResult;

    // 결제 승인 처리
    if (warranty.paymentMethod === "kakaopay" && pgToken) {
      approvalResult = await approveKakaoPay(warranty, pgToken);
    } else if (warranty.paymentMethod === "tosspay" && paymentKey) {
      approvalResult = await approveTossPay(paymentKey, orderId, amount);
    } else {
      res.status(400).json({error: "Missing payment approval parameters"});
      return;
    }

    const now = admin.firestore.Timestamp.now();

    // 새 종료일 계산
    const currentEndDate = warranty.totalWarrantyEndDate?.toDate() || warranty.endDate?.toDate() || new Date();
    const newEndDate = new Date(currentEndDate);
    newEndDate.setMonth(newEndDate.getMonth() + warranty.pendingAdditionalMonths);

    // 보증 업데이트
    await db.collection("warranties").doc(warrantyId).update({
      additionalWarrantyMonths: warranty.pendingAdditionalMonths,
      additionalWarrantyPrice: warranty.pendingAdditionalPrice,
      additionalWarrantyPaidAt: now,

      totalWarrantyMonths: warranty.baseWarrantyMonths + warranty.pendingAdditionalMonths,
      totalWarrantyEndDate: admin.firestore.Timestamp.fromDate(newEndDate),

      // 호환성
      endDate: admin.firestore.Timestamp.fromDate(newEndDate),
      warrantyPeriodMonths: warranty.baseWarrantyMonths + warranty.pendingAdditionalMonths,

      paidAt: now,

      // 대기 정보 제거
      pendingAdditionalMonths: admin.firestore.FieldValue.delete(),
      pendingAdditionalPrice: admin.firestore.FieldValue.delete(),

      updatedAt: now,
    });

    console.log(`Additional warranty approved: ${warrantyId}, +${warranty.pendingAdditionalMonths}mo`);

    res.status(200).json({
      success: true,
      warrantyId,
      baseWarrantyMonths: warranty.baseWarrantyMonths,
      additionalWarrantyMonths: warranty.pendingAdditionalMonths,
      totalWarrantyMonths: warranty.baseWarrantyMonths + warranty.pendingAdditionalMonths,
      totalWarrantyEndDate: newEndDate.toISOString(),
      approvalResult,
    });
  } catch (error: any) {
    console.error("Additional warranty approve error:", error);
    res.status(500).json({
      error: "Failed to approve additional warranty payment",
      message: error.message,
    });
  }
});

// ============================================================================
// POST /warranty/payment/prepare - 보증 결제 준비
// ============================================================================

router.post("/payment/prepare", async (req, res) => {
  try {
    const data = req.body as WarrantyPaymentRequest;

    // 필수 필드 검증
    if (!data.qrCode || !data.warrantyPlan || !data.customerName || !data.customerPhone) {
      res.status(400).json({
        error: "Missing required fields",
        required: ["qrCode", "warrantyPlan", "customerName", "customerPhone", "paymentMethod"],
      });
      return;
    }

    // QR 코드로 거래 조회
    const transactionSnapshot = await db
      .collection("verification_transactions")
      .where("qrCode", "==", data.qrCode)
      .limit(1)
      .get();

    if (transactionSnapshot.empty) {
      res.status(404).json({error: "Transaction not found for the provided QR code"});
      return;
    }

    const transactionDoc = transactionSnapshot.docs[0];
    const transaction = transactionDoc.data() as VerificationTransaction;

    // 이미 보증이 등록된 경우 체크
    if (transaction.warrantyId) {
      res.status(400).json({
        error: "Warranty already registered",
        warrantyId: transaction.warrantyId,
      });
      return;
    }

    // 보증 요금 계산
    const rateConfig = WARRANTY_RATES[data.warrantyPlan];
    if (!rateConfig) {
      res.status(400).json({
        error: "Invalid warranty plan",
        validPlans: Object.keys(WARRANTY_RATES),
      });
      return;
    }

    const warrantyPrice = Math.round(transaction.salePrice * rateConfig.rate);
    const warrantyId = generateWarrantyId();
    const now = admin.firestore.Timestamp.now();

    // 보증 시작/종료일 계산
    const startDate = new Date();
    const baseWarrantyMonths = transaction.baseWarrantyMonths || 12;
    const baseWarrantyEndDate = new Date(startDate);
    baseWarrantyEndDate.setMonth(baseWarrantyEndDate.getMonth() + baseWarrantyMonths);

    // 총 보증 기간 (기본 + 추가)
    const totalWarrantyMonths = baseWarrantyMonths + rateConfig.months;
    const totalWarrantyEndDate = new Date(startDate);
    totalWarrantyEndDate.setMonth(totalWarrantyEndDate.getMonth() + totalWarrantyMonths);

    // 보증 문서 생성 (pending 상태)
    const warranty: Warranty = {
      warrantyId,
      transactionId: transaction.transactionId,
      qrCode: data.qrCode,

      // 기본 보증 (스코어 기반)
      baseWarrantyMonths,
      baseWarrantyEndDate: admin.firestore.Timestamp.fromDate(baseWarrantyEndDate),

      // 추가 보증 (고객 결제)
      additionalWarrantyMonths: rateConfig.months,
      additionalWarrantyPrice: warrantyPrice,

      // 최종 보증 정보
      totalWarrantyMonths,
      totalWarrantyEndDate: admin.firestore.Timestamp.fromDate(totalWarrantyEndDate),

      // 기존 필드 (호환성)
      warrantyPlan: data.warrantyPlan,
      warrantyPeriodMonths: rateConfig.months,
      startDate: admin.firestore.Timestamp.fromDate(startDate),
      endDate: admin.firestore.Timestamp.fromDate(totalWarrantyEndDate),

      warrantyPrice,
      warrantyRate: rateConfig.rate,
      paymentMethod: data.paymentMethod,

      customerName: data.customerName,
      customerPhone: data.customerPhone,
      customerEmail: data.customerEmail || null,

      status: "pending",
      serviceRequestIds: [],

      createdAt: now,
      updatedAt: now,
    };

    await db.collection("warranties").doc(warrantyId).set(warranty);

    // 결제 준비 (카카오페이 또는 토스페이)
    let paymentResult;

    if (data.paymentMethod === "kakaopay") {
      paymentResult = await prepareKakaoPay(warrantyId, transaction, warrantyPrice);
    } else if (data.paymentMethod === "tosspay") {
      paymentResult = await prepareTossPay(warrantyId, transaction, warrantyPrice);
    } else {
      res.status(400).json({
        error: "Invalid payment method",
        validMethods: ["kakaopay", "tosspay"],
      });
      return;
    }

    // 보증 문서에 결제 정보 업데이트
    const paymentKeyValue = "tid" in paymentResult ? paymentResult.tid : paymentResult.paymentKey;
    await db.collection("warranties").doc(warrantyId).update({
      paymentKey: paymentKeyValue,
      updatedAt: admin.firestore.Timestamp.now(),
    });

    console.log(`Warranty payment prepared: ${warrantyId}, price: ${warrantyPrice}`);

    res.status(200).json({
      success: true,
      warrantyId,
      transactionId: transaction.transactionId,
      warrantyPrice,
      warrantyPlan: data.warrantyPlan,
      ...paymentResult,
    });
  } catch (error: any) {
    console.error("Warranty payment prepare error:", error);
    res.status(500).json({
      error: "Failed to prepare payment",
      message: error.message,
    });
  }
});

// ============================================================================
// POST /warranty/payment/approve - 결제 승인
// ============================================================================

router.post("/payment/approve", async (req, res) => {
  try {
    const {warrantyId, pgToken, paymentKey, orderId, amount} = req.body;

    if (!warrantyId) {
      res.status(400).json({error: "Missing warrantyId"});
      return;
    }

    const warrantyDoc = await db.collection("warranties").doc(warrantyId).get();

    if (!warrantyDoc.exists) {
      res.status(404).json({error: "Warranty not found"});
      return;
    }

    const warranty = warrantyDoc.data() as Warranty;

    if (warranty.status !== "pending") {
      res.status(400).json({
        error: "Invalid warranty status",
        currentStatus: warranty.status,
      });
      return;
    }

    let approvalResult;

    // 결제 승인 처리
    if (warranty.paymentMethod === "kakaopay" && pgToken) {
      approvalResult = await approveKakaoPay(warranty, pgToken);
    } else if (warranty.paymentMethod === "tosspay" && paymentKey) {
      approvalResult = await approveTossPay(paymentKey, orderId, amount);
    } else {
      res.status(400).json({error: "Missing payment approval parameters"});
      return;
    }

    const now = admin.firestore.Timestamp.now();

    // 보증 활성화
    await db.collection("warranties").doc(warrantyId).update({
      status: "active",
      paidAt: now,
      updatedAt: now,
    });

    // 거래 문서 업데이트
    await db.collection("verification_transactions").doc(warranty.transactionId).update({
      warrantyId,
      status: "warrantyActive",
      updatedAt: now,
    });

    console.log(`Warranty activated: ${warrantyId}`);

    res.status(200).json({
      success: true,
      warrantyId,
      status: "active",
      approvalResult,
    });
  } catch (error: any) {
    console.error("Warranty payment approve error:", error);
    res.status(500).json({
      error: "Failed to approve payment",
      message: error.message,
    });
  }
});

// ============================================================================
// POST /warranty/payment/cancel - 결제 취소
// ============================================================================

router.post("/payment/cancel", async (req, res) => {
  try {
    const {warrantyId, reason} = req.body;

    if (!warrantyId) {
      res.status(400).json({error: "Missing warrantyId"});
      return;
    }

    const warrantyDoc = await db.collection("warranties").doc(warrantyId).get();

    if (!warrantyDoc.exists) {
      res.status(404).json({error: "Warranty not found"});
      return;
    }

    // 보증 상태 업데이트 (pending으로 되돌림)
    await db.collection("warranties").doc(warrantyId).update({
      status: "pending",
      cancelReason: reason || null,
      updatedAt: admin.firestore.Timestamp.now(),
    });

    console.log(`Warranty payment cancelled: ${warrantyId}, reason: ${reason || "not provided"}`);

    res.status(200).json({
      success: true,
      warrantyId,
      status: "pending",
    });
  } catch (error: any) {
    console.error("Warranty payment cancel error:", error);
    res.status(500).json({
      error: "Failed to cancel payment",
      message: error.message,
    });
  }
});

// ============================================================================
// GET /warranty/:warrantyId - 보증 조회
// ============================================================================

router.get("/:warrantyId", async (req, res) => {
  try {
    const {warrantyId} = req.params;

    if (!warrantyId) {
      res.status(400).json({error: "Missing warrantyId"});
      return;
    }

    const warrantyDoc = await db.collection("warranties").doc(warrantyId).get();

    if (!warrantyDoc.exists) {
      res.status(404).json({error: "Warranty not found"});
      return;
    }

    const warranty = warrantyDoc.data() as Warranty;

    // 관련 거래 정보도 함께 조회
    const transactionDoc = await db
      .collection("verification_transactions")
      .doc(warranty.transactionId)
      .get();

    const transaction = transactionDoc.exists
      ? transactionDoc.data() as VerificationTransaction
      : null;

    res.status(200).json({
      warranty,
      transaction: transaction ? {
        transactionType: transaction.transactionType,
        partCategory: transaction.partCategory,
        brand: transaction.brand,
        modelName: transaction.modelName,
        bundleName: transaction.bundleName,
        items: transaction.items?.map((item) => ({
          itemId: item.itemId,
          partCategory: item.partCategory,
          brand: item.brand,
          modelName: item.modelName,
          conditionScore: item.conditionScore,
          benchmarkScore: item.benchmarkScore,
        })),
        salePrice: transaction.salePrice,
        conditionScore: transaction.conditionScore,
        conditionGrade: transaction.conditionGrade,
        benchmarkScores: transaction.benchmarkScores,
        baseWarrantyMonths: transaction.baseWarrantyMonths,
        photoUrls: transaction.photoUrls,
      } : null,
    });
  } catch (error: any) {
    console.error("Warranty query error:", error);
    res.status(500).json({
      error: "Failed to query warranty",
      message: error.message,
    });
  }
});

// ============================================================================
// Helper Functions
// ============================================================================

async function prepareKakaoPay(
  warrantyId: string,
  transaction: VerificationTransaction,
  amount: number
): Promise<{tid: string; redirectUrl: string}> {
  const kakaoConfig = getKakaoPayConfig();

  if (!kakaoConfig.adminKey) {
    throw new Error("Kakao Admin Key not configured");
  }

  const itemName = `AS 보증 - ${transaction.brand} ${transaction.modelName}`;

  const response = await axios.post(
    `${KAKAO_PAY_API_URL}/ready`,
    {
      cid: kakaoConfig.cid,
      partner_order_id: warrantyId,
      partner_user_id: "warranty_customer",
      item_name: itemName,
      quantity: 1,
      total_amount: amount,
      tax_free_amount: 0,
      approval_url: `${WARRANTY_WEB_URL}/warranty/payment/callback?warrantyId=${warrantyId}&result=success`,
      cancel_url: `${WARRANTY_WEB_URL}/warranty/payment/callback?warrantyId=${warrantyId}&result=cancel`,
      fail_url: `${WARRANTY_WEB_URL}/warranty/payment/callback?warrantyId=${warrantyId}&result=fail`,
    },
    {
      headers: {
        "Authorization": `SECRET_KEY ${kakaoConfig.adminKey}`,
        "Content-Type": "application/json",
      },
    }
  );

  return {
    tid: response.data.tid,
    redirectUrl: response.data.next_redirect_mobile_url || response.data.next_redirect_pc_url,
  };
}

async function prepareTossPay(
  _warrantyId: string,
  transaction: VerificationTransaction,
  _amount: number
): Promise<{paymentKey: string; redirectUrl: string}> {
  // 토스페이먼츠는 클라이언트에서 SDK로 결제를 시작하므로
  // 서버에서는 결제 정보만 준비 (warrantyId, amount는 클라이언트에서 처리)
  console.log(`Preparing Toss payment for: ${transaction.brand} ${transaction.modelName}`);

  return {
    paymentKey: "", // 클라이언트에서 결제 후 받음
    redirectUrl: "", // SDK에서 처리
  };
}

async function approveKakaoPay(
  warranty: Warranty,
  pgToken: string
): Promise<any> {
  const kakaoConfig = getKakaoPayConfig();

  const response = await axios.post(
    `${KAKAO_PAY_API_URL}/approve`,
    {
      cid: kakaoConfig.cid,
      tid: warranty.paymentKey,
      partner_order_id: warranty.warrantyId,
      partner_user_id: "warranty_customer",
      pg_token: pgToken,
    },
    {
      headers: {
        "Authorization": `SECRET_KEY ${kakaoConfig.adminKey}`,
        "Content-Type": "application/json",
      },
    }
  );

  return response.data;
}

async function approveTossPay(
  paymentKey: string,
  orderId: string,
  amount: number
): Promise<any> {
  const tossConfig = getTossPaymentsConfig();
  const encodedKey = Buffer.from(`${tossConfig.secretKey}:`).toString("base64");

  const response = await axios.post(
    `${TOSS_PAYMENTS_API_URL}/confirm`,
    {
      paymentKey,
      orderId,
      amount,
    },
    {
      headers: {
        "Authorization": `Basic ${encodedKey}`,
        "Content-Type": "application/json",
      },
    }
  );

  return response.data;
}

// ============================================================================
// 추가 보증 결제 Helper Functions (v2)
// ============================================================================

async function prepareKakaoPayAdditional(
  warrantyId: string,
  transaction: VerificationTransaction,
  amount: number,
  additionalMonths: number
): Promise<{tid: string; redirectUrl: string}> {
  const kakaoConfig = getKakaoPayConfig();

  if (!kakaoConfig.adminKey) {
    throw new Error("Kakao Admin Key not configured");
  }

  const itemName = transaction.transactionType === "bundle"
    ? `추가 보증 +${additionalMonths}개월 - ${transaction.bundleName || "조립 PC"}`
    : `추가 보증 +${additionalMonths}개월 - ${transaction.brand} ${transaction.modelName}`;

  const response = await axios.post(
    `${KAKAO_PAY_API_URL}/ready`,
    {
      cid: kakaoConfig.cid,
      partner_order_id: `${warrantyId}-ADD`,
      partner_user_id: "warranty_customer",
      item_name: itemName,
      quantity: 1,
      total_amount: amount,
      tax_free_amount: 0,
      approval_url: `${WARRANTY_WEB_URL}/warranty/payment/callback?warrantyId=${warrantyId}&type=additional&result=success`,
      cancel_url: `${WARRANTY_WEB_URL}/warranty/payment/callback?warrantyId=${warrantyId}&type=additional&result=cancel`,
      fail_url: `${WARRANTY_WEB_URL}/warranty/payment/callback?warrantyId=${warrantyId}&type=additional&result=fail`,
    },
    {
      headers: {
        "Authorization": `SECRET_KEY ${kakaoConfig.adminKey}`,
        "Content-Type": "application/json",
      },
    }
  );

  return {
    tid: response.data.tid,
    redirectUrl: response.data.next_redirect_mobile_url || response.data.next_redirect_pc_url,
  };
}

async function prepareTossPayAdditional(
  _warrantyId: string,
  transaction: VerificationTransaction,
  _amount: number,
  additionalMonths: number
): Promise<{paymentKey: string; redirectUrl: string}> {
  const itemName = transaction.transactionType === "bundle"
    ? `추가 보증 +${additionalMonths}개월 - ${transaction.bundleName || "조립 PC"}`
    : `추가 보증 +${additionalMonths}개월 - ${transaction.brand} ${transaction.modelName}`;

  console.log(`Preparing Toss payment for additional warranty: ${itemName}`);

  return {
    paymentKey: "",
    redirectUrl: "",
  };
}

export default router;
