/// Invoice Entity - 송장 도메인 엔티티
///
/// 송장 시스템의 핵심 엔티티로 주문에 대한 세금계산서/영수증 정보를 담습니다.

enum InvoiceStatus {
  issued,   // 발행됨
  voided,   // 무효화됨
}

class InvoiceItemEntity {
  final String name;
  final int quantity;
  final int unitPrice;
  final int totalPrice;

  const InvoiceItemEntity({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });
}

class InvoiceEntity {
  final String invoiceId;
  final String invoiceNumber;
  final String orderId;
  final String invoiceUrl;
  final String storagePath;

  // 구매자 정보
  final String buyerName;
  final String? buyerEmail;
  final String? buyerPhone;
  final String? buyerAddress;

  // 판매자 정보
  final String sellerName;
  final String? sellerBusinessNumber;
  final String? sellerPhone;
  final String? sellerAddress;

  // 금액 정보
  final int totalAmount;
  final int subtotal;
  final int shippingFee;
  final int itemCount;
  final List<InvoiceItemEntity> items;

  // 날짜 정보
  final DateTime issueDate;
  final DateTime? paidAt;
  final DateTime generatedAt;

  // 결제 정보
  final String? paymentMethod;

  // 상태
  final InvoiceStatus status;
  final int version;

  // 무효화 정보
  final DateTime? voidedAt;
  final String? voidReason;

  const InvoiceEntity({
    required this.invoiceId,
    required this.invoiceNumber,
    required this.orderId,
    required this.invoiceUrl,
    required this.storagePath,
    required this.buyerName,
    this.buyerEmail,
    this.buyerPhone,
    this.buyerAddress,
    required this.sellerName,
    this.sellerBusinessNumber,
    this.sellerPhone,
    this.sellerAddress,
    required this.totalAmount,
    required this.subtotal,
    required this.shippingFee,
    required this.itemCount,
    required this.items,
    required this.issueDate,
    this.paidAt,
    required this.generatedAt,
    this.paymentMethod,
    required this.status,
    required this.version,
    this.voidedAt,
    this.voidReason,
  });

  /// 송장이 유효한지 확인
  bool get isValid => status == InvoiceStatus.issued;

  /// 송장이 무효화되었는지 확인
  bool get isVoided => status == InvoiceStatus.voided;

  /// 송장 번호 단축 표시 (INV-XXXXXXXX)
  String get shortNumber {
    if (invoiceNumber.length > 12) {
      return '${invoiceNumber.substring(0, 12)}...';
    }
    return invoiceNumber;
  }

  /// copyWith 메서드
  InvoiceEntity copyWith({
    String? invoiceId,
    String? invoiceNumber,
    String? orderId,
    String? invoiceUrl,
    String? storagePath,
    String? buyerName,
    String? buyerEmail,
    String? buyerPhone,
    String? buyerAddress,
    String? sellerName,
    String? sellerBusinessNumber,
    String? sellerPhone,
    String? sellerAddress,
    int? totalAmount,
    int? subtotal,
    int? shippingFee,
    int? itemCount,
    List<InvoiceItemEntity>? items,
    DateTime? issueDate,
    DateTime? paidAt,
    DateTime? generatedAt,
    String? paymentMethod,
    InvoiceStatus? status,
    int? version,
    DateTime? voidedAt,
    String? voidReason,
  }) {
    return InvoiceEntity(
      invoiceId: invoiceId ?? this.invoiceId,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      orderId: orderId ?? this.orderId,
      invoiceUrl: invoiceUrl ?? this.invoiceUrl,
      storagePath: storagePath ?? this.storagePath,
      buyerName: buyerName ?? this.buyerName,
      buyerEmail: buyerEmail ?? this.buyerEmail,
      buyerPhone: buyerPhone ?? this.buyerPhone,
      buyerAddress: buyerAddress ?? this.buyerAddress,
      sellerName: sellerName ?? this.sellerName,
      sellerBusinessNumber: sellerBusinessNumber ?? this.sellerBusinessNumber,
      sellerPhone: sellerPhone ?? this.sellerPhone,
      sellerAddress: sellerAddress ?? this.sellerAddress,
      totalAmount: totalAmount ?? this.totalAmount,
      subtotal: subtotal ?? this.subtotal,
      shippingFee: shippingFee ?? this.shippingFee,
      itemCount: itemCount ?? this.itemCount,
      items: items ?? this.items,
      issueDate: issueDate ?? this.issueDate,
      paidAt: paidAt ?? this.paidAt,
      generatedAt: generatedAt ?? this.generatedAt,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      version: version ?? this.version,
      voidedAt: voidedAt ?? this.voidedAt,
      voidReason: voidReason ?? this.voidReason,
    );
  }

  @override
  String toString() => 'InvoiceEntity(invoiceNumber: $invoiceNumber, orderId: $orderId, status: $status)';
}
