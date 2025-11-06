// lib/features/admin/data/datasources/admin_sell_request_datasource.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/models/sell_request_model.dart';
import '../../../../core/models/listing_model.dart';
import '../../../../core/constants/firebase_constants.dart';

class AdminSellRequestDataSource {
  final FirebaseFirestore _firestore;

  AdminSellRequestDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// 승인 프로세스 (Transaction)
  Future<void> approveSellRequest({
    required String requestId,
    required int finalPrice,
    required double finalConditionScore,
    // ❌ brand 파라미터 제거
    String? adminNotes,
  }) async {
    await _firestore.runTransaction((transaction) async {
      // 1. SellRequest 조회
      final requestRef = _firestore
          .collection(FirebaseConstants.sellRequestsCollection)
          .doc(requestId);
      final requestDoc = await transaction.get(requestRef);

      if (!requestDoc.exists) {
        throw Exception('SellRequest not found');
      }

      final sellRequest = SellRequest.fromFirestore(requestDoc);

      if (sellRequest.status != SellRequestStatus.pending) {
        throw Exception('SellRequest is not pending');
      }

      // ✅ SellRequest에서 brand 가져오기
      final brand = sellRequest.brand;

      // 2. Listing 생성
      final listingId = _firestore
          .collection(FirebaseConstants.listingsCollection)
          .doc()
          .id;

      final listing = Listing(
        listingId: listingId,
        sellerId: sellRequest.sellerId,
        partId: sellRequest.partId,
        basePartId: sellRequest.basePartId,
        brand: brand, // ✅ SellRequest에서 가져온 brand 사용
        modelName: sellRequest.modelName,
        price: finalPrice,
        conditionScore: finalConditionScore,
        imageUrls: List<String>.from(sellRequest.imageUrls), // ✅ 타입 명시
        status: ListingStatus.available,
        createdAt: DateTime.now(),
        soldAt: null,
        category: sellRequest.category,
      );

      final listingRef = _firestore
          .collection(FirebaseConstants.listingsCollection)
          .doc(listingId);

      transaction.set(listingRef, listing.toMap());

      // 3. BasePart 가격 통계 업데이트
      await _updateBasePriceStatistics(
        transaction: transaction,
        basePartId: sellRequest.basePartId,
        newPrice: finalPrice,
      );

      // 4. SellRequest 상태 업데이트
      transaction.update(requestRef, {
        'status': SellRequestStatus.approved.name,
        'adminNotes': adminNotes,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// BasePart 가격 통계 업데이트
  Future<void> _updateBasePriceStatistics({
    required Transaction transaction,
    required String basePartId,
    required int newPrice,
  }) async {
    // 같은 BasePart의 모든 활성 Listing 조회
    final listingsSnapshot = await _firestore
        .collection(FirebaseConstants.listingsCollection)
        .where('basePartId', isEqualTo: basePartId)
        .where('status', isEqualTo: ListingStatus.available.name)
        .get();

    final prices = listingsSnapshot.docs
        .map((doc) => (doc.data()['price'] as num).toInt())
        .toList()
      ..add(newPrice);

    if (prices.isEmpty) return;

    final lowestPrice = prices.reduce((a, b) => a < b ? a : b);
    final averagePrice = prices.reduce((a, b) => a + b) ~/ prices.length;

    // BasePart 업데이트
    final basePartRef = _firestore
        .collection(FirebaseConstants.basePartsCollection)
        .doc(basePartId);

    transaction.update(basePartRef, {
      'lowestPrice': lowestPrice,
      'averagePrice': averagePrice,
      'listingCount': FieldValue.increment(1),
    });
  }

  /// 반려 프로세스
  Future<void> rejectSellRequest({
    required String requestId,
    required String rejectReason,
  }) async {
    await _firestore
        .collection(FirebaseConstants.sellRequestsCollection)
        .doc(requestId)
        .update({
      'status': SellRequestStatus.rejected.name,
      'adminNotes': rejectReason,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// 🆕 대기 중인 SellRequest 조회 (Stream)
  Stream<List<SellRequest>> getPendingSellRequests() {
    return _firestore
        .collection(FirebaseConstants.sellRequestsCollection)
        .where('status', isEqualTo: SellRequestStatus.pending.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => SellRequest.fromFirestore(doc))
          .toList();
    });
  }

  /// ID로 SellRequest 조회
  Future<SellRequest?> getSellRequestById(String requestId) async {
    final doc = await _firestore
        .collection(FirebaseConstants.sellRequestsCollection)
        .doc(requestId)
        .get();

    if (doc.exists) {
      return SellRequest.fromFirestore(doc);
    } else {
      return null;
    }
  }
}
