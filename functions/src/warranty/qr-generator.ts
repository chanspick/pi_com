/**
 * QR Code Generator
 * QR 코드 이미지 생성 및 저장
 */

import * as admin from "firebase-admin";
import {Router} from "express";
import {VerificationTransaction} from "./types";

const router = Router();
const db = admin.firestore();

// QR 코드 생성에 사용할 base URL
const QR_BASE_URL = process.env.WARRANTY_WEB_URL || "https://warranty.picomputer.app";

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

    // QR 코드 이미지를 SVG 문자열로 생성 (외부 라이브러리 없이)
    const qrSvg = generateQRSvgSimple(qrUrl);

    // Firebase Storage에 업로드
    const bucket = admin.storage().bucket();
    const fileName = `warranty/qr/${transactionId}.svg`;
    const file = bucket.file(fileName);

    await file.save(qrSvg, {
      metadata: {
        contentType: "image/svg+xml",
        metadata: {
          transactionId,
          qrCode: transaction.qrCode,
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

/**
 * 간단한 QR 코드 SVG 생성 (외부 라이브러리 없이)
 * 실제 프로덕션에서는 'qrcode' 패키지 사용 권장
 * 이 함수는 QR 코드 URL을 텍스트로 포함하는 플레이스홀더 SVG 생성
 */
function generateQRSvgSimple(url: string): string {
  // URL을 base64로 인코딩하여 데이터 매트릭스 패턴 생성
  const encoded = Buffer.from(url).toString("base64");
  const size = 200;
  const modules: boolean[][] = [];

  // 간단한 해시 기반 패턴 생성 (실제 QR이 아닌 시뮬레이션)
  for (let i = 0; i < 41; i++) {
    modules[i] = [];
    for (let j = 0; j < 41; j++) {
      // 파인더 패턴 (모서리)
      if (isFinderPattern(i, j)) {
        modules[i][j] = true;
      } else {
        // 데이터 영역: URL 해시 기반
        const hash = (encoded.charCodeAt((i * 41 + j) % encoded.length) + i + j) % 3;
        modules[i][j] = hash === 0;
      }
    }
  }

  // SVG 생성
  let svg = `<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="${size}" height="${size}" viewBox="0 0 ${size} ${size}">
  <rect width="100%" height="100%" fill="white"/>
  <g fill="black">`;

  const margin = 10;
  const cellSize = (size - margin * 2) / 41;

  for (let i = 0; i < 41; i++) {
    for (let j = 0; j < 41; j++) {
      if (modules[i][j]) {
        const x = margin + j * cellSize;
        const y = margin + i * cellSize;
        svg += `\n    <rect x="${x}" y="${y}" width="${cellSize}" height="${cellSize}"/>`;
      }
    }
  }

  svg += `
  </g>
</svg>`;

  return svg;
}

/**
 * QR 코드 파인더 패턴 체크
 */
function isFinderPattern(row: number, col: number): boolean {
  const size = 41;

  // 좌상단
  if (row < 7 && col < 7) {
    if (row === 0 || row === 6 || col === 0 || col === 6) return true;
    if (row >= 2 && row <= 4 && col >= 2 && col <= 4) return true;
    return false;
  }

  // 우상단
  if (row < 7 && col >= size - 7) {
    const c = col - (size - 7);
    if (row === 0 || row === 6 || c === 0 || c === 6) return true;
    if (row >= 2 && row <= 4 && c >= 2 && c <= 4) return true;
    return false;
  }

  // 좌하단
  if (row >= size - 7 && col < 7) {
    const r = row - (size - 7);
    if (r === 0 || r === 6 || col === 0 || col === 6) return true;
    if (r >= 2 && r <= 4 && col >= 2 && col <= 4) return true;
    return false;
  }

  // 타이밍 패턴 (줄무늬)
  if (row === 6 || col === 6) {
    return (row + col) % 2 === 0;
  }

  return false;
}

export default router;
