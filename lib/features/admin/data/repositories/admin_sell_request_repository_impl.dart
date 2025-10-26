// lib/features/admin/data/repositories/admin_sell_request_repository_impl.dart

import 'package:cloud_firestore/cloud_firestore.dart';
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
    String? adminNotes,
  }) async {
    // 1. 먼저 SellRequest 정보 조회 (판매자 ID 확인용)
    final requestDoc = await FirebaseFirestore.instance
        .collection('sellRequests')
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

    // 3. 판매자에게 승인 알림 발송 ⭐⭐⭐
    await _notificationDataSource.sendNotificationToUser(
      userId: sellRequest.sellerId,
      type: NotificationType.statusChanged,
      title: '판매 요청이 승인되었습니다 🎉',
      message: '${sellRequest.brand} ${sellRequest.modelName} 부품의 판매 요청이 승인되었습니다.\n'
          '최종 판매 가격: ${finalPrice.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]},',
      )}원',
      relatedSellRequestId: requestId,
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
        .collection('sellRequests')
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

    // 3. 판매자에게 반려 알림 발송 ⭐⭐⭐
    await _notificationDataSource.sendNotificationToUser(
      userId: sellRequest.sellerId,
      type: NotificationType.statusChanged,
      title: '판매 요청이 반려되었습니다',
      message: '${sellRequest.brand} ${sellRequest.modelName} 부품의 판매 요청이 반려되었습니다.\n\n'
          '반려 사유: $rejectReason\n\n'
          '수정 후 다시 신청해주세요.',
      relatedSellRequestId: requestId,
    );

    print('✅ 반려 알림 발송 완료: ${sellRequest.sellerId}');
  }

  @override
  Stream<List<SellRequest>> getPendingSellRequests() {
    return _sellRequestDataSource.getPendingSellRequests();
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
