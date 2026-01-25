// lib/features/notification/presentation/providers/notification_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/notification_model.dart';
import '../../../../shared/providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../../domain/usecases/get_notifications_stream.dart';
import '../../domain/usecases/mark_as_read.dart';
import '../../domain/usecases/delete_notification.dart';
import '../../domain/usecases/clear_all_notifications.dart';
import '../../domain/usecases/get_unread_count.dart';

/// ========================================
/// Notification Repository Provider
/// ========================================

/// NotificationRepository 인스턴스 제공
final notificationRepositoryProvider = Provider<NotificationRepositoryImpl>((ref) {
  return NotificationRepositoryImpl(
    dataSource: ref.watch(notificationDataSourceProvider),
  );
});

/// ========================================
/// Use Case Providers
/// ========================================

/// Get Notifications Stream Use Case
final getNotificationsStreamUseCaseProvider = Provider<GetNotificationsStream>((ref) {
  return GetNotificationsStream(ref.watch(notificationRepositoryProvider));
});

/// Mark As Read Use Case
final markAsReadUseCaseProvider = Provider<MarkAsRead>((ref) {
  return MarkAsRead(ref.watch(notificationRepositoryProvider));
});

/// Delete Notification Use Case
final deleteNotificationUseCaseProvider = Provider<DeleteNotification>((ref) {
  return DeleteNotification(ref.watch(notificationRepositoryProvider));
});

/// Clear All Notifications Use Case
final clearAllNotificationsUseCaseProvider = Provider<ClearAllNotifications>((ref) {
  return ClearAllNotifications(ref.watch(notificationRepositoryProvider));
});

/// Get Unread Count Use Case
final getUnreadCountUseCaseProvider = Provider<GetUnreadCount>((ref) {
  return GetUnreadCount(ref.watch(notificationRepositoryProvider));
});

/// ========================================
/// Notification Stream Providers
/// ========================================

/// 현재 사용자의 알림 목록 스트림
final currentUserNotificationsStreamProvider = StreamProvider<List<NotificationModel>>((ref) {
  final user = ref.watch(currentUserProvider);

  // 로그인하지 않은 경우 빈 리스트 반환
  if (user == null) {
    return Stream.value([]);
  }

  // Use Case를 통해 알림 스트림 가져오기
  final useCase = ref.watch(getNotificationsStreamUseCaseProvider);
  return useCase(user.uid);
});

/// ========================================
/// Computed Providers
/// ========================================

/// 읽지 않은 알림 개수 (실시간)
final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notificationsAsync = ref.watch(currentUserNotificationsStreamProvider);

  return notificationsAsync.when(
    data: (notifications) => notifications.where((n) => !n.isRead).length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// 알림 목록 (동기적 접근)
final notificationListProvider = Provider<List<NotificationModel>>((ref) {
  final notificationsAsync = ref.watch(currentUserNotificationsStreamProvider);

  return notificationsAsync.when(
    data: (notifications) => notifications,
    loading: () => [],
    error: (_, __) => [],
  );
});

/// 알림이 있는지 여부
final hasNotificationsProvider = Provider<bool>((ref) {
  final notifications = ref.watch(notificationListProvider);
  return notifications.isNotEmpty;
});

/// ========================================
/// Notification Actions (StateNotifier)
/// ========================================

/// Notification 액션 상태
class NotificationActionsState {
  final bool isLoading;
  final String? error;

  NotificationActionsState({
    this.isLoading = false,
    this.error,
  });

  NotificationActionsState copyWith({
    bool? isLoading,
    String? error,
  }) {
    return NotificationActionsState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// Notification 액션 Notifier
class NotificationActionsNotifier extends StateNotifier<NotificationActionsState> {
  final MarkAsRead _markAsReadUseCase;
  final DeleteNotification _deleteNotificationUseCase;
  final ClearAllNotifications _clearAllNotificationsUseCase;

  NotificationActionsNotifier({
    required MarkAsRead markAsReadUseCase,
    required DeleteNotification deleteNotificationUseCase,
    required ClearAllNotifications clearAllNotificationsUseCase,
  })  : _markAsReadUseCase = markAsReadUseCase,
        _deleteNotificationUseCase = deleteNotificationUseCase,
        _clearAllNotificationsUseCase = clearAllNotificationsUseCase,
        super(NotificationActionsState());

  /// 알림 읽음 처리
  Future<void> markAsRead(String notificationId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _markAsReadUseCase(notificationId);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// 알림 삭제
  Future<void> deleteNotification(String notificationId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _deleteNotificationUseCase(notificationId);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// 모든 알림 삭제
  Future<void> clearAllNotifications(String userId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _clearAllNotificationsUseCase(userId);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

/// Notification Actions Provider
final notificationActionsProvider = StateNotifierProvider<NotificationActionsNotifier, NotificationActionsState>((ref) {
  return NotificationActionsNotifier(
    markAsReadUseCase: ref.watch(markAsReadUseCaseProvider),
    deleteNotificationUseCase: ref.watch(deleteNotificationUseCaseProvider),
    clearAllNotificationsUseCase: ref.watch(clearAllNotificationsUseCaseProvider),
  );
});
