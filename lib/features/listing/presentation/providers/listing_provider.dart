// lib/features/listing/presentation/providers/listing_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/listing_remote_datasource.dart';
import '../../data/repositories/listing_repository_impl.dart';
import '../../domain/repositories/listing_repository.dart';
import '../../domain/usecases/get_listing_usecase.dart';
import '../../domain/usecases/get_listings_usecase.dart';
import '../../domain/usecases/create_cart_item_usecase.dart';
import '../../domain/usecases/validate_purchase_usecase.dart';
import '../../domain/entities/listing_entity.dart';

// DataSource Provider
final listingRemoteDataSourceProvider = Provider<ListingRemoteDataSource>((ref) {
  return ListingRemoteDataSourceImpl();
});

// Repository Provider
final listingRepositoryProvider = Provider<ListingRepository>((ref) {
  return ListingRepositoryImpl(
    remoteDataSource: ref.watch(listingRemoteDataSourceProvider),
  );
});

// UseCase Providers
final getListingUseCaseProvider = Provider<GetListingUseCase>((ref) {
  return GetListingUseCase(repository: ref.watch(listingRepositoryProvider));
});

final getListingsUseCaseProvider = Provider<GetListingsUseCase>((ref) {
  return GetListingsUseCase(repository: ref.watch(listingRepositoryProvider));
});

final createCartItemUseCaseProvider = Provider<CreateCartItemUseCase>((ref) {
  return CreateCartItemUseCase();
});

final validatePurchaseUseCaseProvider = Provider<ValidatePurchaseUseCase>((ref) {
  return ValidatePurchaseUseCase();
});

// Stream Providers (Entity 반환)
final listingStreamProvider = StreamProvider.family<ListingEntity, String>((ref, listingId) {
  final useCase = ref.watch(getListingUseCaseProvider);
  return useCase(listingId);
});

final listingsStreamProvider = StreamProvider.family<List<ListingEntity>, ListingQueryParams>((ref, params) {
  final useCase = ref.watch(getListingsUseCaseProvider);
  return useCase(category: params.category, sortBy: params.sortBy);
});

// State Providers
final selectedCategoryProvider = StateProvider<String>((ref) => 'All');
final selectedSortProvider = StateProvider<String>((ref) => '최신순');

// Query Parameters
class ListingQueryParams {
  final String? category;
  final String? sortBy;

  ListingQueryParams({this.category, this.sortBy});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is ListingQueryParams &&
              category == other.category &&
              sortBy == other.sortBy;

  @override
  int get hashCode => category.hashCode ^ sortBy.hashCode;
}
