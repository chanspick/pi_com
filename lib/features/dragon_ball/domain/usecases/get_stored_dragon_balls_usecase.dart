// lib/features/dragon_ball/domain/usecases/get_stored_dragon_balls_usecase.dart

import 'package:pi_com/features/dragon_ball/domain/entities/dragon_ball_entity.dart';
import 'package:pi_com/features/dragon_ball/domain/repositories/dragon_ball_repository.dart';

/// 보관 중인 드래곤볼만 조회 UseCase
class GetStoredDragonBallsUseCase {
  final DragonBallRepository _repository;

  GetStoredDragonBallsUseCase(this._repository);

  Future<List<DragonBallEntity>> call(String userId) {
    return _repository.getStoredDragonBalls(userId);
  }
}
