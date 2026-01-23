// lib/core/utils/result.dart

import 'package:pi_com/core/errors/failures.dart';

/// 성공 또는 실패를 나타내는 Result 타입
///
/// 예외(Exception) 대신 명시적인 에러 핸들링을 위해 사용됩니다.
/// Dart 3의 sealed class를 사용하여 패턴 매칭을 지원합니다.
///
/// 사용 예시:
/// ```dart
/// Future<Result<User>> fetchUser(String id) async {
///   try {
///     final user = await api.getUser(id);
///     return Result.success(user);
///   } on NetworkException {
///     return Result.failure(const NetworkFailure());
///   }
/// }
///
/// // 사용
/// final result = await fetchUser('123');
/// result.when(
///   success: (user) => print('사용자: ${user.name}'),
///   failure: (failure) => print('에러: ${failure.message}'),
/// );
///
/// // 또는 패턴 매칭
/// switch (result) {
///   case Success(:final data):
///     print('사용자: ${data.name}');
///   case Fail(:final failure):
///     print('에러: ${failure.message}');
/// }
/// ```
sealed class Result<T> {
  const Result._();

  /// 성공 결과 생성
  factory Result.success(T data) => Success<T>(data);

  /// 실패 결과 생성
  factory Result.failure(Failure failure) => Fail<T>(failure);

  /// 성공 여부
  bool get isSuccess;

  /// 실패 여부
  bool get isFailure;

  /// 패턴 매칭 메서드
  ///
  /// 성공 또는 실패에 따라 적절한 콜백을 실행하고 결과를 반환합니다.
  ///
  /// [success] 성공 시 호출되는 콜백 (데이터 전달)
  /// [failure] 실패 시 호출되는 콜백 (Failure 전달)
  ///
  /// Returns: 콜백의 반환값
  R when<R>({
    required R Function(T data) success,
    required R Function(Failure failure) failure,
  });
}

/// 성공 결과
///
/// 작업이 성공했을 때의 결과를 나타냅니다.
/// [data]에 성공 시의 데이터가 포함됩니다.
final class Success<T> extends Result<T> {
  /// 성공 시의 데이터
  final T data;

  const Success(this.data) : super._();

  @override
  bool get isSuccess => true;

  @override
  bool get isFailure => false;

  @override
  R when<R>({
    required R Function(T data) success,
    required R Function(Failure failure) failure,
  }) {
    return success(data);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Success<T> && other.data == data;
  }

  @override
  int get hashCode => data.hashCode;

  @override
  String toString() => 'Success($data)';
}

/// 실패 결과
///
/// 작업이 실패했을 때의 결과를 나타냅니다.
/// [failure]에 실패 원인에 대한 정보가 포함됩니다.
final class Fail<T> extends Result<T> {
  /// 실패 정보
  final Failure failure;

  const Fail(this.failure) : super._();

  @override
  bool get isSuccess => false;

  @override
  bool get isFailure => true;

  @override
  R when<R>({
    required R Function(T data) success,
    required R Function(Failure failure) failure,
  }) {
    return failure(this.failure);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Fail<T> && other.failure == failure;
  }

  @override
  int get hashCode => failure.hashCode;

  @override
  String toString() => 'Fail(${failure.code}: ${failure.message})';
}
