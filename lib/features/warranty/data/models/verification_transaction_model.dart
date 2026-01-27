// lib/features/warranty/data/models/verification_transaction_model.dart
// v2: 풀세트 지원, 벤치마크 기반 스코어, 기본 AS 기간

import 'package:cloud_firestore/cloud_firestore.dart';

/// 거래 상태
enum TransactionStatus {
  registered,       // 거래 등록됨
  qrGenerated,      // QR 코드 생성됨
  reportIssued,     // 검증 레포트 발행됨
  delivered,        // 고객에게 전달됨
  warrantyActive,   // 보증 활성화됨
}

/// 거래 타입 (v2)
enum TransactionType {
  single,   // 단일 부품
  bundle,   // 풀세트 (조립PC)
}

/// 등급 (v2)
enum ConditionGrade {
  S,  // 최상급 (90-100)
  A,  // 우수 (80-89)
  B,  // 양호 (70-79)
  C,  // 보통 (60-69)
  D,  // 불량 (0-59)
}

/// 벤치마크 점수 (v2)
class BenchmarkScores {
  final int? cpu;       // PassMark 점수
  final int? gpu;       // 3DMark 점수
  final int? storage;   // 읽기/쓰기 속도 (MB/s)
  final int? memory;    // 메모리 대역폭
  final int? overall;   // 종합 점수

  BenchmarkScores({
    this.cpu,
    this.gpu,
    this.storage,
    this.memory,
    this.overall,
  });

  factory BenchmarkScores.fromMap(Map<String, dynamic>? map) {
    if (map == null) return BenchmarkScores();
    return BenchmarkScores(
      cpu: map['cpu']?.toInt(),
      gpu: map['gpu']?.toInt(),
      storage: map['storage']?.toInt(),
      memory: map['memory']?.toInt(),
      overall: map['overall']?.toInt(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (cpu != null) 'cpu': cpu,
      if (gpu != null) 'gpu': gpu,
      if (storage != null) 'storage': storage,
      if (memory != null) 'memory': memory,
      if (overall != null) 'overall': overall,
    };
  }
}

/// 풀세트 내 개별 부품 (v2)
class TransactionItem {
  final String itemId;
  final String partCategory;
  final String brand;
  final String modelName;
  final String? serialNumber;
  final int? benchmarkScore;
  final int conditionScore;
  final int purchaseCost;
  final List<String> photoUrls;

  TransactionItem({
    required this.itemId,
    required this.partCategory,
    required this.brand,
    required this.modelName,
    this.serialNumber,
    this.benchmarkScore,
    required this.conditionScore,
    required this.purchaseCost,
    required this.photoUrls,
  });

  factory TransactionItem.fromMap(Map<String, dynamic> map) {
    return TransactionItem(
      itemId: map['itemId'] ?? '',
      partCategory: map['partCategory'] ?? '',
      brand: map['brand'] ?? '',
      modelName: map['modelName'] ?? '',
      serialNumber: map['serialNumber'],
      benchmarkScore: map['benchmarkScore']?.toInt(),
      conditionScore: map['conditionScore']?.toInt() ?? 0,
      purchaseCost: map['purchaseCost']?.toInt() ?? 0,
      photoUrls: List<String>.from(map['photoUrls'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'partCategory': partCategory,
      'brand': brand,
      'modelName': modelName,
      'serialNumber': serialNumber,
      'benchmarkScore': benchmarkScore,
      'conditionScore': conditionScore,
      'purchaseCost': purchaseCost,
      'photoUrls': photoUrls,
    };
  }
}

/// B2B 검증 거래 모델 (v2)
class VerificationTransactionModel {
  final String transactionId;
  final String qrCode;

  // 거래 타입 (v2)
  final TransactionType transactionType;

  // 단일 부품 정보
  final String? partCategory;
  final String? brand;
  final String? modelName;
  final String? serialNumber;
  final List<String> photoUrls;

  // 풀세트 정보 (v2)
  final List<TransactionItem>? items;
  final String? bundleName;

  // 검수 정보
  final String inspectorId;
  final String inspectorName;
  final Timestamp inspectedAt;
  final String inspectionNote;
  final List<String> inspectionPhotoUrls;

  // 벤치마크 기반 스코어 (v2)
  final BenchmarkScores? benchmarkScores;
  final ConditionGrade conditionGrade;
  final int conditionScore;  // 1-100 (v2)

  // 가격 정보 (v2)
  final int purchaseCost;
  final int salePrice;
  final double? profitMargin;

  // 기본 보증 (v2)
  final int baseWarrantyMonths;

  // B2B 거래 정보
  final String? buyerCompanyName;
  final String? buyerContactName;
  final String? buyerContactPhone;
  final Timestamp saleDate;

  // 문서 정보
  final String? verificationReportUrl;
  final String? warrantyPdfUrl;
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
    this.transactionType = TransactionType.single,
    this.partCategory,
    this.brand,
    this.modelName,
    this.serialNumber,
    required this.photoUrls,
    this.items,
    this.bundleName,
    required this.inspectorId,
    required this.inspectorName,
    required this.inspectedAt,
    required this.inspectionNote,
    required this.inspectionPhotoUrls,
    this.benchmarkScores,
    this.conditionGrade = ConditionGrade.B,
    required this.conditionScore,
    this.purchaseCost = 0,
    required this.salePrice,
    this.profitMargin,
    this.baseWarrantyMonths = 12,
    this.buyerCompanyName,
    this.buyerContactName,
    this.buyerContactPhone,
    required this.saleDate,
    this.verificationReportUrl,
    this.warrantyPdfUrl,
    this.qrCodeImageUrl,
    required this.status,
    this.warrantyId,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Firestore → Model
  factory VerificationTransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // 풀세트 아이템 파싱
    List<TransactionItem>? items;
    if (data['items'] != null) {
      items = (data['items'] as List)
          .map((item) => TransactionItem.fromMap(item as Map<String, dynamic>))
          .toList();
    }

    return VerificationTransactionModel(
      transactionId: data['transactionId'] ?? doc.id,
      qrCode: data['qrCode'] ?? '',
      transactionType: TransactionType.values.firstWhere(
        (e) => e.name == data['transactionType'],
        orElse: () => TransactionType.single,
      ),
      partCategory: data['partCategory'],
      brand: data['brand'],
      modelName: data['modelName'],
      serialNumber: data['serialNumber'],
      photoUrls: List<String>.from(data['photoUrls'] ?? []),
      items: items,
      bundleName: data['bundleName'],
      inspectorId: data['inspectorId'] ?? '',
      inspectorName: data['inspectorName'] ?? '',
      inspectedAt: data['inspectedAt'] ?? Timestamp.now(),
      inspectionNote: data['inspectionNote'] ?? '',
      inspectionPhotoUrls: List<String>.from(data['inspectionPhotoUrls'] ?? []),
      benchmarkScores: BenchmarkScores.fromMap(data['benchmarkScores']),
      conditionGrade: ConditionGrade.values.firstWhere(
        (e) => e.name == data['conditionGrade'],
        orElse: () => ConditionGrade.B,
      ),
      conditionScore: data['conditionScore'] ?? 0,
      purchaseCost: data['purchaseCost']?.toInt() ?? 0,
      salePrice: data['salePrice']?.toInt() ?? 0,
      profitMargin: data['profitMargin']?.toDouble(),
      baseWarrantyMonths: data['baseWarrantyMonths']?.toInt() ?? 12,
      buyerCompanyName: data['buyerCompanyName'],
      buyerContactName: data['buyerContactName'],
      buyerContactPhone: data['buyerContactPhone'],
      saleDate: data['saleDate'] ?? Timestamp.now(),
      verificationReportUrl: data['verificationReportUrl'],
      warrantyPdfUrl: data['warrantyPdfUrl'],
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
      'transactionType': transactionType.name,
      'partCategory': partCategory,
      'brand': brand,
      'modelName': modelName,
      'serialNumber': serialNumber,
      'photoUrls': photoUrls,
      'items': items?.map((e) => e.toMap()).toList(),
      'bundleName': bundleName,
      'inspectorId': inspectorId,
      'inspectorName': inspectorName,
      'inspectedAt': inspectedAt,
      'inspectionNote': inspectionNote,
      'inspectionPhotoUrls': inspectionPhotoUrls,
      'benchmarkScores': benchmarkScores?.toMap(),
      'conditionGrade': conditionGrade.name,
      'conditionScore': conditionScore,
      'purchaseCost': purchaseCost,
      'salePrice': salePrice,
      'profitMargin': profitMargin,
      'baseWarrantyMonths': baseWarrantyMonths,
      'buyerCompanyName': buyerCompanyName,
      'buyerContactName': buyerContactName,
      'buyerContactPhone': buyerContactPhone,
      'saleDate': saleDate,
      'verificationReportUrl': verificationReportUrl,
      'warrantyPdfUrl': warrantyPdfUrl,
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
    TransactionType? transactionType,
    String? partCategory,
    String? brand,
    String? modelName,
    String? serialNumber,
    List<String>? photoUrls,
    List<TransactionItem>? items,
    String? bundleName,
    String? inspectorId,
    String? inspectorName,
    Timestamp? inspectedAt,
    String? inspectionNote,
    List<String>? inspectionPhotoUrls,
    BenchmarkScores? benchmarkScores,
    ConditionGrade? conditionGrade,
    int? conditionScore,
    int? purchaseCost,
    int? salePrice,
    double? profitMargin,
    int? baseWarrantyMonths,
    String? buyerCompanyName,
    String? buyerContactName,
    String? buyerContactPhone,
    Timestamp? saleDate,
    String? verificationReportUrl,
    String? warrantyPdfUrl,
    String? qrCodeImageUrl,
    TransactionStatus? status,
    String? warrantyId,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return VerificationTransactionModel(
      transactionId: transactionId ?? this.transactionId,
      qrCode: qrCode ?? this.qrCode,
      transactionType: transactionType ?? this.transactionType,
      partCategory: partCategory ?? this.partCategory,
      brand: brand ?? this.brand,
      modelName: modelName ?? this.modelName,
      serialNumber: serialNumber ?? this.serialNumber,
      photoUrls: photoUrls ?? this.photoUrls,
      items: items ?? this.items,
      bundleName: bundleName ?? this.bundleName,
      inspectorId: inspectorId ?? this.inspectorId,
      inspectorName: inspectorName ?? this.inspectorName,
      inspectedAt: inspectedAt ?? this.inspectedAt,
      inspectionNote: inspectionNote ?? this.inspectionNote,
      inspectionPhotoUrls: inspectionPhotoUrls ?? this.inspectionPhotoUrls,
      benchmarkScores: benchmarkScores ?? this.benchmarkScores,
      conditionGrade: conditionGrade ?? this.conditionGrade,
      conditionScore: conditionScore ?? this.conditionScore,
      purchaseCost: purchaseCost ?? this.purchaseCost,
      salePrice: salePrice ?? this.salePrice,
      profitMargin: profitMargin ?? this.profitMargin,
      baseWarrantyMonths: baseWarrantyMonths ?? this.baseWarrantyMonths,
      buyerCompanyName: buyerCompanyName ?? this.buyerCompanyName,
      buyerContactName: buyerContactName ?? this.buyerContactName,
      buyerContactPhone: buyerContactPhone ?? this.buyerContactPhone,
      saleDate: saleDate ?? this.saleDate,
      verificationReportUrl: verificationReportUrl ?? this.verificationReportUrl,
      warrantyPdfUrl: warrantyPdfUrl ?? this.warrantyPdfUrl,
      qrCodeImageUrl: qrCodeImageUrl ?? this.qrCodeImageUrl,
      status: status ?? this.status,
      warrantyId: warrantyId ?? this.warrantyId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// 제품명 표시 (단일 또는 풀세트)
  String get displayName {
    if (transactionType == TransactionType.bundle) {
      return bundleName ?? '조립 PC 세트';
    }
    return '$brand $modelName';
  }

  /// 부품 개수 (풀세트)
  int get itemCount => items?.length ?? 1;
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

/// 거래 타입 한글 변환
extension TransactionTypeExtension on TransactionType {
  String get displayName {
    switch (this) {
      case TransactionType.single:
        return '단일 부품';
      case TransactionType.bundle:
        return '풀세트 (조립PC)';
    }
  }
}

/// 등급 표시
extension ConditionGradeExtension on ConditionGrade {
  String get displayName {
    switch (this) {
      case ConditionGrade.S:
        return 'S (최상급)';
      case ConditionGrade.A:
        return 'A (우수)';
      case ConditionGrade.B:
        return 'B (양호)';
      case ConditionGrade.C:
        return 'C (보통)';
      case ConditionGrade.D:
        return 'D (불량)';
    }
  }

  String get label {
    switch (this) {
      case ConditionGrade.S:
        return '최상급';
      case ConditionGrade.A:
        return '우수';
      case ConditionGrade.B:
        return '양호';
      case ConditionGrade.C:
        return '보통';
      case ConditionGrade.D:
        return '불량';
    }
  }

  int get baseWarrantyMonths {
    switch (this) {
      case ConditionGrade.S:
        return 24;
      case ConditionGrade.A:
        return 18;
      case ConditionGrade.B:
        return 12;
      case ConditionGrade.C:
        return 6;
      case ConditionGrade.D:
        return 3;
    }
  }
}
