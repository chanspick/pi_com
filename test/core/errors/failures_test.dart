// test/core/errors/failures_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:pi_com/core/errors/failures.dart';

void main() {
  group('Failure sealed class', () {
    group('Failure 기본 속성', () {
      test('Failure는 message 속성을 가져야 한다', () {
        const failure = NetworkFailure();
        expect(failure.message, isNotEmpty);
      });

      test('Failure는 code 속성을 가져야 한다', () {
        const failure = NetworkFailure();
        expect(failure.code, isNotEmpty);
      });

      test('Failure는 originalError 속성을 가져야 한다', () {
        const failure = NetworkFailure();
        expect(failure.originalError, isNull);
      });

      test('Failure는 originalError를 받을 수 있어야 한다', () {
        final error = Exception('테스트 에러');
        final failure = NetworkFailure(originalError: error);
        expect(failure.originalError, equals(error));
      });
    });

    group('NetworkFailure', () {
      test('NetworkFailure는 기본 message를 가져야 한다', () {
        const failure = NetworkFailure();
        expect(failure.message, equals('네트워크 연결을 확인해주세요'));
      });

      test('NetworkFailure는 기본 code를 가져야 한다', () {
        const failure = NetworkFailure();
        expect(failure.code, equals('NETWORK_ERROR'));
      });

      test('NetworkFailure는 커스텀 message를 받을 수 있어야 한다', () {
        const failure = NetworkFailure(message: '커스텀 메시지');
        expect(failure.message, equals('커스텀 메시지'));
      });

      test('NetworkFailure는 커스텀 code를 받을 수 있어야 한다', () {
        const failure = NetworkFailure(code: 'CUSTOM_CODE');
        expect(failure.code, equals('CUSTOM_CODE'));
      });
    });

    group('AuthFailure', () {
      test('AuthFailure는 기본 message를 가져야 한다', () {
        const failure = AuthFailure();
        expect(failure.message, equals('인증에 실패했습니다'));
      });

      test('AuthFailure는 기본 code를 가져야 한다', () {
        const failure = AuthFailure();
        expect(failure.code, equals('AUTH_ERROR'));
      });

      test('AuthFailure는 커스텀 message를 받을 수 있어야 한다', () {
        const failure = AuthFailure(message: '세션이 만료되었습니다');
        expect(failure.message, equals('세션이 만료되었습니다'));
      });
    });

    group('PaymentFailure', () {
      test('PaymentFailure는 기본 message를 가져야 한다', () {
        const failure = PaymentFailure();
        expect(failure.message, equals('결제 처리 중 오류가 발생했습니다'));
      });

      test('PaymentFailure는 기본 code를 가져야 한다', () {
        const failure = PaymentFailure();
        expect(failure.code, equals('PAYMENT_ERROR'));
      });

      test('PaymentFailure는 커스텀 message를 받을 수 있어야 한다', () {
        const failure = PaymentFailure(message: '잔액이 부족합니다');
        expect(failure.message, equals('잔액이 부족합니다'));
      });
    });

    group('ServerFailure', () {
      test('ServerFailure는 기본 message를 가져야 한다', () {
        const failure = ServerFailure();
        expect(failure.message, equals('서버 오류가 발생했습니다'));
      });

      test('ServerFailure는 기본 code를 가져야 한다', () {
        const failure = ServerFailure();
        expect(failure.code, equals('SERVER_ERROR'));
      });

      test('ServerFailure는 커스텀 message를 받을 수 있어야 한다', () {
        const failure = ServerFailure(message: '서버 점검 중입니다');
        expect(failure.message, equals('서버 점검 중입니다'));
      });
    });

    group('ValidationFailure', () {
      test('ValidationFailure는 기본 message를 가져야 한다', () {
        const failure = ValidationFailure();
        expect(failure.message, equals('입력값이 올바르지 않습니다'));
      });

      test('ValidationFailure는 기본 code를 가져야 한다', () {
        const failure = ValidationFailure();
        expect(failure.code, equals('VALIDATION_ERROR'));
      });

      test('ValidationFailure는 커스텀 message를 받을 수 있어야 한다', () {
        const failure = ValidationFailure(message: '이메일 형식이 올바르지 않습니다');
        expect(failure.message, equals('이메일 형식이 올바르지 않습니다'));
      });
    });

    group('NotFoundFailure', () {
      test('NotFoundFailure는 기본 message를 가져야 한다', () {
        const failure = NotFoundFailure();
        expect(failure.message, equals('요청한 리소스를 찾을 수 없습니다'));
      });

      test('NotFoundFailure는 기본 code를 가져야 한다', () {
        const failure = NotFoundFailure();
        expect(failure.code, equals('NOT_FOUND'));
      });

      test('NotFoundFailure는 커스텀 message를 받을 수 있어야 한다', () {
        const failure = NotFoundFailure(message: '상품을 찾을 수 없습니다');
        expect(failure.message, equals('상품을 찾을 수 없습니다'));
      });
    });

    group('toString()', () {
      test('NetworkFailure의 toString은 올바른 형식이어야 한다', () {
        const failure = NetworkFailure();
        final result = failure.toString();
        expect(result, contains('NetworkFailure'));
        expect(result, contains('NETWORK_ERROR'));
        expect(result, contains('네트워크 연결을 확인해주세요'));
      });

      test('AuthFailure의 toString은 올바른 형식이어야 한다', () {
        const failure = AuthFailure();
        final result = failure.toString();
        expect(result, contains('AuthFailure'));
        expect(result, contains('AUTH_ERROR'));
      });

      test('PaymentFailure의 toString은 올바른 형식이어야 한다', () {
        const failure = PaymentFailure();
        final result = failure.toString();
        expect(result, contains('PaymentFailure'));
        expect(result, contains('PAYMENT_ERROR'));
      });

      test('ServerFailure의 toString은 올바른 형식이어야 한다', () {
        const failure = ServerFailure();
        final result = failure.toString();
        expect(result, contains('ServerFailure'));
        expect(result, contains('SERVER_ERROR'));
      });

      test('ValidationFailure의 toString은 올바른 형식이어야 한다', () {
        const failure = ValidationFailure();
        final result = failure.toString();
        expect(result, contains('ValidationFailure'));
        expect(result, contains('VALIDATION_ERROR'));
      });

      test('NotFoundFailure의 toString은 올바른 형식이어야 한다', () {
        const failure = NotFoundFailure();
        final result = failure.toString();
        expect(result, contains('NotFoundFailure'));
        expect(result, contains('NOT_FOUND'));
      });
    });

    group('Failure 타입 검사', () {
      test('모든 Failure 서브클래스는 Failure를 상속해야 한다', () {
        const networkFailure = NetworkFailure();
        const authFailure = AuthFailure();
        const paymentFailure = PaymentFailure();
        const serverFailure = ServerFailure();
        const validationFailure = ValidationFailure();
        const notFoundFailure = NotFoundFailure();

        expect(networkFailure, isA<Failure>());
        expect(authFailure, isA<Failure>());
        expect(paymentFailure, isA<Failure>());
        expect(serverFailure, isA<Failure>());
        expect(validationFailure, isA<Failure>());
        expect(notFoundFailure, isA<Failure>());
      });
    });

    group('Equality', () {
      test('같은 값을 가진 NetworkFailure는 동일해야 한다', () {
        const failure1 = NetworkFailure();
        const failure2 = NetworkFailure();
        expect(failure1, equals(failure2));
      });

      test('다른 message를 가진 NetworkFailure는 다르다', () {
        const failure1 = NetworkFailure(message: '메시지1');
        const failure2 = NetworkFailure(message: '메시지2');
        expect(failure1, isNot(equals(failure2)));
      });
    });
  });
}
