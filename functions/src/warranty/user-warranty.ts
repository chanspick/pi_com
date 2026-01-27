/**
 * User-Warranty Linking API
 * 유저-보증 연결 및 내 보증 목록 조회
 */

import * as admin from "firebase-admin";
import {Router, Request, Response, NextFunction} from "express";

const router = Router();
const db = admin.firestore();

// ============================================================================
// Firebase Auth 미들웨어
// ============================================================================

interface AuthRequest extends Request {
  user?: admin.auth.DecodedIdToken;
}

async function authMiddleware(
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    res.status(401).json({error: "Missing or invalid authorization header"});
    return;
  }

  const idToken = authHeader.split("Bearer ")[1];

  try {
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    req.user = decodedToken;
    next();
  } catch (error: any) {
    console.error("Auth verification error:", error.message);
    res.status(401).json({error: "Invalid or expired token"});
  }
}

// ============================================================================
// POST /warranty/link-user - 보증에 유저 연결
// ============================================================================

router.post("/link-user", authMiddleware, async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.user!.uid;
    const {qrCode} = req.body;

    if (!qrCode) {
      res.status(400).json({error: "Missing qrCode"});
      return;
    }

    // qrCode로 거래 조회
    const txSnapshot = await db
      .collection("verification_transactions")
      .where("qrCode", "==", qrCode)
      .limit(1)
      .get();

    if (txSnapshot.empty) {
      res.status(404).json({error: "Transaction not found"});
      return;
    }

    const txDoc = txSnapshot.docs[0];
    const transaction = txDoc.data();

    // warrantyId가 있으면 warranty 문서에 userId 연결
    if (transaction.warrantyId) {
      const warrantyRef = db.collection("warranties").doc(transaction.warrantyId);
      const warrantyDoc = await warrantyRef.get();

      if (warrantyDoc.exists) {
        const warranty = warrantyDoc.data()!;

        // 이미 다른 유저가 연결된 경우
        if (warranty.userId && warranty.userId !== userId) {
          res.status(409).json({
            error: "Warranty already linked to another user",
          });
          return;
        }

        await warrantyRef.update({
          userId,
          userLinkedAt: admin.firestore.Timestamp.now(),
          updatedAt: admin.firestore.Timestamp.now(),
        });
      }
    }

    // transaction에도 userId 연결
    await txDoc.ref.update({
      userId,
      userLinkedAt: admin.firestore.Timestamp.now(),
      updatedAt: admin.firestore.Timestamp.now(),
    });

    console.log(`User ${userId} linked to warranty via qrCode ${qrCode}`);

    res.status(200).json({
      success: true,
      qrCode,
      transactionId: transaction.transactionId,
      warrantyId: transaction.warrantyId || null,
    });
  } catch (error: any) {
    console.error("Link user error:", error);
    res.status(500).json({
      error: "Failed to link user",
      message: error.message,
    });
  }
});

// ============================================================================
// GET /warranty/my-warranties - 내 보증 목록
// ============================================================================

router.get("/my-warranties", authMiddleware, async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.user!.uid;

    // userId로 연결된 거래 조회
    const txSnapshot = await db
      .collection("verification_transactions")
      .where("userId", "==", userId)
      .orderBy("createdAt", "desc")
      .limit(50)
      .get();

    const warranties = [];

    for (const txDoc of txSnapshot.docs) {
      const tx = txDoc.data();

      let warranty = null;
      if (tx.warrantyId) {
        const warrantyDoc = await db.collection("warranties").doc(tx.warrantyId).get();
        if (warrantyDoc.exists) {
          warranty = warrantyDoc.data();
        }
      }

      warranties.push({
        transactionId: tx.transactionId,
        qrCode: tx.qrCode,
        transactionType: tx.transactionType || "single",
        // 제품 정보
        partCategory: tx.partCategory,
        brand: tx.brand,
        modelName: tx.modelName,
        bundleName: tx.bundleName,
        items: tx.items?.map((item: any) => ({
          partCategory: item.partCategory,
          brand: item.brand,
          modelName: item.modelName,
        })),
        // 스코어
        conditionScore: tx.conditionScore,
        conditionGrade: tx.conditionGrade,
        baseWarrantyMonths: tx.baseWarrantyMonths,
        // 가격
        salePrice: tx.salePrice,
        saleDate: tx.saleDate,
        // 문서
        warrantyPdfUrl: tx.warrantyPdfUrl,
        qrCodeImageUrl: tx.qrCodeImageUrl,
        // 보증 상태
        warrantyId: tx.warrantyId || null,
        warrantyStatus: warranty?.status || null,
        totalWarrantyMonths: warranty?.totalWarrantyMonths || tx.baseWarrantyMonths,
        totalWarrantyEndDate: warranty?.totalWarrantyEndDate || null,
      });
    }

    res.status(200).json({
      warranties,
      count: warranties.length,
    });
  } catch (error: any) {
    console.error("My warranties error:", error);
    res.status(500).json({
      error: "Failed to fetch warranties",
      message: error.message,
    });
  }
});

export default router;
