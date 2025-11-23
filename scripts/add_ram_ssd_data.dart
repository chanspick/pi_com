// scripts/add_ram_ssd_data.dart
// Firebase에 RAM과 SSD 데이터를 추가하는 스크립트
// 실행 방법: dart run scripts/add_ram_ssd_data.dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  print('🚀 Firebase RAM/SSD 데이터 추가 스크립트 시작...\n');

  // Firebase 초기화 (실제 프로젝트 설정 필요)
  // await Firebase.initializeApp();

  print('⚠️  이 스크립트는 Firebase Admin SDK 또는 Firebase CLI를 통해 실행해야 합니다.');
  print('📝 생성된 JSON 파일을 Firebase Console에서 수동으로 import하거나,');
  print('   Node.js 스크립트로 변환하여 실행하세요.\n');

  // JSON 파일 생성
  await generateJsonFiles();

  print('✅ JSON 파일 생성 완료!');
  print('   - scripts/base_parts_ram.json');
  print('   - scripts/base_parts_ssd.json');
  print('   - scripts/parts_ram.json');
  print('   - scripts/parts_ssd.json');
}

Future<void> generateJsonFiles() async {
  // 1. BaseParts - RAM 데이터
  final basePartsRam = generateBasePartsRam();
  await File('scripts/base_parts_ram.json').writeAsString(_toJsonString(basePartsRam));
  print('✓ base_parts_ram.json 생성 (${basePartsRam.length}개 항목)');

  // 2. BaseParts - SSD 데이터
  final basePartsSsd = generateBasePartsSsd();
  await File('scripts/base_parts_ssd.json').writeAsString(_toJsonString(basePartsSsd));
  print('✓ base_parts_ssd.json 생성 (${basePartsSsd.length}개 항목)');

  // 3. Parts - RAM 샘플 데이터
  final partsRam = generatePartsRam();
  await File('scripts/parts_ram.json').writeAsString(_toJsonString(partsRam));
  print('✓ parts_ram.json 생성 (${partsRam.length}개 항목)');

  // 4. Parts - SSD 샘플 데이터
  final partsSsd = generatePartsSsd();
  await File('scripts/parts_ssd.json').writeAsString(_toJsonString(partsSsd));
  print('✓ parts_ssd.json 생성 (${partsSsd.length}개 항목)');
}

String _toJsonString(List<Map<String, dynamic>> data) {
  final buffer = StringBuffer();
  buffer.writeln('[');
  for (var i = 0; i < data.length; i++) {
    buffer.write('  ');
    buffer.write(_mapToJson(data[i]));
    if (i < data.length - 1) buffer.write(',');
    buffer.writeln();
  }
  buffer.writeln(']');
  return buffer.toString();
}

String _mapToJson(Map<String, dynamic> map) {
  final items = map.entries.map((e) {
    final value = e.value is String ? '"${e.value}"' : e.value;
    return '"${e.key}": $value';
  }).join(', ');
  return '{$items}';
}

// ==================== BaseParts - RAM ====================
List<Map<String, dynamic>> generateBasePartsRam() {
  final List<Map<String, dynamic>> baseParts = [];

  // DDR4 RAM 모델
  final ddr4Models = [
    {'brand': 'Samsung', 'model': 'DDR4-3200', 'speed': 3200},
    {'brand': 'Samsung', 'model': 'DDR4-2666', 'speed': 2666},
    {'brand': 'Crucial', 'model': 'DDR4-3200 CL22', 'speed': 3200},
    {'brand': 'Crucial', 'model': 'DDR4-2666 CL19', 'speed': 2666},
    {'brand': 'G.SKILL', 'model': 'Ripjaws V DDR4-3600', 'speed': 3600},
    {'brand': 'Corsair', 'model': 'Vengeance LPX DDR4-3200', 'speed': 3200},
    {'brand': 'Kingston', 'model': 'FURY Beast DDR4-3200', 'speed': 3200},
  ];

  final ddr4Capacities = [8, 16, 32];

  for (var model in ddr4Models) {
    for (var capacity in ddr4Capacities) {
      final basePrice = _getRamBasePrice('DDR4', capacity);
      baseParts.add({
        'basePartId': 'ram_ddr4_${model['brand']}_${capacity}gb_${model['speed']}mhz'.toLowerCase().replaceAll(' ', '_').replaceAll('.', ''),
        'modelName': '${model['brand']} ${model['model']} ${capacity}GB',
        'category': 'ram',
        'brand': model['brand'],
        'capacity': capacity,
        'memoryType': 'DDR4',
        'speed': model['speed'],
        'lowestPrice': (basePrice * 0.85).round(),
        'averagePrice': basePrice.toDouble(),
        'listingCount': _randomListingCount(),
      });
    }
  }

  // DDR5 RAM 모델
  final ddr5Models = [
    {'brand': 'Samsung', 'model': 'DDR5-5600', 'speed': 5600},
    {'brand': 'Samsung', 'model': 'DDR5-4800', 'speed': 4800},
    {'brand': 'Crucial', 'model': 'DDR5-5600 CL46', 'speed': 5600},
    {'brand': 'Crucial', 'model': 'DDR5-4800 CL40', 'speed': 4800},
    {'brand': 'G.SKILL', 'model': 'Trident Z5 DDR5-6000', 'speed': 6000},
    {'brand': 'Corsair', 'model': 'Vengeance DDR5-5600', 'speed': 5600},
    {'brand': 'Kingston', 'model': 'FURY Beast DDR5-5600', 'speed': 5600},
  ];

  final ddr5Capacities = [16, 32];

  for (var model in ddr5Models) {
    for (var capacity in ddr5Capacities) {
      final basePrice = _getRamBasePrice('DDR5', capacity);
      baseParts.add({
        'basePartId': 'ram_ddr5_${model['brand']}_${capacity}gb_${model['speed']}mhz'.toLowerCase().replaceAll(' ', '_').replaceAll('.', ''),
        'modelName': '${model['brand']} ${model['model']} ${capacity}GB',
        'category': 'ram',
        'brand': model['brand'],
        'capacity': capacity,
        'memoryType': 'DDR5',
        'speed': model['speed'],
        'lowestPrice': (basePrice * 0.85).round(),
        'averagePrice': basePrice.toDouble(),
        'listingCount': _randomListingCount(),
      });
    }
  }

  return baseParts;
}

// ==================== BaseParts - SSD ====================
List<Map<String, dynamic>> generateBasePartsSsd() {
  final List<Map<String, dynamic>> baseParts = [];

  // NVMe SSD 모델
  final nvmeModels = [
    {'brand': 'Samsung', 'model': '980 PRO NVMe', 'read': 7000, 'write': 5000},
    {'brand': 'Samsung', 'model': '970 EVO Plus NVMe', 'read': 3500, 'write': 3300},
    {'brand': 'WD', 'model': 'Black SN850X NVMe', 'read': 7300, 'write': 6300},
    {'brand': 'WD', 'model': 'Blue SN570 NVMe', 'read': 3500, 'write': 3000},
    {'brand': 'Crucial', 'model': 'P3 Plus NVMe', 'read': 5000, 'write': 4200},
    {'brand': 'Crucial', 'model': 'P2 NVMe', 'read': 2400, 'write': 1900},
    {'brand': 'SK hynix', 'model': 'Platinum P41 NVMe', 'read': 7000, 'write': 6500},
  ];

  final nvmeCapacities = [500, 1000, 2000];

  for (var model in nvmeModels) {
    for (var capacity in nvmeCapacities) {
      final basePrice = _getSsdBasePrice('NVMe', capacity);
      baseParts.add({
        'basePartId': 'ssd_nvme_${model['brand']}_${capacity}gb'.toLowerCase().replaceAll(' ', '_'),
        'modelName': '${model['brand']} ${model['model']} ${_formatCapacity(capacity)}',
        'category': 'ssd',
        'brand': model['brand'],
        'capacity': capacity,
        'interface': 'NVMe',
        'formFactor': 'M.2',
        'readSpeed': model['read'],
        'writeSpeed': model['write'],
        'lowestPrice': (basePrice * 0.85).round(),
        'averagePrice': basePrice.toDouble(),
        'listingCount': _randomListingCount(),
      });
    }
  }

  // SATA SSD 모델
  final sataModels = [
    {'brand': 'Samsung', 'model': '870 EVO SATA', 'read': 560, 'write': 530},
    {'brand': 'Samsung', 'model': '860 EVO SATA', 'read': 550, 'write': 520},
    {'brand': 'WD', 'model': 'Blue SA510 SATA', 'read': 560, 'write': 530},
    {'brand': 'Crucial', 'model': 'MX500 SATA', 'read': 560, 'write': 510},
    {'brand': 'Kingston', 'model': 'A400 SATA', 'read': 500, 'write': 450},
  ];

  final sataCapacities = [500, 1000, 2000];

  for (var model in sataModels) {
    for (var capacity in sataCapacities) {
      final basePrice = _getSsdBasePrice('SATA', capacity);
      baseParts.add({
        'basePartId': 'ssd_sata_${model['brand']}_${capacity}gb'.toLowerCase().replaceAll(' ', '_'),
        'modelName': '${model['brand']} ${model['model']} ${_formatCapacity(capacity)}',
        'category': 'ssd',
        'brand': model['brand'],
        'capacity': capacity,
        'interface': 'SATA',
        'formFactor': '2.5"',
        'readSpeed': model['read'],
        'writeSpeed': model['write'],
        'lowestPrice': (basePrice * 0.85).round(),
        'averagePrice': basePrice.toDouble(),
        'listingCount': _randomListingCount(),
      });
    }
  }

  return baseParts;
}

// ==================== Parts - RAM (샘플 데이터) ====================
List<Map<String, dynamic>> generatePartsRam() {
  final List<Map<String, dynamic>> parts = [];
  int partCounter = 1;

  // 각 BasePart에 대해 2-3개의 샘플 Part 생성
  final basePartsRam = generateBasePartsRam();

  for (var basePart in basePartsRam.take(20)) {  // 처음 20개만 샘플 생성
    final sampleCount = 2 + (partCounter % 2);  // 2~3개

    for (var i = 0; i < sampleCount; i++) {
      parts.add({
        'partId': 'part_ram_${partCounter.toString().padLeft(4, '0')}',
        'basePartId': basePart['basePartId'],
        'category': 'ram',
        'brand': basePart['brand'],
        'modelName': basePart['modelName'],
        'capacity': basePart['capacity'],
        'memoryType': basePart['memoryType'],
        'speed': basePart['speed'],
        'moduleCount': (basePart['capacity'] as int) >= 16 ? 2 : 1,  // 16GB 이상은 듀얼채널
      });
      partCounter++;
    }
  }

  return parts;
}

// ==================== Parts - SSD (샘플 데이터) ====================
List<Map<String, dynamic>> generatePartsSsd() {
  final List<Map<String, dynamic>> parts = [];
  int partCounter = 1;

  // 각 BasePart에 대해 2-3개의 샘플 Part 생성
  final basePartsSsd = generateBasePartsSsd();

  for (var basePart in basePartsSsd.take(20)) {  // 처음 20개만 샘플 생성
    final sampleCount = 2 + (partCounter % 2);  // 2~3개

    for (var i = 0; i < sampleCount; i++) {
      parts.add({
        'partId': 'part_ssd_${partCounter.toString().padLeft(4, '0')}',
        'basePartId': basePart['basePartId'],
        'category': 'ssd',
        'brand': basePart['brand'],
        'modelName': basePart['modelName'],
        'capacity': basePart['capacity'],
        'interface': basePart['interface'],
        'formFactor': basePart['formFactor'],
        'readSpeed': basePart['readSpeed'],
        'writeSpeed': basePart['writeSpeed'],
      });
      partCounter++;
    }
  }

  return parts;
}

// ==================== 헬퍼 함수 ====================

int _getRamBasePrice(String memoryType, int capacity) {
  // 중고 시장 평균 가격 (만원 단위)
  if (memoryType == 'DDR4') {
    switch (capacity) {
      case 8: return 2;   // 2만원
      case 16: return 4;  // 4만원
      case 32: return 8;  // 8만원
      default: return 5;
    }
  } else {  // DDR5
    switch (capacity) {
      case 16: return 8;   // 8만원
      case 32: return 16;  // 16만원
      default: return 10;
    }
  }
}

int _getSsdBasePrice(String interface, int capacity) {
  // 중고 시장 평균 가격 (만원 단위)
  final isNvme = interface == 'NVMe';

  switch (capacity) {
    case 500:
      return isNvme ? 4 : 3;   // NVMe: 4만원, SATA: 3만원
    case 1000:
      return isNvme ? 7 : 5;   // NVMe: 7만원, SATA: 5만원
    case 2000:
      return isNvme ? 14 : 10; // NVMe: 14만원, SATA: 10만원
    default:
      return 5;
  }
}

int _randomListingCount() {
  // 실제로는 랜덤하게 생성하지만, 여기서는 고정값
  return 5 + (DateTime.now().millisecondsSinceEpoch % 15);
}

String _formatCapacity(int capacityGb) {
  if (capacityGb >= 1000) {
    return '${capacityGb ~/ 1000}TB';
  }
  return '${capacityGb}GB';
}
