
// lib/features/cart/data/datasources/cart_remote_datasource_impl.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pi_com/features/cart/data/models/cart_item_model.dart';
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
    return _cartCollection().snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => CartItemModel.fromFirestore(doc.data())).toList();
    });
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
}
