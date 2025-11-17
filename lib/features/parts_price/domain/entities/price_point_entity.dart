// lib/features/parts_price/domain/entities/price_point_entity.dart
class PricePointEntity {
  final DateTime date;
  final double lowestPrice;
  final double averagePrice;
  final int count;

  const PricePointEntity({
    required this.date,
    required this.lowestPrice,
    required this.averagePrice,
    required this.count,
  });
}
