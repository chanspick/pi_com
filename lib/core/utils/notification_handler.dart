// lib/core/utils/notification_handler.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';
import 'app_logger.dart';
import '../constants/routes.dart';

/// 알림 탭 처리 핸들러
class NotificationHandler {
  final BuildContext context;

  NotificationHandler(this.context);

  /// 알림 탭 이벤트 처리
  Future<void> handleNotificationTap(NotificationModel notification) async {
    // 1. 알림을 읽음 처리
    await _markAsRead(notification.notificationId);

    // 2. 타입별 화면 라우팅
    _navigateByType(notification);
  }

  /// 알림을 읽음 상태로 업데이트
  Future<void> _markAsRead(String notificationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      AppLogger.e('Failed to mark notification as read: $e', tag: 'Notification');
    }
  }

  /// 알림 타입별 화면 라우팅
  void _navigateByType(NotificationModel notification) {
    switch (notification.type) {
      // ========================================
      // A. 구매/주문 관련
      // ========================================
      case NotificationType.purchaseConfirmReminder:
      case NotificationType.autoConfirmed:
      case NotificationType.paymentCompleted:
        _navigateToPurchaseDetail(notification.relatedOrderId);
        break;

      // ========================================
      // B. 환불 관련 - 정보 입력 필요
      // ========================================
      case NotificationType.refundApproved:
      case NotificationType.returnShippingRequired:
      case NotificationType.returnAddressExpiring:
        // 환불 승인 → 반품 송장 입력 화면
        _navigateToReturnShipping(notification.relatedRefundId);
        break;

      // ========================================
      // C. 환불 관련 - 정보 확인
      // ========================================
      case NotificationType.refundRequested:
      case NotificationType.refundRejected:
      case NotificationType.refundInspecting:
      case NotificationType.refundInspectionPass:
      case NotificationType.refundInspectionFail:
      case NotificationType.refundProcessing:
      case NotificationType.refundCompleted:
        // 환불 상세 화면
        _navigateToRefundDetail(notification.relatedRefundId);
        break;

      // ========================================
      // D. 보관 서비스 관련
      // ========================================
      case NotificationType.storageCreated:
      case NotificationType.storageExpiring:
      case NotificationType.consignmentWarning:
      case NotificationType.consignmentConverted:
      case NotificationType.consignmentSold:
        // PC 보관함 화면 (DragonBall Storage)
        _navigateToPcStorage(notification.relatedDragonBallId);
        break;

      // ========================================
      // E. 판매 관련 (판매자)
      // ========================================
      case NotificationType.listingSold:
      case NotificationType.purchaseConfirmed:
      case NotificationType.settlementPending:
      case NotificationType.settlementCompleted:
        // 판매 내역 화면
        _navigateToSalesHistory();
        break;

      // ========================================
      // F. 판매 신청 관련
      // ========================================
      case NotificationType.statusChanged:
      case NotificationType.inspectionStarted:
      case NotificationType.inspectionPassed:
      case NotificationType.inspectionFailed:
      case NotificationType.penaltyIssued:
        // 판매 신청 상세 화면
        _navigateToSellRequestDetail(notification.relatedSellRequestId);
        break;

      // ========================================
      // G. 기타
      // ========================================
      case NotificationType.priceAlert:
        // 가격 알림 → 부품 시세 화면
        _navigateToPartsCategory();
        break;

      case NotificationType.marketing:
      case NotificationType.system:
      default:
        // 기본: 알림 목록 화면으로 (이미 있으므로 아무것도 안 함)
        break;
    }
  }

  // ========================================
  // 라우팅 헬퍼 메서드
  // ========================================

  /// 주문 상세 화면으로 이동
  void _navigateToPurchaseDetail(String? orderId) {
    if (orderId == null) {
      _showErrorSnackBar('주문 정보를 찾을 수 없습니다.');
      return;
    }

    Navigator.pushNamed(
      context,
      Routes.purchaseDetail,
      arguments: orderId,
    );
  }

  /// 환불 반품 송장 입력 화면으로 이동
  void _navigateToReturnShipping(String? refundId) {
    if (refundId == null) {
      _showErrorSnackBar('환불 정보를 찾을 수 없습니다.');
      return;
    }

    Navigator.pushNamed(
      context,
      Routes.refundReturnShipping,
      arguments: refundId,
    );
  }

  /// 환불 상세 화면으로 이동
  void _navigateToRefundDetail(String? refundId) {
    if (refundId == null) {
      _showErrorSnackBar('환불 정보를 찾을 수 없습니다.');
      return;
    }

    Navigator.pushNamed(
      context,
      Routes.refundDetail,
      arguments: refundId,
    );
  }

  /// PC 보관함 화면으로 이동 (특정 DragonBall 하이라이트)
  void _navigateToPcStorage(String? dragonBallId) {
    Navigator.pushNamed(
      context,
      Routes.pcStorage,
      arguments: dragonBallId, // DragonBall ID 전달 (선택사항)
    );
  }

  /// 판매 내역 화면으로 이동
  void _navigateToSalesHistory() {
    Navigator.pushNamed(
      context,
      Routes.salesHistory,
    );
  }

  /// 판매 신청 상세 화면으로 이동
  void _navigateToSellRequestDetail(String? sellRequestId) {
    if (sellRequestId == null) {
      _showErrorSnackBar('판매 신청 정보를 찾을 수 없습니다.');
      return;
    }

    Navigator.pushNamed(
      context,
      Routes.sellRequestDetails,
      arguments: sellRequestId,
    );
  }

  /// 부품 시세 화면으로 이동
  void _navigateToPartsCategory() {
    Navigator.pushNamed(
      context,
      Routes.partsCategory,
    );
  }

  /// 에러 스낵바 표시
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
