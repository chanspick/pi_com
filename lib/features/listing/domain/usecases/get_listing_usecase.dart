// lib/features/listing/domain/usecases/get_listing_usecase.dart
import '../entities/listing_entity.dart';
import '../repositories/listing_repository.dart';

class GetListingUseCase {
  final ListingRepository repository;

  GetListingUseCase({required this.repository});

  Stream<ListingEntity> call(String listingId) {
    return repository.getListing(listingId);
  }
}
