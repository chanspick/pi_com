
// lib/features/auth/domain/repositories/user_repository.dart

import 'package:pi_com/core/models/user_model.dart';

abstract class UserRepository {
  Stream<List<UserModel>> getUsers();
}
