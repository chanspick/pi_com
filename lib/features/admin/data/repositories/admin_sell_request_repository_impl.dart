// lib/features/admin/data/repositories/admin_sell_request_repository_impl.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/admin_sell_request_repository.dart';
import '../datasources/admin_sell_request_datasource.dart';
import '../datasources/admin_notification_datasource.dart';
import '../../../../core/models/notification_model.dart';
import '../../../../core/models/sell_request_model.dart';
import '../../../../core/utils/notification_helper.dart';
import '../../../../core/constants/firebase_constants.dart';

class AdminSellRequestRepositoryImpl implements AdminSellRequestRepository {
  final AdminSellRequestDataSource _sellRequestDataSource;
  final AdminNotificationDataSource _notificationDataSource;
  final NotificationHelper _notificationHelper = NotificationHelper();

  AdminSellRequestRepositoryImpl(
      this._sellRequestDataSource,
      this._notificationDataSource,
      );

  @override
  Future<void> approveSellRequest({
    required String requestId,
    required int finalPrice,
    required double finalConditionScore,
    String? adminNotes,
  }) async {
    // 1. 먼저 SellRequest 정보 조회 (판매자 ID 확인용)
    final requestDoc = await FirebaseFirestore.instance
        .collection(FirebaseConstants.sellRequestsCollection)
        .doc(requestId)
        .get();

    if (!requestDoc.exists) {
      throw Exception('SellRequest를 찾을 수 없습니다.');
    }

    final sellRequest = SellRequest.fromFirestore(requestDoc);

    // 2. 승인 처리 (DataSource)
    await _sellRequestDataSource.approveSellRequest(
      requestId: requestId,
      finalPrice: finalPrice,
      finalConditionScore: finalConditionScore,
      adminNotes: adminNotes,
    );

    // 3. 판매자에게 승인 알림 발송 ⭐⭐⭐ (NotificationHelper 사용)
    await _notificationHelper.notifySellRequestApproved(
      sellerId: sellRequest.sellerId,
      sellRequestId: requestId,
      partName: '${sellRequest.brand} ${sellRequest.modelName}',
      finalPrice: finalPrice,
    );

    print('✅ 승인 알림 발송 완료: ${sellRequest.sellerId}');
  }

  @override
  Future<void> rejectSellRequest({
    required String requestId,
    required String rejectReason,
  }) async {
    // 1. 먼저 SellRequest 정보 조회 (판매자 ID 확인용)
    final requestDoc = await FirebaseFirestore.instance
        .collection(FirebaseConstants.sellRequestsCollection)
        .doc(requestId)
        .get();

    if (!requestDoc.exists) {
      throw Exception('SellRequest를 찾을 수 없습니다.');
    }

    final sellRequest = SellRequest.fromFirestore(requestDoc);

    // 2. 반려 처리 (DataSource)
    await _sellRequestDataSource.rejectSellRequest(
      requestId: requestId,
      rejectReason: rejectReason,
    );

    // 3. 판매자에게 반려 알림 발송 ⭐⭐⭐ (NotificationHelper 사용)
    await _notificationHelper.notifySellRequestRejected(
      sellerId: sellRequest.sellerId,
      sellRequestId: requestId,
      partName: '${sellRequest.brand} ${sellRequest.modelName}',
      reason: rejectReason,
    );

    print('✅ 반려 알림 발송 완료: ${sellRequest.sellerId}');
  }

  @override
  Stream<List<SellRequest>> getPendingSellRequests() {
    return _sellRequestDataSource.getPendingSellRequests();
  }

  @override
  Future<SellRequest?> getSellRequestById(String requestId) {
    return _sellRequestDataSource.getSellRequestById(requestId);
  }

  @override
  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String message,
    String? relatedSellRequestId,
    String? relatedListingId,
  }) async {
    await _notificationDataSource.sendNotificationToUser(
      userId: userId,
      type: NotificationType.statusChanged,
      title: title,
      message: message,
      relatedSellRequestId: relatedSellRequestId,
      relatedListingId: relatedListingId,
    );
  }
}
