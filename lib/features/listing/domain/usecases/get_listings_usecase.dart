// lib/features/listing/domain/usecases/get_listings_usecase.dart
import '../entities/listing_entity.dart';
import '../repositories/listing_repository.dart';

class GetListingsUseCase {
  final ListingRepository repository;

  GetListingsUseCase({required this.repository});

  Stream<List<ListingEntity>> call({String? category, String? sortBy}) {
    return repository.getListings(category: category, sortBy: sortBy);
  }
}
