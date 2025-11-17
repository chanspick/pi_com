import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pi_com/core/models/base_part_model.dart';
import 'package:pi_com/features/listing/domain/entities/listing_entity.dart';
import 'package:pi_com/features/listing/data/models/listing_model.dart';
import 'package:pi_com/features/recommendation/data/datasources/compatibility_remote_datasource.dart';

/// 호환성 Remote DataSource 구현체
class CompatibilityRemoteDataSourceImpl implements CompatibilityRemoteDataSource {
  final FirebaseFirestore _firestore;

  CompatibilityRemoteDataSourceImpl({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<BasePart>> getCompatibleBaseParts({
    required PartCategory category,
    Map<String, dynamic>? filters,
  }) {
    // base_parts 컬렉션에서 쿼리 시작
    Query query = _firestore
        .collection('base_parts')
        .where('category', isEqualTo: category.name)
        .where('listingCount', isGreaterThan: 0);

    // 필터 적용
    if (filters != null) {
      filters.forEach((key, value) {
        if (value != null && value.toString().isNotEmpty) {
          query = query.where(key, isEqualTo: value);
        }
      });
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => BasePart.fromFirestore(doc)).toList();
    });
  }


  @override
  Future<List<ListingEntity>> getAvailableListings({
    required String basePartId,
    String status = 'available',
  }) async {
    try {
      final query = await _firestore
          .collection('listings')
          .where('basePartId', isEqualTo: basePartId)
          .where('status', isEqualTo: status)
          .orderBy('price', descending: false) // 가격 낮은 순
          .get();

      final listings = query.docs
          .map((doc) => ListingModel.fromFirestore(doc).toEntity())
          .toList();

      print('📦 [DEBUG] Found ${listings.length} available listings for basePartId=$basePartId');
      return listings;
    } catch (e) {
      // 에러 발생 시 빈 리스트 반환
      print('❌ [ERROR] getAvailableListings failed for basePartId=$basePartId: $e');
      return [];
    }
  }

  @override
  Future<List<BasePart>> getAvailableBaseParts(String category) async {
    try {
      final query = await _firestore
          .collection('base_parts')
          .where('category', isEqualTo: category)
          .orderBy('wattage', descending: false) // PSU는 wattage 낮은 순
          .get();

      final parts = query.docs
          .map((doc) => BasePart.fromFirestore(doc))
          .toList();

      print('📦 [DEBUG] Found ${parts.length} base_parts for category=$category');
      return parts;
    } catch (e) {
      // wattage 인덱스가 없을 수 있으므로 orderBy 없이 재시도
      try {
        final query = await _firestore
            .collection('base_parts')
            .where('category', isEqualTo: category)
            .get();

        final parts = query.docs
            .map((doc) => BasePart.fromFirestore(doc))
            .toList();

        print('📦 [DEBUG] Found ${parts.length} base_parts for category=$category (no orderBy)');
        return parts;
      } catch (e2) {
        print('❌ [ERROR] getAvailableBaseParts failed for category=$category: $e2');
        return [];
      }
    }
  }
}
