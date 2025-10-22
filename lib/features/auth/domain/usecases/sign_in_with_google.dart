// lib/features/auth/domain/usecases/sign_in_with_google.dart

import '../../../../core/models/user_model.dart';
import '../repositories/auth_repository.dart';

/// Google 로그인 Use Case
/// 비즈니스 로직을 캡슐화 (현재는 단순 Repository 호출)
class SignInWithGoogle {
  final AuthRepository _repository;

  SignInWithGoogle(this._repository);

  /// Use Case 실행
  Future<UserModel> call() async {
    try {
      return await _repository.signInWithGoogle();
    } catch (e) {
      // 필요시 비즈니스 로직 추가 (예: 로그, 분석 등)
      rethrow;
    }
  }
}
