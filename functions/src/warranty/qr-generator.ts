/**
 * QR Code Generator
 * QR 코드 이미지 생성 및 저장
 */

import * as admin from "firebase-admin";
import {Router} from "express";
import * as QRCode from "qrcode";
import {VerificationTransaction} from "./types";

const router = Router();
const db = admin.firestore();

// QR 코드 생성에 사용할 base URL
const QR_BASE_URL = process.env.WARRANTY_WEB_URL || "https://picom.site";

// ============================================================================
// POST /warranty/generate-qr/:transactionId - QR 코드 생성
// ============================================================================

router.post("/generate-qr/:transactionId", async (req, res) => {
  try {
    const {transactionId} = req.params;

    if (!transactionId) {
      res.status(400).json({error: "Missing transactionId"});
      return;
    }

    const docRef = db.collection("verification_transactions").doc(transactionId);
    const doc = await docRef.get();

    if (!doc.exists) {
      res.status(404).json({error: "Transaction not found"});
      return;
    }

    const transaction = doc.data() as VerificationTransaction;

    // QR 코드가 가리킬 URL
    const qrUrl = `${QR_BASE_URL}/warranty/${transaction.qrCode}`;

    // QR 코드 이미지 생성 (PNG Buffer)
    const qrBuffer = await QRCode.toBuffer(qrUrl, {
      type: "png",
      width: 300,
      margin: 2,
      color: {
        dark: "#000000",
        light: "#FFFFFF",
      },
      errorCorrectionLevel: "M",
    });

    // Firebase Storage에 업로드
    const bucket = admin.storage().bucket();
    const fileName = `warranty/qr/${transactionId}.png`;
    const file = bucket.file(fileName);

    await file.save(qrBuffer, {
      metadata: {
        contentType: "image/png",
        metadata: {
          transactionId,
          qrCode: transaction.qrCode,
          qrUrl,
        },
      },
    });

    // 공개 URL 생성
    await file.makePublic();
    const qrCodeImageUrl = `https://storage.googleapis.com/${bucket.name}/${fileName}`;

    // 트랜잭션 업데이트
    await docRef.update({
      qrCodeImageUrl,
      status: transaction.status === "registered" ? "qrGenerated" : transaction.status,
      updatedAt: admin.firestore.Timestamp.now(),
    });

    console.log(`QR code generated for transaction ${transactionId}: ${qrCodeImageUrl}`);

    res.status(200).json({
      success: true,
      transactionId,
      qrCode: transaction.qrCode,
      qrUrl,
      qrCodeImageUrl,
    });
  } catch (error: any) {
    console.error("QR generation error:", error);
    res.status(500).json({
      error: "Failed to generate QR code",
      message: error.message,
    });
  }
});

// ============================================================================
// GET /warranty/qr-image/:transactionId - QR 코드 이미지 직접 반환
// ============================================================================

router.get("/qr-image/:transactionId", async (req, res) => {
  try {
    const {transactionId} = req.params;

    const docRef = db.collection("verification_transactions").doc(transactionId);
    const doc = await docRef.get();

    if (!doc.exists) {
      res.status(404).json({error: "Transaction not found"});
      return;
    }

    const transaction = doc.data() as VerificationTransaction;
    const qrUrl = `${QR_BASE_URL}/warranty/${transaction.qrCode}`;

    // QR 코드 이미지를 직접 PNG로 반환
    const qrBuffer = await QRCode.toBuffer(qrUrl, {
      type: "png",
      width: 300,
      margin: 2,
      errorCorrectionLevel: "M",
    });

    res.setHeader("Content-Type", "image/png");
    res.setHeader("Content-Disposition", `inline; filename="qr-${transactionId}.png"`);
    res.send(qrBuffer);
  } catch (error: any) {
    console.error("QR image error:", error);
    res.status(500).json({error: "Failed to generate QR image"});
  }
});

// ============================================================================
// GET /warranty/qr-svg/:transactionId - QR 코드 SVG 반환
// ============================================================================

router.get("/qr-svg/:transactionId", async (req, res) => {
  try {
    const {transactionId} = req.params;

    const docRef = db.collection("verification_transactions").doc(transactionId);
    const doc = await docRef.get();

    if (!doc.exists) {
      res.status(404).json({error: "Transaction not found"});
      return;
    }

    const transaction = doc.data() as VerificationTransaction;
    const qrUrl = `${QR_BASE_URL}/warranty/${transaction.qrCode}`;

    // QR 코드 SVG 문자열 생성
    const qrSvg = await QRCode.toString(qrUrl, {
      type: "svg",
      width: 300,
      margin: 2,
      errorCorrectionLevel: "M",
    });

    res.setHeader("Content-Type", "image/svg+xml");
    res.send(qrSvg);
  } catch (error: any) {
    console.error("QR SVG error:", error);
    res.status(500).json({error: "Failed to generate QR SVG"});
  }
});

export default router;
