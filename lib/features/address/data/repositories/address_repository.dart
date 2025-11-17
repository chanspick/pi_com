// lib/features/address/data/repositories/address_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/address_model.dart';
import '../../domain/entities/address_entity.dart';

class AddressRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 사용자의 모든 배송지 조회 (Stream)
  Stream<List<AddressEntity>> getAddressesStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('addresses')
        .orderBy('isDefault', descending: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AddressModel.fromFirestore(doc).toEntity())
          .toList();
    });
  }

  /// 사용자의 모든 배송지 조회 (Future)
  Future<List<AddressEntity>> getAddresses(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('addresses')
        .orderBy('isDefault', descending: true)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => AddressModel.fromFirestore(doc).toEntity())
        .toList();
  }

  /// 기본 배송지 조회
  Future<AddressEntity?> getDefaultAddress(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('addresses')
        .where('isDefault', isEqualTo: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return AddressModel.fromFirestore(snapshot.docs.first).toEntity();
  }

  /// 배송지 추가
  Future<void> addAddress(String userId, AddressEntity address) async {
    final addressRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('addresses')
        .doc();

    final addressWithId = address.copyWith(addressId: addressRef.id);

    // 기본 배송지로 설정하는 경우, 기존 기본 배송지 해제
    if (address.isDefault) {
      await _clearDefaultAddress(userId);
    }

    await addressRef.set(AddressModel.fromEntity(addressWithId).toFirestore());
  }

  /// 배송지 수정
  Future<void> updateAddress(String userId, AddressEntity address) async {
    // 기본 배송지로 변경하는 경우, 기존 기본 배송지 해제
    if (address.isDefault) {
      await _clearDefaultAddress(userId, except: address.addressId);
    }

    final updatedAddress = address.copyWith(updatedAt: DateTime.now());

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('addresses')
        .doc(address.addressId)
        .update(AddressModel.fromEntity(updatedAddress).toFirestore());
  }

  /// 배송지 삭제
  Future<void> deleteAddress(String userId, String addressId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('addresses')
        .doc(addressId)
        .delete();
  }

  /// 기본 배송지로 설정
  Future<void> setDefaultAddress(String userId, String addressId) async {
    // 기존 기본 배송지 해제
    await _clearDefaultAddress(userId, except: addressId);

    // 새로운 기본 배송지 설정
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('addresses')
        .doc(addressId)
        .update({
      'isDefault': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// 기존 기본 배송지 해제 (내부 헬퍼 함수)
  Future<void> _clearDefaultAddress(String userId, {String? except}) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('addresses')
        .where('isDefault', isEqualTo: true)
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      if (except != null && doc.id == except) continue;
      batch.update(doc.reference, {
        'isDefault': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }
}
