// lib/core/models/dragon_ball_agreement_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// 드래곤볼 동의서 모델
/// 사용자가 드래곤볼 서비스 이용 시 부품 임의 운용 동의를 기록
/// Firestore: dragonBallAgreements/{agreementId}
class DragonBallAgreementModel {
  final String agreementId;
  final String userId;
  final String userName;
  final String userEmail;
  final DateTime agreedAt;       // 동의 시각
  final String ipAddress;        // 법적 증거용 IP 주소
  final String agreementVersion; // 약관 버전 (v1.0, v1.1 등)
  final String signature;        // 디지털 서명 (사용자 이름 입력)

  DragonBallAgreementModel({
    required this.agreementId,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.agreedAt,
    required this.ipAddress,
    required this.agreementVersion,
    required this.signature,
  });

  /// Firestore 문서로 변환
  Map<String, dynamic> toMap() {
    return {
      'agreementId': agreementId,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'agreedAt': Timestamp.fromDate(agreedAt),
      'ipAddress': ipAddress,
      'agreementVersion': agreementVersion,
      'signature': signature,
    };
  }

  /// Firestore 문서에서 생성
  factory DragonBallAgreementModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return DragonBallAgreementModel(
      agreementId: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userEmail: data['userEmail'] ?? '',
      agreedAt: (data['agreedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      ipAddress: data['ipAddress'] ?? '',
      agreementVersion: data['agreementVersion'] ?? 'v1.0',
      signature: data['signature'] ?? '',
    );
  }

  /// Map에서 생성
  factory DragonBallAgreementModel.fromMap(Map<String, dynamic> data) {
    return DragonBallAgreementModel(
      agreementId: data['agreementId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userEmail: data['userEmail'] ?? '',
      agreedAt: data['agreedAt'] is Timestamp
          ? (data['agreedAt'] as Timestamp).toDate()
          : DateTime.now(),
      ipAddress: data['ipAddress'] ?? '',
      agreementVersion: data['agreementVersion'] ?? 'v1.0',
      signature: data['signature'] ?? '',
    );
  }

  /// copyWith 메서드
  DragonBallAgreementModel copyWith({
    String? agreementId,
    String? userId,
    String? userName,
    String? userEmail,
    DateTime? agreedAt,
    String? ipAddress,
    String? agreementVersion,
    String? signature,
  }) {
    return DragonBallAgreementModel(
      agreementId: agreementId ?? this.agreementId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      agreedAt: agreedAt ?? this.agreedAt,
      ipAddress: ipAddress ?? this.ipAddress,
      agreementVersion: agreementVersion ?? this.agreementVersion,
      signature: signature ?? this.signature,
    );
  }
}

/// 드래곤볼 약관 버전 상수
class DragonBallAgreementVersion {
  static const String v1_0 = 'v1.0';

  /// 현재 약관 버전
  static const String current = v1_0;

  /// 약관 전문 가져오기
  static String getTermsText(String version) {
    switch (version) {
      case v1_0:
        return _termsV1_0;
      default:
        return _termsV1_0;
    }
  }

  /// 약관 v1.0 전문
  static const String _termsV1_0 = '''
드래곤볼 서비스 이용약관 (v1.0)

제1조 (서비스 개요)
파이컴퓨터는 고객님의 부품을 최대 30일간 완전 무료로 보관하며, 합배송 서비스를 제공합니다.

제2조 (부품 운용 동의) ⭐ 중요
- 보관 기간 동안 파이컴퓨터는 부품을 렌탈/대여 서비스에 활용할 수 있습니다.
- 부품 보호 보험에 가입하여 손상 시 100% 보상합니다.
- 배송 요청 시 24시간 내 준비를 완료합니다.
- 운용 중인 부품도 우선적으로 회수하여 배송합니다.

제3조 (보관 기간)
- 기본 보관 기간: 30일 (입고일 기준)
- 만료 3일 전 알림을 발송합니다.
- 만료 시: 기본 배송지로 자동 배송 (기본 배송비 적용)

제4조 (배송비)
- 일괄 배송 기본: 10,000원 (구매자 5천 + 판매자 5천)
- 부품 2개 이상: 개당 3,000원 추가
- 개별 배송 대비 최대 50% 절감

제5조 (보상 및 책임)
- 부품 보호 보험 가입 (파이컴퓨터 부담)
- 부품 손상/분실 시 구매가 100% 보상
- 배송 지연 시 배송비 50% 환불

제6조 (서비스 해지)
- 언제든지 배송 요청으로 서비스 종료 가능
- 보관 중인 부품은 즉시 배송 처리

제7조 (약관 동의)
본 약관에 동의함으로써 상기 내용을 모두 이해하고 동의합니다.
''';
}
