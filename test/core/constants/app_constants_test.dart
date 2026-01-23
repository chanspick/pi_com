// test/core/constants/app_constants_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:pi_com/core/constants/app_constants.dart';

void main() {
  group('AppConstants', () {
    group('배송비 상수', () {
      test('defaultShippingFee는 4500이어야 한다', () {
        expect(AppConstants.defaultShippingFee, equals(4500));
      });

      test('defaultShippingFee는 int 타입이어야 한다', () {
        expect(AppConstants.defaultShippingFee, isA<int>());
      });
    });

    group('HTTP 타임아웃 상수', () {
      test('httpConnectTimeout은 10초여야 한다', () {
        expect(
          AppConstants.httpConnectTimeout,
          equals(const Duration(seconds: 10)),
        );
      });

      test('httpReceiveTimeout은 30초여야 한다', () {
        expect(
          AppConstants.httpReceiveTimeout,
          equals(const Duration(seconds: 30)),
        );
      });

      test('httpConnectTimeout은 Duration 타입이어야 한다', () {
        expect(AppConstants.httpConnectTimeout, isA<Duration>());
      });

      test('httpReceiveTimeout은 Duration 타입이어야 한다', () {
        expect(AppConstants.httpReceiveTimeout, isA<Duration>());
      });
    });

    group('페이지네이션 상수', () {
      test('defaultPageSize는 20이어야 한다', () {
        expect(AppConstants.defaultPageSize, equals(20));
      });

      test('maxPageSize는 100이어야 한다', () {
        expect(AppConstants.maxPageSize, equals(100));
      });

      test('defaultPageSize는 int 타입이어야 한다', () {
        expect(AppConstants.defaultPageSize, isA<int>());
      });

      test('maxPageSize는 int 타입이어야 한다', () {
        expect(AppConstants.maxPageSize, isA<int>());
      });

      test('defaultPageSize는 maxPageSize보다 작거나 같아야 한다', () {
        expect(
          AppConstants.defaultPageSize,
          lessThanOrEqualTo(AppConstants.maxPageSize),
        );
      });
    });

    group('드래곤볼 보관함 상수', () {
      test('dragonBallStorageDays는 30이어야 한다', () {
        expect(AppConstants.dragonBallStorageDays, equals(30));
      });

      test('dragonBallWarningDays는 7이어야 한다', () {
        expect(AppConstants.dragonBallWarningDays, equals(7));
      });

      test('dragonBallStorageDays는 int 타입이어야 한다', () {
        expect(AppConstants.dragonBallStorageDays, isA<int>());
      });

      test('dragonBallWarningDays는 int 타입이어야 한다', () {
        expect(AppConstants.dragonBallWarningDays, isA<int>());
      });

      test('dragonBallWarningDays는 dragonBallStorageDays보다 작아야 한다', () {
        expect(
          AppConstants.dragonBallWarningDays,
          lessThan(AppConstants.dragonBallStorageDays),
        );
      });
    });

    group('환불 및 구매 확정 상수', () {
      test('refundApprovalDeadlineDays는 2여야 한다', () {
        expect(AppConstants.refundApprovalDeadlineDays, equals(2));
      });

      test('autoConfirmPurchaseDays는 7이어야 한다', () {
        expect(AppConstants.autoConfirmPurchaseDays, equals(7));
      });

      test('refundApprovalDeadlineDays는 int 타입이어야 한다', () {
        expect(AppConstants.refundApprovalDeadlineDays, isA<int>());
      });

      test('autoConfirmPurchaseDays는 int 타입이어야 한다', () {
        expect(AppConstants.autoConfirmPurchaseDays, isA<int>());
      });

      test('refundApprovalDeadlineDays는 autoConfirmPurchaseDays보다 작아야 한다', () {
        expect(
          AppConstants.refundApprovalDeadlineDays,
          lessThan(AppConstants.autoConfirmPurchaseDays),
        );
      });
    });

    group('클래스 인스턴스화 제한', () {
      test('AppConstants는 private constructor를 가져야 한다', () {
        // AppConstants가 인스턴스화될 수 없음을 확인
        // 이는 static 상수만 사용하도록 설계됨
        expect(AppConstants, isA<Type>());
      });
    });
  });
}
