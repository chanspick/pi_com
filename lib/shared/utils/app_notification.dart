// 경로: lib/shared/utils/app_notification.dart

import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

/// 앱 전체에서 사용하는 알림 유틸리티
/// toastification 패키지를 사용한 세련된 알림 시스템
class AppNotification {
  static const _defaultDuration = Duration(seconds: 3);
  static const _errorDuration = Duration(seconds: 4);

  /// 성공 알림 (초록색)
  static void showSuccess(
    BuildContext context,
    String message, {
    String? title,
    Duration? duration,
  }) {
    toastification.show(
      context: context,
      type: ToastificationType.success,
      style: ToastificationStyle.flatColored,
      title: title != null ? Text(title) : null,
      description: Text(message),
      alignment: Alignment.topCenter,
      autoCloseDuration: duration ?? _defaultDuration,
      animationDuration: const Duration(milliseconds: 300),
      icon: const Icon(Icons.check_circle_rounded),
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
      showProgressBar: false,
      closeButtonShowType: CloseButtonShowType.onHover,
      closeOnClick: true,
      pauseOnHover: true,
      dragToClose: true,
    );
  }

  /// 에러 알림 (빨간색)
  static void showError(
    BuildContext context,
    String message, {
    String? title,
    Duration? duration,
  }) {
    toastification.show(
      context: context,
      type: ToastificationType.error,
      style: ToastificationStyle.flatColored,
      title: title != null ? Text(title) : null,
      description: Text(message),
      alignment: Alignment.topCenter,
      autoCloseDuration: duration ?? _errorDuration,
      animationDuration: const Duration(milliseconds: 300),
      icon: const Icon(Icons.error_rounded),
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
      showProgressBar: false,
      closeButtonShowType: CloseButtonShowType.onHover,
      closeOnClick: true,
      pauseOnHover: true,
      dragToClose: true,
    );
  }

  /// 정보 알림 (파란색)
  static void showInfo(
    BuildContext context,
    String message, {
    String? title,
    Duration? duration,
  }) {
    toastification.show(
      context: context,
      type: ToastificationType.info,
      style: ToastificationStyle.flatColored,
      title: title != null ? Text(title) : null,
      description: Text(message),
      alignment: Alignment.topCenter,
      autoCloseDuration: duration ?? _defaultDuration,
      animationDuration: const Duration(milliseconds: 300),
      icon: const Icon(Icons.info_rounded),
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
      showProgressBar: false,
      closeButtonShowType: CloseButtonShowType.onHover,
      closeOnClick: true,
      pauseOnHover: true,
      dragToClose: true,
    );
  }

  /// 경고 알림 (주황색)
  static void showWarning(
    BuildContext context,
    String message, {
    String? title,
    Duration? duration,
  }) {
    toastification.show(
      context: context,
      type: ToastificationType.warning,
      style: ToastificationStyle.flatColored,
      title: title != null ? Text(title) : null,
      description: Text(message),
      alignment: Alignment.topCenter,
      autoCloseDuration: duration ?? _defaultDuration,
      animationDuration: const Duration(milliseconds: 300),
      icon: const Icon(Icons.warning_rounded),
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
      showProgressBar: false,
      closeButtonShowType: CloseButtonShowType.onHover,
      closeOnClick: true,
      pauseOnHover: true,
      dragToClose: true,
    );
  }

  /// 결제 완료 알림 (특별한 스타일)
  static void showPaymentSuccess(
    BuildContext context,
    String message, {
    String? title,
  }) {
    toastification.show(
      context: context,
      type: ToastificationType.success,
      style: ToastificationStyle.flatColored,
      title: Text(title ?? '결제 완료'),
      description: Text(message),
      alignment: Alignment.topCenter,
      autoCloseDuration: const Duration(seconds: 4),
      animationDuration: const Duration(milliseconds: 300),
      icon: const Icon(Icons.payment_rounded),
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.green.withValues(alpha: 0.2),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
      ],
      showProgressBar: true,
      closeButtonShowType: CloseButtonShowType.always,
      closeOnClick: true,
      pauseOnHover: true,
      dragToClose: true,
    );
  }

  /// 카트 알림 (장바구니 관련)
  static void showCartNotification(
    BuildContext context,
    String message, {
    bool isRemoval = false,
  }) {
    toastification.show(
      context: context,
      type: isRemoval ? ToastificationType.warning : ToastificationType.success,
      style: ToastificationStyle.flatColored,
      description: Text(message),
      alignment: Alignment.topCenter,
      autoCloseDuration: const Duration(seconds: 2),
      animationDuration: const Duration(milliseconds: 300),
      icon: Icon(isRemoval ? Icons.remove_shopping_cart : Icons.shopping_cart_checkout),
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
      showProgressBar: false,
      closeButtonShowType: CloseButtonShowType.onHover,
      closeOnClick: true,
      pauseOnHover: true,
      dragToClose: true,
    );
  }

  /// 로그인/로그아웃 알림
  static void showAuthNotification(
    BuildContext context,
    String message, {
    bool isLogin = true,
  }) {
    toastification.show(
      context: context,
      type: ToastificationType.success,
      style: ToastificationStyle.flatColored,
      title: Text(isLogin ? '로그인' : '로그아웃'),
      description: Text(message),
      alignment: Alignment.topCenter,
      autoCloseDuration: const Duration(seconds: 2),
      animationDuration: const Duration(milliseconds: 300),
      icon: Icon(isLogin ? Icons.login_rounded : Icons.logout_rounded),
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
      showProgressBar: false,
      closeButtonShowType: CloseButtonShowType.onHover,
      closeOnClick: true,
      pauseOnHover: true,
      dragToClose: true,
    );
  }
}
