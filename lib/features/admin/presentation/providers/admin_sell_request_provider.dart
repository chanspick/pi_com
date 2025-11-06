// lib/features/admin/presentation/providers/admin_sell_request_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../data/datasources/admin_sell_request_datasource.dart';
import '../../data/datasources/admin_notification_datasource.dart';
import '../../data/repositories/admin_sell_request_repository_impl.dart';
import '../../domain/repositories/admin_sell_request_repository.dart';
import '../../domain/usecases/approve_sell_request.dart';
import '../../domain/usecases/reject_sell_request.dart';
import '../../domain/usecases/get_pending_sell_requests.dart';
import '../../domain/usecases/send_notification_to_user.dart';
import '../../../../core/models/sell_request_model.dart';
import '../../../../core/constants/firebase_constants.dart';

import '../../domain/usecases/get_sell_request_by_id.dart';

// ============================================
// 🔹 DataSource Providers
// ============================================

/// AdminSellRequestDataSource Provider
final adminSellRequestDataSourceProvider = Provider<AdminSellRequestDataSource>((ref) {
  return AdminSellRequestDataSource(
    firestore: FirebaseFirestore.instance,
  );
});

/// AdminNotificationDataSource Provider
final adminNotificationDataSourceProvider = Provider<AdminNotificationDataSource>((ref) {
  return AdminNotificationDataSource(
    firestore: FirebaseFirestore.instance,
  );
});

// ============================================
// 🔹 Repository Provider
// ============================================

/// AdminSellRequestRepository Provider
final adminSellRequestRepositoryProvider = Provider<AdminSellRequestRepository>((ref) {
  final sellRequestDataSource = ref.watch(adminSellRequestDataSourceProvider);
  final notificationDataSource = ref.watch(adminNotificationDataSourceProvider);

  return AdminSellRequestRepositoryImpl(
    sellRequestDataSource,
    notificationDataSource,
  );
});

// ============================================
// 🔹 UseCase Providers
// ============================================

/// 승인 UseCase Provider
final approveSellRequestProvider = Provider<ApproveSellRequest>((ref) {
  final repository = ref.watch(adminSellRequestRepositoryProvider);
  return ApproveSellRequest(repository);
});

/// 반려 UseCase Provider
final rejectSellRequestProvider = Provider<RejectSellRequest>((ref) {
  final repository = ref.watch(adminSellRequestRepositoryProvider);
  return RejectSellRequest(repository);
});

/// 대기 중 조회 UseCase Provider
final getPendingSellRequestsProvider = Provider<GetPendingSellRequests>((ref) {
  final repository = ref.watch(adminSellRequestRepositoryProvider);
  return GetPendingSellRequests(repository);
});

/// 알림 발송 UseCase Provider
final sendNotificationToUserProvider = Provider<SendNotificationToUser>((ref) {
  final repository = ref.watch(adminSellRequestRepositoryProvider);
  return SendNotificationToUser(repository);
});

/// ID로 SellRequest 조회 UseCase Provider
final getSellRequestByIdProvider = Provider<GetSellRequestById>((ref) {
  final repository = ref.watch(adminSellRequestRepositoryProvider);
  return GetSellRequestById(repository);
});

// ============================================
// 🔹 Stream Provider (실시간 데이터)
// ============================================

/// 대기 중인 SellRequest Stream Provider
///
/// UI에서 직접 사용:
/// ```
/// final pendingRequests = ref.watch(pendingSellRequestsStreamProvider);
/// pendingRequests.when(
///   data: (requests) => ListView(...),
///   loading: () => CircularProgressIndicator(),
///   error: (error, stack) => ErrorWidget(error),
/// );
/// ```
final pendingSellRequestsStreamProvider = StreamProvider<List<SellRequest>>((ref) {
  final useCase = ref.watch(getPendingSellRequestsProvider);
  return useCase.call();
});

// ============================================
// 🔹 State Notifier (승인/반려 상태 관리)
// ============================================

/// 승인/반려 처리 상태
enum AdminActionStatus {
  idle,      // 대기 중
  loading,   // 처리 중
  success,   // 성공
  error,     // 실패
}

/// 승인/반려 상태 클래스
class AdminActionState {
  final AdminActionStatus status;
  final String? errorMessage;
  final String? successMessage;

  AdminActionState({
    required this.status,
    this.errorMessage,
    this.successMessage,
  });

  AdminActionState.idle()
      : status = AdminActionStatus.idle,
        errorMessage = null,
        successMessage = null;

  AdminActionState.loading()
      : status = AdminActionStatus.loading,
        errorMessage = null,
        successMessage = null;

  AdminActionState.success(String message)
      : status = AdminActionStatus.success,
        errorMessage = null,
        successMessage = message;

  AdminActionState.error(String message)
      : status = AdminActionStatus.error,
        errorMessage = message,
        successMessage = null;
}

/// 승인/반려 처리 Controller
class AdminActionController extends StateNotifier<AdminActionState> {
  final ApproveSellRequest _approveSellRequest;
  final RejectSellRequest _rejectSellRequest;

  AdminActionController(
      this._approveSellRequest,
      this._rejectSellRequest,
      ) : super(AdminActionState.idle());

  /// 승인 실행
  Future<void> approve({
    required String requestId,
    required int finalPrice,
    required double finalConditionScore,
    String? adminNotes,
  }) async {
    state = AdminActionState.loading();

    try {
      await _approveSellRequest.call(
        requestId: requestId,
        finalPrice: finalPrice,
        finalConditionScore: finalConditionScore,
        adminNotes: adminNotes,
      );

      state = AdminActionState.success('판매 요청이 승인되었습니다.');
    } catch (e) {
      state = AdminActionState.error('승인 실패: ${e.toString()}');
    }
  }

  /// 반려 실행
  Future<void> reject({
    required String requestId,
    required String reason,
  }) async {
    state = AdminActionState.loading();

    try {
      await _rejectSellRequest.call(
        requestId: requestId,
        reason: reason,
      );

      state = AdminActionState.success('판매 요청이 반려되었습니다.');
    } catch (e) {
      state = AdminActionState.error('반려 실패: ${e.toString()}');
    }
  }

  /// 상태 초기화
  void reset() {
    state = AdminActionState.idle();
  }
}

/// AdminActionController Provider
final adminActionControllerProvider =
StateNotifierProvider<AdminActionController, AdminActionState>((ref) {
  final approveUseCase = ref.watch(approveSellRequestProvider);
  final rejectUseCase = ref.watch(rejectSellRequestProvider);

  return AdminActionController(approveUseCase, rejectUseCase);
});

/// 승인된 SellRequest Stream Provider
final approvedSellRequestsStreamProvider = StreamProvider<List<SellRequest>>((ref) {
  return FirebaseFirestore.instance
      .collection(FirebaseConstants.sellRequestsCollection)
      .where('status', isEqualTo: SellRequestStatus.approved.name)
      .orderBy('updatedAt', descending: true)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs
        .map((doc) => SellRequest.fromFirestore(doc))
        .toList();
  });
});

/// 반려된 SellRequest Stream Provider
final rejectedSellRequestsStreamProvider = StreamProvider<List<SellRequest>>((ref) {
  return FirebaseFirestore.instance
      .collection(FirebaseConstants.sellRequestsCollection)
      .where('status', isEqualTo: SellRequestStatus.rejected.name)
      .orderBy('updatedAt', descending: true)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs
        .map((doc) => SellRequest.fromFirestore(doc))
        .toList();
  });
});
