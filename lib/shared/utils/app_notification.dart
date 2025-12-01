// 경로: lib/shared/utils/app_notification.dart

import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

/// 앱 전체에서 사용하는 알림 유틸리티
/// toastification 패키지를 사용한 세련된 알림 시스템
class AppNotification {
  static const _defaultDuration = Duration(seconds: 3);
  static const _errorDuration = Duration(seconds: 4);

  // 브랜드 컬러
  static const _primaryColor = Color(0xFF2563EB); // 블루
  static const _successColor = Color(0xFF059669); // 에메랄드 그린
  static const _errorColor = Color(0xFFDC2626); // 레드
  static const _warningColor = Color(0xFFF59E0B); // 앰버
  static const _infoColor = Color(0xFF3B82F6); // 라이트 블루

  /// 성공 알림
  static void showSuccess(
    BuildContext context,
    String message, {
    String? title,
    Duration? duration,
  }) {
    toastification.show(
      context: context,
      type: ToastificationType.success,
      style: ToastificationStyle.minimal,
      title: title != null
          ? Text(title, style: const TextStyle(fontWeight: FontWeight.w600))
          : null,
      description: Text(message, style: const TextStyle(fontSize: 14)),
      alignment: Alignment.topCenter,
      autoCloseDuration: duration ?? _defaultDuration,
      animationDuration: const Duration(milliseconds: 250),
      animationBuilder: (context, animation, alignment, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      icon: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: _successColor.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.check_rounded, size: 18, color: _successColor),
      ),
      primaryColor: _successColor,
      backgroundColor: Colors.white,
      foregroundColor: Colors.grey[800],
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: _successColor.withValues(alpha: 0.3), width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
      showProgressBar: false,
      closeButtonShowType: CloseButtonShowType.onHover,
      closeOnClick: true,
      pauseOnHover: true,
      dragToClose: true,
    );
  }

  /// 에러 알림
  static void showError(
    BuildContext context,
    String message, {
    String? title,
    Duration? duration,
  }) {
    toastification.show(
      context: context,
      type: ToastificationType.error,
      style: ToastificationStyle.minimal,
      title: title != null
          ? Text(title, style: const TextStyle(fontWeight: FontWeight.w600))
          : null,
      description: Text(message, style: const TextStyle(fontSize: 14)),
      alignment: Alignment.topCenter,
      autoCloseDuration: duration ?? _errorDuration,
      animationDuration: const Duration(milliseconds: 250),
      animationBuilder: (context, animation, alignment, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      icon: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: _errorColor.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.close_rounded, size: 18, color: _errorColor),
      ),
      primaryColor: _errorColor,
      backgroundColor: Colors.white,
      foregroundColor: Colors.grey[800],
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: _errorColor.withValues(alpha: 0.3), width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
      showProgressBar: false,
      closeButtonShowType: CloseButtonShowType.always,
      closeOnClick: true,
      pauseOnHover: true,
      dragToClose: true,
    );
  }

  /// 정보 알림
  static void showInfo(
    BuildContext context,
    String message, {
    String? title,
    Duration? duration,
  }) {
    toastification.show(
      context: context,
      type: ToastificationType.info,
      style: ToastificationStyle.minimal,
      title: title != null
          ? Text(title, style: const TextStyle(fontWeight: FontWeight.w600))
          : null,
      description: Text(message, style: const TextStyle(fontSize: 14)),
      alignment: Alignment.topCenter,
      autoCloseDuration: duration ?? _defaultDuration,
      animationDuration: const Duration(milliseconds: 250),
      animationBuilder: (context, animation, alignment, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      icon: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: _infoColor.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.info_outline_rounded, size: 18, color: _infoColor),
      ),
      primaryColor: _infoColor,
      backgroundColor: Colors.white,
      foregroundColor: Colors.grey[800],
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: _infoColor.withValues(alpha: 0.3), width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
      showProgressBar: false,
      closeButtonShowType: CloseButtonShowType.onHover,
      closeOnClick: true,
      pauseOnHover: true,
      dragToClose: true,
    );
  }

  /// 경고 알림
  static void showWarning(
    BuildContext context,
    String message, {
    String? title,
    Duration? duration,
  }) {
    toastification.show(
      context: context,
      type: ToastificationType.warning,
      style: ToastificationStyle.minimal,
      title: title != null
          ? Text(title, style: const TextStyle(fontWeight: FontWeight.w600))
          : null,
      description: Text(message, style: const TextStyle(fontSize: 14)),
      alignment: Alignment.topCenter,
      autoCloseDuration: duration ?? _defaultDuration,
      animationDuration: const Duration(milliseconds: 250),
      animationBuilder: (context, animation, alignment, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      icon: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: _warningColor.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.warning_amber_rounded, size: 18, color: _warningColor),
      ),
      primaryColor: _warningColor,
      backgroundColor: Colors.white,
      foregroundColor: Colors.grey[800],
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: _warningColor.withValues(alpha: 0.3), width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
      showProgressBar: false,
      closeButtonShowType: CloseButtonShowType.onHover,
      closeOnClick: true,
      pauseOnHover: true,
      dragToClose: true,
    );
  }

  /// 결제 완료 알림
  static void showPaymentSuccess(
    BuildContext context,
    String message, {
    String? title,
  }) {
    toastification.show(
      context: context,
      type: ToastificationType.success,
      style: ToastificationStyle.minimal,
      title: Text(
        title ?? '결제 완료',
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
      description: Text(message, style: const TextStyle(fontSize: 14)),
      alignment: Alignment.topCenter,
      autoCloseDuration: const Duration(seconds: 4),
      animationDuration: const Duration(milliseconds: 300),
      animationBuilder: (context, animation, alignment, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutBack)),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_primaryColor, _primaryColor.withValues(alpha: 0.7)],
          ),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check_rounded, size: 20, color: Colors.white),
      ),
      primaryColor: _primaryColor,
      backgroundColor: Colors.white,
      foregroundColor: Colors.grey[800],
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: _primaryColor.withValues(alpha: 0.2), width: 1.5),
      boxShadow: [
        BoxShadow(
          color: _primaryColor.withValues(alpha: 0.15),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ],
      showProgressBar: true,
      progressBarTheme: ProgressIndicatorThemeData(
        color: _primaryColor,
        linearTrackColor: _primaryColor.withValues(alpha: 0.1),
      ),
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
    final color = isRemoval ? _warningColor : _primaryColor;

    toastification.show(
      context: context,
      type: isRemoval ? ToastificationType.warning : ToastificationType.success,
      style: ToastificationStyle.minimal,
      description: Text(message, style: const TextStyle(fontSize: 14)),
      alignment: Alignment.topCenter,
      autoCloseDuration: const Duration(seconds: 2),
      animationDuration: const Duration(milliseconds: 200),
      animationBuilder: (context, animation, alignment, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      icon: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isRemoval ? Icons.remove_shopping_cart_outlined : Icons.shopping_cart_checkout_rounded,
          size: 18,
          color: color,
        ),
      ),
      primaryColor: color,
      backgroundColor: Colors.white,
      foregroundColor: Colors.grey[800],
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color.withValues(alpha: 0.3), width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 20,
          offset: const Offset(0, 8),
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
      style: ToastificationStyle.minimal,
      title: Text(
        isLogin ? '로그인 완료' : '로그아웃',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      description: Text(message, style: const TextStyle(fontSize: 14)),
      alignment: Alignment.topCenter,
      autoCloseDuration: const Duration(seconds: 2),
      animationDuration: const Duration(milliseconds: 250),
      animationBuilder: (context, animation, alignment, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      icon: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: _primaryColor.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isLogin ? Icons.person_rounded : Icons.logout_rounded,
          size: 18,
          color: _primaryColor,
        ),
      ),
      primaryColor: _primaryColor,
      backgroundColor: Colors.white,
      foregroundColor: Colors.grey[800],
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: _primaryColor.withValues(alpha: 0.3), width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 20,
          offset: const Offset(0, 8),
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
