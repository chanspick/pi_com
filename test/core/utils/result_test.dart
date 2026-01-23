// test/core/utils/result_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:pi_com/core/errors/failures.dart';
import 'package:pi_com/core/utils/result.dart';

void main() {
  group('Result sealed class', () {
    group('Success', () {
      test('Success는 data 속성을 가져야 한다', () {
        const result = Success<int>(42);
        expect(result.data, equals(42));
      });

      test('Success는 Result를 상속해야 한다', () {
        const result = Success<String>('테스트');
        expect(result, isA<Result<String>>());
      });

      test('Success는 다양한 타입의 데이터를 저장할 수 있어야 한다', () {
        const intResult = Success<int>(100);
        const stringResult = Success<String>('문자열');
        const listResult = Success<List<int>>([1, 2, 3]);

        expect(intResult.data, equals(100));
        expect(stringResult.data, equals('문자열'));
        expect(listResult.data, equals([1, 2, 3]));
      });

      test('Success는 null 값도 저장할 수 있어야 한다', () {
        const result = Success<String?>(null);
        expect(result.data, isNull);
      });
    });

    group('Fail', () {
      test('Fail은 failure 속성을 가져야 한다', () {
        const failure = NetworkFailure();
        const result = Fail<int>(failure);
        expect(result.failure, equals(failure));
      });

      test('Fail은 Result를 상속해야 한다', () {
        const result = Fail<String>(AuthFailure());
        expect(result, isA<Result<String>>());
      });

      test('Fail은 다양한 Failure 타입을 저장할 수 있어야 한다', () {
        const networkResult = Fail<int>(NetworkFailure());
        const authResult = Fail<int>(AuthFailure());
        const paymentResult = Fail<int>(PaymentFailure());
        const serverResult = Fail<int>(ServerFailure());
        const validationResult = Fail<int>(ValidationFailure());
        const notFoundResult = Fail<int>(NotFoundFailure());

        expect(networkResult.failure, isA<NetworkFailure>());
        expect(authResult.failure, isA<AuthFailure>());
        expect(paymentResult.failure, isA<PaymentFailure>());
        expect(serverResult.failure, isA<ServerFailure>());
        expect(validationResult.failure, isA<ValidationFailure>());
        expect(notFoundResult.failure, isA<NotFoundFailure>());
      });
    });

    group('Factory constructors', () {
      test('Result.success()는 Success를 반환해야 한다', () {
        final Result<int> result = Result.success(42);
        expect(result, isA<Success<int>>());
        expect((result as Success<int>).data, equals(42));
      });

      test('Result.failure()는 Fail을 반환해야 한다', () {
        const failure = NetworkFailure();
        final Result<int> result = Result.failure(failure);
        expect(result, isA<Fail<int>>());
        expect((result as Fail<int>).failure, equals(failure));
      });
    });

    group('when() 메서드', () {
      test('Success일 때 success 콜백이 호출되어야 한다', () {
        const result = Success<int>(42);
        var successCalled = false;
        var failCalled = false;

        result.when(
          success: (data) {
            successCalled = true;
            expect(data, equals(42));
          },
          failure: (failure) {
            failCalled = true;
          },
        );

        expect(successCalled, isTrue);
        expect(failCalled, isFalse);
      });

      test('Fail일 때 failure 콜백이 호출되어야 한다', () {
        const result = Fail<int>(NetworkFailure());
        var successCalled = false;
        var failCalled = false;

        result.when(
          success: (data) {
            successCalled = true;
          },
          failure: (failure) {
            failCalled = true;
            expect(failure, isA<NetworkFailure>());
          },
        );

        expect(successCalled, isFalse);
        expect(failCalled, isTrue);
      });

      test('when()은 값을 반환할 수 있어야 한다', () {
        const successResult = Success<int>(42);
        const failResult = Fail<int>(NetworkFailure());

        final successValue = successResult.when(
          success: (data) => 'Success: $data',
          failure: (failure) => 'Fail: ${failure.message}',
        );

        final failValue = failResult.when(
          success: (data) => 'Success: $data',
          failure: (failure) => 'Fail: ${failure.message}',
        );

        expect(successValue, equals('Success: 42'));
        expect(failValue, equals('Fail: 네트워크 연결을 확인해주세요'));
      });

      test('when()은 다양한 반환 타입을 지원해야 한다', () {
        const result = Success<int>(10);

        final intValue = result.when(
          success: (data) => data * 2,
          failure: (failure) => -1,
        );

        final boolValue = result.when(
          success: (data) => data > 5,
          failure: (failure) => false,
        );

        expect(intValue, equals(20));
        expect(boolValue, isTrue);
      });
    });

    group('isSuccess / isFailure', () {
      test('Success의 isSuccess는 true여야 한다', () {
        const result = Success<int>(42);
        expect(result.isSuccess, isTrue);
      });

      test('Success의 isFailure는 false여야 한다', () {
        const result = Success<int>(42);
        expect(result.isFailure, isFalse);
      });

      test('Fail의 isSuccess는 false여야 한다', () {
        const result = Fail<int>(NetworkFailure());
        expect(result.isSuccess, isFalse);
      });

      test('Fail의 isFailure는 true여야 한다', () {
        const result = Fail<int>(NetworkFailure());
        expect(result.isFailure, isTrue);
      });
    });

    group('Pattern matching with switch', () {
      test('Dart 3 패턴 매칭으로 Success를 처리할 수 있어야 한다', () {
        final Result<int> result = Result.success(42);

        final message = switch (result) {
          Success<int>(:final data) => 'Got: $data',
          Fail<int>(:final failure) => 'Error: ${failure.message}',
        };

        expect(message, equals('Got: 42'));
      });

      test('Dart 3 패턴 매칭으로 Fail을 처리할 수 있어야 한다', () {
        final Result<int> result = Result.failure(const AuthFailure());

        final message = switch (result) {
          Success<int>(:final data) => 'Got: $data',
          Fail<int>(:final failure) => 'Error: ${failure.message}',
        };

        expect(message, equals('Error: 인증에 실패했습니다'));
      });
    });

    group('Equality', () {
      test('같은 데이터를 가진 Success는 동일해야 한다', () {
        const result1 = Success<int>(42);
        const result2 = Success<int>(42);
        expect(result1, equals(result2));
      });

      test('다른 데이터를 가진 Success는 다르다', () {
        const result1 = Success<int>(42);
        const result2 = Success<int>(100);
        expect(result1, isNot(equals(result2)));
      });

      test('같은 Failure를 가진 Fail은 동일해야 한다', () {
        const result1 = Fail<int>(NetworkFailure());
        const result2 = Fail<int>(NetworkFailure());
        expect(result1, equals(result2));
      });

      test('다른 Failure를 가진 Fail은 다르다', () {
        const result1 = Fail<int>(NetworkFailure());
        const result2 = Fail<int>(AuthFailure());
        expect(result1, isNot(equals(result2)));
      });
    });
  });
}
