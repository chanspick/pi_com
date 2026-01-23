// lib/core/errors/failures.dart

/// 앱에서 발생하는 실패(에러) 타입을 정의하는 sealed 클래스
///
/// Clean Architecture에서 도메인 레이어의 에러 처리를 위해 사용됩니다.
/// Result 타입과 함께 사용하여 예외 대신 명시적인 에러 핸들링을 구현합니다.
///
/// 사용 예시:
/// ```dart
/// Result<User> fetchUser() {
///   try {
///     final user = await api.getUser();
///     return Result.success(user);
///   } on NetworkException {
///     return Result.failure(const NetworkFailure());
///   }
/// }
/// ```
sealed class Failure {
  /// 사용자에게 표시할 에러 메시지
  final String message;

  /// 에러 코드 (로깅, 디버깅용)
  final String code;

  /// 원본 에러 객체 (디버깅용)
  final Object? originalError;

  const Failure({
    required this.message,
    required this.code,
    this.originalError,
  });

  @override
  String toString() => '$runtimeType(code: $code, message: $message)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Failure &&
        other.runtimeType == runtimeType &&
        other.message == message &&
        other.code == code &&
        other.originalError == originalError;
  }

  @override
  int get hashCode => Object.hash(runtimeType, message, code, originalError);
}

/// 네트워크 관련 실패
///
/// 인터넷 연결 불가, 타임아웃, DNS 오류 등의 경우에 사용됩니다.
final class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = '네트워크 연결을 확인해주세요',
    super.code = 'NETWORK_ERROR',
    super.originalError,
  });
}

/// 인증 관련 실패
///
/// 로그인 실패, 세션 만료, 권한 없음 등의 경우에 사용됩니다.
final class AuthFailure extends Failure {
  const AuthFailure({
    super.message = '인증에 실패했습니다',
    super.code = 'AUTH_ERROR',
    super.originalError,
  });
}

/// 결제 관련 실패
///
/// 결제 실패, 잔액 부족, 카드 오류 등의 경우에 사용됩니다.
final class PaymentFailure extends Failure {
  const PaymentFailure({
    super.message = '결제 처리 중 오류가 발생했습니다',
    super.code = 'PAYMENT_ERROR',
    super.originalError,
  });
}

/// 서버 관련 실패
///
/// 서버 내부 오류, 서버 점검, 응답 파싱 실패 등의 경우에 사용됩니다.
final class ServerFailure extends Failure {
  const ServerFailure({
    super.message = '서버 오류가 발생했습니다',
    super.code = 'SERVER_ERROR',
    super.originalError,
  });
}

/// 유효성 검사 실패
///
/// 입력값 형식 오류, 필수값 누락, 범위 초과 등의 경우에 사용됩니다.
final class ValidationFailure extends Failure {
  const ValidationFailure({
    super.message = '입력값이 올바르지 않습니다',
    super.code = 'VALIDATION_ERROR',
    super.originalError,
  });
}

/// 리소스를 찾을 수 없음
///
/// 존재하지 않는 상품, 사용자, 주문 등을 조회할 때 사용됩니다.
final class NotFoundFailure extends Failure {
  const NotFoundFailure({
    super.message = '요청한 리소스를 찾을 수 없습니다',
    super.code = 'NOT_FOUND',
    super.originalError,
  });
}
