/**
 * Warranty Payment API
 * AS 보증 결제 처리
 */

import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import axios from "axios";
import {Router} from "express";
import {
  Warranty,
  VerificationTransaction,
  WarrantyPaymentRequest,
  WARRANTY_RATES,
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

const WARRANTY_WEB_URL = process.env.WARRANTY_WEB_URL || "https://warranty.picomputer.app";

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
    const endDate = new Date();
    endDate.setMonth(endDate.getMonth() + rateConfig.months);

    // 보증 문서 생성 (pending 상태)
    const warranty: Warranty = {
      warrantyId,
      transactionId: transaction.transactionId,
      qrCode: data.qrCode,

      warrantyPlan: data.warrantyPlan,
      warrantyPeriodMonths: rateConfig.months,
      startDate: admin.firestore.Timestamp.fromDate(startDate),
      endDate: admin.firestore.Timestamp.fromDate(endDate),

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
        partCategory: transaction.partCategory,
        brand: transaction.brand,
        modelName: transaction.modelName,
        salePrice: transaction.salePrice,
        conditionScore: transaction.conditionScore,
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

export default router;
