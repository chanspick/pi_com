// lib/features/notification/presentation/widgets/notification_badge_icon.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/notification_provider.dart';
import '../screens/notification_list_screen.dart'; // ✅ 추가

/// 알림 아이콘 + 뱃지 (홈 화면 AppBar용)
class NotificationBadgeIcon extends ConsumerWidget {
  const NotificationBadgeIcon({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationsCountProvider);

    return IconButton(
      icon: Badge(
        isLabelVisible: unreadCount > 0,
        label: Text('$unreadCount'),
        child: const Icon(Icons.notifications_outlined),
      ),
      onPressed: () {
        // ✅ Navigator.push 사용
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const NotificationListScreen(),
          ),
        );
      },
      tooltip: '알림',
    );
  }
}
