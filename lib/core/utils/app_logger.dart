// lib/core/utils/app_logger.dart

import 'package:flutter/foundation.dart';

/// 로그 레벨 열거형
///
/// 로그의 심각도를 나타내며, debug < info < warning < error 순서로 정렬됩니다.
enum LogLevel {
  /// 디버그 레벨 - 개발 중 상세 정보
  debug,

  /// 정보 레벨 - 일반적인 정보성 메시지
  info,

  /// 경고 레벨 - 잠재적 문제 상황
  warning,

  /// 에러 레벨 - 오류 발생
  error,
}

/// 앱 전역 로거
///
/// Debug 모드에서는 모든 레벨의 로그를 콘솔에 출력합니다.
/// Release 모드에서는 error 레벨만 Crashlytics로 전송합니다 (향후 구현 예정).
///
/// 사용 예시:
/// ```dart
/// AppLogger.d('디버그 메시지');
/// AppLogger.i('정보 메시지', tag: 'MyScreen');
/// AppLogger.w('경고 메시지');
/// AppLogger.e('에러 메시지', stackTrace: StackTrace.current);
/// ```
class AppLogger {
  AppLogger._();

  /// 디버그 로그 출력
  ///
  /// [message] 로그 메시지
  /// [tag] 선택적 태그 (예: 클래스 이름, 기능 이름)
  static void d(String message, {String? tag}) {
    _log(LogLevel.debug, message, tag: tag);
  }

  /// 정보 로그 출력
  ///
  /// [message] 로그 메시지
  /// [tag] 선택적 태그 (예: 클래스 이름, 기능 이름)
  static void i(String message, {String? tag}) {
    _log(LogLevel.info, message, tag: tag);
  }

  /// 경고 로그 출력
  ///
  /// [message] 로그 메시지
  /// [tag] 선택적 태그 (예: 클래스 이름, 기능 이름)
  static void w(String message, {String? tag}) {
    _log(LogLevel.warning, message, tag: tag);
  }

  /// 에러 로그 출력
  ///
  /// [message] 로그 메시지
  /// [tag] 선택적 태그 (예: 클래스 이름, 기능 이름)
  /// [stackTrace] 선택적 스택 트레이스
  static void e(String message, {String? tag, StackTrace? stackTrace}) {
    _log(LogLevel.error, message, tag: tag, stackTrace: stackTrace);
  }

  /// 내부 로그 처리 메서드
  static void _log(
    LogLevel level,
    String message, {
    String? tag,
    StackTrace? stackTrace,
  }) {
    // Debug 모드: 모든 레벨 콘솔 출력
    if (kDebugMode) {
      final prefix = _getPrefix(level);
      final tagPrefix = tag != null ? '[$tag] ' : '';
      final logMessage = '$prefix$tagPrefix$message';

      // ignore: avoid_print
      print(logMessage);

      if (stackTrace != null) {
        // ignore: avoid_print
        print(stackTrace);
      }
    } else {
      // Release 모드: error 레벨만 Crashlytics 전송 (향후 구현)
      if (level == LogLevel.error) {
        _sendToCrashlytics(message, stackTrace: stackTrace, tag: tag);
      }
    }
  }

  /// 로그 레벨에 따른 접두사 반환
  static String _getPrefix(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return '[DEBUG] ';
      case LogLevel.info:
        return '[INFO] ';
      case LogLevel.warning:
        return '[WARNING] ';
      case LogLevel.error:
        return '[ERROR] ';
    }
  }

  /// Crashlytics로 에러 전송 (Placeholder)
  ///
  /// 향후 Firebase Crashlytics 연동 시 구현 예정
  static void _sendToCrashlytics(
    String message, {
    StackTrace? stackTrace,
    String? tag,
  }) {
    // TODO: Firebase Crashlytics 연동
    // FirebaseCrashlytics.instance.recordError(
    //   Exception(message),
    //   stackTrace,
    //   reason: tag ?? 'AppLogger.e',
    // );
  }
}
