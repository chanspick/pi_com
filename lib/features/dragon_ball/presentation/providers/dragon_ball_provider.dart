// lib/features/dragon_ball/presentation/providers/dragon_ball_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pi_com/features/dragon_ball/data/datasources/dragon_ball_remote_datasource.dart';
import 'package:pi_com/features/dragon_ball/data/datasources/batch_shipment_remote_datasource.dart';
import 'package:pi_com/features/dragon_ball/data/repositories/dragon_ball_repository_impl.dart';
import 'package:pi_com/features/dragon_ball/data/repositories/batch_shipment_repository_impl.dart';
import 'package:pi_com/features/dragon_ball/domain/repositories/dragon_ball_repository.dart';
import 'package:pi_com/features/dragon_ball/domain/repositories/batch_shipment_repository.dart';
import 'package:pi_com/features/dragon_ball/domain/usecases/get_user_dragon_balls_usecase.dart';
import 'package:pi_com/features/dragon_ball/domain/usecases/create_dragon_ball_usecase.dart';
import 'package:pi_com/features/dragon_ball/domain/usecases/get_stored_dragon_balls_usecase.dart';
import 'package:pi_com/features/dragon_ball/domain/usecases/get_expiring_soon_dragon_balls_usecase.dart';
import 'package:pi_com/features/dragon_ball/domain/usecases/delete_dragon_ball_usecase.dart';
import 'package:pi_com/features/dragon_ball/domain/usecases/create_batch_shipment_usecase.dart';
import 'package:pi_com/features/dragon_ball/domain/usecases/get_user_batch_shipments_usecase.dart';
import 'package:pi_com/features/dragon_ball/domain/usecases/cancel_batch_shipment_usecase.dart';
import 'package:pi_com/features/dragon_ball/domain/usecases/get_batch_shipment_usecase.dart';
import 'package:pi_com/features/dragon_ball/domain/entities/dragon_ball_entity.dart';
import 'package:pi_com/features/dragon_ball/domain/entities/batch_shipment_entity.dart';
import 'package:pi_com/core/models/batch_shipment_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ===========================
// Data Layer Providers
// ===========================

final dragonBallRemoteDataSourceProvider = Provider<DragonBallRemoteDataSource>((ref) {
  return DragonBallRemoteDataSourceImpl();
});

final batchShipmentRemoteDataSourceProvider = Provider<BatchShipmentRemoteDataSource>((ref) {
  return BatchShipmentRemoteDataSourceImpl();
});

final dragonBallRepositoryProvider = Provider<DragonBallRepository>((ref) {
  final remoteDataSource = ref.watch(dragonBallRemoteDataSourceProvider);
  return DragonBallRepositoryImpl(remoteDataSource: remoteDataSource);
});

final batchShipmentRepositoryProvider = Provider<BatchShipmentRepository>((ref) {
  final remoteDataSource = ref.watch(batchShipmentRemoteDataSourceProvider);
  return BatchShipmentRepositoryImpl(remoteDataSource: remoteDataSource);
});

// ===========================
// Use Case Providers - DragonBall
// ===========================

final getUserDragonBallsUseCaseProvider = Provider<GetUserDragonBallsUseCase>((ref) {
  final repository = ref.watch(dragonBallRepositoryProvider);
  return GetUserDragonBallsUseCase(repository);
});

final createDragonBallUseCaseProvider = Provider<CreateDragonBallUseCase>((ref) {
  final repository = ref.watch(dragonBallRepositoryProvider);
  return CreateDragonBallUseCase(repository);
});

final getStoredDragonBallsUseCaseProvider = Provider<GetStoredDragonBallsUseCase>((ref) {
  final repository = ref.watch(dragonBallRepositoryProvider);
  return GetStoredDragonBallsUseCase(repository);
});

final getExpiringSoonDragonBallsUseCaseProvider = Provider<GetExpiringSoonDragonBallsUseCase>((ref) {
  final repository = ref.watch(dragonBallRepositoryProvider);
  return GetExpiringSoonDragonBallsUseCase(repository);
});

final deleteDragonBallUseCaseProvider = Provider<DeleteDragonBallUseCase>((ref) {
  final repository = ref.watch(dragonBallRepositoryProvider);
  return DeleteDragonBallUseCase(repository);
});

// ===========================
// Use Case Providers - BatchShipment
// ===========================

final createBatchShipmentUseCaseProvider = Provider<CreateBatchShipmentUseCase>((ref) {
  final batchShipmentRepository = ref.watch(batchShipmentRepositoryProvider);
  final dragonBallRepository = ref.watch(dragonBallRepositoryProvider);
  return CreateBatchShipmentUseCase(batchShipmentRepository, dragonBallRepository);
});

final getUserBatchShipmentsUseCaseProvider = Provider<GetUserBatchShipmentsUseCase>((ref) {
  final repository = ref.watch(batchShipmentRepositoryProvider);
  return GetUserBatchShipmentsUseCase(repository);
});

final cancelBatchShipmentUseCaseProvider = Provider<CancelBatchShipmentUseCase>((ref) {
  final batchShipmentRepository = ref.watch(batchShipmentRepositoryProvider);
  final dragonBallRepository = ref.watch(dragonBallRepositoryProvider);
  return CancelBatchShipmentUseCase(batchShipmentRepository, dragonBallRepository);
});

final getBatchShipmentUseCaseProvider = Provider<GetBatchShipmentUseCase>((ref) {
  final repository = ref.watch(batchShipmentRepositoryProvider);
  return GetBatchShipmentUseCase(repository);
});

// ===========================
// Stream Providers
// ===========================

/// 현재 사용자의 드래곤볼 목록 스트림
final userDragonBallsStreamProvider = StreamProvider.autoDispose<List<DragonBallEntity>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value([]);

  final useCase = ref.watch(getUserDragonBallsUseCaseProvider);
  return useCase(user.uid);
});

/// 현재 사용자의 일괄 배송 목록 스트림
final userBatchShipmentsStreamProvider = StreamProvider.autoDispose<List<BatchShipmentEntity>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value([]);

  final useCase = ref.watch(getUserBatchShipmentsUseCaseProvider);
  return useCase(user.uid);
});

// ===========================
// Computed Providers
// ===========================

/// 보관 중인 드래곤볼만 필터링
final storedDragonBallsProvider = Provider<List<DragonBallEntity>>((ref) {
  final dragonBallsAsync = ref.watch(userDragonBallsStreamProvider);
  return dragonBallsAsync.maybeWhen(
    data: (dragonBalls) => dragonBalls.where((db) => db.isStored).toList(),
    orElse: () => [],
  );
});

/// 만료 임박 드래곤볼 (3일 이하)
final expiringSoonDragonBallsProvider = Provider<List<DragonBallEntity>>((ref) {
  final dragonBallsAsync = ref.watch(userDragonBallsStreamProvider);
  return dragonBallsAsync.maybeWhen(
    data: (dragonBalls) => dragonBalls.where((db) => db.isExpiringSoon).toList(),
    orElse: () => [],
  );
});

/// 보관 중인 드래곤볼 개수
final storedDragonBallCountProvider = Provider<int>((ref) {
  final stored = ref.watch(storedDragonBallsProvider);
  return stored.length;
});

// ===========================
// State Providers - UI 상태 관리
// ===========================

/// 선택된 드래곤볼 ID 목록 (일괄 배송용)
final selectedDragonBallIdsProvider = StateProvider<Set<String>>((ref) {
  return {};
});

/// 선택된 드래곤볼 개수
final selectedDragonBallCountProvider = Provider<int>((ref) {
  final selectedIds = ref.watch(selectedDragonBallIdsProvider);
  return selectedIds.length;
});

/// 선택된 드래곤볼들의 예상 배송비
final selectedDragonBallShippingCostProvider = Provider<int>((ref) {
  final selectedCount = ref.watch(selectedDragonBallCountProvider);
  return ShippingCostCalculator.calculateBatchShippingCost(selectedCount);
});

/// 선택된 드래곤볼들의 절약액
final selectedDragonBallSavingsProvider = Provider<int>((ref) {
  final selectedCount = ref.watch(selectedDragonBallCountProvider);
  return ShippingCostCalculator.calculateSavings(selectedCount);
});

// ===========================
// Action Providers - 비즈니스 로직
// ===========================

/// 드래곤볼 선택/선택 해제 토글
final toggleDragonBallSelectionProvider = Provider<void Function(String dragonBallId)>((ref) {
  return (String dragonBallId) {
    final selectedIds = ref.read(selectedDragonBallIdsProvider.notifier);
    final currentIds = ref.read(selectedDragonBallIdsProvider);

    if (currentIds.contains(dragonBallId)) {
      selectedIds.state = Set.from(currentIds)..remove(dragonBallId);
    } else {
      selectedIds.state = Set.from(currentIds)..add(dragonBallId);
    }
  };
});

/// 전체 선택/해제
final toggleSelectAllDragonBallsProvider = Provider<void Function(bool selectAll)>((ref) {
  return (bool selectAll) {
    final selectedIds = ref.read(selectedDragonBallIdsProvider.notifier);

    if (selectAll) {
      final stored = ref.read(storedDragonBallsProvider);
      selectedIds.state = stored.map((db) => db.dragonBallId).toSet();
    } else {
      selectedIds.state = {};
    }
  };
});

/// 선택 초기화
final clearDragonBallSelectionProvider = Provider<void Function()>((ref) {
  return () {
    ref.read(selectedDragonBallIdsProvider.notifier).state = {};
  };
});
