// lib/features/warranty/data/models/verification_transaction_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// 거래 상태
enum TransactionStatus {
  registered,       // 거래 등록됨
  qrGenerated,      // QR 코드 생성됨
  reportIssued,     // 검증 레포트 발행됨
  delivered,        // 고객에게 전달됨
  warrantyActive,   // 보증 활성화됨
}

/// B2B 검증 거래 모델
class VerificationTransactionModel {
  final String transactionId;
  final String qrCode;

  // 부품 정보
  final String partCategory;
  final String brand;
  final String modelName;
  final String? serialNumber;
  final List<String> photoUrls;

  // 검수 정보
  final String inspectorId;
  final String inspectorName;
  final Timestamp inspectedAt;
  final String inspectionNote;
  final int conditionScore;
  final List<String> inspectionPhotoUrls;

  // B2B 거래 정보
  final String? buyerCompanyName;
  final String? buyerContactName;
  final String? buyerContactPhone;
  final int salePrice;
  final Timestamp saleDate;

  // 문서 정보
  final String? verificationReportUrl;
  final String? qrCodeImageUrl;

  // 상태
  final TransactionStatus status;
  final String? warrantyId;

  // 타임스탬프
  final Timestamp createdAt;
  final Timestamp updatedAt;

  VerificationTransactionModel({
    required this.transactionId,
    required this.qrCode,
    required this.partCategory,
    required this.brand,
    required this.modelName,
    this.serialNumber,
    required this.photoUrls,
    required this.inspectorId,
    required this.inspectorName,
    required this.inspectedAt,
    required this.inspectionNote,
    required this.conditionScore,
    required this.inspectionPhotoUrls,
    this.buyerCompanyName,
    this.buyerContactName,
    this.buyerContactPhone,
    required this.salePrice,
    required this.saleDate,
    this.verificationReportUrl,
    this.qrCodeImageUrl,
    required this.status,
    this.warrantyId,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Firestore → Model
  factory VerificationTransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return VerificationTransactionModel(
      transactionId: data['transactionId'] ?? doc.id,
      qrCode: data['qrCode'] ?? '',
      partCategory: data['partCategory'] ?? '',
      brand: data['brand'] ?? '',
      modelName: data['modelName'] ?? '',
      serialNumber: data['serialNumber'],
      photoUrls: List<String>.from(data['photoUrls'] ?? []),
      inspectorId: data['inspectorId'] ?? '',
      inspectorName: data['inspectorName'] ?? '',
      inspectedAt: data['inspectedAt'] ?? Timestamp.now(),
      inspectionNote: data['inspectionNote'] ?? '',
      conditionScore: data['conditionScore'] ?? 0,
      inspectionPhotoUrls: List<String>.from(data['inspectionPhotoUrls'] ?? []),
      buyerCompanyName: data['buyerCompanyName'],
      buyerContactName: data['buyerContactName'],
      buyerContactPhone: data['buyerContactPhone'],
      salePrice: data['salePrice'] ?? 0,
      saleDate: data['saleDate'] ?? Timestamp.now(),
      verificationReportUrl: data['verificationReportUrl'],
      qrCodeImageUrl: data['qrCodeImageUrl'],
      status: TransactionStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => TransactionStatus.registered,
      ),
      warrantyId: data['warrantyId'],
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] ?? Timestamp.now(),
    );
  }

  /// Model → Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'transactionId': transactionId,
      'qrCode': qrCode,
      'partCategory': partCategory,
      'brand': brand,
      'modelName': modelName,
      'serialNumber': serialNumber,
      'photoUrls': photoUrls,
      'inspectorId': inspectorId,
      'inspectorName': inspectorName,
      'inspectedAt': inspectedAt,
      'inspectionNote': inspectionNote,
      'conditionScore': conditionScore,
      'inspectionPhotoUrls': inspectionPhotoUrls,
      'buyerCompanyName': buyerCompanyName,
      'buyerContactName': buyerContactName,
      'buyerContactPhone': buyerContactPhone,
      'salePrice': salePrice,
      'saleDate': saleDate,
      'verificationReportUrl': verificationReportUrl,
      'qrCodeImageUrl': qrCodeImageUrl,
      'status': status.name,
      'warrantyId': warrantyId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  VerificationTransactionModel copyWith({
    String? transactionId,
    String? qrCode,
    String? partCategory,
    String? brand,
    String? modelName,
    String? serialNumber,
    List<String>? photoUrls,
    String? inspectorId,
    String? inspectorName,
    Timestamp? inspectedAt,
    String? inspectionNote,
    int? conditionScore,
    List<String>? inspectionPhotoUrls,
    String? buyerCompanyName,
    String? buyerContactName,
    String? buyerContactPhone,
    int? salePrice,
    Timestamp? saleDate,
    String? verificationReportUrl,
    String? qrCodeImageUrl,
    TransactionStatus? status,
    String? warrantyId,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return VerificationTransactionModel(
      transactionId: transactionId ?? this.transactionId,
      qrCode: qrCode ?? this.qrCode,
      partCategory: partCategory ?? this.partCategory,
      brand: brand ?? this.brand,
      modelName: modelName ?? this.modelName,
      serialNumber: serialNumber ?? this.serialNumber,
      photoUrls: photoUrls ?? this.photoUrls,
      inspectorId: inspectorId ?? this.inspectorId,
      inspectorName: inspectorName ?? this.inspectorName,
      inspectedAt: inspectedAt ?? this.inspectedAt,
      inspectionNote: inspectionNote ?? this.inspectionNote,
      conditionScore: conditionScore ?? this.conditionScore,
      inspectionPhotoUrls: inspectionPhotoUrls ?? this.inspectionPhotoUrls,
      buyerCompanyName: buyerCompanyName ?? this.buyerCompanyName,
      buyerContactName: buyerContactName ?? this.buyerContactName,
      buyerContactPhone: buyerContactPhone ?? this.buyerContactPhone,
      salePrice: salePrice ?? this.salePrice,
      saleDate: saleDate ?? this.saleDate,
      verificationReportUrl: verificationReportUrl ?? this.verificationReportUrl,
      qrCodeImageUrl: qrCodeImageUrl ?? this.qrCodeImageUrl,
      status: status ?? this.status,
      warrantyId: warrantyId ?? this.warrantyId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// 거래 상태 한글 변환
extension TransactionStatusExtension on TransactionStatus {
  String get displayName {
    switch (this) {
      case TransactionStatus.registered:
        return '등록됨';
      case TransactionStatus.qrGenerated:
        return 'QR 생성됨';
      case TransactionStatus.reportIssued:
        return '레포트 발행됨';
      case TransactionStatus.delivered:
        return '전달됨';
      case TransactionStatus.warrantyActive:
        return '보증 활성화';
    }
  }
}
