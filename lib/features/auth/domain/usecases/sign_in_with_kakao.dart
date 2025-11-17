// lib/features/auth/domain/usecases/sign_in_with_kakao.dart

import '../../../../core/models/user_model.dart';
import '../repositories/auth_repository.dart';

/// 카카오 로그인 Use Case
/// 비즈니스 로직을 캡슐화
class SignInWithKakao {
  final AuthRepository _repository;

  SignInWithKakao(this._repository);

  /// Use Case 실행
  Future<UserModel> call() async {
    try {
      return await _repository.signInWithKakao();
    } catch (e) {
      // 필요시 비즈니스 로직 추가
      rethrow;
    }
  }
}
