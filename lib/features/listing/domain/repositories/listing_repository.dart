// lib/features/listing/domain/repositories/listing_repository.dart

import 'package:pi_com/features/listing/domain/entities/listing_entity.dart';

abstract class ListingRepository {
  Stream<ListingEntity> getListing(String listingId);

  // ✅ Stream → Future로 변경, Listing → ListingEntity로 수정
  Future<List<ListingEntity>> getListings({String? category, String? sortBy});

  // basePartId로 필터링된 active listings 가져오기
  Future<List<ListingEntity>> getListingsByBasePartId(String basePartId, {String? sortBy});

  Future<void> updateListingStatus(String listingId, ListingStatus status);
}
