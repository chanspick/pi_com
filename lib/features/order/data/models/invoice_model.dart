/// Invoice Model - Firestore 데이터 변환 모델
///
/// invoices 컬렉션과의 데이터 변환을 담당합니다.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pi_com/features/order/domain/entities/invoice_entity.dart';

class InvoiceItemModel {
  final String name;
  final int quantity;
  final int unitPrice;
  final int totalPrice;

  const InvoiceItemModel({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory InvoiceItemModel.fromMap(Map<String, dynamic> data) {
    return InvoiceItemModel(
      name: data['name'] ?? '',
      quantity: (data['quantity'] as num?)?.toInt() ?? 1,
      unitPrice: (data['unitPrice'] as num?)?.toInt() ?? 0,
      totalPrice: (data['totalPrice'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
    };
  }

  InvoiceItemEntity toEntity() {
    return InvoiceItemEntity(
      name: name,
      quantity: quantity,
      unitPrice: unitPrice,
      totalPrice: totalPrice,
    );
  }

  factory InvoiceItemModel.fromEntity(InvoiceItemEntity entity) {
    return InvoiceItemModel(
      name: entity.name,
      quantity: entity.quantity,
      unitPrice: entity.unitPrice,
      totalPrice: entity.totalPrice,
    );
  }
}

class InvoiceModel {
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
  final List<InvoiceItemModel> items;

  // 날짜 정보
  final Timestamp issueDate;
  final Timestamp? paidAt;
  final Timestamp generatedAt;

  // 결제 정보
  final String? paymentMethod;

  // 상태
  final String status;
  final int version;

  // 무효화 정보
  final Timestamp? voidedAt;
  final String? voidReason;

  const InvoiceModel({
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

  factory InvoiceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return InvoiceModel(
      invoiceId: data['invoiceId'] ?? doc.id,
      invoiceNumber: data['invoiceNumber'] ?? doc.id,
      orderId: data['orderId'] ?? '',
      invoiceUrl: data['invoiceUrl'] ?? '',
      storagePath: data['storagePath'] ?? '',
      buyerName: data['buyerName'] ?? '',
      buyerEmail: data['buyerEmail'],
      buyerPhone: data['buyerPhone'],
      buyerAddress: data['buyerAddress'],
      sellerName: data['sellerName'] ?? '',
      sellerBusinessNumber: data['sellerBusinessNumber'],
      sellerPhone: data['sellerPhone'],
      sellerAddress: data['sellerAddress'],
      totalAmount: (data['totalAmount'] as num?)?.toInt() ?? 0,
      subtotal: (data['subtotal'] as num?)?.toInt() ?? 0,
      shippingFee: (data['shippingFee'] as num?)?.toInt() ?? 0,
      itemCount: (data['itemCount'] as num?)?.toInt() ?? 0,
      items: (data['items'] as List?)
              ?.map((item) => InvoiceItemModel.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [],
      issueDate: data['issueDate'] ?? Timestamp.now(),
      paidAt: data['paidAt'],
      generatedAt: data['generatedAt'] ?? Timestamp.now(),
      paymentMethod: data['paymentMethod'],
      status: data['status'] ?? 'issued',
      version: (data['version'] as num?)?.toInt() ?? 1,
      voidedAt: data['voidedAt'],
      voidReason: data['voidReason'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'invoiceId': invoiceId,
      'invoiceNumber': invoiceNumber,
      'orderId': orderId,
      'invoiceUrl': invoiceUrl,
      'storagePath': storagePath,
      'buyerName': buyerName,
      'buyerEmail': buyerEmail,
      'buyerPhone': buyerPhone,
      'buyerAddress': buyerAddress,
      'sellerName': sellerName,
      'sellerBusinessNumber': sellerBusinessNumber,
      'sellerPhone': sellerPhone,
      'sellerAddress': sellerAddress,
      'totalAmount': totalAmount,
      'subtotal': subtotal,
      'shippingFee': shippingFee,
      'itemCount': itemCount,
      'items': items.map((item) => item.toMap()).toList(),
      'issueDate': issueDate,
      'paidAt': paidAt,
      'generatedAt': generatedAt,
      'paymentMethod': paymentMethod,
      'status': status,
      'version': version,
      'voidedAt': voidedAt,
      'voidReason': voidReason,
    };
  }

  InvoiceEntity toEntity() {
    return InvoiceEntity(
      invoiceId: invoiceId,
      invoiceNumber: invoiceNumber,
      orderId: orderId,
      invoiceUrl: invoiceUrl,
      storagePath: storagePath,
      buyerName: buyerName,
      buyerEmail: buyerEmail,
      buyerPhone: buyerPhone,
      buyerAddress: buyerAddress,
      sellerName: sellerName,
      sellerBusinessNumber: sellerBusinessNumber,
      sellerPhone: sellerPhone,
      sellerAddress: sellerAddress,
      totalAmount: totalAmount,
      subtotal: subtotal,
      shippingFee: shippingFee,
      itemCount: itemCount,
      items: items.map((item) => item.toEntity()).toList(),
      issueDate: issueDate.toDate(),
      paidAt: paidAt?.toDate(),
      generatedAt: generatedAt.toDate(),
      paymentMethod: paymentMethod,
      status: _parseStatus(status),
      version: version,
      voidedAt: voidedAt?.toDate(),
      voidReason: voidReason,
    );
  }

  factory InvoiceModel.fromEntity(InvoiceEntity entity) {
    return InvoiceModel(
      invoiceId: entity.invoiceId,
      invoiceNumber: entity.invoiceNumber,
      orderId: entity.orderId,
      invoiceUrl: entity.invoiceUrl,
      storagePath: entity.storagePath,
      buyerName: entity.buyerName,
      buyerEmail: entity.buyerEmail,
      buyerPhone: entity.buyerPhone,
      buyerAddress: entity.buyerAddress,
      sellerName: entity.sellerName,
      sellerBusinessNumber: entity.sellerBusinessNumber,
      sellerPhone: entity.sellerPhone,
      sellerAddress: entity.sellerAddress,
      totalAmount: entity.totalAmount,
      subtotal: entity.subtotal,
      shippingFee: entity.shippingFee,
      itemCount: entity.itemCount,
      items: entity.items.map((item) => InvoiceItemModel.fromEntity(item)).toList(),
      issueDate: Timestamp.fromDate(entity.issueDate),
      paidAt: entity.paidAt != null ? Timestamp.fromDate(entity.paidAt!) : null,
      generatedAt: Timestamp.fromDate(entity.generatedAt),
      paymentMethod: entity.paymentMethod,
      status: entity.status.name,
      version: entity.version,
      voidedAt: entity.voidedAt != null ? Timestamp.fromDate(entity.voidedAt!) : null,
      voidReason: entity.voidReason,
    );
  }

  static InvoiceStatus _parseStatus(String status) {
    switch (status) {
      case 'voided':
        return InvoiceStatus.voided;
      case 'issued':
      default:
        return InvoiceStatus.issued;
    }
  }
}
