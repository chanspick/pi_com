import 'package:pi_com/core/models/base_part_model.dart';
import 'package:pi_com/features/recommendation/domain/entities/spec_profile_entity.dart';

/// 호환성 체크 Repository 인터페이스
abstract class CompatibilityRepository {
  /// 현재 선택된 부품 조합을 기반으로 호환되는 BasePart 목록을 스트리밍합니다
  ///
  /// [category] 찾을 부품 카테고리
  /// [currentSelection] 현재 선택된 부품 맵
  /// [specProfile] 사양 프로필 (선택 사항)
  ///
  /// Returns: 호환되는 BasePart 목록 스트림
  Stream<List<BasePart>> getCompatibleBaseParts({
    required PartCategory category,
    required Map<PartCategory, BasePart?> currentSelection,
    SpecProfileEntity? specProfile,
  });
}
