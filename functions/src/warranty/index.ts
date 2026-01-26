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

const router = Router();

// 거래 관리 API
router.use("/", transactionRouter);

// QR 코드 생성
router.use("/", qrGeneratorRouter);

// PDF 레포트 생성
router.use("/", reportGeneratorRouter);

// 보증 결제 API
router.use("/", paymentRouter);

// AS 서비스 요청 API
router.use("/", serviceRouter);

export default router;

// 타입 내보내기
export * from "./types";
