// lib/features/parts_price/domain/entities/price_point_entity.dart
class PricePointEntity {
  final DateTime date;
  final double price;
  final int count;

  const PricePointEntity({
    required this.date,
    required this.price,
    required this.count,
  });
}
