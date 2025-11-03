// lib/features/price_alert/data/repositories/price_alert_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/models/price_alert_model.dart';

/// 가격 알림 리포지토리
class PriceAlertRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 사용자의 가격 알림 목록 실시간 조회
  Stream<List<PriceAlert>> getPriceAlertsStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('priceAlerts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => PriceAlert.fromFirestore(doc)).toList();
    });
  }

  /// 사용자의 활성 가격 알림 목록 조회
  Future<List<PriceAlert>> getActivePriceAlerts(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('priceAlerts')
        .where('isActive', isEqualTo: true)
        .get();

    return snapshot.docs.map((doc) => PriceAlert.fromFirestore(doc)).toList();
  }

  /// 특정 부품에 대한 알림이 이미 있는지 확인
  Future<PriceAlert?> getAlertForBasePart(String userId, String basePartId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('priceAlerts')
        .where('basePartId', isEqualTo: basePartId)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return PriceAlert.fromFirestore(snapshot.docs.first);
  }

  /// 가격 알림 추가
  Future<String> addPriceAlert({
    required String userId,
    required String basePartId,
    required String partName,
    required int targetPrice,
    required int currentPrice,
  }) async {
    final docRef = await _firestore
        .collection('users')
        .doc(userId)
        .collection('priceAlerts')
        .add({
      'userId': userId,
      'basePartId': basePartId,
      'partName': partName,
      'targetPrice': targetPrice,
      'priceAtCreation': currentPrice,
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
      'triggeredAt': null,
      'lastCheckedAt': null,
    });

    return docRef.id;
  }

  /// 가격 알림 수정 (목표 가격 변경)
  Future<void> updateTargetPrice(
    String userId,
    String alertId,
    int newTargetPrice,
  ) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('priceAlerts')
        .doc(alertId)
        .update({
      'targetPrice': newTargetPrice,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// 가격 알림 활성화/비활성화
  Future<void> toggleAlertStatus(
    String userId,
    String alertId,
    bool isActive,
  ) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('priceAlerts')
        .doc(alertId)
        .update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// 가격 알림 삭제
  Future<void> deletePriceAlert(String userId, String alertId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('priceAlerts')
        .doc(alertId)
        .delete();
  }

  /// 알림 트리거 (가격 도달 시 호출)
  Future<void> triggerAlert(String userId, String alertId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('priceAlerts')
        .doc(alertId)
        .update({
      'triggeredAt': FieldValue.serverTimestamp(),
      'isActive': false, // 알림 발생 후 비활성화
    });
  }

  /// 마지막 체크 시간 업데이트 (Cloud Function에서 사용)
  Future<void> updateLastChecked(String userId, String alertId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('priceAlerts')
        .doc(alertId)
        .update({
      'lastCheckedAt': FieldValue.serverTimestamp(),
    });
  }
}
