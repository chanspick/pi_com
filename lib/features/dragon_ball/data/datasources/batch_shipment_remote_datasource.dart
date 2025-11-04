// lib/features/dragon_ball/data/datasources/batch_shipment_remote_datasource.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pi_com/core/models/batch_shipment_model.dart';

/// 일괄 배송 Remote DataSource 인터페이스
abstract class BatchShipmentRemoteDataSource {
  /// 사용자의 일괄 배송 목록 스트림
  Stream<List<BatchShipmentModel>> getUserBatchShipments(String userId);

  /// 특정 일괄 배송 조회
  Future<BatchShipmentModel?> getBatchShipment(String batchShipmentId);

  /// 일괄 배송 생성
  Future<String> createBatchShipment(BatchShipmentModel batchShipment);

  /// 일괄 배송 업데이트
  Future<void> updateBatchShipment(BatchShipmentModel batchShipment);

  /// 일괄 배송 삭제
  Future<void> deleteBatchShipment(String batchShipmentId);

  /// 대기 중인 일괄 배송 조회
  Future<List<BatchShipmentModel>> getPendingBatchShipments(String userId);

  /// 배송 중인 일괄 배송 조회
  Future<List<BatchShipmentModel>> getShippingBatchShipments(String userId);
}

/// 일괄 배송 Remote DataSource 구현
class BatchShipmentRemoteDataSourceImpl implements BatchShipmentRemoteDataSource {
  final FirebaseFirestore _firestore;

  BatchShipmentRemoteDataSourceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<BatchShipmentModel>> getUserBatchShipments(String userId) {
    return _firestore
        .collection('batchShipments')
        .where('userId', isEqualTo: userId)
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        try {
          return BatchShipmentModel.fromFirestore(doc);
        } catch (e) {
          throw Exception('Failed to parse BatchShipment: $e');
        }
      }).toList();
    });
  }

  @override
  Future<BatchShipmentModel?> getBatchShipment(String batchShipmentId) async {
    try {
      final doc = await _firestore
          .collection('batchShipments')
          .doc(batchShipmentId)
          .get();

      if (!doc.exists) return null;

      return BatchShipmentModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to get BatchShipment: $e');
    }
  }

  @override
  Future<String> createBatchShipment(BatchShipmentModel batchShipment) async {
    try {
      final docRef = await _firestore
          .collection('batchShipments')
          .add(batchShipment.toMap());

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create BatchShipment: $e');
    }
  }

  @override
  Future<void> updateBatchShipment(BatchShipmentModel batchShipment) async {
    try {
      await _firestore
          .collection('batchShipments')
          .doc(batchShipment.batchShipmentId)
          .update(batchShipment.toMap());
    } catch (e) {
      throw Exception('Failed to update BatchShipment: $e');
    }
  }

  @override
  Future<void> deleteBatchShipment(String batchShipmentId) async {
    try {
      await _firestore
          .collection('batchShipments')
          .doc(batchShipmentId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete BatchShipment: $e');
    }
  }

  @override
  Future<List<BatchShipmentModel>> getPendingBatchShipments(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('batchShipments')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .orderBy('requestedAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return BatchShipmentModel.fromFirestore(doc);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get pending BatchShipments: $e');
    }
  }

  @override
  Future<List<BatchShipmentModel>> getShippingBatchShipments(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('batchShipments')
          .where('userId', isEqualTo: userId)
          .where('status', whereIn: ['processing', 'shipped'])
          .orderBy('requestedAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return BatchShipmentModel.fromFirestore(doc);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get shipping BatchShipments: $e');
    }
  }
}
