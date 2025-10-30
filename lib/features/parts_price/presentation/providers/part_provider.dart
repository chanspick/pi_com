// lib/features/parts_price/presentation/providers/part_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/part_remote_datasource.dart';
import '../../data/repositories/part_repository_impl.dart';
import '../../domain/repositories/part_repository.dart';
import '../../domain/usecases/get_part_by_id_usecase.dart';
import '../../domain/usecases/get_base_parts_by_category_usecase.dart';
import '../../domain/usecases/get_price_history_usecase.dart';
import '../../domain/usecases/search_base_parts_usecase.dart';
import '../../domain/entities/part_entity.dart';
import '../../domain/entities/base_part_entity.dart';
import '../../domain/entities/price_point_entity.dart';

// DataSource Provider
final partRemoteDataSourceProvider = Provider<PartRemoteDataSource>((ref) {
  return PartRemoteDataSourceImpl();
});

// Repository Provider
final partRepositoryProvider = Provider<PartRepository>((ref) {
  return PartRepositoryImpl(
    remoteDataSource: ref.watch(partRemoteDataSourceProvider),
  );
});

// UseCase Providers
final getPartByIdUseCaseProvider = Provider<GetPartByIdUseCase>((ref) {
  return GetPartByIdUseCase(repository: ref.watch(partRepositoryProvider));
});

final getBasePartsByCategoryUseCaseProvider = Provider<GetBasePartsByCategoryUseCase>((ref) {
  return GetBasePartsByCategoryUseCase(repository: ref.watch(partRepositoryProvider));
});

final getPriceHistoryUseCaseProvider = Provider<GetPriceHistoryUseCase>((ref) {
  return GetPriceHistoryUseCase(repository: ref.watch(partRepositoryProvider));
});

final searchBasePartsUseCaseProvider = Provider<SearchBasePartsUseCase>((ref) {
  return SearchBasePartsUseCase(repository: ref.watch(partRepositoryProvider));
});

// State Providers
final selectedPartCategoryProvider = StateProvider<String>((ref) => 'cpu');

// Stream Providers
final basePartsStreamProvider = StreamProvider.family<List<BasePartEntity>, String>((ref, category) {
  final useCase = ref.watch(getBasePartsByCategoryUseCaseProvider);
  return useCase(category);
});

// Future Providers
final partFutureProvider = FutureProvider.family<PartEntity?, String>((ref, partId) {
  final useCase = ref.watch(getPartByIdUseCaseProvider);
  return useCase(partId);
});

final priceHistoryFutureProvider = FutureProvider.family<List<PricePointEntity>, String>((ref, partId) {
  final useCase = ref.watch(getPriceHistoryUseCaseProvider);
  return useCase(partId);
});
