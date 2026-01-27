/**
 * Warranty Transaction API v2
 * B2B 거래 등록 및 QR 코드 관리
 *
 * v2 변경사항:
 * - 풀세트(조립PC) 지원
 * - 벤치마크 기반 스코어 자동 산정
 * - 스코어 기반 기본 AS 기간 자동 결정
 * - 원가 관리 (purchaseCost)
 */

import * as admin from "firebase-admin";
import {Router} from "express";
import {
  VerificationTransaction,
  CreateTransactionRequest,
  CreateTransactionResponse,
  TransactionStatus,
  TransactionItem,
  generateTransactionId,
  generateQRCode,
} from "./types";
import {
  calculateFromBenchmarks,
  calculateFromBundle,
  calculateSinglePartScore,
  calculateProfitMargin,
} from "./score-calculator";
import {generateQrPngBuffer} from "./qr-utils";
import {generateWarrantyCertificatePDF} from "./report-generator";
import { v4 as uuidv4 } from "uuid";

const router = Router();
const db = admin.firestore();

// ============================================================================
// POST /warranty/transaction - B2B 거래 등록 (v2)
// 단일 부품 및 풀세트(조립PC) 모두 지원
// ============================================================================

router.post("/transaction", async (req, res) => {
  try {
    const data = req.body as CreateTransactionRequest;

    // 거래 타입 기본값
    const transactionType = data.transactionType || "single";

    // 필수 필드 검증
    if (!data.inspectorId || !data.inspectorName) {
      res.status(400).json({
        error: "Missing inspector information",
        required: ["inspectorId", "inspectorName"],
      });
      return;
    }

    if (data.salePrice === undefined || data.salePrice <= 0) {
      res.status(400).json({
        error: "salePrice is required and must be positive",
      });
      return;
    }

    if (data.purchaseCost === undefined || data.purchaseCost < 0) {
      res.status(400).json({
        error: "purchaseCost is required and must be non-negative",
      });
      return;
    }

    // 거래 타입별 검증
    if (transactionType === "single") {
      if (!data.partCategory || !data.brand || !data.modelName) {
        res.status(400).json({
          error: "Missing required fields for single part",
          required: ["partCategory", "brand", "modelName"],
        });
        return;
      }
    } else if (transactionType === "bundle") {
      if (!data.items || data.items.length === 0) {
        res.status(400).json({
          error: "Bundle must have at least one item",
          required: ["items"],
        });
        return;
      }
    }

    const now = admin.firestore.Timestamp.now();
    const transactionId = generateTransactionId();
    const qrCode = generateQRCode();

    // 스코어 계산
    let scoreResult;

    if (transactionType === "bundle" && data.items) {
      // 풀세트: 부품들의 스코어로 계산
      const items: TransactionItem[] = data.items.map((item) => ({
        itemId: uuidv4(),
        partCategory: item.partCategory,
        brand: item.brand,
        modelName: item.modelName,
        serialNumber: item.serialNumber || null,
        benchmarkScore: item.benchmarkScore,
        conditionScore: item.benchmarkScore
          ? calculateSinglePartScore(item.partCategory, item.benchmarkScore).conditionScore
          : 70, // 기본값
        purchaseCost: item.purchaseCost,
        photoUrls: item.photoUrls || [],
      }));

      scoreResult = calculateFromBundle(items, data.benchmarkScores);
    } else {
      // 단일 부품: 벤치마크 또는 수동 스코어로 계산
      if (data.benchmarkScores && Object.keys(data.benchmarkScores).length > 0) {
        scoreResult = calculateFromBenchmarks(data.benchmarkScores);
      } else if (data.benchmarkScore) {
        scoreResult = calculateSinglePartScore(
          data.partCategory || "",
          data.benchmarkScore
        );
      } else {
        // 기본값
        scoreResult = calculateSinglePartScore(data.partCategory || "", undefined, 70);
      }
    }

    // 마진율 계산
    const profitMargin = calculateProfitMargin(data.purchaseCost, data.salePrice);

    // 풀세트 아이템 처리
    let items: TransactionItem[] | undefined;
    if (transactionType === "bundle" && data.items) {
      items = data.items.map((item) => ({
        itemId: uuidv4(),
        partCategory: item.partCategory,
        brand: item.brand,
        modelName: item.modelName,
        serialNumber: item.serialNumber || null,
        benchmarkScore: item.benchmarkScore,
        conditionScore: item.benchmarkScore
          ? calculateSinglePartScore(item.partCategory, item.benchmarkScore).conditionScore
          : 70,
        purchaseCost: item.purchaseCost,
        photoUrls: item.photoUrls || [],
      }));
    }

    const transaction: VerificationTransaction = {
      transactionId,
      qrCode,

      // 거래 타입
      transactionType,

      // 단일 부품 정보 (풀세트면 null)
      partCategory: transactionType === "single" ? data.partCategory || null : null,
      brand: transactionType === "single" ? data.brand || null : null,
      modelName: transactionType === "single" ? data.modelName || null : null,
      serialNumber: transactionType === "single" ? data.serialNumber || null : null,
      photoUrls: data.photoUrls || [],

      // 풀세트 정보
      items: items,
      bundleName: transactionType === "bundle" ? data.bundleName || null : null,

      // 검수 정보
      inspectorId: data.inspectorId,
      inspectorName: data.inspectorName,
      inspectedAt: now,
      inspectionNote: data.inspectionNote || "",
      inspectionPhotoUrls: data.inspectionPhotoUrls || [],

      // 벤치마크 기반 스코어
      benchmarkScores: scoreResult.benchmarkScores,
      conditionGrade: scoreResult.conditionGrade,
      conditionScore: scoreResult.conditionScore,

      // 가격 정보
      purchaseCost: data.purchaseCost,
      salePrice: data.salePrice,
      profitMargin,

      // 기본 보증
      baseWarrantyMonths: scoreResult.baseWarrantyMonths,

      // B2B 거래 정보
      buyerCompanyName: data.buyerCompanyName || null,
      buyerContactName: data.buyerContactName || null,
      buyerContactPhone: data.buyerContactPhone || null,
      saleDate: now,

      // 상태
      status: "registered",

      // 타임스탬프
      createdAt: now,
      updatedAt: now,
    };

    // Firestore에 저장
    await db.collection("verification_transactions").doc(transactionId).set(transaction);

    console.log(`Transaction created: ${transactionId}, QR: ${qrCode}, Type: ${transactionType}`);
    console.log(`  Score: ${scoreResult.conditionScore}, Grade: ${scoreResult.conditionGrade}, Warranty: ${scoreResult.baseWarrantyMonths}mo`);

    // QR 코드 + 보증서 PDF 자동 생성 (비동기, 응답 차단하지 않음)
    autoGenerateAssets(transactionId, transaction).catch((err) => {
      console.error(`Auto-generate assets failed for ${transactionId}:`, err.message);
    });

    const response: CreateTransactionResponse = {
      success: true,
      transactionId,
      qrCode,
      conditionScore: scoreResult.conditionScore,
      conditionGrade: scoreResult.conditionGrade,
      baseWarrantyMonths: scoreResult.baseWarrantyMonths,
      message: "Transaction registered successfully",
    };

    res.status(201).json(response);
  } catch (error: any) {
    console.error("Transaction create error:", error);
    res.status(500).json({
      error: "Failed to create transaction",
      message: error.message,
    });
  }
});

// ============================================================================
// GET /warranty/transaction/:qrCode - QR로 거래 조회 (공개)
// ============================================================================

router.get("/transaction/:qrCode", async (req, res) => {
  try {
    const {qrCode} = req.params;

    if (!qrCode) {
      res.status(400).json({error: "Missing qrCode"});
      return;
    }

    // qrCode로 거래 조회
    const snapshot = await db
      .collection("verification_transactions")
      .where("qrCode", "==", qrCode)
      .limit(1)
      .get();

    if (snapshot.empty) {
      res.status(404).json({
        error: "Transaction not found",
        message: "No transaction found for the provided QR code",
      });
      return;
    }

    const doc = snapshot.docs[0];
    const transaction = doc.data() as VerificationTransaction;

    // 공개 정보만 반환 (민감한 정보 제외 - purchaseCost 등)
    const publicData = {
      transactionId: transaction.transactionId,
      qrCode: transaction.qrCode,

      // 거래 타입
      transactionType: transaction.transactionType || "single",

      // 부품 정보 (단일)
      partCategory: transaction.partCategory,
      brand: transaction.brand,
      modelName: transaction.modelName,
      photoUrls: transaction.photoUrls,

      // 풀세트 정보
      bundleName: transaction.bundleName,
      items: transaction.items?.map((item) => ({
        itemId: item.itemId,
        partCategory: item.partCategory,
        brand: item.brand,
        modelName: item.modelName,
        conditionScore: item.conditionScore,
        benchmarkScore: item.benchmarkScore,
        photoUrls: item.photoUrls,
      })),

      // 검수 정보 (공개 가능)
      inspectorName: transaction.inspectorName,
      inspectedAt: transaction.inspectedAt,
      inspectionNote: transaction.inspectionNote,

      // 스코어 정보 (v2)
      conditionScore: transaction.conditionScore,
      conditionGrade: transaction.conditionGrade,
      benchmarkScores: transaction.benchmarkScores,

      // 기본 보증 (v2)
      baseWarrantyMonths: transaction.baseWarrantyMonths,

      inspectionPhotoUrls: transaction.inspectionPhotoUrls,

      // 거래 정보
      salePrice: transaction.salePrice,
      saleDate: transaction.saleDate,

      // 상태
      status: transaction.status,
      warrantyId: transaction.warrantyId,

      // 문서 URL
      verificationReportUrl: transaction.verificationReportUrl,
      warrantyPdfUrl: transaction.warrantyPdfUrl,
      qrCodeImageUrl: transaction.qrCodeImageUrl,
    };

    res.status(200).json(publicData);
  } catch (error: any) {
    console.error("Transaction query error:", error);
    res.status(500).json({
      error: "Failed to query transaction",
      message: error.message,
    });
  }
});

// ============================================================================
// GET /warranty/transaction/id/:transactionId - 거래 ID로 조회 (Admin용)
// ============================================================================

router.get("/transaction/id/:transactionId", async (req, res) => {
  try {
    const {transactionId} = req.params;

    if (!transactionId) {
      res.status(400).json({error: "Missing transactionId"});
      return;
    }

    const doc = await db.collection("verification_transactions").doc(transactionId).get();

    if (!doc.exists) {
      res.status(404).json({
        error: "Transaction not found",
      });
      return;
    }

    const transaction = doc.data() as VerificationTransaction;

    res.status(200).json(transaction);
  } catch (error: any) {
    console.error("Transaction query by ID error:", error);
    res.status(500).json({
      error: "Failed to query transaction",
      message: error.message,
    });
  }
});

// ============================================================================
// GET /warranty/transactions - 거래 목록 조회 (Admin용)
// ============================================================================

router.get("/transactions", async (req, res) => {
  try {
    const {status, limit = "50", startAfter} = req.query;

    let query = db.collection("verification_transactions")
      .orderBy("createdAt", "desc")
      .limit(parseInt(limit as string, 10));

    if (status) {
      query = query.where("status", "==", status);
    }

    if (startAfter) {
      const startDoc = await db.collection("verification_transactions").doc(startAfter as string).get();
      if (startDoc.exists) {
        query = query.startAfter(startDoc);
      }
    }

    const snapshot = await query.get();

    const transactions = snapshot.docs.map((doc) => doc.data());

    res.status(200).json({
      transactions,
      count: transactions.length,
      hasMore: transactions.length === parseInt(limit as string, 10),
    });
  } catch (error: any) {
    console.error("Transactions list error:", error);
    res.status(500).json({
      error: "Failed to list transactions",
      message: error.message,
    });
  }
});

// ============================================================================
// PUT /warranty/transaction/:transactionId/status - 상태 변경 (Admin용)
// ============================================================================

router.put("/transaction/:transactionId/status", async (req, res) => {
  try {
    const {transactionId} = req.params;
    const {status} = req.body as {status: TransactionStatus};

    if (!transactionId || !status) {
      res.status(400).json({
        error: "Missing required fields",
        required: ["transactionId", "status"],
      });
      return;
    }

    const validStatuses: TransactionStatus[] = [
      "registered", "qrGenerated", "reportIssued", "delivered", "warrantyActive",
    ];

    if (!validStatuses.includes(status)) {
      res.status(400).json({
        error: "Invalid status",
        validStatuses,
      });
      return;
    }

    const docRef = db.collection("verification_transactions").doc(transactionId);
    const doc = await docRef.get();

    if (!doc.exists) {
      res.status(404).json({error: "Transaction not found"});
      return;
    }

    await docRef.update({
      status,
      updatedAt: admin.firestore.Timestamp.now(),
    });

    console.log(`Transaction ${transactionId} status updated to: ${status}`);

    res.status(200).json({
      success: true,
      transactionId,
      status,
    });
  } catch (error: any) {
    console.error("Transaction status update error:", error);
    res.status(500).json({
      error: "Failed to update transaction status",
      message: error.message,
    });
  }
});

// ============================================================================
// 자동 생성: QR 코드 이미지 + 보증서 PDF
// ============================================================================

async function autoGenerateAssets(
  transactionId: string,
  transaction: VerificationTransaction
): Promise<void> {
  const bucket = admin.storage().bucket();
  const docRef = db.collection("verification_transactions").doc(transactionId);

  // 1. QR 코드 PNG 생성 및 업로드
  const qrBuffer = await generateQrPngBuffer(transaction.qrCode, {width: 300});
  const qrFileName = `warranty/qr/${transactionId}.png`;
  const qrFile = bucket.file(qrFileName);

  await qrFile.save(qrBuffer, {
    metadata: {
      contentType: "image/png",
      metadata: {transactionId, qrCode: transaction.qrCode},
    },
  });
  await qrFile.makePublic();
  const qrCodeImageUrl = `https://storage.googleapis.com/${bucket.name}/${qrFileName}`;

  // 2. 보증서 PDF 생성 및 업로드
  const pdfBuffer = await generateWarrantyCertificatePDF(transaction);
  const pdfFileName = `warranty/certificates/${transactionId}-warranty.pdf`;
  const pdfFile = bucket.file(pdfFileName);

  await pdfFile.save(pdfBuffer, {
    metadata: {
      contentType: "application/pdf",
      metadata: {transactionId, qrCode: transaction.qrCode, type: "warranty-certificate"},
    },
  });
  await pdfFile.makePublic();
  const warrantyPdfUrl = `https://storage.googleapis.com/${bucket.name}/${pdfFileName}`;

  // 3. 트랜잭션 업데이트
  await docRef.update({
    qrCodeImageUrl,
    warrantyPdfUrl,
    status: "qrGenerated",
    updatedAt: admin.firestore.Timestamp.now(),
  });

  console.log(`Auto-generated assets for ${transactionId}: QR=${qrCodeImageUrl}, PDF=${warrantyPdfUrl}`);
}

export default router;
