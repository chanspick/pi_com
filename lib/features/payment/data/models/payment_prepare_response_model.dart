import 'package:pi_com/features/payment/domain/entities/payment_entity.dart';

/// 결제 준비 응답 모델
class PaymentPrepareResponseModel {
  final String tid; // 결제 고유 번호
  final String nextRedirectAppUrl; // 앱 환경 리다이렉트 URL
  final String nextRedirectMobileUrl; // 모바일 웹 리다이렉트 URL
  final String nextRedirectPcUrl; // PC 웹 리다이렉트 URL
  final String? androidAppScheme; // Android 앱 스킴
  final String? iosAppScheme; // iOS 앱 스킴
  final DateTime createdAt; // 결제 준비 요청 시간

  PaymentPrepareResponseModel({
    required this.tid,
    required this.nextRedirectAppUrl,
    required this.nextRedirectMobileUrl,
    required this.nextRedirectPcUrl,
    this.androidAppScheme,
    this.iosAppScheme,
    required this.createdAt,
  });

  factory PaymentPrepareResponseModel.fromJson(Map<String, dynamic> json) {
    return PaymentPrepareResponseModel(
      tid: json['tid'] as String,
      nextRedirectAppUrl: json['next_redirect_app_url'] as String,
      nextRedirectMobileUrl: json['next_redirect_mobile_url'] as String,
      nextRedirectPcUrl: json['next_redirect_pc_url'] as String,
      androidAppScheme: json['android_app_scheme'] as String?,
      iosAppScheme: json['ios_app_scheme'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  PaymentEntity toEntity({
    required String orderId,
    required String userId,
    required String itemName,
    required int totalAmount,
  }) {
    return PaymentEntity(
      tid: tid,
      orderId: orderId,
      userId: userId,
      itemName: itemName,
      totalAmount: totalAmount,
      createdAt: createdAt,
      status: PaymentStatus.ready,
      nextRedirectAppUrl: nextRedirectAppUrl,
      nextRedirectMobileUrl: nextRedirectMobileUrl,
      nextRedirectPcUrl: nextRedirectPcUrl,
    );
  }
}
