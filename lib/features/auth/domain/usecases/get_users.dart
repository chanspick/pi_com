
// lib/features/auth/domain/usecases/get_users.dart

import 'package:pi_com/core/models/user_model.dart';
import 'package:pi_com/features/auth/domain/repositories/user_repository.dart';

class GetUsers {
  final UserRepository repository;

  GetUsers(this.repository);

  Stream<List<UserModel>> call() {
    return repository.getUsers();
  }
}
