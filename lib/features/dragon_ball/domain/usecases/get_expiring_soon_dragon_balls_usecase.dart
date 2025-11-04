// lib/features/dragon_ball/domain/usecases/get_expiring_soon_dragon_balls_usecase.dart

import 'package:pi_com/features/dragon_ball/domain/entities/dragon_ball_entity.dart';
import 'package:pi_com/features/dragon_ball/domain/repositories/dragon_ball_repository.dart';

/// 만료 임박 드래곤볼 조회 UseCase (3일 이하)
class GetExpiringSoonDragonBallsUseCase {
  final DragonBallRepository _repository;

  GetExpiringSoonDragonBallsUseCase(this._repository);

  Future<List<DragonBallEntity>> call(String userId) {
    return _repository.getExpiringSoonDragonBalls(userId);
  }
}
