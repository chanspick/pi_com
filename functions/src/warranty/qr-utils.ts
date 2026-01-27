/**
 * QR Code Utility
 * QR PNG 버퍼 생성 유틸
 */

import * as QRCode from "qrcode";

const QR_BASE_URL = process.env.WARRANTY_WEB_URL || "https://picom.site";

/**
 * QR 코드 URL 생성
 */
export function getQrUrl(qrCode: string): string {
  return `${QR_BASE_URL}/warranty/${qrCode}`;
}

/**
 * QR 코드 PNG 버퍼 생성
 */
export async function generateQrPngBuffer(
  qrCode: string,
  options?: { width?: number; margin?: number }
): Promise<Buffer> {
  const qrUrl = getQrUrl(qrCode);
  return QRCode.toBuffer(qrUrl, {
    type: "png",
    width: options?.width || 300,
    margin: options?.margin || 2,
    color: {
      dark: "#000000",
      light: "#FFFFFF",
    },
    errorCorrectionLevel: "M",
  });
}
