import 'package:dio/dio.dart';
import 'package:pi_com/core/constants/app_constants.dart';
import 'package:pi_com/features/payment/domain/entities/toss_payment_entity.dart';

/// 토스페이먼츠 Remote DataSource 인터페이스
abstract class TossPaymentRemoteDataSource {
  /// 결제 승인
  Future<TossPaymentEntity> confirmPayment({
    required String paymentKey,
    required String orderId,
    required int amount,
  });

  /// 결제 취소
  Future<TossPaymentEntity> cancelPayment({
    required String paymentKey,
    required String cancelReason,
    int? cancelAmount,
  });

  /// 결제 조회
  Future<TossPaymentEntity> getPayment({
    required String paymentKey,
  });
}

/// 토스페이먼츠 Remote DataSource 구현체
class TossPaymentRemoteDataSourceImpl implements TossPaymentRemoteDataSource {
  final Dio _dio;
  final String _baseUrl;

  TossPaymentRemoteDataSourceImpl({
    Dio? dio,
    String? baseUrl,
  })  : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: AppConstants.httpConnectTimeout,
              receiveTimeout: AppConstants.httpReceiveTimeout,
              sendTimeout: AppConstants.httpReceiveTimeout,
            )),
        // Firebase Functions URL 사용
        _baseUrl = baseUrl ??
            'https://asia-northeast3-picom-team.cloudfunctions.net/api';

  @override
  Future<TossPaymentEntity> confirmPayment({
    required String paymentKey,
    required String orderId,
    required int amount,
  }) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/toss-payment/confirm',
        data: {
          'paymentKey': paymentKey,
          'orderId': orderId,
          'amount': amount,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return TossPaymentEntity.fromJson(
          response.data as Map<String, dynamic>,
        );
      } else {
        throw Exception('결제 승인 실패: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final errorData = e.response?.data;
        final errorMessage = errorData is Map
            ? errorData['message'] ?? errorData['error']
            : '결제 승인 실패';
        throw Exception('결제 승인 실패: $errorMessage');
      } else {
        throw Exception('네트워크 오류: ${e.message}');
      }
    } catch (e) {
      throw Exception('결제 승인 중 오류 발생: $e');
    }
  }

  @override
  Future<TossPaymentEntity> cancelPayment({
    required String paymentKey,
    required String cancelReason,
    int? cancelAmount,
  }) async {
    try {
      final data = <String, dynamic>{
        'paymentKey': paymentKey,
        'cancelReason': cancelReason,
      };
      if (cancelAmount != null) {
        data['cancelAmount'] = cancelAmount;
      }

      final response = await _dio.post(
        '$_baseUrl/toss-payment/cancel',
        data: data,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return TossPaymentEntity.fromJson(
          response.data as Map<String, dynamic>,
        );
      } else {
        throw Exception('결제 취소 실패: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final errorData = e.response?.data;
        final errorMessage = errorData is Map
            ? errorData['message'] ?? errorData['error']
            : '결제 취소 실패';
        throw Exception('결제 취소 실패: $errorMessage');
      } else {
        throw Exception('네트워크 오류: ${e.message}');
      }
    } catch (e) {
      throw Exception('결제 취소 중 오류 발생: $e');
    }
  }

  @override
  Future<TossPaymentEntity> getPayment({
    required String paymentKey,
  }) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/toss-payment/$paymentKey',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return TossPaymentEntity.fromJson(
          response.data as Map<String, dynamic>,
        );
      } else {
        throw Exception('결제 조회 실패: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final errorData = e.response?.data;
        final errorMessage = errorData is Map
            ? errorData['message'] ?? errorData['error']
            : '결제 조회 실패';
        throw Exception('결제 조회 실패: $errorMessage');
      } else {
        throw Exception('네트워크 오류: ${e.message}');
      }
    } catch (e) {
      throw Exception('결제 조회 중 오류 발생: $e');
    }
  }
}
