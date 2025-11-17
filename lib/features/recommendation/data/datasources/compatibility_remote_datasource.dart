import 'package:pi_com/core/models/base_part_model.dart';
import 'package:pi_com/features/listing/domain/entities/listing_entity.dart';

/// 호환성 Remote DataSource 인터페이스
abstract class CompatibilityRemoteDataSource {
  /// Firestore에서 호환되는 BasePart 목록을 스트리밍합니다
  ///
  /// [category] 찾을 부품 카테고리
  /// [filters] 필터 조건 (socket, memoryType 등)
  ///
  /// Returns: 호환되는 BasePart 목록 스트림
  Stream<List<BasePart>> getCompatibleBaseParts({
    required PartCategory category,
    Map<String, dynamic>? filters,
  });

  /// Firestore listings 컬렉션에서 구매 가능한 상품 목록을 가져옵니다
  ///
  /// [basePartId] 조회할 base part ID
  /// [status] listing 상태 (기본값: available)
  ///
  /// Returns: 구매 가능한 listing 목록
  Future<List<ListingEntity>> getAvailableListings({
    required String basePartId,
    String status = 'available',
  });

  /// Firestore base_parts 컬렉션에서 특정 카테고리의 모든 부품을 가져옵니다
  /// (listingCount 무관 - PSU 등 가상 상품용)
  ///
  /// [category] 조회할 부품 카테고리
  ///
  /// Returns: 해당 카테고리의 모든 BasePart 목록
  Future<List<BasePart>> getAvailableBaseParts(String category);
}
