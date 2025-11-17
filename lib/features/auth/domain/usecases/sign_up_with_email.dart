// lib/features/auth/domain/usecases/sign_up_with_email.dart

import '../../../../core/models/user_model.dart';
import '../repositories/auth_repository.dart';

/// 이메일/비밀번호 회원가입 Use Case
class SignUpWithEmail {
  final AuthRepository _repository;

  SignUpWithEmail(this._repository);

  Future<UserModel> call(String email, String password, String displayName) {
    return _repository.signUpWithEmail(email, password, displayName);
  }
}
