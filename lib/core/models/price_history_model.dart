// lib/core/models/price_history_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// 가격 이력 모델
/// 가격 변동 발생 시 실시간으로 저장
class PriceHistory {
  final String id; // Document ID (예: "RTX4090_1699876543210")
  final String basePartId; // 기준 부품 ID
  final DateTime timestamp; // 가격 변경 시간
  final int lowestPrice; // 최저가 (AVAILABLE 매물 기준)
  final double averagePrice; // 평균가 (AVAILABLE 매물 기준)
  final int listingCount; // 현재 판매중인 매물 수
  final DateTime createdAt; // 생성 시간

  PriceHistory({
    required this.id,
    required this.basePartId,
    required this.timestamp,
    required this.lowestPrice,
    required this.averagePrice,
    required this.listingCount,
    required this.createdAt,
  });

  /// Firestore 문서로부터 생성
  factory PriceHistory.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PriceHistory(
      id: doc.id,
      basePartId: data['basePartId'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      lowestPrice: (data['lowestPrice'] as num?)?.toInt() ?? 0,
      averagePrice: (data['averagePrice'] as num?)?.toDouble() ?? 0.0,
      listingCount: (data['listingCount'] as num?)?.toInt() ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  /// Firestore 문서로 변환
  Map<String, dynamic> toFirestore() {
    return {
      'basePartId': basePartId,
      'timestamp': Timestamp.fromDate(timestamp),
      'lowestPrice': lowestPrice,
      'averagePrice': averagePrice,
      'listingCount': listingCount,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// 복사본 생성
  PriceHistory copyWith({
    String? id,
    String? basePartId,
    DateTime? timestamp,
    int? lowestPrice,
    double? averagePrice,
    int? listingCount,
    DateTime? createdAt,
  }) {
    return PriceHistory(
      id: id ?? this.id,
      basePartId: basePartId ?? this.basePartId,
      timestamp: timestamp ?? this.timestamp,
      lowestPrice: lowestPrice ?? this.lowestPrice,
      averagePrice: averagePrice ?? this.averagePrice,
      listingCount: listingCount ?? this.listingCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
