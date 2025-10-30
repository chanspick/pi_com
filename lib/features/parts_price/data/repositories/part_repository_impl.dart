// lib/features/parts_price/data/repositories/part_repository_impl.dart
import '../../domain/entities/part_entity.dart';
import '../../domain/entities/base_part_entity.dart';
import '../../domain/entities/price_point_entity.dart';
import '../../domain/repositories/part_repository.dart';
import '../datasources/part_remote_datasource.dart';
import '../models/price_point_model.dart';

class PartRepositoryImpl implements PartRepository {
  final PartRemoteDataSource remoteDataSource;

  PartRepositoryImpl({required this.remoteDataSource});

  @override
  Future<PartEntity?> getPartById(String partId) async {
    final partModel = await remoteDataSource.getPartById(partId);
    return partModel?.toEntity();
  }

  @override
  Stream<List<BasePartEntity>> getBasePartsByCategory(String category) {
    return remoteDataSource
        .getBasePartsByCategory(category)
        .map((models) => models.map((m) => m.toEntity()).toList());
  }

  @override
  Future<List<PricePointEntity>> getPriceHistory(String partId) async {
    final priceData = await remoteDataSource.getPriceHistory(partId);
    return priceData
        .map((data) => PricePointModel.fromMap(data).toEntity())
        .toList();
  }

  @override
  Future<List<BasePartEntity>> searchBaseParts(String query) async {
    final models = await remoteDataSource.searchBaseParts(query);
    return models.map((m) => m.toEntity()).toList();
  }
}
