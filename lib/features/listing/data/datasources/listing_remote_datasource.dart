// lib/features/listing/data/datasources/listing_remote_datasource.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/listing_model.dart';
import '../../domain/entities/listing_entity.dart';

abstract class ListingRemoteDataSource {
  Stream<ListingModel> getListing(String listingId);

  // ✅ Stream → Future로 변경
  Future<List<ListingModel>> getListings({String? category, String? sortBy, String? searchQuery});

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
    // 로깅 추가: 조회하는 listingId 확인 + 호출 스택
    print('🔍 [ListingDataSource] Fetching listing with ID: $listingId');
    print('📞 [ListingDataSource] Called from:\n${StackTrace.current.toString().split('\n').take(5).join('\n')}');

    return _firestore
        .collection('listings')
        .doc(listingId)
        .snapshots(includeMetadataChanges: false)  // 메타데이터 변경 무시
        .map((doc) {
      // 문서 존재 여부 확인
      if (!doc.exists) {
        print('❌ [ListingDataSource] Document not found: $listingId');
        print('💡 Tip: Firebase Console에서 listings/$listingId 경로를 확인하세요');
        throw Exception('Listing not found: $listingId');
      }

      // 문서 데이터 확인
      print('✅ [ListingDataSource] Document found: $listingId');

      try {
        // 데이터 파싱 시도
        final model = ListingModel.fromFirestore(doc);
        print('✅ [ListingDataSource] Successfully parsed listing: ${model.listingId}');
        return model;
      } catch (e, stackTrace) {
        // 파싱 에러 상세 로그
        print('❌ [ListingDataSource] Parse error for listing $listingId');
        print('Error: $e');
        print('Data: ${doc.data()}');
        print('StackTrace: $stackTrace');
        throw Exception('Failed to parse listing $listingId: $e');
      }
    });
  }

  @override
  // ✅✅✅ 이 부분을 꼭 수정하세요!
  Future<List<ListingModel>> getListings({String? category, String? sortBy, String? searchQuery}) async {
    print('🔍 [ListingDataSource] Fetching listings with category: $category, sortBy: $sortBy, searchQuery: $searchQuery');
    print('🌐 [ListingDataSource] Force fetching from SERVER (no cache)');
    print('📊 [ListingDataSource] Firestore instance: ${_firestore.hashCode}');
    print('⚙️  [ListingDataSource] Firestore settings: ${_firestore.settings}');

    // available 상태인 리스트만 가져오는 기본 쿼리
    final snapshot = await _firestore
        .collection('listings')
        .where('status', isEqualTo: 'available')
        .get(const GetOptions(source: Source.server));

    var listings = snapshot.docs.map((doc) {
      try {
        return ListingModel.fromFirestore(doc);
      } catch (e) {
        print('❌ [ListingDataSource] Failed to parse listing ${doc.id}: $e');
        rethrow;
      }
    }).toList();

    // 검색어 필터링 (클라이언트 사이드)
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      listings = listings.where((listing) {
        final modelNameLower = listing.modelName.toLowerCase();
        final brandLower = listing.brand.toLowerCase();
        final combinedName = '$brandLower $modelNameLower';

        return modelNameLower.contains(query) ||
               brandLower.contains(query) ||
               combinedName.contains(query);
      }).toList();
      print('🔍 [ListingDataSource] Filtered to ${listings.length} listings matching: $searchQuery');
    }

    // 카테고리 필터 (All이 아닐 때만)
    if (category != null && category != 'All') {
      listings = listings.where((listing) => listing.category == category).toList();
      print('📂 [ListingDataSource] Filtered to ${listings.length} listings in category: $category');
    }

    // 정렬
    if (sortBy == '낮은 가격순') {
      listings.sort((a, b) => a.price.compareTo(b.price));
    } else if (sortBy == '높은 가격순') {
      listings.sort((a, b) => b.price.compareTo(a.price));
    } else {
      // 기본값: 최신순
      listings.sort((a, b) => b.createdAt.toDate()
          .compareTo(a.createdAt.toDate()));
    }

    print('✅ [ListingDataSource] Returning ${listings.length} listings');
    print('📋 [ListingDataSource] First 10 listings:');
    for (var i = 0; i < listings.length && i < 10; i++) {
      final listing = listings[i];
      print('  ${i + 1}. ID: ${listing.listingId}');
      print('     Brand: ${listing.brand}, Model: ${listing.modelName}');
      print('     Status: ${listing.status}, Price: ${listing.price}');
      print('     CreatedAt: ${listing.createdAt}');
    }

    return listings;
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

    // 🔥 강제로 서버에서 가져오기 (캐시 무시)
    final snapshot = await query.get(const GetOptions(source: Source.server));

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
