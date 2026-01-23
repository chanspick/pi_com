
// lib/features/cart/data/datasources/cart_remote_datasource_impl.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pi_com/features/cart/data/models/cart_item_model.dart';
import 'package:pi_com/core/utils/app_logger.dart';
import 'cart_remote_datasource.dart';

class CartRemoteDataSourceImpl implements CartRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CartRemoteDataSourceImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> _cartCollection() {
    if (_userId == null) {
      throw Exception('로그인이 필요합니다');
    }
    return _firestore.collection('users').doc(_userId).collection('cart');
  }

  @override
  Future<void> addToCart(CartItemModel item) async {
    // 장바구니에 추가 (listingId를 문서 ID로 사용)
    // 여러 판매자의 상품을 동시에 담을 수 있도록 제한 제거
    return _cartCollection().doc(item.listingId).set(item.toFirestore());
  }

  @override
  Stream<List<CartItemModel>> getCartItems() {
    try {
      if (_userId == null) {
        throw Exception('로그인이 필요합니다');
      }
      AppLogger.d('장바구니 조회 중... userId: $_userId', tag: 'Cart');
      return _cartCollection().snapshots().map((snapshot) {
        AppLogger.d('장바구니 아이템 개수: ${snapshot.docs.length}', tag: 'Cart');
        return snapshot.docs.map((doc) => CartItemModel.fromFirestore(doc.data())).toList();
      }).handleError((error) {
        AppLogger.e('장바구니 조회 에러: $error', tag: 'Cart');
        throw error;
      });
    } catch (e) {
      AppLogger.e('장바구니 조회 실패: $e', tag: 'Cart');
      rethrow;
    }
  }

  @override
  Future<void> removeFromCart(String listingId) {
    return _cartCollection().doc(listingId).delete();
  }

  @override
  Future<void> updateCartItemQuantity(String listingId, int quantity) {
    if (quantity <= 0) {
      return removeFromCart(listingId);
    }
    return _cartCollection().doc(listingId).update({'quantity': quantity});
  }

  @override
  Future<void> clearCart() async {
    final batch = _firestore.batch();
    final cartItems = await _cartCollection().get();
    for (final doc in cartItems.docs) {
      batch.delete(doc.reference);
    }
    return batch.commit();
  }

  @override
  Future<List<CartItemModel>> removeSoldItemsFromCart() async {
    final List<CartItemModel> removedItems = [];

    try {
      // 1. 장바구니 아이템 가져오기
      final cartSnapshot = await _cartCollection().get();
      if (cartSnapshot.docs.isEmpty) {
        return removedItems;
      }

      // 2. 각 아이템의 listing 상태 확인
      for (final cartDoc in cartSnapshot.docs) {
        final cartItem = CartItemModel.fromFirestore(cartDoc.data());
        final listingId = cartItem.listingId;

        // listing 문서 가져오기
        final listingDoc = await _firestore
            .collection('listings')
            .doc(listingId)
            .get();

        // listing이 없거나 sold 상태인 경우 장바구니에서 제거
        if (!listingDoc.exists) {
          AppLogger.w('Listing not found, removing from cart: $listingId', tag: 'Cart');
          await removeFromCart(listingId);
          removedItems.add(cartItem);
        } else {
          final status = listingDoc.data()?['status'] as String?;
          if (status != 'available') {
            AppLogger.w('Listing is $status, removing from cart: $listingId', tag: 'Cart');
            await removeFromCart(listingId);
            removedItems.add(cartItem);
          }
        }
      }

      if (removedItems.isNotEmpty) {
        AppLogger.i('Removed ${removedItems.length} sold items from cart', tag: 'Cart');
      }

      return removedItems;
    } catch (e) {
      AppLogger.e('Error removing sold items: $e', tag: 'Cart');
      rethrow;
    }
  }
}
