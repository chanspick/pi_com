// lib/features/parts_price/domain/repositories/part_repository.dart
import '../entities/part_entity.dart';
import '../entities/base_part_entity.dart';
import '../entities/price_point_entity.dart';

abstract class PartRepository {
  Future<PartEntity?> getPartById(String partId);
  Stream<List<BasePartEntity>> getBasePartsByCategory(String category);
  Future<List<PricePointEntity>> getPriceHistory(String partId);
  Future<List<BasePartEntity>> searchBaseParts(String query);
}
