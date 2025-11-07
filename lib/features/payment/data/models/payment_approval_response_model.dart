import 'package:pi_com/features/payment/domain/entities/payment_entity.dart';

/// 결제 승인 응답 모델
class PaymentApprovalResponseModel {
  final String aid; // 요청 고유 번호
  final String tid; // 결제 고유 번호
  final String cid; // 가맹점 코드
  final String sid; // 정기결제용 ID (단건 결제에서는 없을 수 있음)
  final String partnerOrderId; // 파트너 주문 번호
  final String partnerUserId; // 파트너 회원 ID
  final String paymentMethodType; // 결제 수단 (CARD, MONEY 등)
  final AmountModel amount; // 결제 금액 정보
  final CardInfoModel? cardInfo; // 카드 정보 (카드 결제 시)
  final String itemName; // 상품명
  final String itemCode; // 상품 코드
  final int quantity; // 상품 수량
  final DateTime createdAt; // 결제 준비 요청 시각
  final DateTime approvedAt; // 결제 승인 시각
  final String payload; // 요청 시 전달한 payload

  PaymentApprovalResponseModel({
    required this.aid,
    required this.tid,
    required this.cid,
    this.sid = '',
    required this.partnerOrderId,
    required this.partnerUserId,
    required this.paymentMethodType,
    required this.amount,
    this.cardInfo,
    required this.itemName,
    required this.itemCode,
    required this.quantity,
    required this.createdAt,
    required this.approvedAt,
    this.payload = '',
  });

  factory PaymentApprovalResponseModel.fromJson(Map<String, dynamic> json) {
    return PaymentApprovalResponseModel(
      aid: json['aid'] as String,
      tid: json['tid'] as String,
      cid: json['cid'] as String,
      sid: json['sid'] as String? ?? '',
      partnerOrderId: json['partner_order_id'] as String,
      partnerUserId: json['partner_user_id'] as String,
      paymentMethodType: json['payment_method_type'] as String,
      amount: AmountModel.fromJson(json['amount'] as Map<String, dynamic>),
      cardInfo: json['card_info'] != null
          ? CardInfoModel.fromJson(json['card_info'] as Map<String, dynamic>)
          : null,
      itemName: json['item_name'] as String,
      itemCode: json['item_code'] as String? ?? '',
      quantity: json['quantity'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      approvedAt: DateTime.parse(json['approved_at'] as String),
      payload: json['payload'] as String? ?? '',
    );
  }

  PaymentEntity toEntity() {
    return PaymentEntity(
      tid: tid,
      orderId: partnerOrderId,
      userId: partnerUserId,
      itemName: itemName,
      totalAmount: amount.total,
      createdAt: createdAt,
      approvedAt: approvedAt.toIso8601String(),
      status: PaymentStatus.approved,
    );
  }
}

/// 결제 금액 정보
class AmountModel {
  final int total; // 전체 결제 금액
  final int taxFree; // 비과세 금액
  final int vat; // 부가세 금액
  final int point; // 사용한 포인트
  final int discount; // 할인 금액
  final int greenDeposit; // 컵 보증금

  AmountModel({
    required this.total,
    required this.taxFree,
    required this.vat,
    required this.point,
    required this.discount,
    this.greenDeposit = 0,
  });

  factory AmountModel.fromJson(Map<String, dynamic> json) {
    return AmountModel(
      total: json['total'] as int,
      taxFree: json['tax_free'] as int,
      vat: json['vat'] as int,
      point: json['point'] as int,
      discount: json['discount'] as int,
      greenDeposit: json['green_deposit'] as int? ?? 0,
    );
  }
}

/// 카드 정보
class CardInfoModel {
  final String kakaopayPurchaseCorp; // 카카오페이 매입사명
  final String kakaopayPurchaseCorpCode; // 카카오페이 매입사 코드
  final String kakaopayIssuerCorp; // 카카오페이 발급사명
  final String kakaopayIssuerCorpCode; // 카카오페이 발급사 코드
  final String bin; // 카드 BIN
  final String cardType; // 카드 타입
  final String installMonth; // 할부 개월 수
  final String approvedId; // 카드사 승인번호
  final String cardMid; // 카드사 가맹점 번호

  CardInfoModel({
    required this.kakaopayPurchaseCorp,
    required this.kakaopayPurchaseCorpCode,
    required this.kakaopayIssuerCorp,
    required this.kakaopayIssuerCorpCode,
    required this.bin,
    required this.cardType,
    required this.installMonth,
    required this.approvedId,
    required this.cardMid,
  });

  factory CardInfoModel.fromJson(Map<String, dynamic> json) {
    return CardInfoModel(
      kakaopayPurchaseCorp: json['kakaopay_purchase_corp'] as String,
      kakaopayPurchaseCorpCode: json['kakaopay_purchase_corp_code'] as String,
      kakaopayIssuerCorp: json['kakaopay_issuer_corp'] as String,
      kakaopayIssuerCorpCode: json['kakaopay_issuer_corp_code'] as String,
      bin: json['bin'] as String,
      cardType: json['card_type'] as String,
      installMonth: json['install_month'] as String,
      approvedId: json['approved_id'] as String,
      cardMid: json['card_mid'] as String,
    );
  }
}
