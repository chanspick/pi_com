// lib/features/listing/data/datasources/listing_remote_datasource.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/listing_model.dart';
import '../../domain/entities/listing_entity.dart';

abstract class ListingRemoteDataSource {
  Stream<ListingModel> getListing(String listingId);

  // ✅ Stream → Future로 변경
  Future<List<ListingModel>> getListings({String? category, String? sortBy});

  // basePartId로 필터링된 active listings만 가져오기
  Future<List<ListingModel>> getListingsByBasePartId(String basePartId, {String? sortBy});

  Future<void> updateListingStatus(String listingId, ListingStatus status);
}

class ListingRemoteDataSourceImpl implements ListingRemoteDataSource {
  final FirebaseFirestore _firestore;

  ListingRemoteDataSourceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<ListingModel> getListing(String listingId) {
    return _firestore
        .collection('listings')
        .doc(listingId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) {
        throw Exception('Listing not found');
      }
      return ListingModel.fromFirestore(doc);
    });
  }

  @override
  // ✅✅✅ 이 부분을 꼭 수정하세요!
  Future<List<ListingModel>> getListings({String? category, String? sortBy}) async {
    Query query = _firestore.collection('listings').where('status', isEqualTo: 'available');

    // 카테고리 필터 (All이 아닐 때만)
    if (category != null && category != 'All') {
      query = query.where('category', isEqualTo: category);
    }

    // 정렬
    if (sortBy == '낮은 가격순') {
      query = query.orderBy('price', descending: false);
    } else if (sortBy == '높은 가격순') {
      query = query.orderBy('price', descending: true);
    } else {
      // 기본값: 최신순
      query = query.orderBy('createdAt', descending: true);
    }

    // ✅✅✅ snapshots() → get()으로 변경!
    final snapshot = await query.get();



    return snapshot.docs.map((doc) {
      try {

        return ListingModel.fromFirestore(doc);
      } catch (e) {

        rethrow;
      }
    }).toList();
  }

  @override
  Future<List<ListingModel>> getListingsByBasePartId(String basePartId, {String? sortBy}) async {
    // available 상태이고 basePartId가 일치하는 매물만 가져오기
    Query query = _firestore
        .collection('listings')
        .where('status', isEqualTo: 'available')
        .where('basePartId', isEqualTo: basePartId);

    // 정렬
    if (sortBy == '낮은 가격순') {
      query = query.orderBy('price', descending: false);
    } else if (sortBy == '높은 가격순') {
      query = query.orderBy('price', descending: true);
    } else {
      // 기본값: 최신순
      query = query.orderBy('createdAt', descending: true);
    }

    final snapshot = await query.get();

    return snapshot.docs.map((doc) {
      try {
        return ListingModel.fromFirestore(doc);
      } catch (e) {
        rethrow;
      }
    }).toList();
  }

  @override
  Future<void> updateListingStatus(String listingId, ListingStatus status) async {
    // Listing 정보 먼저 가져오기 (basePartId 필요)
    final listingDoc = await _firestore.collection('listings').doc(listingId).get();

    if (!listingDoc.exists) {
      throw Exception('Listing not found');
    }

    final listingData = listingDoc.data()!;
    final basePartId = listingData['basePartId'] as String?;

    // Listing 상태 업데이트
    await _firestore.collection('listings').doc(listingId).update({
      'status': status.name,
      if (status == ListingStatus.sold) 'soldAt': FieldValue.serverTimestamp(),
    });

    // 판매 완료된 경우, BasePart 통계 재계산
    if (status == ListingStatus.sold && basePartId != null) {
      await _recalculateBasePriceStatistics(basePartId);
    }
  }

  /// BasePart 가격 통계 재계산 (AVAILABLE 상태만 포함)
  Future<void> _recalculateBasePriceStatistics(String basePartId) async {
    // 같은 BasePart의 모든 AVAILABLE Listing만 조회
    final listingsSnapshot = await _firestore
        .collection('listings')
        .where('basePartId', isEqualTo: basePartId)
        .where('status', isEqualTo: 'available')
        .get();

    final prices = listingsSnapshot.docs
        .map((doc) => (doc.data()['price'] as num).toInt())
        .toList();

    // AVAILABLE 매물이 없는 경우
    if (prices.isEmpty) {
      await _firestore.collection('base_parts').doc(basePartId).update({
        'lowestPrice': 0,
        'averagePrice': 0,
        'listingCount': 0,
      });
      return;
    }

    // 가격 통계 계산
    final lowestPrice = prices.reduce((a, b) => a < b ? a : b);
    final averagePrice = prices.reduce((a, b) => a + b) ~/ prices.length;

    // BasePart 업데이트
    await _firestore.collection('base_parts').doc(basePartId).update({
      'lowestPrice': lowestPrice,
      'averagePrice': averagePrice,
      'listingCount': prices.length,
    });
  }
}
