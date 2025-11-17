import 'package:pi_com/core/models/base_part_model.dart';
import 'package:pi_com/features/recommendation/domain/entities/spec_profile_entity.dart';
import 'package:pi_com/features/recommendation/domain/repositories/compatibility_repository.dart';

/// 호환되는 부품 가져오기 Use Case
class GetCompatiblePartsUseCase {
  final CompatibilityRepository _repository;

  GetCompatiblePartsUseCase({
    required CompatibilityRepository repository,
  }) : _repository = repository;

  /// 현재 선택된 부품 조합을 기반으로 호환되는 BasePart 목록을 스트리밍합니다
  ///
  /// [category] 찾을 부품 카테고리
  /// [currentSelection] 현재 선택된 부품 맵
  /// [specProfile] 사양 프로필 (선택 사항)
  ///
  /// Returns: 호환되는 BasePart 목록 스트림
  Stream<List<BasePart>> call({
    required PartCategory category,
    required Map<PartCategory, BasePart?> currentSelection,
    SpecProfileEntity? specProfile,
  }) {
    return _repository.getCompatibleBaseParts(
      category: category,
      currentSelection: currentSelection,
      specProfile: specProfile,
    );
  }
}
