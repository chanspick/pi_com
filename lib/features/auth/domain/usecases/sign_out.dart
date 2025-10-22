// lib/features/auth/domain/usecases/sign_out.dart

import '../repositories/auth_repository.dart';

/// 로그아웃 Use Case
/// 비즈니스 로직을 캡슐화
class SignOut {
  final AuthRepository _repository;

  SignOut(this._repository);

  /// Use Case 실행
  Future<void> call() async {
    try {
      await _repository.signOut();
    } catch (e) {
      // 필요시 비즈니스 로직 추가 (예: 로컬 캐시 정리)
      rethrow;
    }
  }
}
