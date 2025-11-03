// lib/features/price_alert/presentation/providers/price_alert_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/price_alert_repository.dart';
import '../../../../core/models/price_alert_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// PriceAlertRepository Provider
final priceAlertRepositoryProvider = Provider<PriceAlertRepository>((ref) {
  return PriceAlertRepository();
});

/// 사용자의 가격 알림 목록 Stream Provider
final priceAlertsProvider = StreamProvider.autoDispose<List<PriceAlert>>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) {
    return Stream.value([]);
  }

  final repository = ref.watch(priceAlertRepositoryProvider);
  return repository.getPriceAlertsStream(currentUser.uid);
});

/// 활성 가격 알림 개수 Provider
final activePriceAlertsCountProvider = Provider.autoDispose<int>((ref) {
  final alertsAsync = ref.watch(priceAlertsProvider);

  return alertsAsync.when(
    data: (alerts) => alerts.where((alert) => alert.isActive).length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// 가격 알림 액션 클래스
class PriceAlertActions {
  final PriceAlertRepository _repository;
  final String _userId;

  PriceAlertActions(this._repository, this._userId);

  /// 가격 알림 추가
  Future<String> addAlert({
    required String basePartId,
    required String partName,
    required int targetPrice,
    required int currentPrice,
  }) async {
    return await _repository.addPriceAlert(
      userId: _userId,
      basePartId: basePartId,
      partName: partName,
      targetPrice: targetPrice,
      currentPrice: currentPrice,
    );
  }

  /// 목표 가격 수정
  Future<void> updateTargetPrice(String alertId, int newPrice) async {
    await _repository.updateTargetPrice(_userId, alertId, newPrice);
  }

  /// 알림 활성화/비활성화 토글
  Future<void> toggleStatus(String alertId, bool isActive) async {
    await _repository.toggleAlertStatus(_userId, alertId, isActive);
  }

  /// 알림 삭제
  Future<void> deleteAlert(String alertId) async {
    await _repository.deletePriceAlert(_userId, alertId);
  }

  /// 특정 부품에 대한 알림 확인
  Future<PriceAlert?> getAlertForBasePart(String basePartId) async {
    return await _repository.getAlertForBasePart(_userId, basePartId);
  }
}

/// PriceAlertActions Provider
final priceAlertActionsProvider = Provider.autoDispose<PriceAlertActions?>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) return null;

  final repository = ref.watch(priceAlertRepositoryProvider);
  return PriceAlertActions(repository, currentUser.uid);
});
