// test/core/utils/app_logger_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:pi_com/core/utils/app_logger.dart';

void main() {
  group('LogLevel', () {
    test('LogLevel enum에는 debug, info, warning, error가 포함되어야 한다', () {
      // LogLevel enum이 4개의 값을 가지는지 확인
      expect(LogLevel.values.length, equals(4));
      expect(LogLevel.values, contains(LogLevel.debug));
      expect(LogLevel.values, contains(LogLevel.info));
      expect(LogLevel.values, contains(LogLevel.warning));
      expect(LogLevel.values, contains(LogLevel.error));
    });

    test('LogLevel은 올바른 순서를 가져야 한다 (debug < info < warning < error)', () {
      expect(LogLevel.debug.index, lessThan(LogLevel.info.index));
      expect(LogLevel.info.index, lessThan(LogLevel.warning.index));
      expect(LogLevel.warning.index, lessThan(LogLevel.error.index));
    });
  });

  group('AppLogger', () {
    group('d() - Debug 로그', () {
      test('d()는 메시지만으로 호출 가능해야 한다', () {
        // debug 메서드가 예외 없이 호출되어야 함
        expect(() => AppLogger.d('Debug message'), returnsNormally);
      });

      test('d()는 선택적 tag 파라미터를 지원해야 한다', () {
        expect(
          () => AppLogger.d('Debug message', tag: 'TestTag'),
          returnsNormally,
        );
      });
    });

    group('i() - Info 로그', () {
      test('i()는 메시지만으로 호출 가능해야 한다', () {
        expect(() => AppLogger.i('Info message'), returnsNormally);
      });

      test('i()는 선택적 tag 파라미터를 지원해야 한다', () {
        expect(
          () => AppLogger.i('Info message', tag: 'TestTag'),
          returnsNormally,
        );
      });
    });

    group('w() - Warning 로그', () {
      test('w()는 메시지만으로 호출 가능해야 한다', () {
        expect(() => AppLogger.w('Warning message'), returnsNormally);
      });

      test('w()는 선택적 tag 파라미터를 지원해야 한다', () {
        expect(
          () => AppLogger.w('Warning message', tag: 'TestTag'),
          returnsNormally,
        );
      });
    });

    group('e() - Error 로그', () {
      test('e()는 메시지만으로 호출 가능해야 한다', () {
        expect(() => AppLogger.e('Error message'), returnsNormally);
      });

      test('e()는 선택적 tag 파라미터를 지원해야 한다', () {
        expect(
          () => AppLogger.e('Error message', tag: 'TestTag'),
          returnsNormally,
        );
      });

      test('e()는 선택적 stackTrace 파라미터를 지원해야 한다', () {
        final stackTrace = StackTrace.current;
        expect(
          () => AppLogger.e('Error message', stackTrace: stackTrace),
          returnsNormally,
        );
      });

      test('e()는 tag와 stackTrace를 동시에 지원해야 한다', () {
        final stackTrace = StackTrace.current;
        expect(
          () => AppLogger.e(
            'Error message',
            tag: 'TestTag',
            stackTrace: stackTrace,
          ),
          returnsNormally,
        );
      });
    });

    group('Log 포맷팅', () {
      test('tag가 제공되면 로그 출력에 포함되어야 한다', () {
        // tag가 있을 때 형식: [TAG] message
        expect(
          () => AppLogger.i('Message', tag: 'CustomTag'),
          returnsNormally,
        );
      });

      test('tag가 없으면 기본 형식으로 출력되어야 한다', () {
        // tag가 없을 때도 정상 동작해야 함
        expect(() => AppLogger.i('Message without tag'), returnsNormally);
      });
    });
  });
}
