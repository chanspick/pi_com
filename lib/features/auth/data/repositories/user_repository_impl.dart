
// lib/features/auth/data/repositories/user_repository_impl.dart

import 'package:pi_com/features/auth/data/datasources/user_remote_datasource.dart';
import 'package:pi_com/core/models/user_model.dart';
import 'package:pi_com/features/auth/domain/repositories/user_repository.dart';

class UserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource remoteDataSource;

  UserRepositoryImpl({required this.remoteDataSource});

  @override
  Stream<List<UserModel>> getUsers() {
    return remoteDataSource.getUsers();
  }
}
