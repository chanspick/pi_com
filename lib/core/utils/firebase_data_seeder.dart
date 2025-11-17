// lib/core/utils/firebase_data_seeder.dart
// Flutter 앱 내에서 Firebase에 RAM/SSD 데이터를 추가하는 유틸리티

import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class FirebaseDataSeeder {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Random _random = Random();

  // ==================== 메인 실행 함수 ====================
  Future<void> seedRamAndSsdData() async {
    print('🚀 Firebase RAM/SSD 데이터 추가 시작...\n');

    try {
      // 1. BaseParts - RAM 추가
      print('📦 BaseParts - RAM 추가 중...');
      final basePartsRam = _generateBasePartsRam();
      await _addBaseParts(basePartsRam);
      print('✓ BaseParts RAM ${basePartsRam.length}개 추가 완료\n');

      // 2. BaseParts - SSD 추가
      print('📦 BaseParts - SSD 추가 중...');
      final basePartsSsd = _generateBasePartsSsd();
      await _addBaseParts(basePartsSsd);
      print('✓ BaseParts SSD ${basePartsSsd.length}개 추가 완료\n');

      // 3. Parts - RAM 샘플 추가
      print('📦 Parts - RAM 샘플 추가 중...');
      final partsRam = _generatePartsRam(basePartsRam);
      await _addParts(partsRam);
      print('✓ Parts RAM ${partsRam.length}개 추가 완료\n');

      // 4. Parts - SSD 샘플 추가
      print('📦 Parts - SSD 샘플 추가 중...');
      final partsSsd = _generatePartsSsd(basePartsSsd);
      await _addParts(partsSsd);
      print('✓ Parts SSD ${partsSsd.length}개 추가 완료\n');

      print('✅ 모든 데이터 추가 완료!');
      print('   - BaseParts RAM: ${basePartsRam.length}개');
      print('   - BaseParts SSD: ${basePartsSsd.length}개');
      print('   - Parts RAM: ${partsRam.length}개');
      print('   - Parts SSD: ${partsSsd.length}개');
    } catch (error) {
      print('❌ 오류 발생: $error');
      rethrow;
    }
  }

  // ==================== Firebase 추가 함수 ====================
  Future<void> _addBaseParts(List<Map<String, dynamic>> baseParts) async {
    final batch = _firestore.batch();
    int count = 0;

    for (final part in baseParts) {
      final docRef = _firestore.collection('base_parts').doc(part['basePartId']);
      batch.set(docRef, part);
      count++;

      // Firestore batch는 최대 500개 제한
      if (count % 500 == 0) {
        await batch.commit();
        print('  - $count개 배치 커밋 완료');
      }
    }

    // 남은 데이터 커밋
    if (count % 500 != 0) {
      await batch.commit();
    }
  }

  Future<void> _addParts(List<Map<String, dynamic>> parts) async {
    final batch = _firestore.batch();
    int count = 0;

    for (final part in parts) {
      final docRef = _firestore.collection('parts').doc(part['partId']);
      batch.set(docRef, part);
      count++;

      // Firestore batch는 최대 500개 제한
      if (count % 500 == 0) {
        await batch.commit();
        print('  - $count개 배치 커밋 완료');
      }
    }

    // 남은 데이터 커밋
    if (count % 500 != 0) {
      await batch.commit();
    }
  }

  // ==================== BaseParts - RAM ====================
  List<Map<String, dynamic>> _generateBasePartsRam() {
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

    for (final model in ddr4Models) {
      for (final capacity in ddr4Capacities) {
        final basePrice = _getRamBasePrice('DDR4', capacity);
        final basePartId = 'ram_ddr4_${model['brand']}_${capacity}gb_${model['speed']}mhz'
            .toLowerCase()
            .replaceAll(' ', '_')
            .replaceAll('.', '');

        baseParts.add({
          'basePartId': basePartId,
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

    for (final model in ddr5Models) {
      for (final capacity in ddr5Capacities) {
        final basePrice = _getRamBasePrice('DDR5', capacity);
        final basePartId = 'ram_ddr5_${model['brand']}_${capacity}gb_${model['speed']}mhz'
            .toLowerCase()
            .replaceAll(' ', '_')
            .replaceAll('.', '');

        baseParts.add({
          'basePartId': basePartId,
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
  List<Map<String, dynamic>> _generateBasePartsSsd() {
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

    for (final model in nvmeModels) {
      for (final capacity in nvmeCapacities) {
        final basePrice = _getSsdBasePrice('NVMe', capacity);
        final basePartId = 'ssd_nvme_${model['brand']}_${model['model']}_${capacity}gb'
            .toLowerCase()
            .replaceAll(' ', '_');

        baseParts.add({
          'basePartId': basePartId,
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

    for (final model in sataModels) {
      for (final capacity in sataCapacities) {
        final basePrice = _getSsdBasePrice('SATA', capacity);
        final basePartId = 'ssd_sata_${model['brand']}_${model['model']}_${capacity}gb'
            .toLowerCase()
            .replaceAll(' ', '_');

        baseParts.add({
          'basePartId': basePartId,
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

  // ==================== Parts - RAM ====================
  List<Map<String, dynamic>> _generatePartsRam(List<Map<String, dynamic>> basePartsRam) {
    final List<Map<String, dynamic>> parts = [];
    int partCounter = 1;

    // 각 BasePart에 대해 2-3개의 샘플 Part 생성
    for (final basePart in basePartsRam.take(30)) {
      final sampleCount = 2 + (partCounter % 2); // 2~3개

      for (int i = 0; i < sampleCount; i++) {
        final partId = 'part_ram_${partCounter.toString().padLeft(4, '0')}';

        parts.add({
          'partId': partId,
          'basePartId': basePart['basePartId'],
          'category': 'ram',
          'brand': basePart['brand'],
          'modelName': basePart['modelName'],
          'capacity': basePart['capacity'],
          'memoryType': basePart['memoryType'],
          'speed': basePart['speed'],
          'moduleCount': (basePart['capacity'] as int) >= 16 ? 2 : 1, // 16GB 이상은 듀얼채널
        });
        partCounter++;
      }
    }

    return parts;
  }

  // ==================== Parts - SSD ====================
  List<Map<String, dynamic>> _generatePartsSsd(List<Map<String, dynamic>> basePartsSsd) {
    final List<Map<String, dynamic>> parts = [];
    int partCounter = 1;

    // 각 BasePart에 대해 2-3개의 샘플 Part 생성
    for (final basePart in basePartsSsd.take(30)) {
      final sampleCount = 2 + (partCounter % 2); // 2~3개

      for (int i = 0; i < sampleCount; i++) {
        final partId = 'part_ssd_${partCounter.toString().padLeft(4, '0')}';

        parts.add({
          'partId': partId,
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
        case 8:
          return 2; // 2만원
        case 16:
          return 4; // 4만원
        case 32:
          return 8; // 8만원
        default:
          return 5;
      }
    } else {
      // DDR5
      switch (capacity) {
        case 16:
          return 8; // 8만원
        case 32:
          return 16; // 16만원
        default:
          return 10;
      }
    }
  }

  int _getSsdBasePrice(String interface, int capacity) {
    // 중고 시장 평균 가격 (만원 단위)
    final isNvme = interface == 'NVMe';

    switch (capacity) {
      case 500:
        return isNvme ? 4 : 3; // NVMe: 4만원, SATA: 3만원
      case 1000:
        return isNvme ? 7 : 5; // NVMe: 7만원, SATA: 5만원
      case 2000:
        return isNvme ? 14 : 10; // NVMe: 14만원, SATA: 10만원
      default:
        return 5;
    }
  }

  int _randomListingCount() {
    return 5 + _random.nextInt(15);
  }

  String _formatCapacity(int capacityGb) {
    if (capacityGb >= 1000) {
      return '${capacityGb ~/ 1000}TB';
    }
    return '${capacityGb}GB';
  }
}
