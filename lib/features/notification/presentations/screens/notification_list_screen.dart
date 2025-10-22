// lib/features/notification/presentation/screens/notification_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/notification_provider.dart';
import '../widgets/notification_item.dart';
import '../widgets/notification_empty_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// 알림 목록 화면
class NotificationListScreen extends ConsumerWidget {
  const NotificationListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 알림 목록 구독
    final notificationsAsync = ref.watch(currentUserNotificationsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('알림'),
        actions: [
          // 모두 읽음 처리 버튼 (선택)
          Consumer(
            builder: (context, ref, child) {
              final hasUnread = ref.watch(unreadNotificationsCountProvider) > 0;
              if (!hasUnread) return const SizedBox.shrink();

              return IconButton(
                icon: const Icon(Icons.done_all),
                onPressed: () {
                  // 모든 알림을 읽음 처리하는 로직 (추가 구현 가능)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('모두 읽음 처리는 준비 중입니다.')),
                  );
                },
                tooltip: '모두 읽음',
              );
            },
          ),
          // 전체 삭제 버튼
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'clear_all') {
                // 확인 다이얼로그
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('알림 전체 삭제'),
                    content: const Text('모든 알림을 삭제하시겠습니까?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('취소'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text(
                          '삭제',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  final user = ref.read(currentUserProvider);
                  if (user != null) {
                    await ref
                        .read(notificationActionsProvider.notifier)
                        .clearAllNotifications(user.uid);

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('모든 알림이 삭제되었습니다')),
                      );
                    }
                  }
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep, color: Colors.red),
                    SizedBox(width: 8),
                    Text('전체 삭제', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: notificationsAsync.when(
        // 로딩 중
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),

        // 에러
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('알림을 불러올 수 없습니다'),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        // 데이터 로드 완료
        data: (notifications) {
          if (notifications.isEmpty) {
            return const NotificationEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () async {
              // 새로고침 (Provider가 자동으로 갱신됨)
              ref.invalidate(currentUserNotificationsStreamProvider);
            },
            child: ListView.separated(
              itemCount: notifications.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return NotificationItem(notification: notification);
              },
            ),
          );
        },
      ),
    );
  }
}
