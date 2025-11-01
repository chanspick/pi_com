
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
      throw Exception('User not logged in');
    }
    return _firestore.collection('users').doc(_userId).collection('cart');
  }

  @override
  Future<void> addToCart(CartItemModel item) {
    return _cartCollection().doc(item.productId).set(item.toFirestore());
  }

  @override
  Stream<List<CartItemModel>> getCartItems() {
    return _cartCollection().snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => CartItemModel.fromFirestore(doc.data())).toList();
    });
  }

  @override
  Future<void> removeFromCart(String productId) {
    return _cartCollection().doc(productId).delete();
  }

  @override
  Future<void> updateCartItemQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      return removeFromCart(productId);
    }
    return _cartCollection().doc(productId).update({'quantity': quantity});
  }
}
