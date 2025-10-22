// lib/features/sell_request/data/datasources/sell_request_datasource.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/models/sell_request_model.dart'; // ✅ 그대로
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
        .set(sellRequest.toMap()); // ✅ toFirestore() 아님, toMap()
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
        .where('sellerId', isEqualTo: userId) // ✅ userId → sellerId
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
    String? adminNotes, // ✅ adminMemo → adminNotes
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
}
