// lib/core/models/price_alert_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// 가격 알림 모델
/// 사용자가 특정 부품에 대해 설정한 목표 가격 알림
class PriceAlert {
  final String alertId; // Document ID
  final String userId; // 사용자 ID
  final String basePartId; // 기준 부품 ID
  final String partName; // 부품명 (캐시)
  final int targetPrice; // 목표 가격
  final int priceAtCreation; // 설정 당시 가격
  final bool isActive; // 활성화 여부
  final DateTime createdAt; // 생성 시간
  final DateTime? triggeredAt; // 알림 발생 시간 (null이면 미발생)
  final DateTime? lastCheckedAt; // 마지막 체크 시간

  PriceAlert({
    required this.alertId,
    required this.userId,
    required this.basePartId,
    required this.partName,
    required this.targetPrice,
    required this.priceAtCreation,
    required this.isActive,
    required this.createdAt,
    this.triggeredAt,
    this.lastCheckedAt,
  });

  /// Firestore 문서로부터 생성
  factory PriceAlert.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PriceAlert(
      alertId: doc.id,
      userId: data['userId'] ?? '',
      basePartId: data['basePartId'] ?? '',
      partName: data['partName'] ?? '',
      targetPrice: data['targetPrice'] ?? 0,
      priceAtCreation: data['priceAtCreation'] ?? 0,
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      triggeredAt: data['triggeredAt'] != null
          ? (data['triggeredAt'] as Timestamp).toDate()
          : null,
      lastCheckedAt: data['lastCheckedAt'] != null
          ? (data['lastCheckedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Firestore 문서로 변환
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'basePartId': basePartId,
      'partName': partName,
      'targetPrice': targetPrice,
      'priceAtCreation': priceAtCreation,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'triggeredAt': triggeredAt != null ? Timestamp.fromDate(triggeredAt!) : null,
      'lastCheckedAt': lastCheckedAt != null ? Timestamp.fromDate(lastCheckedAt!) : null,
    };
  }

  /// 할인율 계산 (목표가가 설정 당시가보다 낮을 때)
  double get discountPercentage {
    if (priceAtCreation == 0) return 0;
    return ((priceAtCreation - targetPrice) / priceAtCreation * 100);
  }

  /// 알림 상태 텍스트
  String get statusText {
    if (!isActive) return '비활성화';
    if (triggeredAt != null) return '알림 완료';
    return '대기 중';
  }

  /// 복사본 생성
  PriceAlert copyWith({
    String? alertId,
    String? userId,
    String? basePartId,
    String? partName,
    int? targetPrice,
    int? priceAtCreation,
    bool? isActive,
    DateTime? createdAt,
    DateTime? triggeredAt,
    DateTime? lastCheckedAt,
  }) {
    return PriceAlert(
      alertId: alertId ?? this.alertId,
      userId: userId ?? this.userId,
      basePartId: basePartId ?? this.basePartId,
      partName: partName ?? this.partName,
      targetPrice: targetPrice ?? this.targetPrice,
      priceAtCreation: priceAtCreation ?? this.priceAtCreation,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      triggeredAt: triggeredAt ?? this.triggeredAt,
      lastCheckedAt: lastCheckedAt ?? this.lastCheckedAt,
    );
  }
}
