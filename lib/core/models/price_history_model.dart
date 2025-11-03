// lib/core/models/price_history_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// 가격 이력 모델
/// 특정 부품의 일별 가격 통계를 저장
class PriceHistory {
  final String id; // Document ID (예: "RTX4090_2025-11-03")
  final String basePartId; // 기준 부품 ID
  final DateTime date; // 날짜
  final int lowestPrice; // 최저가
  final int averagePrice; // 평균가
  final int highestPrice; // 최고가
  final int transactionCount; // 거래 수
  final DateTime createdAt; // 생성 시간

  PriceHistory({
    required this.id,
    required this.basePartId,
    required this.date,
    required this.lowestPrice,
    required this.averagePrice,
    required this.highestPrice,
    required this.transactionCount,
    required this.createdAt,
  });

  /// Firestore 문서로부터 생성
  factory PriceHistory.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PriceHistory(
      id: doc.id,
      basePartId: data['basePartId'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      lowestPrice: data['lowestPrice'] ?? 0,
      averagePrice: data['averagePrice'] ?? 0,
      highestPrice: data['highestPrice'] ?? 0,
      transactionCount: data['transactionCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  /// Firestore 문서로 변환
  Map<String, dynamic> toFirestore() {
    return {
      'basePartId': basePartId,
      'date': Timestamp.fromDate(date),
      'lowestPrice': lowestPrice,
      'averagePrice': averagePrice,
      'highestPrice': highestPrice,
      'transactionCount': transactionCount,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// 복사본 생성
  PriceHistory copyWith({
    String? id,
    String? basePartId,
    DateTime? date,
    int? lowestPrice,
    int? averagePrice,
    int? highestPrice,
    int? transactionCount,
    DateTime? createdAt,
  }) {
    return PriceHistory(
      id: id ?? this.id,
      basePartId: basePartId ?? this.basePartId,
      date: date ?? this.date,
      lowestPrice: lowestPrice ?? this.lowestPrice,
      averagePrice: averagePrice ?? this.averagePrice,
      highestPrice: highestPrice ?? this.highestPrice,
      transactionCount: transactionCount ?? this.transactionCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
