/// 토스페이먼츠 결제 엔티티
class TossPaymentEntity {
  final String paymentKey; // 토스페이먼츠 결제 키
  final String orderId; // 주문 ID
  final String orderName; // 주문명
  final String status; // 결제 상태
  final String? method; // 결제 수단 (카드, 가상계좌, 간편결제 등)
  final int totalAmount; // 총 결제 금액
  final int balanceAmount; // 남은 금액
  final int suppliedAmount; // 공급가액
  final int vat; // 부가세
  final String requestedAt; // 결제 요청 시간
  final String? approvedAt; // 결제 승인 시간
  final TossCardInfo? card; // 카드 결제 정보
  final TossEasyPayInfo? easyPay; // 간편결제 정보
  final TossTransferInfo? transfer; // 계좌이체 정보
  final TossVirtualAccountInfo? virtualAccount; // 가상계좌 정보
  final TossMobilePhoneInfo? mobilePhone; // 휴대폰 결제 정보

  TossPaymentEntity({
    required this.paymentKey,
    required this.orderId,
    required this.orderName,
    required this.status,
    this.method,
    required this.totalAmount,
    required this.balanceAmount,
    required this.suppliedAmount,
    required this.vat,
    required this.requestedAt,
    this.approvedAt,
    this.card,
    this.easyPay,
    this.transfer,
    this.virtualAccount,
    this.mobilePhone,
  });

  factory TossPaymentEntity.fromJson(Map<String, dynamic> json) {
    return TossPaymentEntity(
      paymentKey: json['paymentKey'] as String,
      orderId: json['orderId'] as String,
      orderName: json['orderName'] as String,
      status: json['status'] as String,
      method: json['method'] as String?,
      totalAmount: json['totalAmount'] as int,
      balanceAmount: json['balanceAmount'] as int? ?? 0,
      suppliedAmount: json['suppliedAmount'] as int? ?? 0,
      vat: json['vat'] as int? ?? 0,
      requestedAt: json['requestedAt'] as String,
      approvedAt: json['approvedAt'] as String?,
      card: json['card'] != null
          ? TossCardInfo.fromJson(json['card'] as Map<String, dynamic>)
          : null,
      easyPay: json['easyPay'] != null
          ? TossEasyPayInfo.fromJson(json['easyPay'] as Map<String, dynamic>)
          : null,
      transfer: json['transfer'] != null
          ? TossTransferInfo.fromJson(json['transfer'] as Map<String, dynamic>)
          : null,
      virtualAccount: json['virtualAccount'] != null
          ? TossVirtualAccountInfo.fromJson(json['virtualAccount'] as Map<String, dynamic>)
          : null,
      mobilePhone: json['mobilePhone'] != null
          ? TossMobilePhoneInfo.fromJson(json['mobilePhone'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'paymentKey': paymentKey,
      'orderId': orderId,
      'orderName': orderName,
      'status': status,
      'method': method,
      'totalAmount': totalAmount,
      'balanceAmount': balanceAmount,
      'suppliedAmount': suppliedAmount,
      'vat': vat,
      'requestedAt': requestedAt,
      'approvedAt': approvedAt,
      'card': card?.toJson(),
      'easyPay': easyPay?.toJson(),
      'transfer': transfer?.toJson(),
      'virtualAccount': virtualAccount?.toJson(),
      'mobilePhone': mobilePhone?.toJson(),
    };
  }

  /// 결제 수단 표시 이름
  String get methodDisplayName {
    switch (method) {
      case '카드':
        return '카드 결제';
      case '가상계좌':
        return '가상계좌';
      case '간편결제':
        return easyPay?.provider ?? '간편결제';
      case '계좌이체':
        return '계좌이체';
      case '휴대폰':
        return '휴대폰 결제';
      default:
        return method ?? '결제';
    }
  }
}

/// 카드 결제 정보
class TossCardInfo {
  final String? issuerCode; // 발급사 코드
  final String? acquirerCode; // 매입사 코드
  final String? number; // 카드 번호 (마스킹)
  final int? installmentPlanMonths; // 할부 개월 수
  final bool? isInterestFree; // 무이자 할부 여부
  final String? approveNo; // 승인 번호
  final String? cardType; // 카드 타입 (신용, 체크, 기프트)
  final String? ownerType; // 소유자 타입 (개인, 법인)

  TossCardInfo({
    this.issuerCode,
    this.acquirerCode,
    this.number,
    this.installmentPlanMonths,
    this.isInterestFree,
    this.approveNo,
    this.cardType,
    this.ownerType,
  });

  factory TossCardInfo.fromJson(Map<String, dynamic> json) {
    return TossCardInfo(
      issuerCode: json['issuerCode'] as String?,
      acquirerCode: json['acquirerCode'] as String?,
      number: json['number'] as String?,
      installmentPlanMonths: json['installmentPlanMonths'] as int?,
      isInterestFree: json['isInterestFree'] as bool?,
      approveNo: json['approveNo'] as String?,
      cardType: json['cardType'] as String?,
      ownerType: json['ownerType'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'issuerCode': issuerCode,
      'acquirerCode': acquirerCode,
      'number': number,
      'installmentPlanMonths': installmentPlanMonths,
      'isInterestFree': isInterestFree,
      'approveNo': approveNo,
      'cardType': cardType,
      'ownerType': ownerType,
    };
  }
}

/// 간편결제 정보
class TossEasyPayInfo {
  final String provider; // 간편결제사 (토스페이, 네이버페이, 카카오페이 등)
  final int amount; // 결제 금액
  final int discountAmount; // 할인 금액

  TossEasyPayInfo({
    required this.provider,
    required this.amount,
    required this.discountAmount,
  });

  factory TossEasyPayInfo.fromJson(Map<String, dynamic> json) {
    return TossEasyPayInfo(
      provider: json['provider'] as String,
      amount: json['amount'] as int,
      discountAmount: json['discountAmount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'provider': provider,
      'amount': amount,
      'discountAmount': discountAmount,
    };
  }
}

/// 계좌이체 정보
class TossTransferInfo {
  final String? bankCode; // 은행 코드
  final String? settlementStatus; // 정산 상태

  TossTransferInfo({
    this.bankCode,
    this.settlementStatus,
  });

  factory TossTransferInfo.fromJson(Map<String, dynamic> json) {
    return TossTransferInfo(
      bankCode: json['bankCode'] as String?,
      settlementStatus: json['settlementStatus'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bankCode': bankCode,
      'settlementStatus': settlementStatus,
    };
  }
}

/// 가상계좌 정보
class TossVirtualAccountInfo {
  final String? accountNumber; // 계좌번호
  final String? accountType; // 계좌 타입 (일반, 고정)
  final String? bankCode; // 은행 코드
  final String? customerName; // 예금주
  final String? dueDate; // 입금 기한
  final bool? expired; // 만료 여부
  final String? settlementStatus; // 정산 상태

  TossVirtualAccountInfo({
    this.accountNumber,
    this.accountType,
    this.bankCode,
    this.customerName,
    this.dueDate,
    this.expired,
    this.settlementStatus,
  });

  factory TossVirtualAccountInfo.fromJson(Map<String, dynamic> json) {
    return TossVirtualAccountInfo(
      accountNumber: json['accountNumber'] as String?,
      accountType: json['accountType'] as String?,
      bankCode: json['bankCode'] as String?,
      customerName: json['customerName'] as String?,
      dueDate: json['dueDate'] as String?,
      expired: json['expired'] as bool?,
      settlementStatus: json['settlementStatus'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accountNumber': accountNumber,
      'accountType': accountType,
      'bankCode': bankCode,
      'customerName': customerName,
      'dueDate': dueDate,
      'expired': expired,
      'settlementStatus': settlementStatus,
    };
  }
}

/// 휴대폰 결제 정보
class TossMobilePhoneInfo {
  final String? carrier; // 통신사
  final String? customerMobilePhone; // 휴대폰 번호
  final String? settlementStatus; // 정산 상태

  TossMobilePhoneInfo({
    this.carrier,
    this.customerMobilePhone,
    this.settlementStatus,
  });

  factory TossMobilePhoneInfo.fromJson(Map<String, dynamic> json) {
    return TossMobilePhoneInfo(
      carrier: json['carrier'] as String?,
      customerMobilePhone: json['customerMobilePhone'] as String?,
      settlementStatus: json['settlementStatus'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'carrier': carrier,
      'customerMobilePhone': customerMobilePhone,
      'settlementStatus': settlementStatus,
    };
  }
}

/// 토스페이먼츠 결제 상태
class TossPaymentStatus {
  static const String ready = 'READY'; // 결제 생성됨
  static const String inProgress = 'IN_PROGRESS'; // 결제 진행중
  static const String waitingForDeposit = 'WAITING_FOR_DEPOSIT'; // 가상계좌 입금 대기
  static const String done = 'DONE'; // 결제 완료
  static const String canceled = 'CANCELED'; // 결제 취소
  static const String partialCanceled = 'PARTIAL_CANCELED'; // 부분 취소
  static const String aborted = 'ABORTED'; // 결제 승인 실패
  static const String expired = 'EXPIRED'; // 가상계좌 입금 기한 만료
}
