// lib/features/parts_price/data/models/part_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/part_entity.dart';

// 공용 유틸
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

// 카테고리 enum
enum PartCategoryModel { cpu, gpu, ssd, mainboard, ram, psu, cooler, pccase }

PartCategoryModel _parseCategory(dynamic raw) {
  final s = (_asString(raw) ?? '').toLowerCase();
  if (s == 'motherboard' || s == 'mb') return PartCategoryModel.mainboard;
  return PartCategoryModel.values.firstWhere(
        (e) => e.name == s,
    orElse: () => PartCategoryModel.pccase,
  );
}

// MemorySpec Model
class MemorySpecModel {
  final String type;
  final int maxSpeedMhz;
  final int channels;

  const MemorySpecModel({
    required this.type,
    required this.maxSpeedMhz,
    required this.channels,
  });

  factory MemorySpecModel.fromMap(Map<String, dynamic>? map) {
    final m = map ?? const {};
    return MemorySpecModel(
      type: _asString(m['type']) ?? '',
      maxSpeedMhz: _asInt(m['maxSpeedMhz'] ?? m['max_speed_mhz']) ?? 0,
      channels: _asInt(m['channels']) ?? 0,
    );
  }

  MemorySpecEntity toEntity() {
    return MemorySpecEntity(
      type: type,
      maxSpeedMhz: maxSpeedMhz,
      channels: channels,
    );
  }
}

// Part 베이스 클래스
abstract class PartModel {
  final String partId;
  final String basePartId;
  final PartCategoryModel category;
  final String brand;
  final String modelName;
  final int? referencePrice;
  final String? imageUrl;
  final int? powerConsumptionW;

  const PartModel({
    required this.partId,
    required this.basePartId,
    required this.category,
    required this.brand,
    required this.modelName,
    this.referencePrice,
    this.imageUrl,
    this.powerConsumptionW,
  });

  factory PartModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>? ?? {});
    data.putIfAbsent('partId', () => data['part_id'] ?? doc.id);
    return PartModel.fromMap(data);
  }

  factory PartModel.fromMap(Map<String, dynamic> map) {
    final category = _parseCategory(map['category']);
    switch (category) {
      case PartCategoryModel.cpu:
        return CpuPartModel.fromMap(map);
      case PartCategoryModel.gpu:
        return GpuPartModel.fromMap(map);
      case PartCategoryModel.mainboard:
        return MainboardPartModel.fromMap(map);
      default:
        return GenericPartModel.fromMap(map);
    }
  }

  PartEntity toEntity();
}

// CPU Part Model
class CpuPartModel extends PartModel {
  final String socket;
  final bool hasIntegratedGraphics;
  final int cores;
  final int threads;
  final double baseClockGhz;
  final double boostClockGhz;
  final double l3CacheMb;
  final String? igpuName;
  final int? igpuFreqMhz;
  final MemorySpecModel memory;
  final bool coolerIncluded;

  const CpuPartModel({
    required super.partId,
    required super.basePartId,
    required super.brand,
    required super.modelName,
    super.referencePrice,
    super.imageUrl,
    super.powerConsumptionW,
    required this.socket,
    required this.hasIntegratedGraphics,
    required this.cores,
    required this.threads,
    required this.baseClockGhz,
    required this.boostClockGhz,
    required this.l3CacheMb,
    this.igpuName,
    this.igpuFreqMhz,
    required this.memory,
    required this.coolerIncluded,
  }) : super(category: PartCategoryModel.cpu);

  factory CpuPartModel.fromMap(Map<String, dynamic> map) {
    final raw = map['raw'] as Map<String, dynamic>?;
    return CpuPartModel(
      partId: _asString(map['partId']) ?? _asString(map['part_id']) ?? 'N/A',
      basePartId: _asString(map['basePartId']) ?? '',
      brand: _asString(map['brand']) ?? 'N/A',
      modelName: _asString(map['modelName']) ??
          _asString(map['name']) ??
          _asString(map['model']) ??
          _asString(raw?['name']) ??
          _asString(raw?['model']) ??
          '',
      referencePrice: _asInt(map['referencePrice'] ?? map['reference_price']),
      imageUrl: _asString(map['imageUrl'] ?? map['image_url']),
      powerConsumptionW:
      _asInt(map['powerConsumptionW'] ?? map['power_consumption_w']),
      socket: _asString(map['socket']) ?? '',
      hasIntegratedGraphics:
      (map['hasIntegratedGraphics'] ?? map['has_integrated_graphics']) == true,
      cores: _asInt(map['cores']) ?? 0,
      threads: _asInt(map['threads']) ?? 0,
      baseClockGhz: _asDouble(map['baseClockGhz'] ?? map['base_clock_ghz']) ?? 0.0,
      boostClockGhz: _asDouble(map['boostClockGhz'] ?? map['boost_clock_ghz']) ?? 0.0,
      l3CacheMb: _asDouble(map['l3CacheMb'] ?? map['l3_cache_mb']) ?? 0.0,
      igpuName: _asString(map['igpuName'] ?? map['igpu_name']),
      igpuFreqMhz: _asInt(map['igpuFreqMhz'] ?? map['igpu_freq_mhz']),
      memory: MemorySpecModel.fromMap(map['memory'] as Map<String, dynamic>?),
      coolerIncluded: (map['coolerIncluded'] ?? map['cooler_included']) == true,
    );
  }

  @override
  CpuPartEntity toEntity() {
    return CpuPartEntity(
      partId: partId,
      basePartId: basePartId,
      brand: brand,
      modelName: modelName,
      referencePrice: referencePrice,
      imageUrl: imageUrl,
      powerConsumptionW: powerConsumptionW,
      socket: socket,
      hasIntegratedGraphics: hasIntegratedGraphics,
      cores: cores,
      threads: threads,
      baseClockGhz: baseClockGhz,
      boostClockGhz: boostClockGhz,
      l3CacheMb: l3CacheMb,
      igpuName: igpuName,
      igpuFreqMhz: igpuFreqMhz,
      memory: memory.toEntity(),
      coolerIncluded: coolerIncluded,
    );
  }
}

// GPU Part Model
class GpuPartModel extends PartModel {
  final String chipset;
  final int memorySizeGb;
  final String memoryType;
  final String? interfaceType;
  final int? boostClockMhz;
  final int? cudaCores;

  const GpuPartModel({
    required super.partId,
    required super.basePartId,
    required super.brand,
    required super.modelName,
    super.referencePrice,
    super.imageUrl,
    super.powerConsumptionW,
    required this.chipset,
    required this.memorySizeGb,
    required this.memoryType,
    this.interfaceType,
    this.boostClockMhz,
    this.cudaCores,
  }) : super(category: PartCategoryModel.gpu);

  factory GpuPartModel.fromMap(Map<String, dynamic> map) {
    final raw = map['raw'] as Map<String, dynamic>?;
    final memory = map['memory'] as Map<String, dynamic>?;
    final chipsetMap = map['chipset'] as Map<String, dynamic>?;
    final iface = map['interface'] as Map<String, dynamic>?;
    final clocks = map['clockSpeeds'] ?? map['clock_speeds'] as Map<String, dynamic>?;
    final power = map['power'] as Map<String, dynamic>?;

    return GpuPartModel(
      partId: _asString(map['partId']) ?? _asString(map['part_id']) ?? 'N/A',
      basePartId: _asString(map['basePartId']) ?? '',
      brand: _asString(map['brand']) ?? 'N/A',
      modelName: _asString(map['modelName']) ??
          _asString(map['name']) ??
          _asString(map['model']) ??
          _asString(raw?['name']) ??
          _asString(raw?['model']) ??
          '',
      referencePrice: _asInt(map['referencePrice'] ?? map['reference_price']),
      imageUrl: _asString(map['imageUrl'] ?? map['image_url']),
      powerConsumptionW:
      _asInt(power?['recommendedPsuWatt'] ?? power?['recommended_psu_watt']),
      chipset: _asString(chipsetMap?['model']) ?? '',
      memorySizeGb: _asInt(memory?['sizeGb'] ?? memory?['size_gb']) ?? 0,
      memoryType: _asString(memory?['type']) ?? '',
      interfaceType: _ifaceToString(
        type: iface?['type'],
        version: iface?['version'],
        lanes: iface?['lanes'],
      ),
      boostClockMhz: _asInt(clocks?['boostMhz'] ?? clocks?['boost_mhz']),
      cudaCores: _asInt(chipsetMap?['cudaCores'] ?? chipsetMap?['cuda_cores']),
    );
  }

  @override
  GpuPartEntity toEntity() {
    return GpuPartEntity(
      partId: partId,
      basePartId: basePartId,
      brand: brand,
      modelName: modelName,
      referencePrice: referencePrice,
      imageUrl: imageUrl,
      powerConsumptionW: powerConsumptionW,
      chipset: chipset,
      memorySizeGb: memorySizeGb,
      memoryType: memoryType,
      interfaceType: interfaceType,
      boostClockMhz: boostClockMhz,
      cudaCores: cudaCores,
    );
  }
}

// Mainboard Part Model
class MainboardPartModel extends PartModel {
  final String socket;
  final String chipset;
  final String formFactor;
  final String memoryType;
  final int memorySlots;
  final int maxMemoryGb;
  final int sataPorts;
  final int m2Slots;

  const MainboardPartModel({
    required super.partId,
    required super.basePartId,
    required super.brand,
    required super.modelName,
    super.referencePrice,
    super.imageUrl,
    required this.socket,
    required this.chipset,
    required this.formFactor,
    required this.memoryType,
    required this.memorySlots,
    required this.maxMemoryGb,
    required this.sataPorts,
    required this.m2Slots,
  }) : super(category: PartCategoryModel.mainboard);

  factory MainboardPartModel.fromMap(Map<String, dynamic> map) {
    final raw = map['raw'] as Map<String, dynamic>?;
    final memory = map['memory'] as Map<String, dynamic>?;
    final storage = map['storage'] as Map<String, dynamic>?;

    return MainboardPartModel(
      partId: _asString(map['partId']) ?? _asString(map['part_id']) ?? 'N/A',
      basePartId: _asString(map['basePartId']) ?? '',
      brand: _asString(map['brand']) ?? 'N/A',
      modelName: _asString(map['modelName']) ??
          _asString(map['name']) ??
          _asString(map['model']) ??
          _asString(raw?['name']) ??
          _asString(raw?['model']) ??
          '',
      referencePrice: _asInt(map['referencePrice'] ?? map['reference_price']),
      imageUrl: _asString(map['imageUrl'] ?? map['image_url']),
      socket: _asString(map['socket']) ?? '',
      chipset: _asString(map['chipset']) ?? '',
      formFactor: _asString(map['formFactor'] ?? map['form_factor']) ?? '',
      memoryType: _asString(memory?['type']) ?? '',
      memorySlots: _asInt(memory?['slots']) ?? 0,
      maxMemoryGb:
      _asInt(memory?['maxCapacityGb'] ?? memory?['max_capacity_gb']) ?? 0,
      sataPorts: _asInt(storage?['sata3Ports'] ?? storage?['sata3_ports']) ?? 0,
      m2Slots: _asInt(storage?['m2Slots'] ?? storage?['m2_slots']) ?? 0,
    );
  }

  @override
  MainboardPartEntity toEntity() {
    return MainboardPartEntity(
      partId: partId,
      basePartId: basePartId,
      brand: brand,
      modelName: modelName,
      referencePrice: referencePrice,
      imageUrl: imageUrl,
      socket: socket,
      chipset: chipset,
      formFactor: formFactor,
      memoryType: memoryType,
      memorySlots: memorySlots,
      maxMemoryGb: maxMemoryGb,
      sataPorts: sataPorts,
      m2Slots: m2Slots,
    );
  }
}

// Generic Part Model
class GenericPartModel extends PartModel {
  const GenericPartModel({
    required super.partId,
    required super.basePartId,
    required super.category,
    required super.brand,
    required super.modelName,
    super.referencePrice,
    super.imageUrl,
    super.powerConsumptionW,
  });

  factory GenericPartModel.fromMap(Map<String, dynamic> map) {
    final raw = map['raw'] as Map<String, dynamic>?;
    return GenericPartModel(
      partId: _asString(map['partId']) ?? _asString(map['part_id']) ?? 'N/A',
      basePartId: _asString(map['basePartId']) ?? '',
      category: _parseCategory(map['category']),
      brand: _asString(map['brand']) ?? 'N/A',
      modelName: _asString(map['modelName']) ??
          _asString(map['name']) ??
          _asString(map['model']) ??
          _asString(raw?['name']) ??
          _asString(raw?['model']) ??
          '',
      referencePrice: _asInt(map['referencePrice'] ?? map['reference_price']),
      imageUrl: _asString(map['imageUrl'] ?? map['image_url']),
      powerConsumptionW:
      _asInt(map['powerConsumptionW'] ?? map['power_consumption_w']),
    );
  }

  @override
  GenericPartEntity toEntity() {
    return GenericPartEntity(
      partId: partId,
      basePartId: basePartId,
      category: _convertCategoryToEntity(category),
      brand: brand,
      modelName: modelName,
      referencePrice: referencePrice,
      imageUrl: imageUrl,
      powerConsumptionW: powerConsumptionW,
    );
  }
}

// Category 변환 헬퍼
PartCategory _convertCategoryToEntity(PartCategoryModel cat) {
  switch (cat) {
    case PartCategoryModel.cpu:
      return PartCategory.cpu;
    case PartCategoryModel.gpu:
      return PartCategory.gpu;
    case PartCategoryModel.mainboard:
      return PartCategory.mainboard;
    case PartCategoryModel.ram:
      return PartCategory.ram;
    case PartCategoryModel.ssd:
      return PartCategory.ssd;
    case PartCategoryModel.psu:
      return PartCategory.psu;
    case PartCategoryModel.cooler:
      return PartCategory.cooler;
    case PartCategoryModel.pccase:
      return PartCategory.pccase;
  }
}
