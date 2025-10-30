// lib/features/parts_price/domain/usecases/get_base_parts_by_category_usecase.dart
import '../entities/base_part_entity.dart';
import '../repositories/part_repository.dart';

class GetBasePartsByCategoryUseCase {
  final PartRepository repository;

  GetBasePartsByCategoryUseCase({required this.repository});

  Stream<List<BasePartEntity>> call(String category) {
    return repository.getBasePartsByCategory(category);
  }
}
