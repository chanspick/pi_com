// lib/features/parts_price/domain/usecases/get_price_history_usecase.dart
import '../entities/price_point_entity.dart';
import '../repositories/part_repository.dart';

class GetPriceHistoryUseCase {
  final PartRepository repository;

  GetPriceHistoryUseCase({required this.repository});

  Future<List<PricePointEntity>> call(String basePartId) {
    if (basePartId.isEmpty) {
      throw ArgumentError('BasePart ID cannot be empty');
    }
    return repository.getPriceHistory(basePartId);
  }
}
