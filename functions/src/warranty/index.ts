/**
 * Warranty Module
 * QR 기반 AS 보증 시스템
 */

import {Router} from "express";
import transactionRouter from "./transaction";
import qrGeneratorRouter from "./qr-generator";
import reportGeneratorRouter from "./report-generator";
import paymentRouter from "./payment";
import serviceRouter from "./service";
import userWarrantyRouter from "./user-warranty";

const router = Router();

// 거래 관리 API
router.use("/", transactionRouter);

// QR 코드 생성
router.use("/", qrGeneratorRouter);

// PDF 레포트 생성
router.use("/", reportGeneratorRouter);

// 유저-보증 연결 API
router.use("/", userWarrantyRouter);

// AS 서비스 요청 API (paymentRouter보다 먼저 - /:warrantyId 충돌 방지)
router.use("/", serviceRouter);

// 보증 결제 API (마지막 - /:warrantyId 와일드카드 포함)
router.use("/", paymentRouter);

export default router;

// 타입 내보내기
export * from "./types";
