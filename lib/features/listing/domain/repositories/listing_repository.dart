// lib/features/listing/domain/repositories/listing_repository.dart
import '../entities/listing_entity.dart';

abstract class ListingRepository {
  Stream<ListingEntity> getListing(String listingId);
  Stream<List<ListingEntity>> getListings({String? category, String? sortBy});
  Future<void> updateListingStatus(String listingId, ListingStatus status);
}
