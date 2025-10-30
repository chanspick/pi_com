// lib/features/parts_price/domain/entities/base_part_entity.dart
class BasePartEntity {
  final String basePartId;
  final String modelName;
  final String category;
  final int lowestPrice;
  final double averagePrice;
  final int listingCount;

  const BasePartEntity({
    required this.basePartId,
    required this.modelName,
    required this.category,
    required this.lowestPrice,
    required this.averagePrice,
    required this.listingCount,
  });

  bool get hasListings => listingCount > 0;
  bool get hasPriceInfo => lowestPrice > 0;

  String get priceRangeText {
    if (!hasPriceInfo) return '가격 정보 없음';
    final formatted = lowestPrice
        .toString()
        .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
    return '$formatted원~';
  }
}
