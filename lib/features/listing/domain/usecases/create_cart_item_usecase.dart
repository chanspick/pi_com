// lib/features/listing/domain/usecases/create_cart_item_usecase.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../entities/listing_entity.dart';
import 'package:pi_com/core/models/listing_model.dart';
import 'package:pi_com/features/cart/domain/entities/cart_item_entity.dart';

class CreateCartItemUseCase {
  final FirebaseFirestore _firestore;

  CreateCartItemUseCase({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<CartItemEntity> call(ListingEntity listingEntity) async {
    if (listingEntity.isSold) {
      throw Exception('판매 완료된 상품입니다.');
    }

    // Firestore에서 전체 Listing 정보 조회 (shippingCostSellerRatio 포함)
    final listingDoc = await _firestore
        .collection('listings')
        .doc(listingEntity.listingId)
        .get();

    if (!listingDoc.exists) {
      throw Exception('매물 정보를 찾을 수 없습니다.');
    }

    final listing = Listing.fromFirestore(listingDoc);

    // Firestore에서 판매자 정보 조회
    final sellerDoc = await _firestore
        .collection('users')
        .doc(listing.sellerId)
        .get();
    final sellerName = sellerDoc.data()?['displayName'] ?? '알 수 없음';

    return CartItemEntity(
      listingId: listing.listingId,
      sellerId: listing.sellerId,
      sellerName: sellerName,
      partName: '${listing.brand} ${listing.modelName}',
      category: listing.category ?? 'UNKNOWN',
      price: listing.price,
      quantity: 1,
      imageUrl: listing.imageUrls.isNotEmpty ? listing.imageUrls.first : '',
      shippingCostSellerRatio: listing.shippingCostSellerRatio,
      addedAt: DateTime.now(),
    );
  }
}
