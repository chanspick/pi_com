// lib/core/models/base_part_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// 부품 카테고리 enum
enum PartCategory {
  cpu,
  gpu,
  ssd,
  mainboard,
  ram,
  psu,
  cooler,
  pccase,
}

class BasePart {
  final String basePartId;
  final String modelName;
  final String category;
  final String brand;  // 제조사 (예: Intel, AMD, Samsung)

  // Cloud Function이 업데이트해 줄 가격 통계 필드
  final int lowestPrice;
  final double averagePrice;
  final int listingCount;

  // ============ 카테고리별 공통 스펙 필드 ============
  // RAM, SSD용: 용량 (GB)
  final int? capacity;

  // RAM용: DDR4, DDR5
  final String? memoryType;

  // RAM용: 클럭 (MHz)
  final int? speed;

  // CPU, Mainboard, Cooler용: 소켓 타입
  final String? socket;

  // Mainboard, Case, PSU용: 폼팩터
  final String? formFactor;

  // PSU용: 용량 (W)
  final int? wattage;

  // CPU, GPU용: 소비 전력 (W), Cooler용: 냉각 능력 (W)
  final int? tdp;

  // SSD용: SATA, NVMe
  final String? interface;

  BasePart({
    required this.basePartId,
    required this.modelName,
    required this.category,
    this.brand = '',  // 기본값: 빈 문자열
    required this.lowestPrice,
    required this.averagePrice,
    required this.listingCount,
    // 선택적 스펙 필드
    this.capacity,
    this.memoryType,
    this.speed,
    this.socket,
    this.formFactor,
    this.wattage,
    this.tdp,
    this.interface,
  });

  factory BasePart.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return BasePart(
      basePartId: doc.id,
      modelName: data['modelName'] ?? '이름 없음',
      category: data['category'] ?? '',
      brand: data['brand'] ?? '',
      lowestPrice: (data['lowestPrice'] as num?)?.toInt() ?? 0,
      averagePrice: (data['averagePrice'] as num?)?.toDouble() ?? 0.0,
      listingCount: (data['listingCount'] as num?)?.toInt() ?? 0,
      // 스펙 필드
      capacity: (data['capacity'] as num?)?.toInt(),
      memoryType: data['memoryType'] as String?,
      speed: (data['speed'] as num?)?.toInt(),
      socket: data['socket'] as String?,
      formFactor: data['formFactor'] as String?,
      wattage: (data['wattage'] as num?)?.toInt(),
      tdp: (data['tdp'] as num?)?.toInt(),
      interface: data['interface'] as String?,
    );
  }

  // === 추가: fromMap 팩토리 생성자 ===
  factory BasePart.fromMap(Map<String, dynamic> data) {
    return BasePart(
      basePartId: data['basePartId'] ?? data['objectID'] ?? '',
      modelName: data['modelName'] ?? '이름 없음',
      category: data['category'] ?? '',
      brand: data['brand'] ?? '',
      lowestPrice: (data['lowestPrice'] as num?)?.toInt() ?? 0,
      averagePrice: (data['averagePrice'] as num?)?.toDouble() ?? 0.0,
      listingCount: (data['listingCount'] as num?)?.toInt() ?? 0,
      // 스펙 필드
      capacity: (data['capacity'] as num?)?.toInt(),
      memoryType: data['memoryType'] as String?,
      speed: (data['speed'] as num?)?.toInt(),
      socket: data['socket'] as String?,
      formFactor: data['formFactor'] as String?,
      wattage: (data['wattage'] as num?)?.toInt(),
      tdp: (data['tdp'] as num?)?.toInt(),
      interface: data['interface'] as String?,
    );
  }

  // === 추가: toMap 메서드 (필요시 사용) ===
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'basePartId': basePartId,
      'modelName': modelName,
      'category': category,
      'brand': brand,
      'lowestPrice': lowestPrice,
      'averagePrice': averagePrice,
      'listingCount': listingCount,
    };

    // null이 아닌 스펙 필드만 추가
    if (capacity != null) map['capacity'] = capacity!;
    if (memoryType != null) map['memoryType'] = memoryType!;
    if (speed != null) map['speed'] = speed!;
    if (socket != null) map['socket'] = socket!;
    if (formFactor != null) map['formFactor'] = formFactor!;
    if (wattage != null) map['wattage'] = wattage!;
    if (tdp != null) map['tdp'] = tdp!;
    if (interface != null) map['interface'] = interface!;

    return map;
  }

  // === 편의 메서드: 용량 표시 (RAM, SSD용) ===
  String get capacityText {
    if (capacity == null) return '';
    if (category == 'ram' || category == 'ssd') {
      return capacity! >= 1000 ? '${capacity! ~/ 1000}TB' : '${capacity}GB';
    }
    return '';
  }

  // === 편의 메서드: RAM 전체 스펙 표시 ===
  String get ramSpecText {
    if (category != 'ram') return '';
    final parts = <String>[];
    if (memoryType != null) parts.add(memoryType!);
    if (capacity != null) parts.add('${capacity}GB');
    if (speed != null) parts.add('${speed}MHz');
    return parts.join(' ');
  }

  // === 편의 메서드: SSD 전체 스펙 표시 ===
  String get ssdSpecText {
    if (category != 'ssd') return '';
    final parts = <String>[];
    if (capacity != null) parts.add(capacityText);
    if (interface != null) parts.add(interface!);
    return parts.join(' ');
  }
}
