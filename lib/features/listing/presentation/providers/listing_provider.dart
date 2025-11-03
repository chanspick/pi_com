// lib/features/listing/presentation/providers/listing_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pi_com/features/listing/data/repositories/listing_repository_impl.dart';
import 'package:pi_com/features/listing/domain/entities/listing_entity.dart';
import 'package:pi_com/features/listing/domain/usecases/get_listings_usecase.dart';
import 'package:pi_com/features/listing/domain/usecases/get_listing_usecase.dart';
import '../../data/datasources/listing_remote_datasource.dart';
import '../../domain/repositories/listing_repository.dart';

class ListingQueryParams {
  final String? category;
  final String? sortBy;

  ListingQueryParams({this.category, this.sortBy});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ListingQueryParams &&
          runtimeType == other.runtimeType &&
          category == other.category &&
          sortBy == other.sortBy;

  @override
  int get hashCode => category.hashCode ^ sortBy.hashCode;
}

final selectedCategoryProvider = StateProvider<String>((ref) => 'All');

final selectedSortProvider = StateProvider<String>((ref) => '최신순');

final listingRemoteDataSourceProvider = Provider<ListingRemoteDataSource>((ref) {
  return ListingRemoteDataSourceImpl(firestore: FirebaseFirestore.instance);
});

final listingRepositoryProvider = Provider<ListingRepository>((ref) {
  return ListingRepositoryImpl(remoteDataSource: ref.watch(listingRemoteDataSourceProvider));
});

final getListingsProvider = Provider<GetListingsUseCase>((ref) {
  return GetListingsUseCase(ref.watch(listingRepositoryProvider));
});

final getListingProvider = Provider<GetListingUseCase>((ref) {
  return GetListingUseCase(repository: ref.watch(listingRepositoryProvider));
});

// ✅ .first 제거 - getListings()가 이제 Future를 반환하므로 바로 사용
final listingsFutureProvider = FutureProvider.autoDispose.family<List<ListingEntity>, ListingQueryParams>((ref, params) {
  return ref.watch(getListingsProvider).call(category: params.category, sortBy: params.sortBy);
});

// ✅ 단일 listing은 Stream으로 유지 (실시간 업데이트 필요할 수 있음)
final listingProvider = StreamProvider.autoDispose.family<ListingEntity, String>((ref, id) {
  return ref.watch(getListingProvider).call(id);
});

// basePartId로 필터링된 listings
final listingsByBasePartIdProvider = FutureProvider.autoDispose.family<List<ListingEntity>, String>((ref, basePartId) async {
  final repository = ref.watch(listingRepositoryProvider);
  return repository.getListingsByBasePartId(basePartId);
});
