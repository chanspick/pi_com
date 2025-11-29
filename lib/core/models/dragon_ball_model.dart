// lib/core/models/dragon_ball_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// 드래곤볼 상태
enum DragonBallStatus {
  stored,      // 보관 중
  packing,     // 배송 준비 중
  shipping,    // 배송 중
  delivered,   // 배송 완료
  consignment, // 위탁판매 중
  sold,        // 위탁판매 완료 (매각 완료)
}

/// 보관 서비스 타입 - 보관서비스 약관 제4조
enum StorageType {
  general,     // 일반 보관 (하루 0.5% 보관료)
  rental,      // 임대 보관 (무료, 회사가 임의 사용 가능)
}

/// 드래곤볼 모델
/// 사용자가 구매한 부품을 무료로 보관하고, 나중에 합배송할 수 있는 서비스
/// Firestore: users/{userId}/dragonBalls/{dragonBallId}
class DragonBallModel {
  final String dragonBallId;
  final String userId;
  final String listingId;        // 연결된 매물
  final String orderId;           // 연결된 주문
  final String partName;          // 부품 이름
  final String? imageUrl;         // 부품 이미지
  final DragonBallStatus status;  // 보관 상태
  final DateTime storedAt;        // 입고일
  final DateTime expiresAt;       // 보관 만료일 (기본 7일)
  final DateTime? shippedAt;      // 배송 시작일
  final DateTime? deliveredAt;    // 배송 완료일
  final String? batchShipmentId;  // 일괄 배송 ID

  // 동의서 관련
  final bool agreedToTerms;       // 임의 운용 동의 여부
  final DateTime agreedAt;        // 동의 시각

  // 가격 분석 메타데이터
  final int purchasePrice;        // 구매 당시 가격
  final String? basePartId;       // 부품 카테고리 (가격 분석용)
  final String? category;         // 부품 카테고리명
  final int accumulatedFee;       // 누적 보관료

  // 보관 서비스 타입 (약관 제4조)
  final StorageType storageType;  // 일반 보관 vs 임대 보관

  // 위탁판매 관련 (약관 제8조)
  final int? salePrice;           // 위탁판매 매각 가격
  final DateTime? consignmentConvertedAt;  // 위탁판매 전환일 (37일 경과 시)
  final int? revenueReturned;     // 고객에게 반환된 수익금

  DragonBallModel({
    required this.dragonBallId,
    required this.userId,
    required this.listingId,
    required this.orderId,
    required this.partName,
    this.imageUrl,
    required this.status,
    required this.storedAt,
    required this.expiresAt,
    this.shippedAt,
    this.deliveredAt,
    this.batchShipmentId,
    required this.agreedToTerms,
    required this.agreedAt,
    required this.purchasePrice,
    this.basePartId,
    this.category,
    this.accumulatedFee = 0,
    this.storageType = StorageType.general,  // 기본값: 일반 보관
    this.salePrice,
    this.consignmentConvertedAt,
    this.revenueReturned,
  });

  /// Firestore 문서로 변환
  Map<String, dynamic> toMap() {
    return {
      'dragonBallId': dragonBallId,
      'userId': userId,
      'listingId': listingId,
      'orderId': orderId,
      'partName': partName,
      'imageUrl': imageUrl,
      'status': status.name,
      'storedAt': Timestamp.fromDate(storedAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'shippedAt': shippedAt != null ? Timestamp.fromDate(shippedAt!) : null,
      'deliveredAt': deliveredAt != null ? Timestamp.fromDate(deliveredAt!) : null,
      'batchShipmentId': batchShipmentId,
      'agreedToTerms': agreedToTerms,
      'agreedAt': Timestamp.fromDate(agreedAt),
      'purchasePrice': purchasePrice,
      'basePartId': basePartId,
      'category': category,
      'accumulatedFee': accumulatedFee,
      'storageType': storageType.name,
      'salePrice': salePrice,
      'consignmentConvertedAt': consignmentConvertedAt != null ? Timestamp.fromDate(consignmentConvertedAt!) : null,
      'revenueReturned': revenueReturned,
    };
  }

  /// Firestore 문서에서 생성
  factory DragonBallModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return DragonBallModel(
      dragonBallId: doc.id,
      userId: data['userId'] ?? '',
      listingId: data['listingId'] ?? '',
      orderId: data['orderId'] ?? '',
      partName: data['partName'] ?? '',
      imageUrl: data['imageUrl'],
      status: _parseStatus(data['status']),
      storedAt: (data['storedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(days: 7)),
      shippedAt: (data['shippedAt'] as Timestamp?)?.toDate(),
      deliveredAt: (data['deliveredAt'] as Timestamp?)?.toDate(),
      batchShipmentId: data['batchShipmentId'],
      agreedToTerms: data['agreedToTerms'] ?? false,
      agreedAt: (data['agreedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      purchasePrice: (data['purchasePrice'] as num?)?.toInt() ?? 0,
      basePartId: data['basePartId'],
      category: data['category'],
      accumulatedFee: (data['accumulatedFee'] as num?)?.toInt() ?? 0,
      storageType: _parseStorageType(data['storageType']),
      salePrice: (data['salePrice'] as num?)?.toInt(),
      consignmentConvertedAt: (data['consignmentConvertedAt'] as Timestamp?)?.toDate(),
      revenueReturned: (data['revenueReturned'] as num?)?.toInt(),
    );
  }

  /// Map에서 생성
  factory DragonBallModel.fromMap(Map<String, dynamic> data) {
    return DragonBallModel(
      dragonBallId: data['dragonBallId'] ?? '',
      userId: data['userId'] ?? '',
      listingId: data['listingId'] ?? '',
      orderId: data['orderId'] ?? '',
      partName: data['partName'] ?? '',
      imageUrl: data['imageUrl'],
      status: _parseStatus(data['status']),
      storedAt: data['storedAt'] is Timestamp
          ? (data['storedAt'] as Timestamp).toDate()
          : DateTime.now(),
      expiresAt: data['expiresAt'] is Timestamp
          ? (data['expiresAt'] as Timestamp).toDate()
          : DateTime.now().add(const Duration(days: 7)),
      shippedAt: data['shippedAt'] is Timestamp
          ? (data['shippedAt'] as Timestamp).toDate()
          : null,
      deliveredAt: data['deliveredAt'] is Timestamp
          ? (data['deliveredAt'] as Timestamp).toDate()
          : null,
      batchShipmentId: data['batchShipmentId'],
      agreedToTerms: data['agreedToTerms'] ?? false,
      agreedAt: data['agreedAt'] is Timestamp
          ? (data['agreedAt'] as Timestamp).toDate()
          : DateTime.now(),
      purchasePrice: (data['purchasePrice'] as num?)?.toInt() ?? 0,
      basePartId: data['basePartId'],
      category: data['category'],
      accumulatedFee: (data['accumulatedFee'] as num?)?.toInt() ?? 0,
      storageType: _parseStorageType(data['storageType']),
      salePrice: (data['salePrice'] as num?)?.toInt(),
      consignmentConvertedAt: data['consignmentConvertedAt'] is Timestamp
          ? (data['consignmentConvertedAt'] as Timestamp).toDate()
          : null,
      revenueReturned: (data['revenueReturned'] as num?)?.toInt(),
    );
  }

  /// 상태 파싱 헬퍼
  static DragonBallStatus _parseStatus(dynamic status) {
    if (status == null) return DragonBallStatus.stored;

    switch (status.toString()) {
      case 'stored':
        return DragonBallStatus.stored;
      case 'packing':
        return DragonBallStatus.packing;
      case 'shipping':
        return DragonBallStatus.shipping;
      case 'delivered':
        return DragonBallStatus.delivered;
      case 'consignment':
        return DragonBallStatus.consignment;
      case 'sold':
        return DragonBallStatus.sold;
      default:
        return DragonBallStatus.stored;
    }
  }

  /// 보관 타입 파싱 헬퍼
  static StorageType _parseStorageType(dynamic storageType) {
    if (storageType == null) return StorageType.general;

    switch (storageType.toString()) {
      case 'general':
        return StorageType.general;
      case 'rental':
        return StorageType.rental;
      default:
        return StorageType.general;
    }
  }

  /// copyWith 메서드
  DragonBallModel copyWith({
    String? dragonBallId,
    String? userId,
    String? listingId,
    String? orderId,
    String? partName,
    String? imageUrl,
    DragonBallStatus? status,
    DateTime? storedAt,
    DateTime? expiresAt,
    DateTime? shippedAt,
    DateTime? deliveredAt,
    String? batchShipmentId,
    bool? agreedToTerms,
    DateTime? agreedAt,
    int? purchasePrice,
    String? basePartId,
    String? category,
    int? accumulatedFee,
    StorageType? storageType,
    int? salePrice,
    DateTime? consignmentConvertedAt,
    int? revenueReturned,
  }) {
    return DragonBallModel(
      dragonBallId: dragonBallId ?? this.dragonBallId,
      userId: userId ?? this.userId,
      listingId: listingId ?? this.listingId,
      orderId: orderId ?? this.orderId,
      partName: partName ?? this.partName,
      imageUrl: imageUrl ?? this.imageUrl,
      status: status ?? this.status,
      storedAt: storedAt ?? this.storedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      shippedAt: shippedAt ?? this.shippedAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      batchShipmentId: batchShipmentId ?? this.batchShipmentId,
      agreedToTerms: agreedToTerms ?? this.agreedToTerms,
      agreedAt: agreedAt ?? this.agreedAt,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      basePartId: basePartId ?? this.basePartId,
      category: category ?? this.category,
      accumulatedFee: accumulatedFee ?? this.accumulatedFee,
      storageType: storageType ?? this.storageType,
      salePrice: salePrice ?? this.salePrice,
      consignmentConvertedAt: consignmentConvertedAt ?? this.consignmentConvertedAt,
      revenueReturned: revenueReturned ?? this.revenueReturned,
    );
  }

  /// 만료까지 남은 일수 계산
  int get daysUntilExpiration {
    final now = DateTime.now();
    if (expiresAt.isBefore(now)) return 0;
    return expiresAt.difference(now).inDays;
  }

  /// 만료 임박 여부 (3일 이하)
  bool get isExpiringSoon {
    return daysUntilExpiration <= 3 && daysUntilExpiration > 0;
  }

  /// 만료됨 여부
  bool get isExpired {
    return daysUntilExpiration <= 0;
  }

  /// 상태 배지 텍스트
  String get statusBadgeText {
    switch (status) {
      case DragonBallStatus.stored:
        return '보관 중';
      case DragonBallStatus.packing:
        return '배송 준비 중';
      case DragonBallStatus.shipping:
        return '배송 중';
      case DragonBallStatus.delivered:
        return '배송 완료';
      case DragonBallStatus.consignment:
        return '위탁판매 중';
      case DragonBallStatus.sold:
        return '매각 완료';
    }
  }

  /// 상태 배지 색상 (Material Color name)
  String get statusBadgeColor {
    switch (status) {
      case DragonBallStatus.stored:
        return 'green';
      case DragonBallStatus.packing:
        return 'orange';
      case DragonBallStatus.shipping:
        return 'blue';
      case DragonBallStatus.delivered:
        return 'grey';
      case DragonBallStatus.consignment:
        return 'purple';
      case DragonBallStatus.sold:
        return 'teal';
    }
  }
}
