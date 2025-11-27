import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import axios from "axios";
import express from "express";
import cors from "cors";

admin.initializeApp();

// ============================================================================
// Schedulers Import
// ============================================================================
import {checkStorageNotifications} from "./schedulers/storage_scheduler";
import {checkSettlementNotifications} from "./schedulers/settlement_scheduler";
import {checkReturnAddressDeadline} from "./schedulers/return_address_scheduler";

// ============================================================================
// Refund Functions Import
// ============================================================================
import {
  processRefundCompletion,
  autoApproveRefundInspection,
  notifyPendingInspections,
} from "./refund/process_refund";
import {notifyRefundApprovalDeadline} from "./refund/approval_deadline_scheduler";

// Export schedulers
export {
  checkStorageNotifications,
  checkSettlementNotifications,
  checkReturnAddressDeadline,
};

// Export refund functions
export {
  processRefundCompletion,
  autoApproveRefundInspection,
  notifyPendingInspections,
  notifyRefundApprovalDeadline,
};

// Express 앱 생성
const app = express();
app.use(cors({origin: true}));
app.use(express.json());

// ============================================================================
// 카카오 로그인 Custom Token 생성
// ============================================================================

interface KakaoUserInfo {
  id: number;
  connected_at?: string;
  kakao_account?: {
    profile?: {
      nickname?: string;
      profile_image_url?: string;
    };
    email?: string;
  };
}

/**
 * 카카오 액세스 토큰으로 사용자 정보 조회
 */
async function getKakaoUserInfo(kakaoAccessToken: string): Promise<KakaoUserInfo> {
  const response = await axios.get<KakaoUserInfo>("https://kapi.kakao.com/v2/user/me", {
    headers: {
      Authorization: `Bearer ${kakaoAccessToken}`,
      "Content-Type": "application/x-www-form-urlencoded;charset=utf-8",
    },
  });
  return response.data;
}

/**
 * 카카오 로그인을 위한 Firebase Custom Token 생성
 * POST /auth/kakao
 */
app.post("/auth/kakao", async (req, res) => {
  try {
    console.log("🔍 [Kakao Auth] Request received");
    const {kakaoAccessToken} = req.body;

    if (!kakaoAccessToken) {
      console.error("❌ Missing kakaoAccessToken in request");
      res.status(400).json({
        error: "Missing required parameter",
        required: ["kakaoAccessToken"],
      });
      return;
    }

    console.log(`✅ Kakao access token received: ${kakaoAccessToken.substring(0, 20)}...`);

    // 카카오 사용자 정보 조회
    console.log("🔍 Fetching Kakao user info...");
    const kakaoUser = await getKakaoUserInfo(kakaoAccessToken);

    if (!kakaoUser || !kakaoUser.id) {
      console.error("❌ Invalid Kakao user info:", kakaoUser);
      res.status(401).json({
        error: "Invalid Kakao token",
        message: "Failed to get Kakao user info",
      });
      return;
    }

    console.log(`✅ Kakao user info: ID=${kakaoUser.id}, Email=${kakaoUser.kakao_account?.email}`);

    // 이메일 기반 계정 병합: 같은 이메일의 기존 사용자 찾기
    const email = kakaoUser.kakao_account?.email;
    let uid = `kakao_${kakaoUser.id}`;

    if (email) {
      console.log(`🔍 Checking for existing user with email: ${email}`);
      try {
        // Firebase Auth에서 이메일로 기존 사용자 검색
        const existingUser = await admin.auth().getUserByEmail(email);
        console.log(`✅ Found existing user: ${existingUser.uid} (provider: ${existingUser.providerData[0]?.providerId})`);

        // 기존 사용자의 UID 사용 (계정 병합)
        uid = existingUser.uid;
        console.log(`🔗 Merging accounts: Using existing UID=${uid}`);
      } catch (error: any) {
        if (error.code === "auth/user-not-found") {
          console.log(`ℹ️ No existing user with email ${email}, creating new user`);
        } else {
          console.error(`⚠️ Error checking existing user:`, error);
        }
      }
    }

    console.log(`🔍 Creating custom token for UID: ${uid}`);

    // Firebase Custom Token 생성
    const customToken = await admin.auth().createCustomToken(uid, {
      // Additional claims
      provider: "kakao",
      kakaoId: kakaoUser.id.toString(),
    });
    console.log(`✅ Custom token created: ${customToken.substring(0, 20)}...`);

    // Firestore에 사용자 정보 저장/업데이트
    console.log("🔍 Saving user to Firestore...");
    const userRef = admin.firestore().collection("users").doc(uid);
    const userDoc = await userRef.get();

    const userData = {
      email: kakaoUser.kakao_account?.email || `kakao_${kakaoUser.id}@kakao.user`,
      displayName: kakaoUser.kakao_account?.profile?.nickname || userDoc.data()?.displayName || "카카오 사용자",
      photoURL: kakaoUser.kakao_account?.profile?.profile_image_url || userDoc.data()?.photoURL || null,
      kakaoId: kakaoUser.id.toString(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      lastLoginAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    if (!userDoc.exists) {
      // 신규 사용자
      await userRef.set({
        uid,
        ...userData,
        provider: "kakao",
        providers: ["kakao"], // 여러 provider 지원
        isAdmin: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      console.log(`✅ New Kakao user created: ${uid}`);
    } else {
      // 기존 사용자 정보 업데이트 (provider 병합)
      const existingData = userDoc.data();
      const existingProviders = existingData?.providers || [existingData?.provider].filter(Boolean);

      await userRef.update({
        ...userData,
        providers: Array.from(new Set([...existingProviders, "kakao"])), // provider 추가
      });
      console.log(`✅ Kakao user updated (merged): ${uid}, providers: ${existingProviders.join(", ")} + kakao`);
    }

    console.log("✅ [Kakao Auth] Success");
    res.status(200).json({
      customToken,
      user: {
        uid,
        email: userData.email,
        displayName: userData.displayName,
        photoURL: userData.photoURL,
        provider: "kakao",
      },
    });
  } catch (error: any) {
    console.error("❌ [Kakao Auth] Error:", error);
    console.error("❌ Error details:", {
      message: error.message,
      stack: error.stack,
      response: error.response?.data,
      status: error.response?.status,
    });
    res.status(error.response?.status || 500).json({
      error: "Kakao authentication failed",
      message: error.message,
      details: error.response?.data || error.toString(),
      stack: error.stack,
    });
  }
});

// ============================================================================
// 타입 정의
// ============================================================================

interface ListingData {
  basePartId: string;
  status: string;
  price: number;
  [key: string]: any;
}

// 카카오페이 API 타입 정의
interface KakaoPayPrepareRequest {
  partner_order_id: string;
  partner_user_id: string;
  item_name: string;
  quantity: number;
  total_amount: number;
  tax_free_amount: number;
  approval_url: string;
  cancel_url: string;
  fail_url: string;
}

interface KakaoPayPrepareResponse {
  tid: string;
  next_redirect_app_url: string;
  next_redirect_mobile_url: string;
  next_redirect_pc_url: string;
  android_app_scheme?: string;
  ios_app_scheme?: string;
  created_at: string;
}

interface KakaoPayApproveRequest {
  tid: string;
  partner_order_id: string;
  partner_user_id: string;
  pg_token: string;
}

interface KakaoPayApproveResponse {
  aid: string;
  tid: string;
  cid: string;
  sid?: string;
  partner_order_id: string;
  partner_user_id: string;
  payment_method_type: string;
  amount: {
    total: number;
    tax_free: number;
    vat: number;
    point: number;
    discount: number;
    green_deposit?: number;
  };
  card_info?: {
    kakaopay_purchase_corp: string;
    kakaopay_purchase_corp_code: string;
    kakaopay_issuer_corp: string;
    kakaopay_issuer_corp_code: string;
    bin: string;
    card_type: string;
    install_month: string;
    approved_id: string;
    card_mid: string;
  };
  item_name: string;
  item_code?: string;
  quantity: number;
  created_at: string;
  approved_at: string;
  payload?: string;
}

interface KakaoCancelRequest {
  tid: string;
  cancel_amount: number;
  cancel_tax_free_amount: number;
}

// ============================================================================
// 카카오페이 API 상수 및 설정
// ============================================================================

const KAKAO_PAY_API_URL = "https://open-api.kakaopay.com/online/v1/payment";

// 환경변수에서 카카오페이 설정 가져오기
// Firebase Console에서 설정: firebase functions:config:set kakaopay.admin_key="YOUR_ADMIN_KEY" kakaopay.cid="YOUR_CID"
const getKakaoPayConfig = () => {
  const config = functions.config();
  return {
    adminKey: config.kakaopay?.admin_key || process.env.KAKAO_ADMIN_KEY || "",
    cid: config.kakaopay?.cid || process.env.KAKAO_CID || "TC0ONETIME", // 테스트용 CID
  };
};

// ============================================================================
// 카카오페이 결제 API (Express Routes)
// ============================================================================

/**
 * 결제 준비 API
 * POST /payment/prepare
 */
app.post("/payment/prepare", async (req, res) => {
  try {
      const {
        partner_order_id,
        partner_user_id,
        item_name,
        quantity,
        total_amount,
        tax_free_amount,
        approval_url,
        cancel_url,
        fail_url,
      } = req.body as KakaoPayPrepareRequest;

      // 필수 파라미터 검증
      if (!partner_order_id || !partner_user_id || !item_name || !total_amount) {
        res.status(400).json({
          error: "Missing required parameters",
          required: ["partner_order_id", "partner_user_id", "item_name", "total_amount"],
        });
        return;
      }

      const kakaoConfig = getKakaoPayConfig();

      if (!kakaoConfig.adminKey) {
        console.error("Kakao Admin Key not configured");
        res.status(500).json({
          error: "Payment service not configured",
          message: "Kakao Admin Key is missing. Please set it using: firebase functions:config:set kakaopay.admin_key=YOUR_KEY",
        });
        return;
      }

      // 카카오페이 결제 준비 API 호출
      const response = await axios.post<KakaoPayPrepareResponse>(
        `${KAKAO_PAY_API_URL}/ready`,
        {
          cid: kakaoConfig.cid,
          partner_order_id,
          partner_user_id,
          item_name,
          quantity: quantity || 1,
          total_amount,
          tax_free_amount: tax_free_amount || 0,
          approval_url,
          cancel_url,
          fail_url,
        },
        {
          headers: {
            "Authorization": `SECRET_KEY ${kakaoConfig.adminKey}`,
            "Content-Type": "application/json",
          },
        }
      );

      console.log("Payment prepared:", {
        tid: response.data.tid,
        partner_order_id,
        total_amount,
      });

      // Firestore에 결제 정보 저장
      await admin.firestore().collection("payments").doc(response.data.tid).set({
        tid: response.data.tid,
        partner_order_id,
        partner_user_id,
        item_name,
        quantity: quantity || 1,
        total_amount,
        tax_free_amount: tax_free_amount || 0,
        status: "ready",
        created_at: admin.firestore.FieldValue.serverTimestamp(),
      });

      res.status(200).json(response.data);
    } catch (error: any) {
      console.error("Payment prepare error:", error.response?.data || error.message);
      res.status(error.response?.status || 500).json({
        error: "Payment preparation failed",
        details: error.response?.data || error.message,
      });
    }
});

/**
 * 결제 승인 API
 * POST /payment/approve
 */
app.post("/payment/approve", async (req, res) => {
  try {
      const {
        tid,
        partner_order_id,
        partner_user_id,
        pg_token,
      } = req.body as KakaoPayApproveRequest;

      // 필수 파라미터 검증
      if (!tid || !partner_order_id || !partner_user_id || !pg_token) {
        res.status(400).json({
          error: "Missing required parameters",
          required: ["tid", "partner_order_id", "partner_user_id", "pg_token"],
        });
        return;
      }

      const kakaoConfig = getKakaoPayConfig();

      if (!kakaoConfig.adminKey) {
        res.status(500).json({error: "Payment service not configured"});
        return;
      }

      // 카카오페이 결제 승인 API 호출
      const response = await axios.post<KakaoPayApproveResponse>(
        `${KAKAO_PAY_API_URL}/approve`,
        {
          cid: kakaoConfig.cid,
          tid,
          partner_order_id,
          partner_user_id,
          pg_token,
        },
        {
          headers: {
            "Authorization": `SECRET_KEY ${kakaoConfig.adminKey}`,
            "Content-Type": "application/json",
          },
        }
      );

      console.log("Payment approved:", {
        tid: response.data.tid,
        partner_order_id,
        amount: response.data.amount.total,
      });

      // Firestore에 결제 승인 정보 업데이트
      await admin.firestore().collection("payments").doc(tid).update({
        status: "approved",
        approved_at: admin.firestore.FieldValue.serverTimestamp(),
        payment_method_type: response.data.payment_method_type,
        aid: response.data.aid,
        amount: response.data.amount,
        card_info: response.data.card_info || null,
      });

      res.status(200).json(response.data);
    } catch (error: any) {
      console.error("Payment approve error:", error.response?.data || error.message);
      res.status(error.response?.status || 500).json({
        error: "Payment approval failed",
        details: error.response?.data || error.message,
      });
    }
});

/**
 * 결제 취소 API
 * POST /payment/cancel
 */
app.post("/payment/cancel", async (req, res) => {
  try {
      const {
        tid,
        cancel_amount,
        cancel_tax_free_amount,
      } = req.body as KakaoCancelRequest;

      // 필수 파라미터 검증
      if (!tid || !cancel_amount) {
        res.status(400).json({
          error: "Missing required parameters",
          required: ["tid", "cancel_amount"],
        });
        return;
      }

      const kakaoConfig = getKakaoPayConfig();

      if (!kakaoConfig.adminKey) {
        res.status(500).json({error: "Payment service not configured"});
        return;
      }

      // 카카오페이 결제 취소 API 호출
      const response = await axios.post(
        `${KAKAO_PAY_API_URL}/cancel`,
        {
          cid: kakaoConfig.cid,
          tid,
          cancel_amount,
          cancel_tax_free_amount: cancel_tax_free_amount || 0,
        },
        {
          headers: {
            "Authorization": `SECRET_KEY ${kakaoConfig.adminKey}`,
            "Content-Type": "application/json",
          },
        }
      );

      console.log("Payment cancelled:", {
        tid,
        cancel_amount,
      });

      // Firestore에 결제 취소 정보 업데이트
      await admin.firestore().collection("payments").doc(tid).update({
        status: "cancelled",
        cancelled_at: admin.firestore.FieldValue.serverTimestamp(),
        cancel_amount,
        cancel_tax_free_amount: cancel_tax_free_amount || 0,
      });

      res.status(200).json(response.data);
    } catch (error: any) {
      console.error("Payment cancel error:", error.response?.data || error.message);
      res.status(error.response?.status || 500).json({
        error: "Payment cancellation failed",
        details: error.response?.data || error.message,
      });
    }
});

// ============================================================================
// 토스페이먼츠 API
// ============================================================================

const TOSS_PAYMENTS_API_URL = "https://api.tosspayments.com/v1/payments";

// 토스페이먼츠 설정 가져오기
// Firebase Console에서 설정: firebase functions:config:set tosspayments.secret_key="YOUR_SECRET_KEY"
const getTossPaymentsConfig = () => {
  const config = functions.config();
  return {
    // 테스트 시크릿 키 (실제 배포 시 환경변수로 교체)
    secretKey: config.tosspayments?.secret_key || process.env.TOSS_SECRET_KEY || "test_sk_zXLkKEypNArWmo50nX3lmeaxYG5R",
  };
};

// 토스페이먼츠 API 타입 정의
interface TossPaymentConfirmRequest {
  paymentKey: string;
  orderId: string;
  amount: number;
}

interface TossPaymentCancelRequest {
  paymentKey: string;
  cancelReason: string;
  cancelAmount?: number;
}

interface TossPaymentResponse {
  paymentKey: string;
  orderId: string;
  orderName: string;
  status: string;
  method: string;
  totalAmount: number;
  balanceAmount: number;
  suppliedAmount: number;
  vat: number;
  requestedAt: string;
  approvedAt?: string;
  card?: {
    issuerCode: string;
    acquirerCode: string;
    number: string;
    installmentPlanMonths: number;
    isInterestFree: boolean;
    approveNo: string;
    cardType: string;
    ownerType: string;
  };
  easyPay?: {
    provider: string;
    amount: number;
    discountAmount: number;
  };
  transfer?: {
    bankCode: string;
    settlementStatus: string;
  };
  virtualAccount?: {
    accountNumber: string;
    accountType: string;
    bankCode: string;
    customerName: string;
    dueDate: string;
    expired: boolean;
    settlementStatus: string;
  };
  mobilePhone?: {
    carrier: string;
    customerMobilePhone: string;
    settlementStatus: string;
  };
}

/**
 * 토스페이먼츠 결제 승인 API
 * POST /toss-payment/confirm
 */
app.post("/toss-payment/confirm", async (req, res) => {
  try {
    const {paymentKey, orderId, amount} = req.body as TossPaymentConfirmRequest;

    // 필수 파라미터 검증
    if (!paymentKey || !orderId || !amount) {
      res.status(400).json({
        error: "Missing required parameters",
        required: ["paymentKey", "orderId", "amount"],
      });
      return;
    }

    const tossConfig = getTossPaymentsConfig();

    if (!tossConfig.secretKey) {
      console.error("Toss Payments Secret Key not configured");
      res.status(500).json({
        error: "Payment service not configured",
        message: "Toss Secret Key is missing. Please set it using: firebase functions:config:set tosspayments.secret_key=YOUR_KEY",
      });
      return;
    }

    // Base64 인코딩된 시크릿 키 생성
    const encodedKey = Buffer.from(`${tossConfig.secretKey}:`).toString("base64");

    // 토스페이먼츠 결제 승인 API 호출
    const response = await axios.post<TossPaymentResponse>(
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

    console.log("Toss Payment confirmed:", {
      paymentKey: response.data.paymentKey,
      orderId: response.data.orderId,
      amount: response.data.totalAmount,
      method: response.data.method,
    });

    // Firestore에 결제 정보 저장
    await admin.firestore().collection("toss_payments").doc(paymentKey).set({
      paymentKey: response.data.paymentKey,
      orderId: response.data.orderId,
      orderName: response.data.orderName,
      status: response.data.status,
      method: response.data.method,
      totalAmount: response.data.totalAmount,
      balanceAmount: response.data.balanceAmount,
      suppliedAmount: response.data.suppliedAmount,
      vat: response.data.vat,
      requestedAt: response.data.requestedAt,
      approvedAt: response.data.approvedAt || null,
      card: response.data.card || null,
      easyPay: response.data.easyPay || null,
      transfer: response.data.transfer || null,
      virtualAccount: response.data.virtualAccount || null,
      mobilePhone: response.data.mobilePhone || null,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    res.status(200).json(response.data);
  } catch (error: any) {
    console.error("Toss Payment confirm error:", error.response?.data || error.message);
    res.status(error.response?.status || 500).json({
      error: "Payment confirmation failed",
      code: error.response?.data?.code || "UNKNOWN_ERROR",
      message: error.response?.data?.message || error.message,
    });
  }
});

/**
 * 토스페이먼츠 결제 취소 API
 * POST /toss-payment/cancel
 */
app.post("/toss-payment/cancel", async (req, res) => {
  try {
    const {paymentKey, cancelReason, cancelAmount} = req.body as TossPaymentCancelRequest;

    // 필수 파라미터 검증
    if (!paymentKey || !cancelReason) {
      res.status(400).json({
        error: "Missing required parameters",
        required: ["paymentKey", "cancelReason"],
      });
      return;
    }

    const tossConfig = getTossPaymentsConfig();

    if (!tossConfig.secretKey) {
      res.status(500).json({error: "Payment service not configured"});
      return;
    }

    const encodedKey = Buffer.from(`${tossConfig.secretKey}:`).toString("base64");

    // 취소 요청 데이터
    const cancelData: {cancelReason: string; cancelAmount?: number} = {cancelReason};
    if (cancelAmount) {
      cancelData.cancelAmount = cancelAmount;
    }

    // 토스페이먼츠 결제 취소 API 호출
    const response = await axios.post(
      `${TOSS_PAYMENTS_API_URL}/${paymentKey}/cancel`,
      cancelData,
      {
        headers: {
          "Authorization": `Basic ${encodedKey}`,
          "Content-Type": "application/json",
        },
      }
    );

    console.log("Toss Payment cancelled:", {
      paymentKey,
      cancelReason,
      cancelAmount,
    });

    // Firestore에 취소 정보 업데이트
    await admin.firestore().collection("toss_payments").doc(paymentKey).update({
      status: "CANCELED",
      cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
      cancelReason,
      cancelAmount: cancelAmount || null,
    });

    res.status(200).json(response.data);
  } catch (error: any) {
    console.error("Toss Payment cancel error:", error.response?.data || error.message);
    res.status(error.response?.status || 500).json({
      error: "Payment cancellation failed",
      code: error.response?.data?.code || "UNKNOWN_ERROR",
      message: error.response?.data?.message || error.message,
    });
  }
});

/**
 * 토스페이먼츠 결제 조회 API
 * GET /toss-payment/:paymentKey
 */
app.get("/toss-payment/:paymentKey", async (req, res) => {
  try {
    const {paymentKey} = req.params;

    if (!paymentKey) {
      res.status(400).json({error: "Missing paymentKey"});
      return;
    }

    const tossConfig = getTossPaymentsConfig();
    const encodedKey = Buffer.from(`${tossConfig.secretKey}:`).toString("base64");

    const response = await axios.get<TossPaymentResponse>(
      `${TOSS_PAYMENTS_API_URL}/${paymentKey}`,
      {
        headers: {
          "Authorization": `Basic ${encodedKey}`,
        },
      }
    );

    res.status(200).json(response.data);
  } catch (error: any) {
    console.error("Toss Payment query error:", error.response?.data || error.message);
    res.status(error.response?.status || 500).json({
      error: "Payment query failed",
      code: error.response?.data?.code || "UNKNOWN_ERROR",
      message: error.response?.data?.message || error.message,
    });
  }
});

/**
 * 토스페이먼츠 결제 리다이렉트 - 성공
 * GET /toss-payment-redirect/success
 */
app.get("/toss-payment-redirect/success", (req, res) => {
  const {paymentKey, orderId, amount} = req.query;
  // 앱으로 리다이렉트
  res.redirect(`picom://toss-payment/success?paymentKey=${paymentKey}&orderId=${orderId}&amount=${amount}`);
});

/**
 * 토스페이먼츠 결제 리다이렉트 - 실패
 * GET /toss-payment-redirect/fail
 */
app.get("/toss-payment-redirect/fail", (req, res) => {
  const {code, message, orderId} = req.query;
  res.redirect(`picom://toss-payment/fail?code=${code}&message=${encodeURIComponent(String(message || ""))}&orderId=${orderId}`);
});

// Express 앱을 Firebase Function으로 export
export const api = functions.region("asia-northeast3").https.onRequest(app);

// ============================================================================
// 기존 Functions
// ============================================================================

interface BasePartStats {
  lowestPrice: number;
  averagePrice: number;
  listingCount: number;
}

interface PriceAlertData {
  userId: string;
  basePartId: string;
  partName: string;
  targetPrice: number;
  isActive: boolean;
  triggeredAt?: admin.firestore.Timestamp;
  lastCheckedAt?: admin.firestore.Timestamp;
}

interface DragonBallData {
  userId: string;
  partName: string;
  expiresAt: admin.firestore.Timestamp;
  status: string;
  [key: string]: any;
}

function generateCpuKeywords(part: Record<string, any>): string[] {
  const keywords = new Set<string>();
  if (part.basePartId) {
    part.basePartId.split("-").forEach((k: string) => keywords.add(k.toLowerCase()));
  }
  if (part.brand) keywords.add(part.brand.toLowerCase());
  if (part.modelName) {
    part.modelName.split(/\s+/).forEach((k: string) => keywords.add(k.toLowerCase()));
  }
  if (part.generation) keywords.add(part.generation.toLowerCase());
  if (part.codename) keywords.add(part.codename.toLowerCase());
  if (part.cores) keywords.add(`${part.cores}코어`);
  if (part.socket) keywords.add(part.socket.toLowerCase());
  return Array.from(keywords);
}

function generateGpuKeywords(part: Record<string, any>): string[] {
  const keywords = new Set<string>();
  if (part.basePartId) {
    part.basePartId.split("-").forEach((k: string) => keywords.add(k.toLowerCase()));
  }
  if (part.brand) keywords.add(part.brand.toLowerCase());
  if (part.modelName) {
    part.modelName.split(/\s+/).forEach((k: string) => keywords.add(k.toLowerCase()));
  }
  if (part.chipset?.model) keywords.add(part.chipset.model.toLowerCase());
  if (part.chipset?.series) keywords.add(part.chipset.series.toLowerCase());
  if (part.chipset?.vendor) keywords.add(part.chipset.vendor.toLowerCase());
  if (part.memory?.sizeGb) keywords.add(`${part.memory.sizeGb}gb`);
  return Array.from(keywords);
}

function generateMainboardKeywords(part: Record<string, any>): string[] {
  const keywords = new Set<string>();
  if (part.basePartId) {
    part.basePartId.split("-").forEach((k: string) => keywords.add(k.toLowerCase()));
  }
  if (part.brand) keywords.add(part.brand.toLowerCase());
  if (part.modelName) {
    part.modelName.split(/\s+/).forEach((k: string) => keywords.add(k.toLowerCase()));
  }
  if (part.chipset) keywords.add(part.chipset.toLowerCase());
  if (part.socket) keywords.add(part.socket.toLowerCase());
  if (part.formFactor) keywords.add(part.formFactor.toLowerCase());
  if (part.platform) keywords.add(part.platform.toLowerCase());
  return Array.from(keywords);
}

function generateSimpleKeywords(part: Record<string, any>): string[] {
  const keywords = new Set<string>();
  if (part.basePartId) {
    part.basePartId.split("-").forEach((k: string) => keywords.add(k.toLowerCase()));
  }
  if (part.brand) keywords.add(part.brand.toLowerCase());
  if (part.modelName) {
    part.modelName.split(/\s+/).forEach((k: string) => keywords.add(k.toLowerCase()));
  }
  const category = part.category?.toLowerCase();
  if (category === "ram") {
    if (part.capacity) keywords.add(`${part.capacity}gb`);
    if (part.memoryType) keywords.add(part.memoryType.toLowerCase());
  } else if (category === "ssd") {
    if (part.capacity) {
      keywords.add(`${part.capacity}gb`);
      if (part.capacity >= 1000) {
        keywords.add(`${Math.floor(part.capacity / 1000)}tb`);
      }
    }
  } else if (category === "psu") {
    if (part.wattage) keywords.add(`${part.wattage}w`);
  }
  return Array.from(keywords);
}

function generateSearchKeywords(part: Record<string, any>): string[] {
  const category = part.category?.toLowerCase();
  switch (category) {
    case "cpu": return generateCpuKeywords(part);
    case "gpu": return generateGpuKeywords(part);
    case "mainboard": return generateMainboardKeywords(part);
    case "ram":
    case "ssd":
    case "psu": return generateSimpleKeywords(part);
    default: return generateSimpleKeywords(part);
  }
}

export const addSearchKeywordsToParts = functions.region("asia-northeast3").https.onCall(async (data: any) => {
  const {startAfter, batchSize = 500} = data;
  try {
    let query = admin.firestore().collection("parts").orderBy("partId").limit(batchSize);
    if (startAfter) query = query.startAfter(startAfter);
    const snapshot = await query.get();
    if (snapshot.empty) {
      return {success: true, updatedCount: 0, hasMore: false, message: "더 이상 업데이트할 Part가 없습니다."};
    }
    const batch = admin.firestore().batch();
    let updatedCount = 0;
    snapshot.docs.forEach((doc) => {
      const partData = doc.data();
      const searchKeywords = generateSearchKeywords(partData);
      batch.update(doc.ref, {searchKeywords});
      updatedCount++;
    });
    await batch.commit();
    const lastDoc = snapshot.docs[snapshot.docs.length - 1];
    const lastPartId = lastDoc.data().partId;
    return {success: true, updatedCount, hasMore: snapshot.docs.length === batchSize, lastPartId, message: `${updatedCount}개 Part에 searchKeywords 추가 완료`};
  } catch (error: any) {
    console.error("Error:", error);
    throw new functions.https.HttpsError("internal", error.message);
  }
});

export const searchParts = functions.region("asia-northeast3").https.onCall(async (data: any) => {
  const {category, query} = data;
  if (!category || !query) {
    throw new functions.https.HttpsError("invalid-argument", "category and query required");
  }
  const lowerQuery = query.toLowerCase().trim();
  const lowerCategory = category.toLowerCase().trim(); // ✅ 카테고리 정규화

  // base_parts 컬렉션에서 검색 (parts 사용 중단)
  // searchKeywords가 없으므로 전체 조회 후 클라이언트 필터링
  // ✅ SellRequest 생성 시 매물이 없는 부품도 선택 가능해야 하므로 listingCount 조건 제거
  const snapshot = await admin.firestore()
    .collection("base_parts")
    .limit(500)
    .get();

  // 클라이언트 측 필터링: category(대소문자 무시) + modelName/brand 검색
  const results = snapshot.docs
    .map((doc) => ({
      basePartId: doc.id,
      partId: doc.id, // 호환성을 위해 partId도 포함
      ...doc.data(),
    }))
    .filter((part: any) => {
      const partCategory = (part.category || "").toLowerCase();
      const modelName = (part.modelName || "").toLowerCase();
      const brand = (part.brand || "").toLowerCase();

      // ✅ 카테고리 매칭 (대소문자 무시) + 검색어 매칭
      return partCategory === lowerCategory &&
             (modelName.includes(lowerQuery) || brand.includes(lowerQuery));
    })
    .slice(0, 50); // 상위 50개만

  // 🔍 디버그: 검색 결과 확인
  if (results.length > 0) {
    console.log("🔍 searchParts 첫 번째 결과:", JSON.stringify(results[0]));
  }

  return results;
});

export const onPartCreated = functions.region("asia-northeast3").firestore.document("parts/{partId}").onCreate(async (snap: admin.firestore.QueryDocumentSnapshot) => {
  const partData = snap.data();
  const searchKeywords = generateSearchKeywords(partData);
  return snap.ref.update({searchKeywords});
});

// ============================================================================
// A. BasePart listingCount 자동 업데이트
// ============================================================================

/**
 * BasePart의 통계 재계산 함수
 * active listings만 대상으로 lowestPrice, averagePrice, listingCount 업데이트
 * 가격 변경 감지 시 PriceHistory에 새 포인트 추가
 */
async function recalculateBasePartStats(basePartId: string): Promise<void> {
  const db = admin.firestore();

  // 이전 BasePart 정보 조회 (가격 변경 감지용)
  const basePartRef = db.collection("base_parts").doc(basePartId);
  const basePartDoc = await basePartRef.get();
  const previousStats = basePartDoc.exists ? basePartDoc.data() : null;

  // active listings만 조회
  const activeListingsSnapshot = await db
    .collection("listings")
    .where("basePartId", "==", basePartId)
    .where("status", "==", "available")
    .get();

  if (activeListingsSnapshot.empty) {
    // active listings가 없으면 0으로 설정
    const newStats = {
      lowestPrice: 0,
      averagePrice: 0,
      listingCount: 0,
    };

    await basePartRef.set(newStats, {merge: true});
    console.log(`BasePart ${basePartId}: No active listings, stats reset to 0`);

    // 가격 변경 감지 및 PriceHistory 추가
    if (previousStats && (
      previousStats.lowestPrice !== newStats.lowestPrice ||
      previousStats.averagePrice !== newStats.averagePrice ||
      previousStats.listingCount !== newStats.listingCount
    )) {
      await addPriceHistoryPoint(basePartId, newStats, previousStats);
    }

    return;
  }

  // 가격 통계 계산 및 첫 번째 listing에서 기본 정보 가져오기
  const firstListing = activeListingsSnapshot.docs[0].data() as ListingData;
  const prices = activeListingsSnapshot.docs.map((doc) => {
    const data = doc.data() as ListingData;
    return data.price;
  });

  const lowestPrice = Math.min(...prices);
  const averagePrice = prices.reduce((sum, p) => sum + p, 0) / prices.length;
  const listingCount = prices.length;

  const stats: BasePartStats = {
    lowestPrice,
    averagePrice: Math.round(averagePrice * 100) / 100, // 소수점 2자리
    listingCount,
  };

  // BasePart 문서 생성/업데이트 (merge: true로 문서가 없으면 생성)
  const updateData: {[key: string]: any} = {
    basePartId: basePartId,
    modelName: firstListing.modelName || "",
    category: firstListing.category || "",
    brand: firstListing.brand || "",
    lowestPrice: stats.lowestPrice,
    averagePrice: stats.averagePrice,
    listingCount: stats.listingCount,
  };
  await basePartRef.set(updateData, {merge: true});

  console.log(`BasePart ${basePartId} stats updated:`, stats, `brand: ${updateData.brand}`);

  // 가격 변경 감지 및 PriceHistory 추가
  if (!previousStats || (
    previousStats.lowestPrice !== stats.lowestPrice ||
    previousStats.averagePrice !== stats.averagePrice ||
    previousStats.listingCount !== stats.listingCount
  )) {
    await addPriceHistoryPoint(basePartId, stats, previousStats);
  }
}

/**
 * PriceHistory에 새로운 가격 포인트 추가
 */
async function addPriceHistoryPoint(
  basePartId: string,
  newStats: BasePartStats,
  previousStats: any
): Promise<void> {
  const db = admin.firestore();
  const now = admin.firestore.Timestamp.now();

  // 고유 ID 생성 (basePartId + timestamp)
  const docId = `${basePartId}_${now.toMillis()}`;

  const priceHistoryData = {
    basePartId,
    timestamp: now,
    lowestPrice: newStats.lowestPrice,
    averagePrice: newStats.averagePrice,
    listingCount: newStats.listingCount,
    createdAt: now,
    // 변경 내역 기록 (디버깅용)
    previousLowestPrice: previousStats?.lowestPrice ?? null,
    previousAveragePrice: previousStats?.averagePrice ?? null,
    previousListingCount: previousStats?.listingCount ?? null,
  };

  await db.collection("priceHistory").doc(docId).set(priceHistoryData);

  console.log(`PriceHistory added for ${basePartId}:`, {
    lowestPrice: `${previousStats?.lowestPrice ?? 'N/A'} → ${newStats.lowestPrice}`,
    averagePrice: `${previousStats?.averagePrice ?? 'N/A'} → ${newStats.averagePrice}`,
    listingCount: `${previousStats?.listingCount ?? 'N/A'} → ${newStats.listingCount}`,
  });
}

/**
 * Listing 생성 시 트리거
 */
export const onListingCreated = functions
  .region("asia-northeast3")
  .firestore.document("listings/{listingId}")
  .onCreate(async (snap: admin.firestore.QueryDocumentSnapshot) => {
    const data = snap.data() as ListingData;
    if (data.basePartId && data.status === "available") {
      await recalculateBasePartStats(data.basePartId);
    }
  });

/**
 * Listing 업데이트 시 트리거 (상태 변경 감지)
 */
export const onListingUpdated = functions
  .region("asia-northeast3")
  .firestore.document("listings/{listingId}")
  .onUpdate(async (change: functions.Change<functions.firestore.QueryDocumentSnapshot>) => {
    const before = change.before.data() as ListingData;
    const after = change.after.data() as ListingData;

    // status가 변경된 경우에만 재계산
    if (before.status !== after.status && after.basePartId) {
      await recalculateBasePartStats(after.basePartId);
    }

    // price가 변경된 경우에도 재계산 (available 상태일 때만)
    if (before.price !== after.price && after.status === "available" && after.basePartId) {
      await recalculateBasePartStats(after.basePartId);
    }
  });

/**
 * Listing 삭제 시 트리거
 */
export const onListingDeleted = functions
  .region("asia-northeast3")
  .firestore.document("listings/{listingId}")
  .onDelete(async (snap: admin.firestore.QueryDocumentSnapshot) => {
    const data = snap.data() as ListingData;
    if (data.basePartId) {
      await recalculateBasePartStats(data.basePartId);
    }
  });

// ============================================================================
// B. 가격 알림 자동화
// ============================================================================

/**
 * 매일 오전 10시에 실행되는 가격 알림 체크 스케줄러
 * 활성화된 알림 중 목표가에 도달한 경우 알림 발송
 */
export const checkPriceAlerts = functions
  .region("asia-northeast3")
  .pubsub.schedule("0 10 * * *") // 매일 오전 10시
  .timeZone("Asia/Seoul")
  .onRun(async () => {
    const db = admin.firestore();
    const now = admin.firestore.Timestamp.now();

    console.log("Price alert check started at", now.toDate());

    // 활성화된 알림 조회
    const alertsSnapshot = await db
      .collection("priceAlerts")
      .where("isActive", "==", true)
      .where("triggeredAt", "==", null)
      .get();

    if (alertsSnapshot.empty) {
      console.log("No active price alerts to check");
      return;
    }

    console.log(`Found ${alertsSnapshot.size} active price alerts`);

    const batch = db.batch();
    let triggeredCount = 0;

    for (const alertDoc of alertsSnapshot.docs) {
      const alert = alertDoc.data() as PriceAlertData;

      // BasePart의 현재 최저가 조회
      const basePartDoc = await db.collection("base_parts").doc(alert.basePartId).get();

      if (!basePartDoc.exists) {
        console.log(`BasePart ${alert.basePartId} not found for alert ${alertDoc.id}`);
        continue;
      }

      const basePart = basePartDoc.data();
      const currentLowestPrice = basePart?.lowestPrice || 0;

      // lastCheckedAt 업데이트
      batch.update(alertDoc.ref, {lastCheckedAt: now});

      // 목표가 도달 여부 확인
      if (currentLowestPrice > 0 && currentLowestPrice <= alert.targetPrice) {
        // 알림 발송 (FCM 사용)
        try {
          // 사용자의 FCM 토큰 조회
          const userDoc = await db.collection("users").doc(alert.userId).get();
          const userData = userDoc.data();
          const fcmToken = userData?.fcmToken;

          if (fcmToken) {
            const message = {
              token: fcmToken,
              notification: {
                title: "🎉 가격 알림!",
                body: `${alert.partName}이(가) 목표가 ${alert.targetPrice.toLocaleString()}원에 도달했습니다! (현재 최저가: ${currentLowestPrice.toLocaleString()}원)`,
              },
              data: {
                type: "price_alert",
                basePartId: alert.basePartId,
                alertId: alertDoc.id,
                currentPrice: currentLowestPrice.toString(),
                targetPrice: alert.targetPrice.toString(),
              },
            };

            await admin.messaging().send(message);
            console.log(`Price alert notification sent to user ${alert.userId} for ${alert.partName}`);
          } else {
            console.log(`No FCM token for user ${alert.userId}`);
          }

          // 알림 트리거 상태 업데이트
          batch.update(alertDoc.ref, {
            triggeredAt: now,
            isActive: false, // 알림 발송 후 비활성화
          });

          triggeredCount++;
        } catch (error) {
          console.error(`Failed to send notification for alert ${alertDoc.id}:`, error);
        }
      }
    }

    await batch.commit();
    console.log(`Price alert check completed. ${triggeredCount} alerts triggered out of ${alertsSnapshot.size}`);
  });

// ============================================================================
// C. 드래곤볼 만료 알림 자동화
// ============================================================================

/**
 * 매일 오전 9시에 실행되는 드래곤볼 만료 체크 스케줄러
 * 1. 만료 3일 전 알림 발송
 * 2. 만료된 드래곤볼 자동 배송 처리 (status: stored인 경우)
 */
export const checkDragonBallExpiry = functions
  .region("asia-northeast3")
  .pubsub.schedule("0 9 * * *") // 매일 오전 9시
  .timeZone("Asia/Seoul")
  .onRun(async () => {
    const db = admin.firestore();
    const now = new Date();

    console.log("DragonBall expiry check started at", now);

    // 1. 만료 3일 전 알림 발송
    const threeDaysLater = new Date(now);
    threeDaysLater.setDate(threeDaysLater.getDate() + 3);
    threeDaysLater.setHours(23, 59, 59, 999);

    const threeDaysEarlier = new Date(now);
    threeDaysEarlier.setDate(threeDaysEarlier.getDate() + 3);
    threeDaysEarlier.setHours(0, 0, 0, 0);

    // 만료 3일 전인 드래곤볼 조회 (stored 상태만)
    const expiringSoonSnapshot = await db
      .collectionGroup("dragonBalls")
      .where("status", "==", "stored")
      .where("expiresAt", ">=", admin.firestore.Timestamp.fromDate(threeDaysEarlier))
      .where("expiresAt", "<=", admin.firestore.Timestamp.fromDate(threeDaysLater))
      .get();

    console.log(`Found ${expiringSoonSnapshot.size} DragonBalls expiring in 3 days`);

    for (const dragonBallDoc of expiringSoonSnapshot.docs) {
      const dragonBall = dragonBallDoc.data() as DragonBallData;

      try {
        // 사용자의 FCM 토큰 조회
        const userDoc = await db.collection("users").doc(dragonBall.userId).get();
        const userData = userDoc.data();
        const fcmToken = userData?.fcmToken;

        if (fcmToken) {
          const message = {
            token: fcmToken,
            notification: {
              title: "⚠️ 드래곤볼 만료 임박",
              body: `${dragonBall.partName}의 보관 기간이 3일 후 만료됩니다. 일괄 배송을 신청해주세요!`,
            },
            data: {
              type: "dragonball_expiring",
              dragonBallId: dragonBallDoc.id,
              userId: dragonBall.userId,
              expiresAt: dragonBall.expiresAt.toDate().toISOString(),
            },
          };

          await admin.messaging().send(message);
          console.log(`Expiry warning sent for DragonBall ${dragonBallDoc.id} (user: ${dragonBall.userId})`);
        }
      } catch (error) {
        console.error(`Failed to send expiry warning for DragonBall ${dragonBallDoc.id}:`, error);
      }
    }

    // 2. 만료된 드래곤볼 처리
    const expiredSnapshot = await db
      .collectionGroup("dragonBalls")
      .where("status", "==", "stored")
      .where("expiresAt", "<=", admin.firestore.Timestamp.now())
      .get();

    console.log(`Found ${expiredSnapshot.size} expired DragonBalls`);

    const batch = db.batch();
    let processedCount = 0;

    for (const dragonBallDoc of expiredSnapshot.docs) {
      const dragonBall = dragonBallDoc.data() as DragonBallData;

      try {
        // 만료 알림 발송
        const userDoc = await db.collection("users").doc(dragonBall.userId).get();
        const userData = userDoc.data();
        const fcmToken = userData?.fcmToken;

        if (fcmToken) {
          const message = {
            token: fcmToken,
            notification: {
              title: "📦 드래곤볼 자동 배송",
              body: `${dragonBall.partName}의 보관 기간이 만료되어 기본 배송지로 자동 배송 처리되었습니다.`,
            },
            data: {
              type: "dragonball_auto_shipped",
              dragonBallId: dragonBallDoc.id,
              userId: dragonBall.userId,
            },
          };

          await admin.messaging().send(message);
        }

        // DragonBall 상태를 packing으로 변경
        batch.update(dragonBallDoc.ref, {
          status: "packing",
          shippedAt: admin.firestore.Timestamp.now(),
        });

        processedCount++;
        console.log(`DragonBall ${dragonBallDoc.id} auto-shipped (user: ${dragonBall.userId})`);
      } catch (error) {
        console.error(`Failed to auto-ship DragonBall ${dragonBallDoc.id}:`, error);
      }
    }

    if (processedCount > 0) {
      await batch.commit();
    }

    console.log(
      `DragonBall expiry check completed. ` +
      `${expiringSoonSnapshot.size} warnings sent, ${processedCount} auto-shipped`
    );
  });
