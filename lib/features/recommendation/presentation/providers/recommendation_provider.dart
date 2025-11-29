import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pi_com/core/constants/fixed_price_parts.dart';
import 'package:pi_com/core/models/base_part_model.dart';
import 'package:pi_com/core/repositories/base_part_repository.dart';
import 'package:pi_com/features/recommendation/data/datasources/compatibility_remote_datasource.dart';
import 'package:pi_com/features/recommendation/data/datasources/compatibility_remote_datasource_impl.dart';
import 'package:pi_com/features/recommendation/data/datasources/recommendation_local_datasource.dart';
import 'package:pi_com/features/recommendation/data/datasources/recommendation_local_datasource_impl.dart';
import 'package:pi_com/features/recommendation/data/repositories/compatibility_repository_impl.dart';
import 'package:pi_com/features/recommendation/data/repositories/recommendation_repository_impl.dart';
import 'package:pi_com/features/recommendation/data/services/recommendation_engine_service_impl.dart';
import 'package:pi_com/features/recommendation/domain/repositories/compatibility_repository.dart';
import 'package:pi_com/features/recommendation/domain/repositories/recommendation_repository.dart';
import 'package:pi_com/features/recommendation/domain/services/recommendation_engine_service.dart';
import 'package:pi_com/features/recommendation/domain/usecases/get_compatible_parts_usecase.dart';
import 'package:pi_com/features/recommendation/domain/usecases/get_recommendation_usecase.dart';
import 'package:pi_com/features/recommendation/domain/entities/spec_profile_entity.dart';
import 'package:pi_com/features/recommendation/domain/entities/recommendation_entity.dart';
import 'package:pi_com/features/recommendation/domain/entities/pc_build_entity.dart';

// ============================================================================
// Data Layer Providers
// ============================================================================

/// Recommendation Local DataSource Provider
final recommendationLocalDataSourceProvider = Provider<RecommendationLocalDataSource>((ref) {
  return RecommendationLocalDataSourceImpl();
});

/// Compatibility Remote DataSource Provider
final compatibilityRemoteDataSourceProvider = Provider<CompatibilityRemoteDataSource>((ref) {
  return CompatibilityRemoteDataSourceImpl(
    firestore: FirebaseFirestore.instance,
  );
});

/// BasePart Repository Provider (Core)
final basePartRepositoryProvider = Provider<BasePartRepository>((ref) {
  return BasePartRepository(firestore: FirebaseFirestore.instance);
});

/// Recommendation Engine Service Provider (Phase 2)
final recommendationEngineServiceProvider = Provider<RecommendationEngineService>((ref) {
  final dataSource = ref.watch(compatibilityRemoteDataSourceProvider);
  return RecommendationEngineServiceImpl(
    dataSource: dataSource,
  );
});

/// Recommendation Repository Provider
final recommendationRepositoryProvider = Provider<RecommendationRepository>((ref) {
  final localDataSource = ref.watch(recommendationLocalDataSourceProvider);
  final basePartRepository = ref.watch(basePartRepositoryProvider);
  final recommendationEngine = ref.watch(recommendationEngineServiceProvider);

  return RecommendationRepositoryImpl(
    localDataSource: localDataSource,
    basePartRepository: basePartRepository,
    recommendationEngine: recommendationEngine,
    firestore: FirebaseFirestore.instance,
  );
});

/// Compatibility Repository Provider
final compatibilityRepositoryProvider = Provider<CompatibilityRepository>((ref) {
  final remoteDataSource = ref.watch(compatibilityRemoteDataSourceProvider);
  return CompatibilityRepositoryImpl(
    remoteDataSource: remoteDataSource,
  );
});

// ============================================================================
// Use Case Providers
// ============================================================================

/// 추천 견적 가져오기 Use Case Provider
final getRecommendationUseCaseProvider = Provider<GetRecommendationUseCase>((ref) {
  final repository = ref.watch(recommendationRepositoryProvider);
  return GetRecommendationUseCase(repository: repository);
});

/// 호환되는 부품 가져오기 Use Case Provider
final getCompatiblePartsUseCaseProvider = Provider<GetCompatiblePartsUseCase>((ref) {
  final repository = ref.watch(compatibilityRepositoryProvider);
  return GetCompatiblePartsUseCase(repository: repository);
});

// ============================================================================
// State Providers
// ============================================================================

/// 현재 추천 결과 Provider (Phase 1 - 정적)
final currentRecommendationProvider = StateProvider<
    ({SpecProfileEntity profile, RecommendationEntity recommendation})?
>((ref) => null);

/// 추천 로딩 상태 Provider
final isLoadingRecommendationProvider = StateProvider<bool>((ref) => false);

/// 추천 에러 메시지 Provider
final recommendationErrorProvider = StateProvider<String?>((ref) => null);

// ============================================================================
// Phase 2 - Dynamic Recommendation Providers
// ============================================================================

/// 현재 동적 추천 결과 Provider (Phase 2 - 동적)
final dynamicRecommendationsProvider = StateProvider<List<PcBuildEntity>?>((ref) => null);

/// 동적 추천 로딩 상태 Provider
final isDynamicLoadingProvider = StateProvider<bool>((ref) => false);

/// 동적 추천 에러 메시지 Provider
final dynamicErrorProvider = StateProvider<String?>((ref) => null);

// ============================================================================
// Phase 2 - Fixed Price Parts Selection Providers (정가제 부품 선택)
// ============================================================================

/// PSU 목록 Provider (Firestore에서 조회)
final availablePsuListProvider = FutureProvider<List<BasePart>>((ref) async {
  final dataSource = ref.watch(compatibilityRemoteDataSourceProvider);
  return await dataSource.getAvailableBaseParts('psu');
});

/// 선택된 쿨러 타입 Provider
final selectedCoolerTypeProvider = StateProvider<CoolerType>((ref) => CoolerType.budget);

/// 선택된 PSU Provider
final selectedPsuProvider = StateProvider<BasePart?>((ref) => null);

/// 정가제 부품 선택 완료 여부
final fixedPartsConfirmedProvider = StateProvider<bool>((ref) => false);

/// 정가제 부품 총액 계산 Provider
final fixedPartsTotalProvider = Provider<int>((ref) {
  final coolerType = ref.watch(selectedCoolerTypeProvider);
  final psu = ref.watch(selectedPsuProvider);

  final coolerPrice = getCoolerInfo(coolerType).price;
  final psuPrice = psu?.lowestPrice ?? 0;

  return kFixedCasePrice + coolerPrice + psuPrice;
});
