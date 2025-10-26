// lib/features/sell_request/data/datasources/sell_request_datasource.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/models/sell_request_model.dart';
import '../../../../core/constants/firebase_constants.dart';

class SellRequestDataSource {
  final FirebaseFirestore _firestore;

  SellRequestDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // ==================== 사용자용 ====================

  /// SellRequest 생성
  Future<void> createSellRequest(SellRequest sellRequest) async {
    await _firestore
        .collection(FirebaseConstants.sellRequestsCollection)
        .doc(sellRequest.requestId)
        .set(sellRequest.toMap());
  }

  /// SellRequest 조회 (ID)
  Future<SellRequest?> getSellRequest(String requestId) async {
    final doc = await _firestore
        .collection(FirebaseConstants.sellRequestsCollection)
        .doc(requestId)
        .get();
    if (!doc.exists) return null;
    return SellRequest.fromFirestore(doc);
  }

  /// 사용자의 SellRequest 목록 (실시간)
  Stream<List<SellRequest>> getUserSellRequestsStream(String userId) {
    return _firestore
        .collection(FirebaseConstants.sellRequestsCollection)
        .where('sellerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => SellRequest.fromFirestore(doc))
        .toList());
  }

  /// SellRequest 삭제
  Future<void> deleteSellRequest(String requestId) async {
    await _firestore
        .collection(FirebaseConstants.sellRequestsCollection)
        .doc(requestId)
        .delete();
  }

  // ==================== Admin용 ====================

  /// 모든 SellRequest 조회 (실시간)
  Stream<List<SellRequest>> getAllSellRequestsStream() {
    return _firestore
        .collection(FirebaseConstants.sellRequestsCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => SellRequest.fromFirestore(doc))
        .toList());
  }

  /// 상태별 SellRequest 조회 (실시간)
  Stream<List<SellRequest>> getSellRequestsByStatusStream(
      SellRequestStatus status,
      ) {
    return _firestore
        .collection(FirebaseConstants.sellRequestsCollection)
        .where('status', isEqualTo: status.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => SellRequest.fromFirestore(doc))
        .toList());
  }

  /// SellRequest 상태 업데이트 (Admin)
  Future<void> updateSellRequestStatus({
    required String requestId,
    required SellRequestStatus status,
    String? listingId,
    String? adminNotes,
  }) async {
    final updates = <String, dynamic>{
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (status == SellRequestStatus.approved && listingId != null) {
      updates['listingId'] = listingId;
    }

    if (adminNotes != null) {
      updates['adminNotes'] = adminNotes;
    }

    await _firestore
        .collection(FirebaseConstants.sellRequestsCollection)
        .doc(requestId)
        .update(updates);
  }

  // ==================== Batch 작업 ====================

  /// 여러 SellRequest를 Batch로 생성 (트랜잭션)
  /// 완제품 PC 판매 시 여러 부품을 한 번에 등록
  Future<void> createMultipleSellRequests(
      List<SellRequest> sellRequests,
      ) async {
    if (sellRequests.isEmpty) return;

    final batch = _firestore.batch();

    for (var sellRequest in sellRequests) {
      final docRef = _firestore
          .collection(FirebaseConstants.sellRequestsCollection)
          .doc(sellRequest.requestId);
      batch.set(docRef, sellRequest.toMap());
    }

    await batch.commit();
  }
}
