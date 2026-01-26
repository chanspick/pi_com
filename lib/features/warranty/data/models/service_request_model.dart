// lib/features/warranty/data/models/service_request_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// AS 서비스 유형
enum ServiceType {
  repair,       // 수리
  replacement,  // 교환
  inspection,   // 점검
}

/// AS 요청 상태
enum ServiceRequestStatus {
  pending,         // 신청됨
  reviewing,       // 검토 중
  approved,        // 승인됨
  rejected,        // 거부됨
  itemShipping,    // 부품 발송 중
  itemReceived,    // 부품 수령됨
  repairing,       // 수리 중
  repaired,        // 수리 완료
  returnShipping,  // 반송 중
  completed,       // 완료
}

/// AS 요청 모델
class ServiceRequestModel {
  final String requestId;
  final String warrantyId;
  final String transactionId;

  // 신청 정보
  final ServiceType serviceType;
  final String issueDescription;
  final List<String> issuePhotoUrls;

  // 고객 정보
  final String customerName;
  final String customerPhone;
  final String shippingAddress;

  // 처리 정보
  final ServiceRequestStatus status;
  final String? handlerId;
  final String? handlerNote;

  // 배송 정보
  final String? inboundTrackingNumber;
  final String? outboundTrackingNumber;

  // 타임스탬프
  final Timestamp requestedAt;
  final Timestamp? completedAt;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  ServiceRequestModel({
    required this.requestId,
    required this.warrantyId,
    required this.transactionId,
    required this.serviceType,
    required this.issueDescription,
    required this.issuePhotoUrls,
    required this.customerName,
    required this.customerPhone,
    required this.shippingAddress,
    required this.status,
    this.handlerId,
    this.handlerNote,
    this.inboundTrackingNumber,
    this.outboundTrackingNumber,
    required this.requestedAt,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Firestore → Model
  factory ServiceRequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ServiceRequestModel(
      requestId: data['requestId'] ?? doc.id,
      warrantyId: data['warrantyId'] ?? '',
      transactionId: data['transactionId'] ?? '',
      serviceType: ServiceType.values.firstWhere(
        (e) => e.name == data['serviceType'],
        orElse: () => ServiceType.repair,
      ),
      issueDescription: data['issueDescription'] ?? '',
      issuePhotoUrls: List<String>.from(data['issuePhotoUrls'] ?? []),
      customerName: data['customerName'] ?? '',
      customerPhone: data['customerPhone'] ?? '',
      shippingAddress: data['shippingAddress'] ?? '',
      status: ServiceRequestStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => ServiceRequestStatus.pending,
      ),
      handlerId: data['handlerId'],
      handlerNote: data['handlerNote'],
      inboundTrackingNumber: data['inboundTrackingNumber'],
      outboundTrackingNumber: data['outboundTrackingNumber'],
      requestedAt: data['requestedAt'] ?? Timestamp.now(),
      completedAt: data['completedAt'],
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] ?? Timestamp.now(),
    );
  }

  /// Model → Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'requestId': requestId,
      'warrantyId': warrantyId,
      'transactionId': transactionId,
      'serviceType': serviceType.name,
      'issueDescription': issueDescription,
      'issuePhotoUrls': issuePhotoUrls,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'shippingAddress': shippingAddress,
      'status': status.name,
      'handlerId': handlerId,
      'handlerNote': handlerNote,
      'inboundTrackingNumber': inboundTrackingNumber,
      'outboundTrackingNumber': outboundTrackingNumber,
      'requestedAt': requestedAt,
      'completedAt': completedAt,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  ServiceRequestModel copyWith({
    String? requestId,
    String? warrantyId,
    String? transactionId,
    ServiceType? serviceType,
    String? issueDescription,
    List<String>? issuePhotoUrls,
    String? customerName,
    String? customerPhone,
    String? shippingAddress,
    ServiceRequestStatus? status,
    String? handlerId,
    String? handlerNote,
    String? inboundTrackingNumber,
    String? outboundTrackingNumber,
    Timestamp? requestedAt,
    Timestamp? completedAt,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return ServiceRequestModel(
      requestId: requestId ?? this.requestId,
      warrantyId: warrantyId ?? this.warrantyId,
      transactionId: transactionId ?? this.transactionId,
      serviceType: serviceType ?? this.serviceType,
      issueDescription: issueDescription ?? this.issueDescription,
      issuePhotoUrls: issuePhotoUrls ?? this.issuePhotoUrls,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      status: status ?? this.status,
      handlerId: handlerId ?? this.handlerId,
      handlerNote: handlerNote ?? this.handlerNote,
      inboundTrackingNumber: inboundTrackingNumber ?? this.inboundTrackingNumber,
      outboundTrackingNumber: outboundTrackingNumber ?? this.outboundTrackingNumber,
      requestedAt: requestedAt ?? this.requestedAt,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// 서비스 유형 한글 변환
extension ServiceTypeExtension on ServiceType {
  String get displayName {
    switch (this) {
      case ServiceType.repair:
        return '수리';
      case ServiceType.replacement:
        return '교환';
      case ServiceType.inspection:
        return '점검';
    }
  }
}

/// AS 요청 상태 한글 변환
extension ServiceRequestStatusExtension on ServiceRequestStatus {
  String get displayName {
    switch (this) {
      case ServiceRequestStatus.pending:
        return '접수됨';
      case ServiceRequestStatus.reviewing:
        return '검토 중';
      case ServiceRequestStatus.approved:
        return '승인됨';
      case ServiceRequestStatus.rejected:
        return '거부됨';
      case ServiceRequestStatus.itemShipping:
        return '부품 발송 중';
      case ServiceRequestStatus.itemReceived:
        return '부품 수령됨';
      case ServiceRequestStatus.repairing:
        return '수리 중';
      case ServiceRequestStatus.repaired:
        return '수리 완료';
      case ServiceRequestStatus.returnShipping:
        return '반송 중';
      case ServiceRequestStatus.completed:
        return '완료';
    }
  }

  bool get isCompleted => this == ServiceRequestStatus.completed || this == ServiceRequestStatus.rejected;
  bool get isInProgress => !isCompleted;
}
