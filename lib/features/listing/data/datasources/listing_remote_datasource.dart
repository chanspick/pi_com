// lib/features/listing/data/datasources/listing_remote_datasource.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/utils/app_logger.dart';
import '../models/listing_model.dart';
import '../../domain/entities/listing_entity.dart';

abstract class ListingRemoteDataSource {
  Stream<ListingModel> getListing(String listingId);

  // ✅ Stream → Future로 변경
  Future<List<ListingModel>> getListings({
    String? category,
    String? sortBy,
    String? searchQuery,
    bool includeAllStatuses = false,
  });

  // 🆕 페이지네이션을 지원하는 getListings
  Future<ListingPaginationResult> getListingsPaginated({
    String? category,
    String? sortBy,
    String? searchQuery,
    bool includeAllStatuses = false,
    int limit = 20,
    DocumentSnapshot? lastDocument,
    bool useCache = true,
  });

  // basePartId로 필터링된 active listings만 가져오기
  Future<List<ListingModel>> getListingsByBasePartId(String basePartId, {String? sortBy});

  Future<void> updateListingStatus(String listingId, ListingStatus status);
}

// 🆕 페이지네이션 결과 클래스
class ListingPaginationResult {
  final List<ListingModel> listings;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;

  ListingPaginationResult({
    required this.listings,
    this.lastDocument,
    required this.hasMore,
  });
}

class ListingRemoteDataSourceImpl implements ListingRemoteDataSource {
  final FirebaseFirestore _firestore;

  ListingRemoteDataSourceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<ListingModel> getListing(String listingId) {
    // 로깅 추가: 조회하는 listingId 확인 + 호출 스택
    AppLogger.d('Fetching listing with ID: $listingId', tag: 'ListingDataSource');
    AppLogger.d('Called from:\n${StackTrace.current.toString().split('\n').take(5).join('\n')}', tag: 'ListingDataSource');

    return _firestore
        .collection('listings')
        .doc(listingId)
        .snapshots(includeMetadataChanges: false)  // 메타데이터 변경 무시
        .map((doc) {
      // 문서 존재 여부 확인
      if (!doc.exists) {
        AppLogger.e('Document not found: $listingId', tag: 'ListingDataSource');
        AppLogger.d('Tip: Firebase Console에서 listings/$listingId 경로를 확인하세요', tag: 'ListingDataSource');
        throw Exception('Listing not found: $listingId');
      }

      // 문서 데이터 확인
      AppLogger.d('Document found: $listingId', tag: 'ListingDataSource');

      try {
        // 데이터 파싱 시도
        final model = ListingModel.fromFirestore(doc);
        AppLogger.d('Successfully parsed listing: ${model.listingId}', tag: 'ListingDataSource');
        return model;
      } catch (e, stackTrace) {
        // 파싱 에러 상세 로그
        AppLogger.e('Parse error for listing $listingId', tag: 'ListingDataSource');
        AppLogger.e('Error: $e', tag: 'ListingDataSource');
        AppLogger.d('Data: ${doc.data()}', tag: 'ListingDataSource');
        AppLogger.d('StackTrace: $stackTrace', tag: 'ListingDataSource');
        throw Exception('Failed to parse listing $listingId: $e');
      }
    });
  }

  @override
  // ⚠️ DEPRECATED: 기존 메서드 (하위 호환성 유지)
  // 새 코드는 getListingsPaginated()를 사용하세요
  Future<List<ListingModel>> getListings({
    String? category,
    String? sortBy,
    String? searchQuery,
    bool includeAllStatuses = false,
  }) async {
    AppLogger.w('[DEPRECATED] getListings() called - use getListingsPaginated() instead', tag: 'ListingDataSource');

    // 🎯 Admin용: includeAllStatuses면 더 많이 가져오기
    final limit = includeAllStatuses ? 500 : 20;

    // ⚠️ 중고 거래 플랫폼 특성상 실시간성 중요 → 캐시 사용 안 함
    final result = await getListingsPaginated(
      category: category,
      sortBy: sortBy,
      searchQuery: searchQuery,
      includeAllStatuses: includeAllStatuses,
      limit: limit,
      useCache: false, // ✅ 실시간성 보장 (판매 완료 상품 즉시 반영)
    );

    return result.listings;
  }

  @override
  // 🆕 페이지네이션 지원 버전 (비용 최적화)
  Future<ListingPaginationResult> getListingsPaginated({
    String? category,
    String? sortBy,
    String? searchQuery,
    bool includeAllStatuses = false,
    int limit = 20,
    DocumentSnapshot? lastDocument,
    bool useCache = true,
  }) async {
    AppLogger.d('Fetching listings (paginated)', tag: 'ListingDataSource');
    AppLogger.d('Category: $category, Sort: $sortBy, Search: $searchQuery', tag: 'ListingDataSource');
    AppLogger.d('Limit: $limit, UseCache: $useCache, HasLastDoc: ${lastDocument != null}', tag: 'ListingDataSource');

    // 쿼리 빌더 시작
    Query query = _firestore.collection('listings');

    // 1️⃣ Status 필터 (서버 사이드)
    if (!includeAllStatuses) {
      query = query.where('status', isEqualTo: 'available');
    }

    // 2️⃣ Category 필터 (서버 사이드)
    if (category != null && category != 'All') {
      query = query.where('category', isEqualTo: category);
    }

    // 3️⃣ 정렬 (서버 사이드)
    // ⚠️ Firestore 제약: orderBy 필드에 인덱스 필요
    if (sortBy == '낮은 가격순') {
      query = query.orderBy('price', descending: false);
    } else if (sortBy == '높은 가격순') {
      query = query.orderBy('price', descending: true);
    } else {
      // 기본값: 최신순
      query = query.orderBy('createdAt', descending: true);
    }

    // 4️⃣ 페이지네이션 (startAfter)
    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    // 5️⃣ Limit (+1로 hasMore 체크)
    query = query.limit(limit + 1);

    // 6️⃣ 캐싱 전략
    final source = useCache ? Source.serverAndCache : Source.server;
    final snapshot = await query.get(GetOptions(source: source));

    AppLogger.d('Fetched ${snapshot.docs.length} documents from ${source.name}', tag: 'ListingDataSource');

    // 7️⃣ hasMore 체크
    final hasMore = snapshot.docs.length > limit;
    final docs = hasMore ? snapshot.docs.sublist(0, limit) : snapshot.docs;

    // 8️⃣ 모델 변환
    var listings = docs.map((doc) {
      try {
        return ListingModel.fromFirestore(doc);
      } catch (e) {
        AppLogger.e('Failed to parse listing ${doc.id}: $e', tag: 'ListingDataSource');
        rethrow;
      }
    }).toList();

    // 9️⃣ 검색어 필터링 (클라이언트 사이드)
    // ⚠️ Firestore는 full-text search 미지원
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
      AppLogger.d('Filtered to ${listings.length} listings matching: $searchQuery', tag: 'ListingDataSource');
    }

    AppLogger.d('Returning ${listings.length} listings, hasMore: $hasMore', tag: 'ListingDataSource');

    return ListingPaginationResult(
      listings: listings,
      lastDocument: docs.isEmpty ? null : docs.last,
      hasMore: hasMore,
    );
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

    // 🔍 디버깅: 현재 listing 상태 확인
    final currentStatus = listingData['status'];
    final sellerId = listingData['sellerId'];
    AppLogger.d('═══════════════════════════════════════════════════════', tag: 'ListingDataSource');
    AppLogger.d('updateListingStatus listingId: $listingId', tag: 'ListingDataSource');
    AppLogger.d('현재 status: $currentStatus', tag: 'ListingDataSource');
    AppLogger.d('sellerId: $sellerId', tag: 'ListingDataSource');
    AppLogger.d('변경하려는 status: ${status.name}', tag: 'ListingDataSource');
    AppLogger.d('═══════════════════════════════════════════════════════', tag: 'ListingDataSource');

    // Listing 상태 업데이트
    try {
      await _firestore.collection('listings').doc(listingId).update({
        'status': status.name,
        if (status == ListingStatus.sold) 'soldAt': FieldValue.serverTimestamp(),
      });
      AppLogger.i('Firestore 업데이트 성공 for listingId: $listingId', tag: 'ListingDataSource');
    } catch (e) {
      AppLogger.e('Firestore 업데이트 실패: $e', tag: 'ListingDataSource');
      rethrow;
    }

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
