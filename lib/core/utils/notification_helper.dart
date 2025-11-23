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
    String? relatedOrderId,
    String? relatedRefundId,
    String? relatedDragonBallId,
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
      relatedOrderId: relatedOrderId,
      relatedRefundId: relatedRefundId,
      relatedDragonBallId: relatedDragonBallId,
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
    required String orderId,
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
      relatedOrderId: orderId,
      relatedListingId: listingId,
    );
  }

  /// 배송 시작 알림 (구매자에게)
  Future<void> notifyShippingStarted({
    required String buyerId,
    required String orderId,
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
      relatedOrderId: orderId,
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
  // 검수/QC 관련 알림
  // ========================================

  /// 검수 시작 알림
  Future<void> notifyInspectionStarted({
    required String sellerId,
    required String sellRequestId,
    required String partName,
  }) async {
    await sendNotification(
      userId: sellerId,
      type: NotificationType.inspectionStarted,
      title: '검수가 시작되었습니다 🔍',
      message: '$partName 부품의 검수가 시작되었습니다.\n'
          '검수 결과는 영업일 기준 3일 이내에 안내드립니다.',
      relatedSellRequestId: sellRequestId,
    );
  }

  /// 검수 합격 알림
  Future<void> notifyInspectionPassed({
    required String sellerId,
    required String sellRequestId,
    required String partName,
    required int finalPrice,
  }) async {
    await sendNotification(
      userId: sellerId,
      type: NotificationType.inspectionPassed,
      title: '검수 합격! 판매가 승인되었습니다 🎉',
      message: '$partName 부품이 검수를 통과했습니다.\n'
          '최종 판매 가격: ${_formatPrice(finalPrice)}원\n'
          '구매자가 나타날 때까지 보관됩니다.',
      relatedSellRequestId: sellRequestId,
    );
  }

  /// 검수 불합격 알림 (반송 주소 등록 요청)
  Future<void> notifyInspectionFailed({
    required String sellerId,
    required String sellRequestId,
    required String partName,
    required String failReason,
    required int penaltyAmount,
  }) async {
    await sendNotification(
      userId: sellerId,
      type: NotificationType.inspectionFailed,
      title: '검수 불합격 - 반송 주소를 등록해주세요',
      message: '$partName 부품이 검수에서 불합격되었습니다.\n\n'
          '불합격 사유: $failReason\n\n'
          '⚠️ 위약금: ${_formatPrice(penaltyAmount)}원\n'
          '60일 이내 반송 주소를 등록하지 않으면 보관 서비스로 자동 전환됩니다.',
      relatedSellRequestId: sellRequestId,
    );
  }

  /// 반송 주소 등록 마감 임박 알림
  Future<void> notifyReturnAddressExpiring({
    required String sellerId,
    required String sellRequestId,
    required String partName,
    required int daysRemaining,
  }) async {
    await sendNotification(
      userId: sellerId,
      type: NotificationType.returnAddressExpiring,
      title: '⚠️ 반송 주소 등록 마감 임박 (${daysRemaining}일 남음)',
      message: '$partName 부품의 반송 주소 등록 기한이 ${daysRemaining}일 남았습니다.\n\n'
          '기한 내 반송 주소를 등록하지 않으면 보관 서비스로 자동 전환되며,\n'
          '일일 0.5% 보관료가 부과됩니다.\n\n'
          '지금 바로 반송 주소를 등록해주세요!',
      relatedSellRequestId: sellRequestId,
    );
  }

  /// 위약금 부과 알림
  Future<void> notifyPenaltyIssued({
    required String sellerId,
    required String sellRequestId,
    required String partName,
    required int penaltyAmount,
    required String reason,
  }) async {
    await sendNotification(
      userId: sellerId,
      type: NotificationType.penaltyIssued,
      title: '위약금이 부과되었습니다',
      message: '$partName 부품에 대한 위약금이 부과되었습니다.\n\n'
          '사유: $reason\n'
          '위약금: ${_formatPrice(penaltyAmount)}원\n\n'
          '다음 정산 시 자동으로 차감됩니다.',
      relatedSellRequestId: sellRequestId,
    );
  }

  // ========================================
  // 보관 서비스 관련 알림
  // ========================================

  /// 보관 서비스 시작 알림
  Future<void> notifyStorageCreated({
    required String userId,
    required String dragonBallId,
    required String partName,
    required String storageType, // 'general' or 'rental'
  }) async {
    final storageTypeText = storageType == 'general' ? '일반 보관' : '임대 보관 (무료)';
    final feeInfo = storageType == 'general'
        ? '7일 무료 기간 후 일일 0.5% 보관료가 부과됩니다.'
        : '보관 기간 동안 무료이며, 렌탈 서비스에 활용될 수 있습니다.';

    await sendNotification(
      userId: userId,
      type: NotificationType.storageCreated,
      title: '보관 서비스가 시작되었습니다 📦',
      message: '$partName 부품이 보관 서비스에 등록되었습니다.\n\n'
          '보관 유형: $storageTypeText\n'
          '$feeInfo\n\n'
          '최대 59일 보관 가능하며, 60일 초과 시 위탁판매로 전환됩니다.',
      relatedDragonBallId: dragonBallId,
    );
  }

  /// 보관료 발생 시작 알림 (7일 무료 기간 종료)
  Future<void> notifyStorageFeeStart({
    required String userId,
    required String dragonBallId,
    required String partName,
    required int purchasePrice,
  }) async {
    final dailyFee = (purchasePrice * 0.005).round();

    await sendNotification(
      userId: userId,
      type: NotificationType.storageFeeStart,
      title: '보관료가 발생하기 시작했습니다 💰',
      message: '$partName 부품의 7일 무료 보관 기간이 종료되었습니다.\n\n'
          '오늘부터 일일 ${_formatPrice(dailyFee)}원(구매가의 0.5%)의 보관료가 부과됩니다.\n'
          '최대 보관료는 구매가의 30%(${_formatPrice((purchasePrice * 0.3).round())}원)입니다.\n\n'
          '출고를 원하시면 배송 신청을 해주세요.',
      relatedDragonBallId: dragonBallId,
    );
  }

  /// 보관 기간 만료 임박 알림
  Future<void> notifyStorageExpiring({
    required String userId,
    required String dragonBallId,
    required String partName,
    required int daysRemaining,
  }) async {
    await sendNotification(
      userId: userId,
      type: NotificationType.storageExpiring,
      title: '⚠️ 보관 기간 만료 임박 (${daysRemaining}일 남음)',
      message: '$partName 부품의 최대 보관 기간(59일)이 ${daysRemaining}일 남았습니다.\n\n'
          '60일 경과 시 위탁판매로 자동 전환됩니다.\n'
          '출고를 원하시면 지금 배송 신청을 해주세요!',
      relatedDragonBallId: dragonBallId,
    );
  }

  /// 위탁판매 전환 경고 알림
  Future<void> notifyConsignmentWarning({
    required String userId,
    required String dragonBallId,
    required String partName,
    required int daysUntilConsignment,
  }) async {
    await sendNotification(
      userId: userId,
      type: NotificationType.consignmentWarning,
      title: '⚠️ 위탁판매 전환 예정 (${daysUntilConsignment}일 후)',
      message: '$partName 부품이 ${daysUntilConsignment}일 후 위탁판매로 전환됩니다.\n\n'
          '위탁판매 전환 시:\n'
          '• 회사가 임의로 판매 가격을 결정합니다\n'
          '• 판매 대금에서 보관료(최대 30%)와 판매 수수료(10%)가 차감됩니다\n\n'
          '전환을 원하지 않으시면 지금 배송 신청을 해주세요!',
      relatedDragonBallId: dragonBallId,
    );
  }

  /// 위탁판매 전환 완료 알림
  Future<void> notifyConsignmentConverted({
    required String userId,
    required String dragonBallId,
    required String partName,
  }) async {
    await sendNotification(
      userId: userId,
      type: NotificationType.consignmentConverted,
      title: '위탁판매로 전환되었습니다',
      message: '$partName 부품이 최대 보관 기간(59일)을 초과하여\n'
          '위탁판매로 전환되었습니다.\n\n'
          '회사에서 적정 가격에 판매를 진행하며,\n'
          '판매 완료 시 보관료 및 수수료를 제외한 금액이 정산됩니다.',
      relatedDragonBallId: dragonBallId,
    );
  }

  /// 위탁판매 매각 완료 알림
  Future<void> notifyConsignmentSold({
    required String userId,
    required String dragonBallId,
    required String partName,
    required int salePrice,
    required int storageFee,
    required int commission,
    required int netAmount,
  }) async {
    await sendNotification(
      userId: userId,
      type: NotificationType.consignmentSold,
      title: '위탁판매가 완료되었습니다 💰',
      message: '$partName 부품이 위탁판매로 매각되었습니다.\n\n'
          '판매 금액: ${_formatPrice(salePrice)}원\n'
          '보관료 차감: -${_formatPrice(storageFee)}원\n'
          '판매 수수료 차감: -${_formatPrice(commission)}원\n'
          '─────────────────\n'
          '정산 금액: ${_formatPrice(netAmount)}원\n\n'
          '정산 금액은 2영업일 내 지급됩니다.',
      relatedDragonBallId: dragonBallId,
    );
  }

  // ========================================
  // 환불 관련 알림
  // ========================================

  /// 환불 신청 접수 알림 (판매자에게)
  Future<void> notifyRefundRequested({
    required String sellerId,
    required String refundId,
    required String orderId,
    required String partName,
    required String reason,
  }) async {
    await sendNotification(
      userId: sellerId,
      type: NotificationType.refundRequested,
      title: '환불 신청이 접수되었습니다',
      message: '$partName 주문에 대한 환불 신청이 접수되었습니다.\n\n'
          '환불 사유: $reason\n\n'
          '관리자 검토 후 승인/거부 여부를 안내드립니다.',
      relatedRefundId: refundId,
      relatedOrderId: orderId,
    );
  }

  /// 환불 승인 알림 (구매자에게)
  Future<void> notifyRefundApproved({
    required String buyerId,
    required String refundId,
    required String orderId,
    required String partName,
  }) async {
    await sendNotification(
      userId: buyerId,
      type: NotificationType.refundApproved,
      title: '환불이 승인되었습니다 ✅',
      message: '$partName 환불 요청이 승인되었습니다.\n\n'
          '반품 택배 발송 후 송장번호를 등록해주세요.\n'
          '물품 수령 및 검수 완료 후 환불이 진행됩니다.',
      relatedRefundId: refundId,
      relatedOrderId: orderId,
    );
  }

  /// 환불 거부 알림 (구매자에게)
  Future<void> notifyRefundRejected({
    required String buyerId,
    required String refundId,
    required String orderId,
    required String partName,
    required String rejectReason,
  }) async {
    await sendNotification(
      userId: buyerId,
      type: NotificationType.refundRejected,
      title: '환불 요청이 거부되었습니다',
      message: '$partName 환불 요청이 거부되었습니다.\n\n'
          '거부 사유: $rejectReason\n\n'
          '추가 문의사항은 고객센터로 연락해주세요.',
      relatedRefundId: refundId,
      relatedOrderId: orderId,
    );
  }

  /// 반품 택배 발송 요청 알림
  Future<void> notifyReturnShippingRequired({
    required String buyerId,
    required String refundId,
    required String orderId,
    required String partName,
  }) async {
    await sendNotification(
      userId: buyerId,
      type: NotificationType.returnShippingRequired,
      title: '반품 택배를 발송해주세요 📦',
      message: '$partName 환불이 승인되었습니다.\n\n'
          '반품 택배 발송 후 송장번호를 등록해주세요.\n'
          '⚠️ 봉인 씰이 파손되지 않도록 주의해주세요.\n\n'
          '봉인 씰이 파손된 경우 환불이 불가능합니다.',
      relatedListingId: orderId,
    );
  }

  /// 반품 물품 수령 알림
  Future<void> notifyReturnItemReceived({
    required String buyerId,
    required String refundId,
    required String orderId,
    required String partName,
  }) async {
    await sendNotification(
      userId: buyerId,
      type: NotificationType.returnItemReceived,
      title: '반품 물품이 수령되었습니다',
      message: '$partName 반품 물품을 수령했습니다.\n\n'
          '검수가 시작되며, 3영업일 이내에 검수 결과를 안내드립니다.\n'
          '검수 합격 시 환불이 진행됩니다.',
      relatedListingId: orderId,
    );
  }

  /// 환불 검수 중 알림
  Future<void> notifyRefundInspecting({
    required String buyerId,
    required String refundId,
    required String orderId,
    required String partName,
  }) async {
    await sendNotification(
      userId: buyerId,
      type: NotificationType.refundInspecting,
      title: '환불 검수가 진행 중입니다 🔍',
      message: '$partName 반품 물품의 검수가 진행 중입니다.\n\n'
          '검수는 3영업일 이내에 완료되며,\n'
          '검수 결과에 따라 환불이 진행됩니다.',
      relatedRefundId: refundId,
      relatedOrderId: orderId,
    );
  }

  /// 환불 검수 합격 알림
  Future<void> notifyRefundInspectionPass({
    required String buyerId,
    required String refundId,
    required String orderId,
    required String partName,
    required int refundAmount,
  }) async {
    await sendNotification(
      userId: buyerId,
      type: NotificationType.refundInspectionPass,
      title: '검수 합격! 환불이 진행됩니다 ✅',
      message: '$partName 반품 물품이 검수를 통과했습니다.\n\n'
          '환불 금액: ${_formatPrice(refundAmount)}원\n\n'
          '환불 처리가 시작되며, 2-3영업일 내 환불이 완료됩니다.',
      relatedRefundId: refundId,
      relatedOrderId: orderId,
    );
  }

  /// 환불 검수 불합격 알림
  Future<void> notifyRefundInspectionFail({
    required String buyerId,
    required String refundId,
    required String orderId,
    required String partName,
    required String failReason,
    String? trackingNumber,
  }) async {
    final trackingInfo = trackingNumber != null
        ? '\n\n재발송 송장번호: $trackingNumber'
        : '';

    await sendNotification(
      userId: buyerId,
      type: NotificationType.refundInspectionFail,
      title: '검수 불합격 - 물품이 재발송됩니다',
      message: '$partName 반품 물품이 검수에서 불합격되었습니다.\n\n'
          '불합격 사유: $failReason\n\n'
          '물품은 원래 배송지로 재발송됩니다.$trackingInfo',
      relatedRefundId: refundId,
      relatedOrderId: orderId,
    );
  }

  /// 환불 처리 중 알림
  Future<void> notifyRefundProcessing({
    required String buyerId,
    required String refundId,
    required String orderId,
    required String partName,
    required int refundAmount,
  }) async {
    await sendNotification(
      userId: buyerId,
      type: NotificationType.refundProcessing,
      title: '환불 처리 중입니다 💳',
      message: '$partName 환불이 처리 중입니다.\n\n'
          '환불 금액: ${_formatPrice(refundAmount)}원\n\n'
          '2-3영업일 내 결제 수단으로 환불됩니다.',
      relatedRefundId: refundId,
      relatedOrderId: orderId,
    );
  }

  /// 환불 완료 알림
  Future<void> notifyRefundCompleted({
    required String buyerId,
    required String refundId,
    required String orderId,
    required String partName,
    required int refundAmount,
  }) async {
    await sendNotification(
      userId: buyerId,
      type: NotificationType.refundCompleted,
      title: '환불이 완료되었습니다 ✅',
      message: '$partName 환불이 완료되었습니다.\n\n'
          '환불 금액: ${_formatPrice(refundAmount)}원\n\n'
          '결제 수단으로 환불되었으며,\n'
          '카드사에 따라 1-3일 소요될 수 있습니다.',
      relatedRefundId: refundId,
      relatedOrderId: orderId,
    );
  }

  // ========================================
  // 정산 관련 알림
  // ========================================

  /// 구매 확정 요청 알림 (배송 완료 5일 후)
  Future<void> notifyPurchaseConfirmReminder({
    required String buyerId,
    required String orderId,
    required String partName,
  }) async {
    await sendNotification(
      userId: buyerId,
      type: NotificationType.purchaseConfirmReminder,
      title: '구매 확정을 요청드립니다',
      message: '$partName 주문이 배송 완료된 지 5일이 지났습니다.\n\n'
          '상품에 이상이 없으시면 구매 확정을 해주세요.\n'
          '2일 후 자동으로 구매 확정됩니다.\n\n'
          '문제가 있으시면 환불 신청을 해주세요.',
      relatedOrderId: orderId,
    );
  }

  /// 자동 구매 확정 알림
  Future<void> notifyAutoConfirmed({
    required String buyerId,
    required String sellerId,
    required String orderId,
    required String partName,
  }) async {
    // 구매자에게
    await sendNotification(
      userId: buyerId,
      type: NotificationType.autoConfirmed,
      title: '구매가 자동 확정되었습니다',
      message: '$partName 주문이 배송 완료 후 7일이 경과하여\n'
          '자동으로 구매 확정되었습니다.\n\n'
          '이용해주셔서 감사합니다!',
      relatedOrderId: orderId,
    );

    // 판매자에게
    await sendNotification(
      userId: sellerId,
      type: NotificationType.purchaseConfirmed,
      title: '구매가 자동 확정되었습니다 💰',
      message: '$partName 주문이 자동 구매 확정되었습니다.\n\n'
          '2영업일 내 정산이 완료됩니다.',
      relatedOrderId: orderId,
    );
  }

  /// 정산 대기 중 알림 (D+1)
  Future<void> notifySettlementPending({
    required String sellerId,
    required String orderId,
    required String partName,
    required int settlementAmount,
  }) async {
    await sendNotification(
      userId: sellerId,
      type: NotificationType.settlementPending,
      title: '정산이 준비 중입니다',
      message: '$partName 판매에 대한 정산이 준비 중입니다.\n\n'
          '정산 예정 금액: ${_formatPrice(settlementAmount)}원\n\n'
          '내일 정산이 완료됩니다.',
      relatedOrderId: orderId,
    );
  }

  /// 정산 완료 알림 (D+2)
  Future<void> notifySettlementCompleted({
    required String sellerId,
    required String orderId,
    required String partName,
    required int settlementAmount,
  }) async {
    await sendNotification(
      userId: sellerId,
      type: NotificationType.settlementCompleted,
      title: '정산이 완료되었습니다 💰',
      message: '$partName 판매 대금이 정산되었습니다.\n\n'
          '정산 금액: ${_formatPrice(settlementAmount)}원\n\n'
          '등록하신 계좌로 입금되었습니다.\n'
          '감사합니다!',
      relatedOrderId: orderId,
    );
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
