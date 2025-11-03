// lib/core/utils/notification_helper.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

/// 알림 헬퍼 클래스 (모든 알림 전송을 담당)
class NotificationHelper {
  final FirebaseFirestore _firestore;

  NotificationHelper({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// 기본 알림 전송
  Future<void> sendNotification({
    required String userId,
    required NotificationType type,
    required String title,
    required String message,
    String? relatedSellRequestId,
    String? relatedListingId,
  }) async {
    final notificationId = _firestore.collection('notifications').doc().id;

    final notification = NotificationModel(
      notificationId: notificationId,
      userId: userId,
      type: type,
      title: title,
      message: message,
      isRead: false,
      createdAt: DateTime.now(),
      relatedSellRequestId: relatedSellRequestId,
      relatedListingId: relatedListingId,
    );

    await _firestore
        .collection('notifications')
        .doc(notificationId)
        .set(notification.toMap());
  }

  // ========================================
  // 판매 관련 알림
  // ========================================

  /// 판매 요청 승인 알림
  Future<void> notifySellRequestApproved({
    required String sellerId,
    required String sellRequestId,
    required String partName,
    required int finalPrice,
  }) async {
    await sendNotification(
      userId: sellerId,
      type: NotificationType.statusChanged,
      title: '판매 요청이 승인되었습니다 🎉',
      message: '$partName 부품의 판매 요청이 승인되었습니다.\n'
          '최종 판매 가격: ${_formatPrice(finalPrice)}원',
      relatedSellRequestId: sellRequestId,
    );
  }

  /// 판매 요청 반려 알림
  Future<void> notifySellRequestRejected({
    required String sellerId,
    required String sellRequestId,
    required String partName,
    required String reason,
  }) async {
    await sendNotification(
      userId: sellerId,
      type: NotificationType.statusChanged,
      title: '판매 요청이 반려되었습니다',
      message: '$partName 부품의 판매 요청이 반려되었습니다.\n\n'
          '반려 사유: $reason\n\n'
          '수정 후 다시 신청해주세요.',
      relatedSellRequestId: sellRequestId,
    );
  }

  /// 매물 판매 완료 알림 (판매자에게)
  Future<void> notifyListingSold({
    required String sellerId,
    required String listingId,
    required String partName,
    required int soldPrice,
  }) async {
    await sendNotification(
      userId: sellerId,
      type: NotificationType.listingSold,
      title: '축하합니다! 매물이 판매되었습니다 🎊',
      message: '$partName이(가) ${_formatPrice(soldPrice)}원에 판매되었습니다.\n'
          '구매자가 결제를 완료하면 배송을 시작해주세요.',
      relatedListingId: listingId,
    );
  }

  // ========================================
  // 구매 관련 알림
  // ========================================

  /// 결제 완료 알림 (구매자에게)
  Future<void> notifyPaymentCompleted({
    required String buyerId,
    required String listingId,
    required String partName,
    required int totalAmount,
  }) async {
    await sendNotification(
      userId: buyerId,
      type: NotificationType.paymentCompleted,
      title: '결제가 완료되었습니다 ✅',
      message: '$partName 구매 결제가 완료되었습니다.\n'
          '결제 금액: ${_formatPrice(totalAmount)}원\n'
          '판매자가 배송을 준비하고 있습니다.',
      relatedListingId: listingId,
    );
  }

  /// 배송 시작 알림 (구매자에게)
  Future<void> notifyShippingStarted({
    required String buyerId,
    required String listingId,
    required String partName,
    String? trackingNumber,
  }) async {
    final trackingInfo = trackingNumber != null
        ? '\n송장번호: $trackingNumber'
        : '';

    await sendNotification(
      userId: buyerId,
      type: NotificationType.shipping,
      title: '배송이 시작되었습니다 📦',
      message: '$partName 배송이 시작되었습니다.$trackingInfo\n'
          '상품을 받으신 후 구매 확정을 해주세요.',
      relatedListingId: listingId,
    );
  }

  /// 구매 확정 알림 (판매자에게)
  Future<void> notifyPurchaseConfirmed({
    required String sellerId,
    required String listingId,
    required String partName,
    required int finalAmount,
  }) async {
    await sendNotification(
      userId: sellerId,
      type: NotificationType.purchaseConfirmed,
      title: '구매가 확정되었습니다 💰',
      message: '$partName 구매가 확정되었습니다!\n'
          '정산 금액: ${_formatPrice(finalAmount)}원\n'
          '수수료를 제외한 금액이 지급됩니다.',
      relatedListingId: listingId,
    );
  }

  // ========================================
  // 시세 알림
  // ========================================

  /// 목표 가격 도달 알림
  Future<void> notifyPriceAlert({
    required String userId,
    required String partName,
    required int targetPrice,
    required int currentPrice,
    String? listingId,
  }) async {
    await sendNotification(
      userId: userId,
      type: NotificationType.priceAlert,
      title: '목표 가격에 도달했습니다! 🎯',
      message: '$partName의 가격이 목표 가격에 도달했습니다.\n'
          '목표 가격: ${_formatPrice(targetPrice)}원\n'
          '현재 가격: ${_formatPrice(currentPrice)}원',
      relatedListingId: listingId,
    );
  }

  // ========================================
  // 시스템 알림
  // ========================================

  /// 시스템 공지
  Future<void> notifySystem({
    required String userId,
    required String title,
    required String message,
  }) async {
    await sendNotification(
      userId: userId,
      type: NotificationType.system,
      title: title,
      message: message,
    );
  }

  /// 마케팅 알림
  Future<void> notifyMarketing({
    required String userId,
    required String title,
    required String message,
  }) async {
    await sendNotification(
      userId: userId,
      type: NotificationType.marketing,
      title: title,
      message: message,
    );
  }

  /// 전체 사용자에게 마케팅 알림
  Future<int> notifyAllUsers({
    required String title,
    required String message,
  }) async {
    final usersSnapshot = await _firestore.collection('users').get();
    int sentCount = 0;

    for (final userDoc in usersSnapshot.docs) {
      await notifyMarketing(
        userId: userDoc.id,
        title: title,
        message: message,
      );
      sentCount++;
    }

    return sentCount;
  }

  // ========================================
  // 유틸리티
  // ========================================

  /// 가격 포맷팅 (1000 → "1,000")
  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
}
