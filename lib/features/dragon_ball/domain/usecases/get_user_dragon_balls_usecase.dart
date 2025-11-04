// lib/features/dragon_ball/domain/usecases/get_user_dragon_balls_usecase.dart

import 'package:pi_com/features/dragon_ball/domain/entities/dragon_ball_entity.dart';
import 'package:pi_com/features/dragon_ball/domain/repositories/dragon_ball_repository.dart';

/// 사용자의 드래곤볼 목록 조회 UseCase
class GetUserDragonBallsUseCase {
  final DragonBallRepository _repository;

  GetUserDragonBallsUseCase(this._repository);

  Stream<List<DragonBallEntity>> call(String userId) {
    return _repository.getUserDragonBalls(userId);
  }
}
