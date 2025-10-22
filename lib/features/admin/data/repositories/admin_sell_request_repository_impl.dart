// lib/features/admin/data/repositories/admin_sell_request_repository_impl.dart

import '../../domain/repositories/admin_sell_request_repository.dart';
import '../datasources/admin_sell_request_datasource.dart';
import '../datasources/admin_notification_datasource.dart';
import '../../../../core/models/notification_model.dart';
import '../../../../core/models/sell_request_model.dart';

class AdminSellRequestRepositoryImpl implements AdminSellRequestRepository {
  final AdminSellRequestDataSource _sellRequestDataSource;
  final AdminNotificationDataSource _notificationDataSource;

  AdminSellRequestRepositoryImpl(
      this._sellRequestDataSource,
      this._notificationDataSource,
      );

  @override
  Future<void> approveSellRequest({
    required String requestId,
    required int finalPrice,
    required int finalConditionScore,
    // ❌ brand 파라미터 제거
    String? adminNotes,
  }) async {
    await _sellRequestDataSource.approveSellRequest(
      requestId: requestId,
      finalPrice: finalPrice,
      finalConditionScore: finalConditionScore,
      // ❌ brand 제거
      adminNotes: adminNotes,
    );
  }

  @override
  Future<void> rejectSellRequest({
    required String requestId,
    required String rejectReason,
  }) async {
    await _sellRequestDataSource.rejectSellRequest(
      requestId: requestId,
      rejectReason: rejectReason,
    );
  }

  @override
  Stream<List<SellRequest>> getPendingSellRequests() {
    // 🆕 추가: DataSource에서 Stream 가져오기
    return _sellRequestDataSource.getPendingSellRequests();
  }

  @override
  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String message,
    String? relatedSellRequestId,
    String? relatedListingId,  // 🆕 추가
  }) async {
    await _notificationDataSource.sendNotificationToUser(
      userId: userId,
      type: NotificationType.statusChanged,
      title: title,
      message: message,
      relatedSellRequestId: relatedSellRequestId,
      relatedListingId: relatedListingId,  // 🆕 전달
    );
  }
}
