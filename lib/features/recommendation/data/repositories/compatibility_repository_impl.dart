import 'package:pi_com/core/models/base_part_model.dart';
import 'package:pi_com/features/recommendation/data/datasources/compatibility_remote_datasource.dart';
import 'package:pi_com/features/recommendation/domain/entities/spec_profile_entity.dart';
import 'package:pi_com/features/recommendation/domain/repositories/compatibility_repository.dart';

/// 호환성 Repository 구현체
class CompatibilityRepositoryImpl implements CompatibilityRepository {
  final CompatibilityRemoteDataSource _remoteDataSource;

  CompatibilityRepositoryImpl({
    required CompatibilityRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  @override
  Stream<List<BasePart>> getCompatibleBaseParts({
    required PartCategory category,
    required Map<PartCategory, BasePart?> currentSelection,
    SpecProfileEntity? specProfile,
  }) {
    // 호환성 필터 생성
    final filters = <String, dynamic>{};

    // 1. 메인보드 선택 시: CPU 소켓과 일치하는 메인보드 필터링
    if (category == PartCategory.mainboard) {
      final cpu = currentSelection[PartCategory.cpu];
      if (cpu != null && cpu.socket != null && cpu.socket!.isNotEmpty) {
        filters['socket'] = cpu.socket;
      }
    }

    // 2. RAM 선택 시: 메인보드의 메모리 타입과 일치하는 RAM 필터링
    if (category == PartCategory.ram) {
      final mainboard = currentSelection[PartCategory.mainboard];
      if (mainboard != null && mainboard.memoryType != null && mainboard.memoryType!.isNotEmpty) {
        filters['memoryType'] = mainboard.memoryType;
      }
    }

    // 3. CPU 선택 시: 메인보드의 소켓과 일치하는 CPU 필터링
    if (category == PartCategory.cpu) {
      final mainboard = currentSelection[PartCategory.mainboard];
      if (mainboard != null && mainboard.socket != null && mainboard.socket!.isNotEmpty) {
        filters['socket'] = mainboard.socket;
      }
    }

    // 4. 케이스 선택 시: 메인보드 폼팩터와 호환되는 케이스 필터링
    if (category == PartCategory.pccase) {
      final mainboard = currentSelection[PartCategory.mainboard];
      if (mainboard != null && mainboard.formFactor != null && mainboard.formFactor!.isNotEmpty) {
        filters['formFactor'] = mainboard.formFactor;
      }
    }

    return _remoteDataSource.getCompatibleBaseParts(
      category: category,
      filters: filters,
    );
  }
}
