// lib/features/listing/domain/usecases/get_listings_usecase.dart

import 'package:pi_com/features/listing/domain/entities/listing_entity.dart';
import 'package:pi_com/features/listing/domain/repositories/listing_repository.dart';

class GetListingsUseCase {
  final ListingRepository repository;

  GetListingsUseCase(this.repository);

  // ✅ Stream → Future로 변경, ListingEntity 사용
  Future<List<ListingEntity>> call({String? category, String? sortBy}) async {
    return await repository.getListings(category: category, sortBy: sortBy);
  }
}
