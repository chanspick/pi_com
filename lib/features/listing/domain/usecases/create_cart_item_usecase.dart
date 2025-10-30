// lib/features/listing/domain/usecases/create_cart_item_usecase.dart
import '../entities/listing_entity.dart';
import '../entities/cart_item_entity.dart';

class CreateCartItemUseCase {
  CartItemEntity call(ListingEntity listing) {
    if (!listing.isActive) {
      throw Exception('판매 완료된 상품입니다.');
    }

    return CartItemEntity(
      productId: listing.listingId,
      productName: listing.modelName,
      price: listing.price.toDouble(),
      quantity: 1,
      imageUrl: listing.imageUrls.isNotEmpty ? listing.imageUrls.first : '',
      addedAt: DateTime.now(),
    );
  }
}
