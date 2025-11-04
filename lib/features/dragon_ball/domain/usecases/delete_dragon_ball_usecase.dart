// lib/features/dragon_ball/domain/usecases/delete_dragon_ball_usecase.dart

import 'package:pi_com/features/dragon_ball/domain/repositories/dragon_ball_repository.dart';

/// 드래곤볼 삭제 UseCase
class DeleteDragonBallUseCase {
  final DragonBallRepository _repository;

  DeleteDragonBallUseCase(this._repository);

  Future<void> call(String userId, String dragonBallId) {
    return _repository.deleteDragonBall(userId, dragonBallId);
  }
}
