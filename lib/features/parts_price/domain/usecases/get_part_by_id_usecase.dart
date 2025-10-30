// lib/features/parts_price/domain/usecases/get_part_by_id_usecase.dart
import '../entities/part_entity.dart';
import '../repositories/part_repository.dart';

class GetPartByIdUseCase {
  final PartRepository repository;

  GetPartByIdUseCase({required this.repository});

  Future<PartEntity?> call(String partId) {
    if (partId.isEmpty) {
      throw ArgumentError('Part ID cannot be empty');
    }
    return repository.getPartById(partId);
  }
}
