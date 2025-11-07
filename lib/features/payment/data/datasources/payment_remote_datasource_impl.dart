import 'package:dio/dio.dart';
import 'package:pi_com/features/payment/data/datasources/payment_remote_datasource.dart';
import 'package:pi_com/features/payment/data/models/payment_prepare_request_model.dart';
import 'package:pi_com/features/payment/data/models/payment_prepare_response_model.dart';
import 'package:pi_com/features/payment/data/models/payment_approval_request_model.dart';
import 'package:pi_com/features/payment/data/models/payment_approval_response_model.dart';

/// 결제 Remote DataSource 구현체
class PaymentRemoteDataSourceImpl implements PaymentRemoteDataSource {
  final Dio _dio;
  final String _baseUrl;

  PaymentRemoteDataSourceImpl({
    Dio? dio,
    String? baseUrl,
  })  : _dio = dio ?? Dio(),
        // Firebase Functions URL 사용
        _baseUrl = baseUrl ?? 'https://asia-northeast3-picom-team.cloudfunctions.net/api';

  @override
  Future<PaymentPrepareResponseModel> preparePayment(
    PaymentPrepareRequestModel request,
  ) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/api/payment/prepare',
        data: request.toJson(),
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return PaymentPrepareResponseModel.fromJson(
          response.data as Map<String, dynamic>,
        );
      } else {
        throw Exception('결제 준비 실패: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception('결제 준비 실패: ${e.response?.data}');
      } else {
        throw Exception('네트워크 오류: ${e.message}');
      }
    } catch (e) {
      throw Exception('결제 준비 중 오류 발생: $e');
    }
  }

  @override
  Future<PaymentApprovalResponseModel> approvePayment(
    PaymentApprovalRequestModel request,
  ) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/api/payment/approve',
        data: request.toJson(),
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return PaymentApprovalResponseModel.fromJson(
          response.data as Map<String, dynamic>,
        );
      } else {
        throw Exception('결제 승인 실패: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception('결제 승인 실패: ${e.response?.data}');
      } else {
        throw Exception('네트워크 오류: ${e.message}');
      }
    } catch (e) {
      throw Exception('결제 승인 중 오류 발생: $e');
    }
  }

  @override
  Future<void> cancelPayment({
    required String tid,
    required int cancelAmount,
    required int cancelTaxFreeAmount,
  }) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/api/payment/cancel',
        data: {
          'tid': tid,
          'cancel_amount': cancelAmount,
          'cancel_tax_free_amount': cancelTaxFreeAmount,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('결제 취소 실패: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception('결제 취소 실패: ${e.response?.data}');
      } else {
        throw Exception('네트워크 오류: ${e.message}');
      }
    } catch (e) {
      throw Exception('결제 취소 중 오류 발생: $e');
    }
  }
}
