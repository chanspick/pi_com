/// 하드웨어 추천 엔티티
class RecommendationEntity {
  // 부품명
  final String? cpu;
  final String? mainboard;
  final String? memory;
  final String? gpu;
  final String? ssd;
  final String? psu;
  final String? cpuCooler;
  final String? pcCase;

  // Listing ID (실제 상품 연결)
  final String? cpuListingId;
  final String? mainboardListingId;
  final String? memoryListingId;
  final String? gpuListingId;
  final String? ssdListingId;
  final String? psuListingId;
  final String? cpuCoolerListingId;
  final String? pcCaseListingId;

  // 가격 정보
  final int? cpuPrice;
  final int? mainboardPrice;
  final int? memoryPrice;
  final int? gpuPrice;
  final int? ssdPrice;
  final int? psuPrice;
  final int? cpuCoolerPrice;
  final int? pcCasePrice;
  final int? totalPrice;

  const RecommendationEntity({
    this.cpu,
    this.mainboard,
    this.memory,
    this.gpu,
    this.ssd,
    this.psu,
    this.cpuCooler,
    this.pcCase,
    this.cpuListingId,
    this.mainboardListingId,
    this.memoryListingId,
    this.gpuListingId,
    this.ssdListingId,
    this.psuListingId,
    this.cpuCoolerListingId,
    this.pcCaseListingId,
    this.cpuPrice,
    this.mainboardPrice,
    this.memoryPrice,
    this.gpuPrice,
    this.ssdPrice,
    this.psuPrice,
    this.cpuCoolerPrice,
    this.pcCasePrice,
    this.totalPrice,
  });

  RecommendationEntity copyWith({
    String? cpu,
    String? mainboard,
    String? memory,
    String? gpu,
    String? ssd,
    String? psu,
    String? cpuCooler,
    String? pcCase,
    String? cpuListingId,
    String? mainboardListingId,
    String? memoryListingId,
    String? gpuListingId,
    String? ssdListingId,
    String? psuListingId,
    String? cpuCoolerListingId,
    String? pcCaseListingId,
    int? cpuPrice,
    int? mainboardPrice,
    int? memoryPrice,
    int? gpuPrice,
    int? ssdPrice,
    int? psuPrice,
    int? cpuCoolerPrice,
    int? pcCasePrice,
    int? totalPrice,
  }) {
    return RecommendationEntity(
      cpu: cpu ?? this.cpu,
      mainboard: mainboard ?? this.mainboard,
      memory: memory ?? this.memory,
      gpu: gpu ?? this.gpu,
      ssd: ssd ?? this.ssd,
      psu: psu ?? this.psu,
      cpuCooler: cpuCooler ?? this.cpuCooler,
      pcCase: pcCase ?? this.pcCase,
      cpuListingId: cpuListingId ?? this.cpuListingId,
      mainboardListingId: mainboardListingId ?? this.mainboardListingId,
      memoryListingId: memoryListingId ?? this.memoryListingId,
      gpuListingId: gpuListingId ?? this.gpuListingId,
      ssdListingId: ssdListingId ?? this.ssdListingId,
      psuListingId: psuListingId ?? this.psuListingId,
      cpuCoolerListingId: cpuCoolerListingId ?? this.cpuCoolerListingId,
      pcCaseListingId: pcCaseListingId ?? this.pcCaseListingId,
      cpuPrice: cpuPrice ?? this.cpuPrice,
      mainboardPrice: mainboardPrice ?? this.mainboardPrice,
      memoryPrice: memoryPrice ?? this.memoryPrice,
      gpuPrice: gpuPrice ?? this.gpuPrice,
      ssdPrice: ssdPrice ?? this.ssdPrice,
      psuPrice: psuPrice ?? this.psuPrice,
      cpuCoolerPrice: cpuCoolerPrice ?? this.cpuCoolerPrice,
      pcCasePrice: pcCasePrice ?? this.pcCasePrice,
      totalPrice: totalPrice ?? this.totalPrice,
    );
  }
}
