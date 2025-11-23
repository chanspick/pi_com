// lib/features/listing/data/repositories/listing_repository_impl.dart

import 'package:pi_com/features/listing/data/datasources/listing_remote_datasource.dart';
import 'package:pi_com/features/listing/domain/entities/listing_entity.dart';
import 'package:pi_com/features/listing/domain/repositories/listing_repository.dart';

class ListingRepositoryImpl implements ListingRepository {
  final ListingRemoteDataSource remoteDataSource;

  ListingRepositoryImpl({required this.remoteDataSource});

  @override
  Stream<ListingEntity> getListing(String listingId) {
    return remoteDataSource.getListing(listingId).map((model) => model.toEntity());
  }

  @override
  // ✅ Stream → Future, Listing → ListingEntity
  Future<List<ListingEntity>> getListings({
    String? category,
    String? sortBy,
    String? searchQuery,
    bool includeAllStatuses = false,
  }) async {
    final models = await remoteDataSource.getListings(
      category: category,
      sortBy: sortBy,
      searchQuery: searchQuery,
      includeAllStatuses: includeAllStatuses,
    );
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  // 🆕 페이지네이션 지원
  Future<ListingPaginationEntity> getListingsPaginated({
    String? category,
    String? sortBy,
    String? searchQuery,
    bool includeAllStatuses = false,
    int limit = 20,
    dynamic lastDocument,
    bool useCache = true,
  }) async {
    final result = await remoteDataSource.getListingsPaginated(
      category: category,
      sortBy: sortBy,
      searchQuery: searchQuery,
      includeAllStatuses: includeAllStatuses,
      limit: limit,
      lastDocument: lastDocument,
      useCache: useCache,
    );

    return ListingPaginationEntity(
      listings: result.listings.map((model) => model.toEntity()).toList(),
      lastDocument: result.lastDocument,
      hasMore: result.hasMore,
    );
  }

  @override
  Future<List<ListingEntity>> getListingsByBasePartId(String basePartId, {String? sortBy}) async {
    final models = await remoteDataSource.getListingsByBasePartId(basePartId, sortBy: sortBy);
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<void> updateListingStatus(String listingId, ListingStatus status) {
    return remoteDataSource.updateListingStatus(listingId, status);
  }
}
