// lib/features/listing/data/repositories/listing_repository_impl.dart
import '../../domain/entities/listing_entity.dart';
import '../../domain/repositories/listing_repository.dart';
import '../datasources/listing_remote_datasource.dart';

class ListingRepositoryImpl implements ListingRepository {
  final ListingRemoteDataSource remoteDataSource;

  ListingRepositoryImpl({required this.remoteDataSource});

  @override
  Stream<ListingEntity> getListing(String listingId) {
    return remoteDataSource
        .getListing(listingId)
        .map((model) => model.toEntity()); // Model → Entity 변환
  }

  @override
  Stream<List<ListingEntity>> getListings({String? category, String? sortBy}) {
    return remoteDataSource
        .getListings(category: category, sortBy: sortBy)
        .map((models) => models.map((m) => m.toEntity()).toList()); // Model → Entity 변환
  }

  @override
  Future<void> updateListingStatus(String listingId, ListingStatus status) {
    return remoteDataSource.updateListingStatus(listingId, status);
  }
}
