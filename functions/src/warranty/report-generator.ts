/**
 * Verification Report PDF Generator
 * 검증 레포트 PDF 생성
 */

import * as admin from "firebase-admin";
import {Router} from "express";
import PDFDocument from "pdfkit";
import {VerificationTransaction} from "./types";

const router = Router();
const db = admin.firestore();

// ============================================================================
// POST /warranty/generate-report/:transactionId - PDF 레포트 생성
// ============================================================================

router.post("/generate-report/:transactionId", async (req, res) => {
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

    // PDF 생성
    const pdfBuffer = await generateVerificationReportPDF(transaction);

    // Firebase Storage에 업로드
    const bucket = admin.storage().bucket();
    const fileName = `warranty/reports/${transactionId}.pdf`;
    const file = bucket.file(fileName);

    await file.save(pdfBuffer, {
      metadata: {
        contentType: "application/pdf",
        metadata: {
          transactionId,
          qrCode: transaction.qrCode,
          generatedAt: new Date().toISOString(),
        },
      },
    });

    // 공개 URL 생성
    await file.makePublic();
    const reportUrl = `https://storage.googleapis.com/${bucket.name}/${fileName}`;

    // 트랜잭션 업데이트
    await docRef.update({
      verificationReportUrl: reportUrl,
      status: "reportIssued",
      updatedAt: admin.firestore.Timestamp.now(),
    });

    console.log(`Report generated for transaction ${transactionId}: ${reportUrl}`);

    res.status(200).json({
      success: true,
      transactionId,
      reportUrl,
    });
  } catch (error: any) {
    console.error("Report generation error:", error);
    res.status(500).json({
      error: "Failed to generate report",
      message: error.message,
    });
  }
});

/**
 * 검증 레포트 PDF 생성
 */
async function generateVerificationReportPDF(
  transaction: VerificationTransaction
): Promise<Buffer> {
  return new Promise((resolve, reject) => {
    const chunks: Buffer[] = [];

    // A4 사이즈 PDF
    const doc = new PDFDocument({
      size: "A4",
      margin: 50,
      info: {
        Title: `검증 레포트 - ${transaction.transactionId}`,
        Author: "PiComputer",
        Subject: "부품 검증 레포트",
      },
    });

    doc.on("data", (chunk) => chunks.push(chunk));
    doc.on("end", () => resolve(Buffer.concat(chunks)));
    doc.on("error", reject);

    // 헤더
    doc
      .fontSize(24)
      .font("Helvetica-Bold")
      .text("VERIFICATION REPORT", {align: "center"});

    doc.moveDown(0.5);
    doc
      .fontSize(12)
      .font("Helvetica")
      .text("PiComputer Parts Verification System", {align: "center"});

    doc.moveDown(2);

    // 문서 정보
    doc
      .fontSize(10)
      .fillColor("#666666")
      .text(`Document ID: ${transaction.transactionId}`, {align: "right"});
    doc.text(`Issue Date: ${formatDate(new Date())}`, {align: "right"});

    doc.moveDown(2);

    // 구분선
    drawHorizontalLine(doc);
    doc.moveDown(1);

    // 부품 정보 섹션
    doc
      .fontSize(14)
      .fillColor("#000000")
      .font("Helvetica-Bold")
      .text("PART INFORMATION");

    doc.moveDown(0.5);
    doc.fontSize(11).font("Helvetica");

    const partInfo = [
      ["Category", transaction.partCategory],
      ["Brand", transaction.brand],
      ["Model", transaction.modelName],
      ["Serial Number", transaction.serialNumber || "N/A"],
    ];

    drawInfoTable(doc, partInfo);
    doc.moveDown(1.5);

    // 검수 정보 섹션
    doc
      .fontSize(14)
      .font("Helvetica-Bold")
      .text("INSPECTION DETAILS");

    doc.moveDown(0.5);
    doc.fontSize(11).font("Helvetica");

    const inspectionDate = transaction.inspectedAt?.toDate?.()
      ? formatDate(transaction.inspectedAt.toDate())
      : formatDate(new Date());

    const inspectionInfo = [
      ["Inspector", transaction.inspectorName],
      ["Inspection Date", inspectionDate],
      ["Condition Score", `${transaction.conditionScore} / 10`],
    ];

    drawInfoTable(doc, inspectionInfo);
    doc.moveDown(1);

    // 검수 소견
    doc
      .fontSize(11)
      .font("Helvetica-Bold")
      .text("Inspection Note:");

    doc.moveDown(0.3);
    doc
      .font("Helvetica")
      .text(transaction.inspectionNote || "No notes provided.", {
        width: 495,
        align: "justify",
      });

    doc.moveDown(1.5);

    // 상태 표시
    drawConditionBar(doc, transaction.conditionScore);
    doc.moveDown(2);

    // 구분선
    drawHorizontalLine(doc);
    doc.moveDown(1);

    // 거래 정보 섹션
    doc
      .fontSize(14)
      .font("Helvetica-Bold")
      .text("TRANSACTION DETAILS");

    doc.moveDown(0.5);
    doc.fontSize(11).font("Helvetica");

    const saleDate = transaction.saleDate?.toDate?.()
      ? formatDate(transaction.saleDate.toDate())
      : formatDate(new Date());

    const transactionInfo = [
      ["Sale Price", formatCurrency(transaction.salePrice)],
      ["Sale Date", saleDate],
      ["Buyer Company", transaction.buyerCompanyName || "N/A"],
      ["Contact", transaction.buyerContactName || "N/A"],
    ];

    drawInfoTable(doc, transactionInfo);
    doc.moveDown(2);

    // QR 코드 안내
    doc
      .fontSize(14)
      .font("Helvetica-Bold")
      .text("WARRANTY REGISTRATION", {align: "center"});

    doc.moveDown(0.5);
    doc
      .fontSize(10)
      .font("Helvetica")
      .fillColor("#666666")
      .text("Scan the QR code to register AS warranty", {align: "center"});

    doc.moveDown(0.5);
    doc
      .fontSize(9)
      .text(`QR Code: ${transaction.qrCode}`, {align: "center"});

    // QR 코드 이미지 영역 (플레이스홀더)
    const qrSize = 100;
    const qrX = (doc.page.width - qrSize) / 2;
    doc.moveDown(1);
    doc
      .rect(qrX, doc.y, qrSize, qrSize)
      .stroke();

    doc.y += qrSize + 10;
    doc
      .fontSize(8)
      .fillColor("#999999")
      .text("[QR Code Image]", {align: "center"});

    // 푸터
    doc.moveDown(3);
    drawHorizontalLine(doc);
    doc.moveDown(0.5);

    doc
      .fontSize(8)
      .fillColor("#999999")
      .text("This document is issued by PiComputer Parts Verification System.", {
        align: "center",
      });
    doc.text(
      "For AS warranty, please scan the QR code and complete the registration.",
      {align: "center"}
    );

    doc.end();
  });
}

/**
 * 수평선 그리기
 */
function drawHorizontalLine(doc: PDFKit.PDFDocument): void {
  const startX = 50;
  const endX = doc.page.width - 50;
  doc
    .strokeColor("#cccccc")
    .lineWidth(1)
    .moveTo(startX, doc.y)
    .lineTo(endX, doc.y)
    .stroke();
}

/**
 * 정보 테이블 그리기
 */
function drawInfoTable(doc: PDFKit.PDFDocument, rows: string[][]): void {
  const startX = 50;
  const labelWidth = 120;
  const valueX = startX + labelWidth;

  rows.forEach((row) => {
    const [label, value] = row;
    doc
      .font("Helvetica-Bold")
      .fillColor("#333333")
      .text(`${label}:`, startX, doc.y, {continued: false, width: labelWidth});

    doc.moveUp();
    doc
      .font("Helvetica")
      .fillColor("#000000")
      .text(value, valueX);
  });
}

/**
 * 상태 바 그리기
 */
function drawConditionBar(doc: PDFKit.PDFDocument, score: number): void {
  const barWidth = 300;
  const barHeight = 20;
  const barX = (doc.page.width - barWidth) / 2;
  const barY = doc.y;

  // 배경 바
  doc
    .rect(barX, barY, barWidth, barHeight)
    .fillColor("#e0e0e0")
    .fill();

  // 점수 바
  const scoreWidth = (score / 10) * barWidth;
  let scoreColor = "#4CAF50"; // 녹색

  if (score < 4) {
    scoreColor = "#F44336"; // 빨강
  } else if (score < 7) {
    scoreColor = "#FF9800"; // 주황
  }

  doc
    .rect(barX, barY, scoreWidth, barHeight)
    .fillColor(scoreColor)
    .fill();

  // 테두리
  doc
    .rect(barX, barY, barWidth, barHeight)
    .strokeColor("#999999")
    .stroke();

  // 점수 텍스트
  doc.y = barY + barHeight + 5;
  doc
    .fontSize(12)
    .fillColor("#000000")
    .font("Helvetica-Bold")
    .text(`Condition: ${score}/10`, {align: "center"});
}

/**
 * 날짜 포맷팅
 */
function formatDate(date: Date): string {
  return date.toISOString().split("T")[0];
}

/**
 * 통화 포맷팅
 */
function formatCurrency(amount: number): string {
  return `₩${amount.toLocaleString("ko-KR")}`;
}

export default router;
