// lib/features/parts_price/domain/entities/part_entity.dart
enum PartCategory { cpu, gpu, ssd, mainboard, ram, psu, cooler, pccase }

abstract class PartEntity {
  final String partId;
  final String basePartId;
  final PartCategory category;
  final String brand;
  final String modelName;
  final int? referencePrice;
  final String? imageUrl;
  final int? powerConsumptionW;

  const PartEntity({
    required this.partId,
    required this.basePartId,
    required this.category,
    required this.brand,
    required this.modelName,
    this.referencePrice,
    this.imageUrl,
    this.powerConsumptionW,
  });

  String get displayCategory {
    switch (category) {
      case PartCategory.cpu:
        return 'CPU';
      case PartCategory.gpu:
        return 'GPU';
      case PartCategory.mainboard:
        return '메인보드';
      case PartCategory.ram:
        return 'RAM';
      case PartCategory.ssd:
        return 'SSD';
      case PartCategory.psu:
        return '파워';
      case PartCategory.cooler:
        return '쿨러';
      case PartCategory.pccase:
        return '케이스';
    }
  }
}

class CpuPartEntity extends PartEntity {
  final String socket;
  final bool hasIntegratedGraphics;
  final int cores;
  final int threads;
  final double baseClockGhz;
  final double boostClockGhz;
  final double l3CacheMb;
  final String? igpuName;
  final int? igpuFreqMhz;
  final MemorySpecEntity memory;
  final bool coolerIncluded;

  const CpuPartEntity({
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
  }) : super(category: PartCategory.cpu);
}

class GpuPartEntity extends PartEntity {
  final String chipset;
  final int memorySizeGb;
  final String memoryType;
  final String? interfaceType;
  final int? boostClockMhz;
  final int? cudaCores;

  const GpuPartEntity({
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
  }) : super(category: PartCategory.gpu);
}

class MainboardPartEntity extends PartEntity {
  final String socket;
  final String chipset;
  final String formFactor;
  final String memoryType;
  final int memorySlots;
  final int maxMemoryGb;
  final int sataPorts;
  final int m2Slots;

  const MainboardPartEntity({
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
  }) : super(category: PartCategory.mainboard);
}

class GenericPartEntity extends PartEntity {
  const GenericPartEntity({
    required super.partId,
    required super.basePartId,
    required super.category,
    required super.brand,
    required super.modelName,
    super.referencePrice,
    super.imageUrl,
    super.powerConsumptionW,
  });
}

class MemorySpecEntity {
  final String type;
  final int maxSpeedMhz;
  final int channels;

  const MemorySpecEntity({
    required this.type,
    required this.maxSpeedMhz,
    required this.channels,
  });
}
