// lib/features/parts_price/domain/usecases/search_base_parts_usecase.dart
import '../entities/base_part_entity.dart';
import '../repositories/part_repository.dart';

class SearchBasePartsUseCase {
  final PartRepository repository;

  SearchBasePartsUseCase({required this.repository});

  Future<List<BasePartEntity>> call(String query) {
    if (query.trim().isEmpty) {
      return Future.value([]);
    }
    return repository.searchBaseParts(query);
  }
}
