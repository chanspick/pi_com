/**
 * Warranty Transaction API
 * B2B 거래 등록 및 QR 코드 관리
 */

import * as admin from "firebase-admin";
import {Router} from "express";
import {
  VerificationTransaction,
  CreateTransactionRequest,
  TransactionStatus,
  generateTransactionId,
  generateQRCode,
} from "./types";

const router = Router();
const db = admin.firestore();

// ============================================================================
// POST /warranty/transaction - B2B 거래 등록
// ============================================================================

router.post("/transaction", async (req, res) => {
  try {
    const data = req.body as CreateTransactionRequest;

    // 필수 필드 검증
    if (!data.partCategory || !data.brand || !data.modelName || !data.salePrice) {
      res.status(400).json({
        error: "Missing required fields",
        required: ["partCategory", "brand", "modelName", "salePrice"],
      });
      return;
    }

    if (!data.inspectorId || !data.inspectorName || !data.conditionScore) {
      res.status(400).json({
        error: "Missing inspector information",
        required: ["inspectorId", "inspectorName", "conditionScore"],
      });
      return;
    }

    if (data.conditionScore < 1 || data.conditionScore > 10) {
      res.status(400).json({
        error: "conditionScore must be between 1 and 10",
      });
      return;
    }

    const now = admin.firestore.Timestamp.now();
    const transactionId = generateTransactionId();
    const qrCode = generateQRCode();

    const transaction: VerificationTransaction = {
      transactionId,
      qrCode,

      // 부품 정보
      partCategory: data.partCategory,
      brand: data.brand,
      modelName: data.modelName,
      serialNumber: data.serialNumber || null,
      photoUrls: data.photoUrls || [],

      // 검수 정보
      inspectorId: data.inspectorId,
      inspectorName: data.inspectorName,
      inspectedAt: now,
      inspectionNote: data.inspectionNote || "",
      conditionScore: data.conditionScore,
      inspectionPhotoUrls: data.inspectionPhotoUrls || [],

      // B2B 거래 정보
      buyerCompanyName: data.buyerCompanyName || null,
      buyerContactName: data.buyerContactName || null,
      buyerContactPhone: data.buyerContactPhone || null,
      salePrice: data.salePrice,
      saleDate: now,

      // 상태
      status: "registered",

      // 타임스탬프
      createdAt: now,
      updatedAt: now,
    };

    // Firestore에 저장
    await db.collection("verification_transactions").doc(transactionId).set(transaction);

    console.log(`Transaction created: ${transactionId}, QR: ${qrCode}`);

    res.status(201).json({
      success: true,
      transactionId,
      qrCode,
      message: "Transaction registered successfully",
    });
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

    // 공개 정보만 반환 (민감한 정보 제외)
    const publicData = {
      transactionId: transaction.transactionId,
      qrCode: transaction.qrCode,

      // 부품 정보
      partCategory: transaction.partCategory,
      brand: transaction.brand,
      modelName: transaction.modelName,
      photoUrls: transaction.photoUrls,

      // 검수 정보 (공개 가능)
      inspectorName: transaction.inspectorName,
      inspectedAt: transaction.inspectedAt,
      inspectionNote: transaction.inspectionNote,
      conditionScore: transaction.conditionScore,
      inspectionPhotoUrls: transaction.inspectionPhotoUrls,

      // 거래 정보
      salePrice: transaction.salePrice,
      saleDate: transaction.saleDate,

      // 상태
      status: transaction.status,
      warrantyId: transaction.warrantyId,

      // 문서 URL
      verificationReportUrl: transaction.verificationReportUrl,
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

export default router;
