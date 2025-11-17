// lib/features/auth/domain/usecases/sign_in_with_email.dart

import '../../../../core/models/user_model.dart';
import '../repositories/auth_repository.dart';

/// 이메일/비밀번호 로그인 Use Case
class SignInWithEmail {
  final AuthRepository _repository;

  SignInWithEmail(this._repository);

  Future<UserModel> call(String email, String password) {
    return _repository.signInWithEmail(email, password);
  }
}
