// lib/features/dragon_ball/domain/usecases/create_dragon_ball_usecase.dart

import 'package:pi_com/features/dragon_ball/domain/repositories/dragon_ball_repository.dart';

/// 드래곤볼 생성 UseCase (구매 완료 시)
class CreateDragonBallUseCase {
  final DragonBallRepository _repository;

  CreateDragonBallUseCase(this._repository);

  Future<String> call({
    required String userId,
    required String listingId,
    required String orderId,
    required String partName,
    String? imageUrl,
    required int purchasePrice,
    String? basePartId,
    String? category,
    required bool agreedToTerms,
  }) {
    return _repository.createDragonBall(
      userId: userId,
      listingId: listingId,
      orderId: orderId,
      partName: partName,
      imageUrl: imageUrl,
      purchasePrice: purchasePrice,
      basePartId: basePartId,
      category: category,
      agreedToTerms: agreedToTerms,
    );
  }
}
