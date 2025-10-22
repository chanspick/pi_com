// lib/features/sell_request/presentation/providers/sell_request_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/models/sell_request_model.dart';
import '../../data/datasources/sell_request_datasource.dart';
import '../../data/repositories/sell_request_repository_impl.dart';
import '../../domain/repositories/sell_request_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

// ==================== DataSource ====================
final sellRequestDataSourceProvider = Provider<SellRequestDataSource>((ref) {
  return SellRequestDataSource(firestore: FirebaseFirestore.instance);
});

// ==================== Repository ====================
final sellRequestRepositoryProvider = Provider<SellRequestRepository>((ref) {
  final dataSource = ref.watch(sellRequestDataSourceProvider);
  return SellRequestRepositoryImpl(dataSource);
});

// ==================== 사용자 SellRequest 목록 ====================
final userSellRequestsStreamProvider =
StreamProvider<List<SellRequest>>((ref) {
  final userId = ref.watch(currentUserProvider)?.uid;
  if (userId == null) return Stream.value([]);

  final repository = ref.watch(sellRequestRepositoryProvider);
  return repository.getUserSellRequestsStream(userId);
});

// ==================== Admin: 전체 SellRequest 목록 ====================
final allSellRequestsStreamProvider =
StreamProvider<List<SellRequest>>((ref) {
  final repository = ref.watch(sellRequestRepositoryProvider);
  return repository.getAllSellRequestsStream();
});

// ==================== Admin: 상태별 SellRequest 목록 ====================
final sellRequestsByStatusStreamProvider = StreamProvider.family<
    List<SellRequest>, SellRequestStatus>((ref, status) {
  final repository = ref.watch(sellRequestRepositoryProvider);
  return repository.getSellRequestsByStatusStream(status);
});

// ==================== Admin: 대기 중인 SellRequest (편의용) ====================
final pendingSellRequestsStreamProvider =
StreamProvider<List<SellRequest>>((ref) {
  final repository = ref.watch(sellRequestRepositoryProvider);
  return repository.getSellRequestsByStatusStream(SellRequestStatus.pending);
});
