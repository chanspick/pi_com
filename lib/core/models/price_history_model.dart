// lib/core/models/price_history_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// 가격 이력 모델
/// 특정 부품의 6시간 간격 가격 통계를 저장
class PriceHistory {
  final String id; // Document ID (예: "RTX4090_2025-11-03T12:00:00")
  final String basePartId; // 기준 부품 ID
  final DateTime timestamp; // 스냅샷 시간 (6시간 단위로 정렬)
  final int lowestPrice; // 최저가 (AVAILABLE 매물 기준)
  final int averagePrice; // 평균가 (AVAILABLE 매물 기준)
  final int highestPrice; // 최고가 (AVAILABLE 매물 기준)
  final int availableCount; // 현재 판매중인 매물 수
  final DateTime createdAt; // 생성 시간

  PriceHistory({
    required this.id,
    required this.basePartId,
    required this.timestamp,
    required this.lowestPrice,
    required this.averagePrice,
    required this.highestPrice,
    required this.availableCount,
    required this.createdAt,
  });

  /// 6시간 단위로 정렬된 타임스탬프 생성 (0시, 6시, 12시, 18시)
  static DateTime get6HourAlignedTimestamp(DateTime dt) {
    final hour = (dt.hour ~/ 6) * 6;
    return DateTime(dt.year, dt.month, dt.day, hour);
  }

  /// Document ID 생성 (basePartId + 6시간 단위 타임스탬프)
  static String generateId(String basePartId, DateTime timestamp) {
    final aligned = get6HourAlignedTimestamp(timestamp);
    return '${basePartId}_${aligned.toIso8601String()}';
  }

  /// Firestore 문서로부터 생성
  factory PriceHistory.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PriceHistory(
      id: doc.id,
      basePartId: data['basePartId'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      lowestPrice: data['lowestPrice'] ?? 0,
      averagePrice: data['averagePrice'] ?? 0,
      highestPrice: data['highestPrice'] ?? 0,
      availableCount: data['availableCount'] ?? 0,
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
      'highestPrice': highestPrice,
      'availableCount': availableCount,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// 복사본 생성
  PriceHistory copyWith({
    String? id,
    String? basePartId,
    DateTime? timestamp,
    int? lowestPrice,
    int? averagePrice,
    int? highestPrice,
    int? availableCount,
    DateTime? createdAt,
  }) {
    return PriceHistory(
      id: id ?? this.id,
      basePartId: basePartId ?? this.basePartId,
      timestamp: timestamp ?? this.timestamp,
      lowestPrice: lowestPrice ?? this.lowestPrice,
      averagePrice: averagePrice ?? this.averagePrice,
      highestPrice: highestPrice ?? this.highestPrice,
      availableCount: availableCount ?? this.availableCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
