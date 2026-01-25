/**
 * Invoice Generator - PDF 송장 생성 모듈
 *
 * 기능:
 * - PDF 생성 (pdfkit)
 * - Firebase Storage 업로드
 * - Firestore invoices 컬렉션 문서 생성
 */

import * as admin from "firebase-admin";
import PDFDocument from "pdfkit";

// 송장 데이터 타입 정의
export interface InvoiceItem {
  name: string;
  quantity: number;
  unitPrice: number;
  totalPrice: number;
}

export interface InvoiceData {
  orderId: string;
  invoiceNumber: string;
  issueDate: Date;
  buyerName: string;
  buyerEmail?: string;
  buyerPhone?: string;
  buyerAddress: string;
  sellerName: string;
  sellerBusinessNumber?: string;
  sellerAddress?: string;
  sellerPhone?: string;
  items: InvoiceItem[];
  subtotal: number;
  shippingFee: number;
  totalAmount: number;
  paymentMethod?: string;
  paidAt?: Date;
}

export interface GenerateInvoiceResult {
  invoiceId: string;
  invoiceNumber: string;
  invoiceUrl: string;
  generatedAt: Date;
}

/**
 * 송장 번호 생성 (YYYYMMDD-XXXXX 형식)
 */
export function generateInvoiceNumber(): string {
  const now = new Date();
  const dateStr = now.toISOString().split("T")[0].replace(/-/g, "");
  const random = Math.floor(Math.random() * 100000).toString().padStart(5, "0");
  return `INV-${dateStr}-${random}`;
}

/**
 * 숫자를 한국 원화 형식으로 포맷
 */
function formatKRW(amount: number): string {
  return new Intl.NumberFormat("ko-KR", {
    style: "currency",
    currency: "KRW",
  }).format(amount);
}

/**
 * 날짜를 한국어 형식으로 포맷
 */
function formatDate(date: Date): string {
  return new Intl.DateTimeFormat("ko-KR", {
    year: "numeric",
    month: "long",
    day: "numeric",
  }).format(date);
}

/**
 * PDF 송장 생성
 */
export async function generateInvoicePDF(data: InvoiceData): Promise<Buffer> {
  return new Promise((resolve, reject) => {
    try {
      const chunks: Buffer[] = [];
      const doc = new PDFDocument({
        size: "A4",
        margin: 50,
        info: {
          Title: `Invoice ${data.invoiceNumber}`,
          Author: "PiCom",
          Subject: `Order ${data.orderId}`,
        },
      });

      // PDF 데이터를 버퍼로 수집
      doc.on("data", (chunk: Buffer) => chunks.push(chunk));
      doc.on("end", () => resolve(Buffer.concat(chunks)));
      doc.on("error", reject);

      // 헤더
      doc.fontSize(24).text("INVOICE", {align: "center"});
      doc.moveDown(0.5);
      doc.fontSize(10).fillColor("#666").text("Tax Invoice / Receipt", {align: "center"});
      doc.moveDown(2);

      // 송장 정보
      doc.fillColor("#000");
      doc.fontSize(12).text(`Invoice Number: ${data.invoiceNumber}`);
      doc.text(`Issue Date: ${formatDate(data.issueDate)}`);
      doc.text(`Order ID: ${data.orderId}`);

      if (data.paidAt) {
        doc.text(`Payment Date: ${formatDate(data.paidAt)}`);
      }
      if (data.paymentMethod) {
        doc.text(`Payment Method: ${data.paymentMethod}`);
      }

      doc.moveDown(1.5);

      // 구분선
      doc.strokeColor("#ddd").lineWidth(1);
      doc.moveTo(50, doc.y).lineTo(545, doc.y).stroke();
      doc.moveDown(1);

      // 구매자 정보 (왼쪽)
      const startY = doc.y;
      doc.fontSize(11).fillColor("#333").text("Bill To:", 50);
      doc.fontSize(10).fillColor("#000");
      doc.text(data.buyerName);
      if (data.buyerPhone) doc.text(data.buyerPhone);
      if (data.buyerEmail) doc.text(data.buyerEmail);
      doc.text(data.buyerAddress, {width: 220});

      // 판매자 정보 (오른쪽)
      doc.fontSize(11).fillColor("#333").text("From:", 325, startY);
      doc.fontSize(10).fillColor("#000");
      doc.text(data.sellerName, 325);
      if (data.sellerBusinessNumber) doc.text(`Business No: ${data.sellerBusinessNumber}`, 325);
      if (data.sellerPhone) doc.text(data.sellerPhone, 325);
      if (data.sellerAddress) doc.text(data.sellerAddress, 325, doc.y, {width: 220});

      doc.moveDown(3);

      // 상품 목록 테이블 헤더
      const tableTop = doc.y;
      const tableHeaders = ["Item", "Qty", "Unit Price", "Total"];
      const colWidths = [250, 50, 100, 95];
      const colStarts = [50, 300, 350, 450];

      // 테이블 헤더 배경
      doc.rect(50, tableTop, 495, 25).fill("#f5f5f5");

      // 테이블 헤더 텍스트
      doc.fillColor("#333").fontSize(10);
      tableHeaders.forEach((header, i) => {
        doc.text(header, colStarts[i], tableTop + 8, {
          width: colWidths[i],
          align: i === 0 ? "left" : "right",
        });
      });

      // 테이블 행
      let rowY = tableTop + 30;
      doc.fillColor("#000").fontSize(9);

      data.items.forEach((item, index) => {
        // 줄무늬 배경
        if (index % 2 === 1) {
          doc.rect(50, rowY - 5, 495, 25).fill("#fafafa");
          doc.fillColor("#000");
        }

        doc.text(item.name, colStarts[0], rowY, {width: colWidths[0]});
        doc.text(item.quantity.toString(), colStarts[1], rowY, {
          width: colWidths[1],
          align: "right",
        });
        doc.text(formatKRW(item.unitPrice), colStarts[2], rowY, {
          width: colWidths[2],
          align: "right",
        });
        doc.text(formatKRW(item.totalPrice), colStarts[3], rowY, {
          width: colWidths[3],
          align: "right",
        });

        rowY += 25;
      });

      // 테이블 하단 선
      doc.strokeColor("#ddd").moveTo(50, rowY + 5).lineTo(545, rowY + 5).stroke();
      doc.moveDown(1);

      // 합계 섹션
      const summaryX = 350;
      let summaryY = rowY + 20;

      doc.fontSize(10).fillColor("#666");
      doc.text("Subtotal:", summaryX);
      doc.fillColor("#000").text(formatKRW(data.subtotal), 450, summaryY, {
        width: 95,
        align: "right",
      });

      summaryY += 20;
      doc.fillColor("#666").text("Shipping:", summaryX, summaryY);
      doc.fillColor("#000").text(formatKRW(data.shippingFee), 450, summaryY, {
        width: 95,
        align: "right",
      });

      summaryY += 25;
      doc.rect(summaryX - 5, summaryY - 5, 200, 25).fill("#333");
      doc.fillColor("#fff").fontSize(12).text("Total:", summaryX, summaryY);
      doc.text(formatKRW(data.totalAmount), 450, summaryY, {
        width: 95,
        align: "right",
      });

      // 푸터
      doc.fillColor("#666").fontSize(8);
      doc.text(
        "Thank you for your purchase! | PiCom - Your Trusted Parts Marketplace",
        50,
        doc.page.height - 50,
        {align: "center"}
      );

      doc.end();
    } catch (error) {
      reject(error);
    }
  });
}

/**
 * PDF를 Firebase Storage에 업로드하고 invoices 컬렉션에 문서 생성
 */
export async function uploadInvoiceAndCreateDoc(
  pdfBuffer: Buffer,
  data: InvoiceData
): Promise<GenerateInvoiceResult> {
  const bucket = admin.storage().bucket();
  const db = admin.firestore();
  const now = new Date();

  // 파일 경로 생성
  const fileName = `invoices/${data.orderId}/${data.invoiceNumber}.pdf`;
  const file = bucket.file(fileName);

  // PDF 업로드
  await file.save(pdfBuffer, {
    contentType: "application/pdf",
    metadata: {
      metadata: {
        orderId: data.orderId,
        invoiceNumber: data.invoiceNumber,
        generatedAt: now.toISOString(),
      },
    },
  });

  // 다운로드 URL 생성 (1년 유효)
  const [signedUrl] = await file.getSignedUrl({
    action: "read",
    expires: Date.now() + 365 * 24 * 60 * 60 * 1000, // 1년
  });

  // Firestore invoices 컬렉션에 문서 생성
  const invoiceDoc = {
    invoiceId: data.invoiceNumber,
    invoiceNumber: data.invoiceNumber,
    orderId: data.orderId,
    invoiceUrl: signedUrl,
    storagePath: fileName,
    buyerName: data.buyerName,
    buyerEmail: data.buyerEmail || null,
    sellerName: data.sellerName,
    totalAmount: data.totalAmount,
    subtotal: data.subtotal,
    shippingFee: data.shippingFee,
    itemCount: data.items.length,
    items: data.items,
    issueDate: admin.firestore.Timestamp.fromDate(data.issueDate),
    paidAt: data.paidAt ? admin.firestore.Timestamp.fromDate(data.paidAt) : null,
    paymentMethod: data.paymentMethod || null,
    generatedAt: admin.firestore.Timestamp.fromDate(now),
    status: "issued",
    version: 1,
  };

  await db.collection("invoices").doc(data.invoiceNumber).set(invoiceDoc);

  // orders 컬렉션에 invoice 정보 업데이트
  await db.collection("orders").doc(data.orderId).update({
    invoiceId: data.invoiceNumber,
    invoiceUrl: signedUrl,
    invoiceGeneratedAt: admin.firestore.Timestamp.fromDate(now),
  });

  console.log(`Invoice generated: ${data.invoiceNumber} for order ${data.orderId}`);

  return {
    invoiceId: data.invoiceNumber,
    invoiceNumber: data.invoiceNumber,
    invoiceUrl: signedUrl,
    generatedAt: now,
  };
}

/**
 * 주문 데이터로부터 송장 생성
 */
export async function generateInvoiceFromOrder(
  orderId: string,
  forceRegenerate = false
): Promise<GenerateInvoiceResult> {
  const db = admin.firestore();

  // 주문 정보 조회
  const orderDoc = await db.collection("orders").doc(orderId).get();
  if (!orderDoc.exists) {
    throw new Error(`Order not found: ${orderId}`);
  }

  const order = orderDoc.data()!;

  // 이미 송장이 있고 재생성이 아닌 경우
  if (order.invoiceId && !forceRegenerate) {
    return {
      invoiceId: order.invoiceId,
      invoiceNumber: order.invoiceId,
      invoiceUrl: order.invoiceUrl,
      generatedAt: order.invoiceGeneratedAt?.toDate() || new Date(),
    };
  }

  // 판매자 정보 조회
  let sellerData: admin.firestore.DocumentData | undefined;
  if (order.sellerId) {
    const sellerDoc = await db.collection("users").doc(order.sellerId).get();
    sellerData = sellerDoc.data();
  }

  // 구매자 정보 조회
  let buyerData: admin.firestore.DocumentData | undefined;
  if (order.userId) {
    const buyerDoc = await db.collection("users").doc(order.userId).get();
    buyerData = buyerDoc.data();
  }

  // 송장 데이터 구성
  const invoiceNumber = generateInvoiceNumber();
  const items: InvoiceItem[] = (order.items || []).map((item: any) => ({
    name: item.partName || item.name || "Unknown Item",
    quantity: item.quantity || 1,
    unitPrice: item.price || 0,
    totalPrice: (item.price || 0) * (item.quantity || 1),
  }));

  const subtotal = items.reduce((sum, item) => sum + item.totalPrice, 0);
  const shippingFee = order.shippingFee || 0;

  const invoiceData: InvoiceData = {
    orderId,
    invoiceNumber,
    issueDate: new Date(),
    buyerName: order.buyerName || buyerData?.displayName || "Customer",
    buyerEmail: buyerData?.email,
    buyerPhone: order.shippingAddress?.phone,
    buyerAddress: formatAddress(order.shippingAddress),
    sellerName: order.sellerName || sellerData?.displayName || "PiCom Seller",
    sellerBusinessNumber: sellerData?.businessNumber,
    sellerPhone: sellerData?.phone,
    sellerAddress: sellerData?.address,
    items,
    subtotal,
    shippingFee,
    totalAmount: order.totalPrice || subtotal + shippingFee,
    paymentMethod: order.paymentMethod || "Card",
    paidAt: order.paidAt?.toDate(),
  };

  // PDF 생성
  const pdfBuffer = await generateInvoicePDF(invoiceData);

  // Storage 업로드 및 Firestore 문서 생성
  return uploadInvoiceAndCreateDoc(pdfBuffer, invoiceData);
}

/**
 * 주소 객체를 문자열로 변환
 */
function formatAddress(address: any): string {
  if (!address) return "Address not provided";
  if (typeof address === "string") return address;

  const parts = [];
  if (address.zipCode) parts.push(`(${address.zipCode})`);
  if (address.fullAddress) parts.push(address.fullAddress);
  if (address.detailAddress) parts.push(address.detailAddress);

  return parts.join(" ") || "Address not provided";
}

/**
 * 송장 재발행 (기존 송장 무효화 후 새로 생성)
 */
export async function regenerateInvoice(
  orderId: string,
  reason: string
): Promise<GenerateInvoiceResult> {
  const db = admin.firestore();

  // 기존 송장 조회
  const orderDoc = await db.collection("orders").doc(orderId).get();
  if (!orderDoc.exists) {
    throw new Error(`Order not found: ${orderId}`);
  }

  const order = orderDoc.data()!;
  const oldInvoiceId = order.invoiceId;

  // 기존 송장 무효화
  if (oldInvoiceId) {
    await db.collection("invoices").doc(oldInvoiceId).update({
      status: "voided",
      voidedAt: admin.firestore.Timestamp.now(),
      voidReason: reason,
    });
    console.log(`Previous invoice ${oldInvoiceId} voided. Reason: ${reason}`);
  }

  // 새 송장 생성
  return generateInvoiceFromOrder(orderId, true);
}
