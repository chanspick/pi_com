// lib/core/models/part_model.dart


import 'package:cloud_firestore/cloud_firestore.dart';

// ==================== 공용 유틸 ====================

num? _asNum(dynamic v) {
  if (v == null) return null;
  if (v is num) return v;
  if (v is String) return num.tryParse(v);
  return null;
}

int? _asInt(dynamic v) => _asNum(v)?.toInt();
double? _asDouble(dynamic v) => _asNum(v)?.toDouble();
String? _asString(dynamic v) => v?.toString();

String _ifaceToString({dynamic type, dynamic version, dynamic lanes}) {
  final t = _asString(type)?.trim() ?? '';
  final v = _asString(version)?.trim() ?? '';
  final l = (_asInt(lanes) != null) ? 'x${_asInt(lanes)}' : '';
  return [t, v, l].where((s) => s.isNotEmpty).join(' ');
}

// ==================== 카테고리 ====================
enum PartCategory { cpu, gpu, ssd, mainboard, ram, psu, cooler, pccase }

PartCategory _parseCategory(dynamic raw) {
  final s = (_asString(raw) ?? '').toLowerCase();
  if (s == 'motherboard' || s == 'mb') return PartCategory.mainboard;
  try {
    return PartCategory.values.firstWhere((e) => e.name.toLowerCase() == s);
  } catch (_) {
    return PartCategory.cpu;
  }
}

// ==================== 추상 Part ====================
abstract class Part {
  final String partId;
  final String basePartId;        // 🆕 추가
  final PartCategory category;
  final String brand;
  final String modelName;

  const Part({
    required this.partId,
    required this.basePartId,    // 🆕
    required this.category,
    required this.brand,
    required this.modelName,
  });

  Map<String, dynamic> toMap();

  factory Part.fromFirestore(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;
    map['partId'] = doc.id;
    return Part.fromMap(map);
  }

  static Part fromMap(Map<String, dynamic> map) {
    final cat = _parseCategory(map['category']);
    switch (cat) {
      case PartCategory.cpu:
        return CpuPart.fromMap(map);
      case PartCategory.gpu:
        return GpuPart.fromMap(map);
      case PartCategory.mainboard:
        return MainboardPart.fromMap(map);
      default:
        return GenericPart.fromMap(map);
    }
  }
}

// ==================== CpuPart ====================
class CpuPart extends Part {
  final String? socket;
  final int? cores;
  final int? threads;
  final double? baseClock;
  final double? boostClock;
  final int? tdp;

  const CpuPart({
    required super.partId,
    required super.basePartId,    // 🆕
    required super.category,
    required super.brand,
    required super.modelName,
    this.socket,
    this.cores,
    this.threads,
    this.baseClock,
    this.boostClock,
    this.tdp,
  });

  factory CpuPart.fromMap(Map<String, dynamic> map) {
    return CpuPart(
      partId: _asString(map['partId']) ?? '',
      basePartId: _asString(map['basePartId']) ?? '',    // 🆕
      category: _parseCategory(map['category']),
      brand: _asString(map['brand']) ?? '',
      modelName: _asString(map['modelName']) ?? '',
      socket: _asString(map['socket']),
      cores: _asInt(map['cores']),
      threads: _asInt(map['threads']),
      baseClock: _asDouble(map['baseClock']),
      boostClock: _asDouble(map['boostClock']),
      tdp: _asInt(map['tdp']),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'partId': partId,
      'basePartId': basePartId,    // 🆕
      'category': category.name,
      'brand': brand,
      'modelName': modelName,
      'socket': socket,
      'cores': cores,
      'threads': threads,
      'baseClock': baseClock,
      'boostClock': boostClock,
      'tdp': tdp,
    };
  }
}

// ==================== GpuPart ====================
class GpuPart extends Part {
  final String? chipset;
  final int? vramSize;
  final String? vramType;
  final int? tdp;
  final String? interface;

  const GpuPart({
    required super.partId,
    required super.basePartId,    // 🆕
    required super.category,
    required super.brand,
    required super.modelName,
    this.chipset,
    this.vramSize,
    this.vramType,
    this.tdp,
    this.interface,
  });

  factory GpuPart.fromMap(Map<String, dynamic> map) {
    return GpuPart(
      partId: _asString(map['partId']) ?? '',
      basePartId: _asString(map['basePartId']) ?? '',    // 🆕
      category: _parseCategory(map['category']),
      brand: _asString(map['brand']) ?? '',
      modelName: _asString(map['modelName']) ?? '',
      chipset: _asString(map['chipset']),
      vramSize: _asInt(map['vramSize']),
      vramType: _asString(map['vramType']),
      tdp: _asInt(map['tdp']),
      interface: _ifaceToString(
        type: map['interfaceType'],
        version: map['interfaceVersion'],
        lanes: map['interfaceLanes'],
      ),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'partId': partId,
      'basePartId': basePartId,    // 🆕
      'category': category.name,
      'brand': brand,
      'modelName': modelName,
      'chipset': chipset,
      'vramSize': vramSize,
      'vramType': vramType,
      'tdp': tdp,
      'interface': interface,
    };
  }
}

// ==================== MainboardPart ====================
class MainboardPart extends Part {
  final String? chipset;
  final String? socket;
  final String? formFactor;
  final int? ramSlots;
  final String? ramType;
  final int? maxRamCapacity;

  const MainboardPart({
    required super.partId,
    required super.basePartId,    // 🆕
    required super.category,
    required super.brand,
    required super.modelName,
    this.chipset,
    this.socket,
    this.formFactor,
    this.ramSlots,
    this.ramType,
    this.maxRamCapacity,
  });

  factory MainboardPart.fromMap(Map<String, dynamic> map) {
    return MainboardPart(
      partId: _asString(map['partId']) ?? '',
      basePartId: _asString(map['basePartId']) ?? '',    // 🆕
      category: _parseCategory(map['category']),
      brand: _asString(map['brand']) ?? '',
      modelName: _asString(map['modelName']) ?? '',
      chipset: _asString(map['chipset']),
      socket: _asString(map['socket']),
      formFactor: _asString(map['formFactor']),
      ramSlots: _asInt(map['ramSlots']),
      ramType: _asString(map['ramType']),
      maxRamCapacity: _asInt(map['maxRamCapacity']),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'partId': partId,
      'basePartId': basePartId,    // 🆕
      'category': category.name,
      'brand': brand,
      'modelName': modelName,
      'chipset': chipset,
      'socket': socket,
      'formFactor': formFactor,
      'ramSlots': ramSlots,
      'ramType': ramType,
      'maxRamCapacity': maxRamCapacity,
    };
  }
}

// ==================== GenericPart ====================
class GenericPart extends Part {
  final Map<String, dynamic> extraData;

  const GenericPart({
    required super.partId,
    required super.basePartId,    // 🆕
    required super.category,
    required super.brand,
    required super.modelName,
    required this.extraData,
  });

  factory GenericPart.fromMap(Map<String, dynamic> map) {
    final filtered = Map<String, dynamic>.from(map)
      ..removeWhere((k, v) =>
          ['partId', 'basePartId', 'category', 'brand', 'modelName'].contains(k));    // 🆕

    return GenericPart(
      partId: _asString(map['partId']) ?? '',
      basePartId: _asString(map['basePartId']) ?? '',    // 🆕
      category: _parseCategory(map['category']),
      brand: _asString(map['brand']) ?? '',
      modelName: _asString(map['modelName']) ?? '',
      extraData: filtered,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'partId': partId,
      'basePartId': basePartId,    // 🆕
      'category': category.name,
      'brand': brand,
      'modelName': modelName,
      ...extraData,
    };
  }
}
