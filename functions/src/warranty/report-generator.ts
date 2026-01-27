/**
 * Report PDF Generator v3
 * 검증 레포트 및 보증서 PDF 생성
 *
 * v3 변경사항:
 * - 한글 폰트 (Noto Sans KR) 지원
 * - 실제 QR 코드 PNG 이미지 삽입
 * - 벤치마크 점수 2x2 그리드 표시
 * - 등급 배지 + 스코어 바 시각화
 * - A4 인쇄 최적화 레이아웃
 */

import * as admin from "firebase-admin";
import {Router} from "express";
import PDFDocument from "pdfkit";
import * as path from "path";
import * as fs from "fs";
import {VerificationTransaction, GRADE_THRESHOLDS, BENCHMARK_CONFIG} from "./types";
import {generateQrPngBuffer, getQrUrl} from "./qr-utils";

const router = Router();
const db = admin.firestore();

// 폰트 경로
const FONTS_DIR = path.join(__dirname, "../../assets/fonts");
const FONT_REGULAR = path.join(FONTS_DIR, "NotoSansKR-Regular.otf");
const FONT_BOLD = path.join(FONTS_DIR, "NotoSansKR-Bold.otf");

// 폰트 파일 존재 여부 확인
function fontsAvailable(): boolean {
  return fs.existsSync(FONT_REGULAR) && fs.existsSync(FONT_BOLD);
}

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

    await file.makePublic();
    const reportUrl = `https://storage.googleapis.com/${bucket.name}/${fileName}`;

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

// ============================================================================
// POST /warranty/generate-warranty-pdf/:transactionId - 보증서 PDF 생성 (v3)
// ============================================================================

router.post("/generate-warranty-pdf/:transactionId", async (req, res) => {
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

    // 보증서 PDF 생성
    const pdfBuffer = await generateWarrantyCertificatePDF(transaction);

    // Firebase Storage에 업로드
    const bucket = admin.storage().bucket();
    const fileName = `warranty/certificates/${transactionId}-warranty.pdf`;
    const file = bucket.file(fileName);

    await file.save(pdfBuffer, {
      metadata: {
        contentType: "application/pdf",
        metadata: {
          transactionId,
          qrCode: transaction.qrCode,
          type: "warranty-certificate",
          generatedAt: new Date().toISOString(),
        },
      },
    });

    await file.makePublic();
    const warrantyPdfUrl = `https://storage.googleapis.com/${bucket.name}/${fileName}`;

    await docRef.update({
      warrantyPdfUrl,
      updatedAt: admin.firestore.Timestamp.now(),
    });

    console.log(`Warranty PDF generated for transaction ${transactionId}: ${warrantyPdfUrl}`);

    res.status(200).json({
      success: true,
      transactionId,
      warrantyPdfUrl,
    });
  } catch (error: any) {
    console.error("Warranty PDF generation error:", error);
    res.status(500).json({
      error: "Failed to generate warranty PDF",
      message: error.message,
    });
  }
});

// ============================================================================
// 보증서 PDF 생성 (v3) - 전면 재설계
// ============================================================================

/**
 * 보증서 PDF 생성 (인쇄용 A4)
 * 실제 QR 코드 이미지 포함, 한글 폰트, 벤치마크 표시
 */
export async function generateWarrantyCertificatePDF(
  transaction: VerificationTransaction
): Promise<Buffer> {
  // QR PNG 버퍼 생성
  const qrBuffer = await generateQrPngBuffer(transaction.qrCode, {width: 300});

  return new Promise((resolve, reject) => {
    const chunks: Buffer[] = [];

    const doc = new PDFDocument({
      size: "A4",
      margin: 50,
      info: {
        Title: `보증서 - ${transaction.transactionId}`,
        Author: "PiComputer",
        Subject: "AS 보증서",
      },
    });

    doc.on("data", (chunk) => chunks.push(chunk));
    doc.on("end", () => resolve(Buffer.concat(chunks)));
    doc.on("error", reject);

    // 한글 폰트 등록
    const useKoreanFont = fontsAvailable();
    if (useKoreanFont) {
      doc.registerFont("Korean", FONT_REGULAR);
      doc.registerFont("Korean-Bold", FONT_BOLD);
    }

    const fontRegular = useKoreanFont ? "Korean" : "Helvetica";
    const fontBold = useKoreanFont ? "Korean-Bold" : "Helvetica-Bold";

    const isBundle = transaction.transactionType === "bundle";
    const gradeConfig = GRADE_THRESHOLDS[transaction.conditionGrade || "B"];
    const pageWidth = doc.page.width;
    const contentWidth = pageWidth - 100; // 50px margins on each side

    // ========== 헤더 ==========
    doc
      .fontSize(24)
      .font(fontBold)
      .fillColor("#1a56db")
      .text("PiComputer", {align: "center"});

    doc.moveDown(0.2);
    doc
      .fontSize(20)
      .text("WARRANTY CERTIFICATE", {align: "center"});

    doc.moveDown(0.2);
    doc
      .fontSize(14)
      .font(fontRegular)
      .fillColor("#6b7280")
      .text("AS \uBCF4\uC99D\uC11C", {align: "center"});

    doc.moveDown(1);
    drawHorizontalLine(doc);
    doc.moveDown(1);

    // ========== QR 코드 (실제 PNG 이미지) ==========
    const qrSize = 120;
    const qrX = (pageWidth - qrSize) / 2;

    doc.image(qrBuffer, qrX, doc.y, {
      width: qrSize,
      height: qrSize,
    });

    doc.y += qrSize + 8;
    doc
      .fontSize(8)
      .font(fontRegular)
      .fillColor("#9ca3af")
      .text(getQrUrl(transaction.qrCode), {align: "center"});

    doc.moveDown(1);
    drawHorizontalLine(doc);
    doc.moveDown(1);

    // ========== 등급 배지 + 스코어 바 ==========
    const grade = transaction.conditionGrade || "B";
    const score = transaction.conditionScore || 0;

    // 등급 배지 (좌측)
    const badgeSize = 60;
    const badgeX = 50;
    const badgeY = doc.y;

    const gradeColors: Record<string, string> = {
      S: "#4f46e5",
      A: "#059669",
      B: "#d97706",
      C: "#dc2626",
      D: "#6b7280",
    };

    const gradeBgColors: Record<string, string> = {
      S: "#eef2ff",
      A: "#ecfdf5",
      B: "#fef3c7",
      C: "#fef2f2",
      D: "#f3f4f6",
    };

    doc
      .roundedRect(badgeX, badgeY, badgeSize, badgeSize, 8)
      .fillColor(gradeBgColors[grade])
      .fill();

    doc
      .fontSize(28)
      .font(fontBold)
      .fillColor(gradeColors[grade])
      .text(grade, badgeX, badgeY + 8, {
        width: badgeSize,
        align: "center",
      });

    doc
      .fontSize(9)
      .font(fontRegular)
      .text(gradeConfig.labelKo, badgeX, badgeY + 40, {
        width: badgeSize,
        align: "center",
      });

    // 스코어 바 (우측)
    const barX = badgeX + badgeSize + 20;
    const barWidth = contentWidth - badgeSize - 20;
    const barHeight = 16;
    const barY = badgeY + 10;

    doc
      .fontSize(13)
      .font(fontBold)
      .fillColor("#1f2937")
      .text(`\uC885\uD569 \uC2A4\uCF54\uC5B4: ${score}/100`, barX, barY - 2);

    const scoreBarY = barY + 22;

    // 배경 바
    doc
      .roundedRect(barX, scoreBarY, barWidth, barHeight, 4)
      .fillColor("#e5e7eb")
      .fill();

    // 점수 바
    const scoreWidth = Math.max(0, (score / 100) * barWidth);
    if (scoreWidth > 0) {
      doc
        .roundedRect(barX, scoreBarY, scoreWidth, barHeight, 4)
        .fillColor(gradeColors[grade])
        .fill();
    }

    // 보증 기간 표시
    const warrantyMonths = transaction.baseWarrantyMonths || 12;
    doc
      .fontSize(10)
      .font(fontRegular)
      .fillColor("#6b7280")
      .text(`\uAE30\uBCF8 \uBCF4\uC99D: ${warrantyMonths}\uAC1C\uC6D4`, barX, scoreBarY + barHeight + 6);

    doc.y = badgeY + badgeSize + 20;
    doc.moveDown(0.5);
    drawHorizontalLine(doc);
    doc.moveDown(1);

    // ========== 벤치마크 점수 (2x2 그리드) ==========
    if (transaction.benchmarkScores) {
      const benchmarks = transaction.benchmarkScores;
      const hasAnyBenchmark = benchmarks.cpu || benchmarks.gpu || benchmarks.storage || benchmarks.memory;

      if (hasAnyBenchmark) {
        doc
          .fontSize(13)
          .font(fontBold)
          .fillColor("#1f2937")
          .text("\uBCA4\uCE58\uB9C8\uD06C \uC810\uC218");

        doc.moveDown(0.5);

        const gridStartY = doc.y;
        const cellWidth = contentWidth / 2;
        const cellHeight = 35;

        const benchmarkItems: Array<{label: string; value?: number; unit: string}> = [
          {label: "CPU", value: benchmarks.cpu, unit: BENCHMARK_CONFIG.cpu?.unit || "PassMark"},
          {label: "GPU", value: benchmarks.gpu, unit: BENCHMARK_CONFIG.gpu?.unit || "3DMark"},
          {label: "Storage", value: benchmarks.storage, unit: BENCHMARK_CONFIG.storage?.unit || "MB/s"},
          {label: "Memory", value: benchmarks.memory, unit: BENCHMARK_CONFIG.memory?.unit || "MB/s"},
        ];

        benchmarkItems.forEach((item, index) => {
          const col = index % 2;
          const row = Math.floor(index / 2);
          const cellX = 50 + col * cellWidth;
          const cellY = gridStartY + row * cellHeight;

          // 라벨
          doc
            .fontSize(9)
            .font(fontRegular)
            .fillColor("#6b7280")
            .text(item.label, cellX, cellY);

          // 값
          if (item.value) {
            doc
              .fontSize(14)
              .font(fontBold)
              .fillColor("#1f2937")
              .text(
                `${item.value.toLocaleString("ko-KR")}`,
                cellX,
                cellY + 14
              );

            // unit 표시를 값 옆에 배치
            const valueStr = `${item.value.toLocaleString("ko-KR")}`;
            doc.font(fontBold).fontSize(14);
            const valueWidth = doc.widthOfString(valueStr);
            doc
              .fontSize(8)
              .font(fontRegular)
              .fillColor("#9ca3af")
              .text(
                `(${item.unit})`,
                cellX + valueWidth + 4,
                cellY + 18
              );
          } else {
            doc
              .fontSize(12)
              .font(fontRegular)
              .fillColor("#d1d5db")
              .text("-", cellX, cellY + 14);
          }
        });

        doc.y = gridStartY + Math.ceil(benchmarkItems.length / 2) * cellHeight + 5;
        drawHorizontalLine(doc);
        doc.moveDown(1);
      }
    }

    // ========== 제품 정보 ==========
    doc
      .fontSize(13)
      .font(fontBold)
      .fillColor("#1f2937")
      .text("\uC81C\uD488 \uC815\uBCF4");

    doc.moveDown(0.5);

    if (isBundle) {
      doc
        .fontSize(12)
        .font(fontBold)
        .fillColor("#374151")
        .text(transaction.bundleName || "\uC870\uB9BD PC \uC138\uD2B8", 50);

      doc.moveDown(0.3);

      if (transaction.items && transaction.items.length > 0) {
        for (const item of transaction.items.slice(0, 8)) {
          doc
            .fontSize(10)
            .font(fontRegular)
            .fillColor("#4b5563")
            .text(`\u2022 ${item.partCategory}: ${item.brand} ${item.modelName}`, 60);
        }
        if (transaction.items.length > 8) {
          doc
            .fontSize(10)
            .font(fontRegular)
            .fillColor("#9ca3af")
            .text(`  ... \uC678 ${transaction.items.length - 8}\uAC1C`, 60);
        }
      }
    } else {
      const productInfo = [
        ["\uCE74\uD14C\uACE0\uB9AC", transaction.partCategory || "N/A"],
        ["\uBE0C\uB79C\uB4DC", transaction.brand || "N/A"],
        ["\uBAA8\uB378\uBA85", transaction.modelName || "N/A"],
      ];

      if (transaction.serialNumber) {
        productInfo.push(["\uC2DC\uB9AC\uC5BC", transaction.serialNumber]);
      }

      drawKoreanInfoTable(doc, productInfo, fontBold, fontRegular);
    }

    doc.moveDown(1);
    drawHorizontalLine(doc);
    doc.moveDown(1);

    // ========== 거래 정보 ==========
    doc
      .fontSize(13)
      .font(fontBold)
      .fillColor("#1f2937")
      .text("\uAC70\uB798 \uC815\uBCF4");

    doc.moveDown(0.5);

    const saleDate = transaction.saleDate?.toDate?.()
      ? formatDate(transaction.saleDate.toDate())
      : formatDate(new Date());

    const transactionInfo = [
      ["\uD310\uB9E4\uAC00", formatCurrency(transaction.salePrice)],
      ["\uD310\uB9E4\uC77C", saleDate],
      ["\uAC80\uC218\uC790", transaction.inspectorName],
      ["\uAE30\uBCF8\uBCF4\uC99D", `${warrantyMonths}\uAC1C\uC6D4`],
    ];

    drawKoreanInfoTable(doc, transactionInfo, fontBold, fontRegular);

    doc.moveDown(1.5);

    // ========== 푸터 ==========
    drawHorizontalLine(doc);
    doc.moveDown(0.5);

    doc
      .fontSize(8)
      .font(fontRegular)
      .fillColor("#9ca3af")
      .text(
        `\u00A9 PiComputer  \uBB38\uC11C\uBC88\uD638: ${transaction.transactionId}`,
        {align: "center"}
      );

    doc.text(
      "\uBCF8 \uBCF4\uC99D\uC11C\uB294 PiComputer\uC5D0\uC11C \uBC1C\uD589\uD55C \uACF5\uC2DD AS \uBCF4\uC99D\uC11C\uC785\uB2C8\uB2E4.",
      {align: "center"}
    );

    doc.end();
  });
}

// ============================================================================
// 검증 레포트 PDF 생성
// ============================================================================

async function generateVerificationReportPDF(
  transaction: VerificationTransaction
): Promise<Buffer> {
  const qrBuffer = await generateQrPngBuffer(transaction.qrCode, {width: 300});

  return new Promise((resolve, reject) => {
    const chunks: Buffer[] = [];

    const doc = new PDFDocument({
      size: "A4",
      margin: 50,
      info: {
        Title: `\uAC80\uC99D \uB808\uD3EC\uD2B8 - ${transaction.transactionId}`,
        Author: "PiComputer",
        Subject: "\uBD80\uD488 \uAC80\uC99D \uB808\uD3EC\uD2B8",
      },
    });

    doc.on("data", (chunk) => chunks.push(chunk));
    doc.on("end", () => resolve(Buffer.concat(chunks)));
    doc.on("error", reject);

    // 한글 폰트 등록
    const useKoreanFont = fontsAvailable();
    if (useKoreanFont) {
      doc.registerFont("Korean", FONT_REGULAR);
      doc.registerFont("Korean-Bold", FONT_BOLD);
    }

    const fontRegular = useKoreanFont ? "Korean" : "Helvetica";
    const fontBold = useKoreanFont ? "Korean-Bold" : "Helvetica-Bold";

    // 헤더
    doc
      .fontSize(24)
      .font(fontBold)
      .fillColor("#1a56db")
      .text("VERIFICATION REPORT", {align: "center"});

    doc.moveDown(0.3);
    doc
      .fontSize(12)
      .font(fontRegular)
      .fillColor("#6b7280")
      .text("PiComputer Parts Verification System", {align: "center"});

    doc.moveDown(1);

    doc
      .fontSize(10)
      .fillColor("#666666")
      .text(`Document ID: ${transaction.transactionId}`, {align: "right"});
    doc.text(`Issue Date: ${formatDate(new Date())}`, {align: "right"});

    doc.moveDown(1.5);
    drawHorizontalLine(doc);
    doc.moveDown(1);

    // 부품 정보 섹션
    doc
      .fontSize(14)
      .fillColor("#000000")
      .font(fontBold)
      .text("PART INFORMATION");

    doc.moveDown(0.5);

    if (transaction.transactionType === "bundle" && transaction.items) {
      const bundleInfo = [
        ["Type", "Bundle (PC Set)"],
        ["Bundle Name", transaction.bundleName || "N/A"],
        ["Components", `${transaction.items.length} parts`],
      ];
      drawInfoTable(doc, bundleInfo, fontBold, fontRegular);

      doc.moveDown(0.8);
      doc.fontSize(10).font(fontBold).text("Component List:");
      doc.moveDown(0.3);

      for (const item of transaction.items.slice(0, 8)) {
        doc
          .fontSize(9)
          .font(fontRegular)
          .text(`  \u2022 ${item.partCategory}: ${item.brand} ${item.modelName}`);
      }

      if (transaction.items.length > 8) {
        doc.text(`  ... and ${transaction.items.length - 8} more`);
      }
    } else {
      const partInfo = [
        ["Category", transaction.partCategory || "N/A"],
        ["Brand", transaction.brand || "N/A"],
        ["Model", transaction.modelName || "N/A"],
        ["Serial Number", transaction.serialNumber || "N/A"],
      ];
      drawInfoTable(doc, partInfo, fontBold, fontRegular);
    }

    doc.moveDown(1.5);

    // 검수 정보
    doc.fontSize(14).font(fontBold).text("INSPECTION DETAILS");
    doc.moveDown(0.5);

    const inspectionDate = transaction.inspectedAt?.toDate?.()
      ? formatDate(transaction.inspectedAt.toDate())
      : formatDate(new Date());

    const gradeLabel = transaction.conditionGrade
      ? `${transaction.conditionGrade} (${GRADE_THRESHOLDS[transaction.conditionGrade]?.label || ""})`
      : "N/A";

    const inspectionInfo = [
      ["Inspector", transaction.inspectorName],
      ["Inspection Date", inspectionDate],
      ["Condition Score", `${transaction.conditionScore} / 100`],
      ["Grade", gradeLabel],
      ["Base Warranty", `${transaction.baseWarrantyMonths || 12} months`],
    ];

    drawInfoTable(doc, inspectionInfo, fontBold, fontRegular);
    doc.moveDown(1);

    // 상태 바
    drawConditionBar(doc, transaction.conditionScore, transaction.conditionGrade || "B");
    doc.moveDown(2);

    drawHorizontalLine(doc);
    doc.moveDown(1);

    // 거래 정보
    doc.fontSize(14).font(fontBold).text("TRANSACTION DETAILS");
    doc.moveDown(0.5);

    const saleDate = transaction.saleDate?.toDate?.()
      ? formatDate(transaction.saleDate.toDate())
      : formatDate(new Date());

    const transactionInfo = [
      ["Sale Price", formatCurrency(transaction.salePrice)],
      ["Sale Date", saleDate],
      ["Buyer Company", transaction.buyerCompanyName || "N/A"],
      ["Contact", transaction.buyerContactName || "N/A"],
    ];

    drawInfoTable(doc, transactionInfo, fontBold, fontRegular);
    doc.moveDown(1.5);

    // QR 코드 (실제 이미지)
    doc
      .fontSize(14)
      .font(fontBold)
      .text("WARRANTY REGISTRATION", {align: "center"});

    doc.moveDown(0.5);
    doc
      .fontSize(10)
      .font(fontRegular)
      .fillColor("#666666")
      .text("Scan the QR code to register AS warranty", {align: "center"});

    doc.moveDown(0.8);

    const qrSize = 100;
    const qrX = (doc.page.width - qrSize) / 2;

    doc.image(qrBuffer, qrX, doc.y, {
      width: qrSize,
      height: qrSize,
    });

    doc.y += qrSize + 8;
    doc
      .fontSize(8)
      .fillColor("#999999")
      .text(getQrUrl(transaction.qrCode), {align: "center"});

    // 푸터
    doc.moveDown(2);
    drawHorizontalLine(doc);
    doc.moveDown(0.5);

    doc
      .fontSize(8)
      .fillColor("#999999")
      .text("This document is issued by PiComputer Parts Verification System.", {
        align: "center",
      });

    doc.end();
  });
}

// ============================================================================
// Helper Functions
// ============================================================================

function drawHorizontalLine(doc: PDFKit.PDFDocument): void {
  const startX = 50;
  const endX = doc.page.width - 50;
  doc
    .strokeColor("#e5e7eb")
    .lineWidth(1)
    .moveTo(startX, doc.y)
    .lineTo(endX, doc.y)
    .stroke();
}

function drawInfoTable(
  doc: PDFKit.PDFDocument,
  rows: string[][],
  fontBold: string,
  fontRegular: string
): void {
  const startX = 50;
  const labelWidth = 120;
  const valueX = startX + labelWidth;

  rows.forEach((row) => {
    const [label, value] = row;
    doc
      .fontSize(11)
      .font(fontBold)
      .fillColor("#333333")
      .text(`${label}:`, startX, doc.y, {continued: false, width: labelWidth});

    doc.moveUp();
    doc
      .font(fontRegular)
      .fillColor("#000000")
      .text(value, valueX);
  });
}

function drawKoreanInfoTable(
  doc: PDFKit.PDFDocument,
  rows: string[][],
  fontBold: string,
  fontRegular: string
): void {
  const startX = 60;
  const labelWidth = 80;
  const valueX = startX + labelWidth;

  rows.forEach((row) => {
    const [label, value] = row;
    doc
      .fontSize(10)
      .font(fontRegular)
      .fillColor("#6b7280")
      .text(`${label}:`, startX, doc.y, {continued: false, width: labelWidth});

    doc.moveUp();
    doc
      .font(fontBold)
      .fillColor("#1f2937")
      .text(value, valueX);
  });
}

function drawConditionBar(
  doc: PDFKit.PDFDocument,
  score: number,
  grade: string
): void {
  const barWidth = 300;
  const barHeight = 20;
  const barX = (doc.page.width - barWidth) / 2;
  const barY = doc.y;

  const gradeColors: Record<string, string> = {
    S: "#4f46e5",
    A: "#059669",
    B: "#d97706",
    C: "#dc2626",
    D: "#6b7280",
  };

  // 배경 바
  doc
    .roundedRect(barX, barY, barWidth, barHeight, 4)
    .fillColor("#e5e7eb")
    .fill();

  // 점수 바
  const scoreWidth = (score / 100) * barWidth;
  if (scoreWidth > 0) {
    doc
      .roundedRect(barX, barY, scoreWidth, barHeight, 4)
      .fillColor(gradeColors[grade] || "#4CAF50")
      .fill();
  }

  // 점수 텍스트
  doc.y = barY + barHeight + 5;
  doc
    .fontSize(12)
    .fillColor("#000000")
    .font("Helvetica-Bold")
    .text(`Condition: ${score}/100`, {align: "center"});
}

function formatDate(date: Date): string {
  return date.toISOString().split("T")[0];
}

function formatCurrency(amount: number): string {
  return `\u20A9${amount.toLocaleString("ko-KR")}`;
}

export default router;
