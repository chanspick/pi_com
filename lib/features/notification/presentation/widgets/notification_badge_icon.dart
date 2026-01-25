// lib/features/notification/presentation/widgets/notification_badge_icon.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/notification_provider.dart';
import '../screens/notification_list_screen.dart';
import '../../../price_alert/presentation/providers/price_alert_provider.dart';

/// 알림 아이콘 + 뱃지 (홈 화면 AppBar용)
/// 일반 알림 + 가격 알림 통합 표시
class NotificationBadgeIcon extends ConsumerWidget {
  const NotificationBadgeIcon({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationsCountProvider);
    final priceAlertCount = ref.watch(activePriceAlertsCountProvider);
    final totalCount = unreadCount + priceAlertCount;

    return IconButton(
      icon: Badge(
        isLabelVisible: totalCount > 0,
        label: Text(totalCount > 9 ? '9+' : '$totalCount'),
        child: const Icon(Icons.notifications_outlined),
      ),
      onPressed: () {
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
