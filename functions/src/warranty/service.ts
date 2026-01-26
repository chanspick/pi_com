/**
 * Service Request API
 * AS 요청 처리
 */

import * as admin from "firebase-admin";
import {Router} from "express";
import {
  ServiceRequest,
  ServiceRequestCreate,
  ServiceRequestStatus,
  Warranty,
  generateServiceRequestId,
} from "./types";

const router = Router();
const db = admin.firestore();

// ============================================================================
// POST /warranty/service-request - AS 신청
// ============================================================================

router.post("/service-request", async (req, res) => {
  try {
    const data = req.body as ServiceRequestCreate;

    // 필수 필드 검증
    if (!data.warrantyId || !data.serviceType || !data.issueDescription) {
      res.status(400).json({
        error: "Missing required fields",
        required: ["warrantyId", "serviceType", "issueDescription", "customerName", "customerPhone", "shippingAddress"],
      });
      return;
    }

    if (!data.customerName || !data.customerPhone || !data.shippingAddress) {
      res.status(400).json({
        error: "Missing customer information",
        required: ["customerName", "customerPhone", "shippingAddress"],
      });
      return;
    }

    // 보증 조회
    const warrantyDoc = await db.collection("warranties").doc(data.warrantyId).get();

    if (!warrantyDoc.exists) {
      res.status(404).json({error: "Warranty not found"});
      return;
    }

    const warranty = warrantyDoc.data() as Warranty;

    // 보증 상태 확인
    if (warranty.status !== "active") {
      res.status(400).json({
        error: "Warranty is not active",
        currentStatus: warranty.status,
      });
      return;
    }

    // 보증 만료 확인
    const now = new Date();
    const endDate = warranty.endDate.toDate();

    if (now > endDate) {
      // 보증 만료 처리
      await db.collection("warranties").doc(data.warrantyId).update({
        status: "expired",
        updatedAt: admin.firestore.Timestamp.now(),
      });

      res.status(400).json({
        error: "Warranty has expired",
        endDate: endDate.toISOString(),
      });
      return;
    }

    // 서비스 요청 생성
    const requestId = generateServiceRequestId();
    const timestamp = admin.firestore.Timestamp.now();

    const serviceRequest: ServiceRequest = {
      requestId,
      warrantyId: data.warrantyId,
      transactionId: warranty.transactionId,

      serviceType: data.serviceType,
      issueDescription: data.issueDescription,
      issuePhotoUrls: data.issuePhotoUrls || [],

      customerName: data.customerName,
      customerPhone: data.customerPhone,
      shippingAddress: data.shippingAddress,

      status: "pending",

      requestedAt: timestamp,
      createdAt: timestamp,
      updatedAt: timestamp,
    };

    // Firestore에 저장
    await db.collection("service_requests").doc(requestId).set(serviceRequest);

    // 보증 문서 업데이트
    await db.collection("warranties").doc(data.warrantyId).update({
      status: "claimed",
      serviceRequestIds: admin.firestore.FieldValue.arrayUnion(requestId),
      updatedAt: timestamp,
    });

    console.log(`Service request created: ${requestId} for warranty ${data.warrantyId}`);

    res.status(201).json({
      success: true,
      requestId,
      warrantyId: data.warrantyId,
      status: "pending",
    });
  } catch (error: any) {
    console.error("Service request create error:", error);
    res.status(500).json({
      error: "Failed to create service request",
      message: error.message,
    });
  }
});

// ============================================================================
// GET /warranty/service-request/:id - AS 상태 조회
// ============================================================================

router.get("/service-request/:id", async (req, res) => {
  try {
    const {id} = req.params;

    if (!id) {
      res.status(400).json({error: "Missing request ID"});
      return;
    }

    const doc = await db.collection("service_requests").doc(id).get();

    if (!doc.exists) {
      res.status(404).json({error: "Service request not found"});
      return;
    }

    const serviceRequest = doc.data() as ServiceRequest;

    res.status(200).json(serviceRequest);
  } catch (error: any) {
    console.error("Service request query error:", error);
    res.status(500).json({
      error: "Failed to query service request",
      message: error.message,
    });
  }
});

// ============================================================================
// GET /warranty/service-history/:warrantyId - AS 이력 조회
// ============================================================================

router.get("/service-history/:warrantyId", async (req, res) => {
  try {
    const {warrantyId} = req.params;

    if (!warrantyId) {
      res.status(400).json({error: "Missing warrantyId"});
      return;
    }

    const snapshot = await db
      .collection("service_requests")
      .where("warrantyId", "==", warrantyId)
      .orderBy("createdAt", "desc")
      .get();

    const requests = snapshot.docs.map((doc) => doc.data());

    res.status(200).json({
      warrantyId,
      requests,
      count: requests.length,
    });
  } catch (error: any) {
    console.error("Service history query error:", error);
    res.status(500).json({
      error: "Failed to query service history",
      message: error.message,
    });
  }
});

// ============================================================================
// GET /warranty/service-requests - AS 요청 목록 조회 (Admin)
// ============================================================================

router.get("/service-requests", async (req, res) => {
  try {
    const {status, limit = "50", startAfter} = req.query;

    let query = db.collection("service_requests")
      .orderBy("createdAt", "desc")
      .limit(parseInt(limit as string, 10));

    if (status) {
      query = query.where("status", "==", status);
    }

    if (startAfter) {
      const startDoc = await db.collection("service_requests").doc(startAfter as string).get();
      if (startDoc.exists) {
        query = query.startAfter(startDoc);
      }
    }

    const snapshot = await query.get();

    const requests = snapshot.docs.map((doc) => doc.data());

    res.status(200).json({
      requests,
      count: requests.length,
      hasMore: requests.length === parseInt(limit as string, 10),
    });
  } catch (error: any) {
    console.error("Service requests list error:", error);
    res.status(500).json({
      error: "Failed to list service requests",
      message: error.message,
    });
  }
});

// ============================================================================
// PUT /warranty/service-request/:id/status - 상태 업데이트 (Admin)
// ============================================================================

router.put("/service-request/:id/status", async (req, res) => {
  try {
    const {id} = req.params;
    const {status, handlerId, handlerNote, inboundTrackingNumber, outboundTrackingNumber} = req.body;

    if (!id || !status) {
      res.status(400).json({
        error: "Missing required fields",
        required: ["id", "status"],
      });
      return;
    }

    const validStatuses: ServiceRequestStatus[] = [
      "pending", "reviewing", "approved", "rejected",
      "itemShipping", "itemReceived", "repairing",
      "repaired", "returnShipping", "completed",
    ];

    if (!validStatuses.includes(status)) {
      res.status(400).json({
        error: "Invalid status",
        validStatuses,
      });
      return;
    }

    const docRef = db.collection("service_requests").doc(id);
    const doc = await docRef.get();

    if (!doc.exists) {
      res.status(404).json({error: "Service request not found"});
      return;
    }

    const serviceRequest = doc.data() as ServiceRequest;
    const now = admin.firestore.Timestamp.now();

    const updateData: Partial<ServiceRequest> = {
      status,
      updatedAt: now,
    };

    if (handlerId) updateData.handlerId = handlerId;
    if (handlerNote) updateData.handlerNote = handlerNote;
    if (inboundTrackingNumber) updateData.inboundTrackingNumber = inboundTrackingNumber;
    if (outboundTrackingNumber) updateData.outboundTrackingNumber = outboundTrackingNumber;

    // 완료 상태인 경우
    if (status === "completed") {
      updateData.completedAt = now;

      // 보증 상태도 업데이트
      await db.collection("warranties").doc(serviceRequest.warrantyId).update({
        status: "completed",
        updatedAt: now,
      });
    }

    await docRef.update(updateData);

    console.log(`Service request ${id} status updated to: ${status}`);

    res.status(200).json({
      success: true,
      requestId: id,
      status,
    });
  } catch (error: any) {
    console.error("Service request status update error:", error);
    res.status(500).json({
      error: "Failed to update service request status",
      message: error.message,
    });
  }
});

export default router;
