import 'package:cloud_firestore/cloud_firestore.dart';

// --- Enums ---

enum AgeInfoType {
  originalPurchaseDate,
  manufacturDate,
  unknown,
}

enum SellRequestStatus {
  pending,
  approved,
  rejected,
  sold,
}

// --- Model Class ---

class SellRequest {
  final String requestId;
  final String sellerId;

  // 부품 정보
  final String partId;        // Part의 ID (제조사 포함 상세)
  final String basePartId;    // BasePart ID (검색/통계용)
  final String brand;         // 🆕 제조사 (예: Samsung, Intel)
  final String category;
  final String modelName;

  // 핵심 정보: 부품 연식 및 소유 이력
  final AgeInfoType ageInfoType;
  final int? ageInfoYear;
  final int? ageInfoMonth;
  final bool isSecondHand;

  // 기타 정보
  final bool hasWarranty;
  final int? warrantyMonthsLeft;
  final String usageFrequency;
  final String purpose;
  final int requestedPrice;
  final List imageUrls;

  // 관리 정보
  final SellRequestStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? adminNotes;

  SellRequest({
    required this.requestId,
    required this.sellerId,
    required this.partId,
    required this.basePartId,
    required this.brand,          // 🆕 필수 파라미터
    required this.category,
    required this.modelName,
    required this.ageInfoType,
    this.ageInfoYear,
    this.ageInfoMonth,
    required this.isSecondHand,
    required this.hasWarranty,
    this.warrantyMonthsLeft,
    required this.usageFrequency,
    required this.purpose,
    required this.requestedPrice,
    required this.imageUrls,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.adminNotes,
  });

  Map<String, dynamic> toMap() {
    return {
      'requestId': requestId,
      'sellerId': sellerId,
      'partId': partId,
      'basePartId': basePartId,
      'brand': brand,           // 🆕
      'category': category,
      'modelName': modelName,
      'ageInfoType': ageInfoType.name,
      'ageInfoYear': ageInfoYear,
      'ageInfoMonth': ageInfoMonth,
      'isSecondHand': isSecondHand,
      'hasWarranty': hasWarranty,
      'warrantyMonthsLeft': warrantyMonthsLeft,
      'usageFrequency': usageFrequency,
      'purpose': purpose,
      'requestedPrice': requestedPrice,
      'imageUrls': imageUrls,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'adminNotes': adminNotes,
    };
  }

  factory SellRequest.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return SellRequest(
      requestId: doc.id,
      sellerId: data['sellerId'] ?? '',
      partId: data['partId'] ?? '',
      basePartId: data['basePartId'] ?? '',
      brand: data['brand'] ?? '',  // 🆕 기본값 빈 문자열
      category: data['category'] ?? '',
      modelName: data['modelName'] ?? '',
      ageInfoType: AgeInfoType.values.firstWhere(
            (e) => e.name == data['ageInfoType'],
        orElse: () => AgeInfoType.unknown,
      ),
      ageInfoYear: data['ageInfoYear'],
      ageInfoMonth: data['ageInfoMonth'],
      isSecondHand: data['isSecondHand'] ?? false,
      hasWarranty: data['hasWarranty'] ?? false,
      warrantyMonthsLeft: data['warrantyMonthsLeft'],
      usageFrequency: data['usageFrequency'] ?? '',
      purpose: data['purpose'] ?? '',
      requestedPrice: (data['requestedPrice'] as num?)?.toInt() ?? 0,
      imageUrls: List.from(data['imageUrls'] ?? []),
      status: SellRequestStatus.values.firstWhere(
            (e) => e.name == data['status'],
        orElse: () => SellRequestStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      adminNotes: data['adminNotes'],
    );
  }

  SellRequest copyWith({
    String? requestId,
    String? sellerId,
    String? partId,
    String? basePartId,
    String? brand,              // 🆕
    String? category,
    String? modelName,
    AgeInfoType? ageInfoType,
    int? ageInfoYear,
    int? ageInfoMonth,
    bool? isSecondHand,
    bool? hasWarranty,
    int? warrantyMonthsLeft,
    String? usageFrequency,
    String? purpose,
    int? requestedPrice,
    List? imageUrls,
    SellRequestStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? adminNotes,
  }) {
    return SellRequest(
      requestId: requestId ?? this.requestId,
      sellerId: sellerId ?? this.sellerId,
      partId: partId ?? this.partId,
      basePartId: basePartId ?? this.basePartId,
      brand: brand ?? this.brand,  // 🆕
      category: category ?? this.category,
      modelName: modelName ?? this.modelName,
      ageInfoType: ageInfoType ?? this.ageInfoType,
      ageInfoYear: ageInfoYear ?? this.ageInfoYear,
      ageInfoMonth: ageInfoMonth ?? this.ageInfoMonth,
      isSecondHand: isSecondHand ?? this.isSecondHand,
      hasWarranty: hasWarranty ?? this.hasWarranty,
      warrantyMonthsLeft: warrantyMonthsLeft ?? this.warrantyMonthsLeft,
      usageFrequency: usageFrequency ?? this.usageFrequency,
      purpose: purpose ?? this.purpose,
      requestedPrice: requestedPrice ?? this.requestedPrice,
      imageUrls: imageUrls ?? this.imageUrls,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      adminNotes: adminNotes ?? this.adminNotes,
    );
  }
}
