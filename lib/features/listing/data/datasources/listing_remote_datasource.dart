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
  Future<void> updateListingStatus(String listingId, ListingStatus status) {
    return _firestore.collection('listings').doc(listingId).update({
      'status': status.name,
    });
  }
}
