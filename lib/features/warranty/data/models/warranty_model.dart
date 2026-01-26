// lib/features/warranty/data/models/warranty_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// 보증 플랜
enum WarrantyPlan {
  oneYear,   // 1년 (10%)
  twoYear,   // 2년 (20%)
}

/// 보증 상태
enum WarrantyStatus {
  pending,    // 결제 대기
  active,     // 활성화 (보증 유효)
  expired,    // 만료됨
  claimed,    // AS 신청됨 (처리 중)
  completed,  // AS 완료됨
}

/// AS 보증 모델
class WarrantyModel {
  final String warrantyId;
  final String transactionId;
  final String qrCode;

  // 보증 정보
  final WarrantyPlan warrantyPlan;
  final int warrantyPeriodMonths;
  final Timestamp startDate;
  final Timestamp endDate;

  // 결제 정보
  final int warrantyPrice;
  final double warrantyRate;
  final String? paymentMethod;
  final String? paymentKey;
  final Timestamp? paidAt;

  // 고객 정보
  final String customerName;
  final String customerPhone;
  final String? customerEmail;

  // 상태
  final WarrantyStatus status;
  final List<String> serviceRequestIds;

  // 타임스탬프
  final Timestamp createdAt;
  final Timestamp updatedAt;

  WarrantyModel({
    required this.warrantyId,
    required this.transactionId,
    required this.qrCode,
    required this.warrantyPlan,
    required this.warrantyPeriodMonths,
    required this.startDate,
    required this.endDate,
    required this.warrantyPrice,
    required this.warrantyRate,
    this.paymentMethod,
    this.paymentKey,
    this.paidAt,
    required this.customerName,
    required this.customerPhone,
    this.customerEmail,
    required this.status,
    required this.serviceRequestIds,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Firestore → Model
  factory WarrantyModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return WarrantyModel(
      warrantyId: data['warrantyId'] ?? doc.id,
      transactionId: data['transactionId'] ?? '',
      qrCode: data['qrCode'] ?? '',
      warrantyPlan: _parseWarrantyPlan(data['warrantyPlan']),
      warrantyPeriodMonths: data['warrantyPeriodMonths'] ?? 12,
      startDate: data['startDate'] ?? Timestamp.now(),
      endDate: data['endDate'] ?? Timestamp.now(),
      warrantyPrice: data['warrantyPrice'] ?? 0,
      warrantyRate: (data['warrantyRate'] ?? 0.1).toDouble(),
      paymentMethod: data['paymentMethod'],
      paymentKey: data['paymentKey'],
      paidAt: data['paidAt'],
      customerName: data['customerName'] ?? '',
      customerPhone: data['customerPhone'] ?? '',
      customerEmail: data['customerEmail'],
      status: WarrantyStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => WarrantyStatus.pending,
      ),
      serviceRequestIds: List<String>.from(data['serviceRequestIds'] ?? []),
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] ?? Timestamp.now(),
    );
  }

  static WarrantyPlan _parseWarrantyPlan(String? value) {
    if (value == '1year') return WarrantyPlan.oneYear;
    if (value == '2year') return WarrantyPlan.twoYear;
    return WarrantyPlan.oneYear;
  }

  /// Model → Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'warrantyId': warrantyId,
      'transactionId': transactionId,
      'qrCode': qrCode,
      'warrantyPlan': warrantyPlan == WarrantyPlan.oneYear ? '1year' : '2year',
      'warrantyPeriodMonths': warrantyPeriodMonths,
      'startDate': startDate,
      'endDate': endDate,
      'warrantyPrice': warrantyPrice,
      'warrantyRate': warrantyRate,
      'paymentMethod': paymentMethod,
      'paymentKey': paymentKey,
      'paidAt': paidAt,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerEmail': customerEmail,
      'status': status.name,
      'serviceRequestIds': serviceRequestIds,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  /// 보증 만료 여부
  bool get isExpired {
    return DateTime.now().isAfter(endDate.toDate());
  }

  /// 남은 일수
  int get daysRemaining {
    final diff = endDate.toDate().difference(DateTime.now());
    return diff.inDays;
  }

  WarrantyModel copyWith({
    String? warrantyId,
    String? transactionId,
    String? qrCode,
    WarrantyPlan? warrantyPlan,
    int? warrantyPeriodMonths,
    Timestamp? startDate,
    Timestamp? endDate,
    int? warrantyPrice,
    double? warrantyRate,
    String? paymentMethod,
    String? paymentKey,
    Timestamp? paidAt,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
    WarrantyStatus? status,
    List<String>? serviceRequestIds,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return WarrantyModel(
      warrantyId: warrantyId ?? this.warrantyId,
      transactionId: transactionId ?? this.transactionId,
      qrCode: qrCode ?? this.qrCode,
      warrantyPlan: warrantyPlan ?? this.warrantyPlan,
      warrantyPeriodMonths: warrantyPeriodMonths ?? this.warrantyPeriodMonths,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      warrantyPrice: warrantyPrice ?? this.warrantyPrice,
      warrantyRate: warrantyRate ?? this.warrantyRate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentKey: paymentKey ?? this.paymentKey,
      paidAt: paidAt ?? this.paidAt,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerEmail: customerEmail ?? this.customerEmail,
      status: status ?? this.status,
      serviceRequestIds: serviceRequestIds ?? this.serviceRequestIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// 보증 플랜 정보
extension WarrantyPlanExtension on WarrantyPlan {
  String get displayName {
    switch (this) {
      case WarrantyPlan.oneYear:
        return '1년 보증';
      case WarrantyPlan.twoYear:
        return '2년 보증';
    }
  }

  int get months {
    switch (this) {
      case WarrantyPlan.oneYear:
        return 12;
      case WarrantyPlan.twoYear:
        return 24;
    }
  }

  double get rate {
    switch (this) {
      case WarrantyPlan.oneYear:
        return 0.10;
      case WarrantyPlan.twoYear:
        return 0.20;
    }
  }
}

/// 보증 상태 한글 변환
extension WarrantyStatusExtension on WarrantyStatus {
  String get displayName {
    switch (this) {
      case WarrantyStatus.pending:
        return '결제 대기';
      case WarrantyStatus.active:
        return '보증 유효';
      case WarrantyStatus.expired:
        return '만료됨';
      case WarrantyStatus.claimed:
        return 'AS 신청됨';
      case WarrantyStatus.completed:
        return 'AS 완료';
    }
  }

  bool get isActive => this == WarrantyStatus.active;
}
