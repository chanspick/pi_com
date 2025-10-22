// lib/features/notification/presentation/widgets/notification_item.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../../core/models/notification_model.dart';
import '../../../../core/constants/routes.dart'; // ✅ 추가
import '../providers/notification_provider.dart';

/// 알림 항목 위젯
class NotificationItem extends ConsumerWidget {
  final NotificationModel notification;

  const NotificationItem({
    super.key,
    required this.notification,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backgroundColor = notification.isRead
        ? Colors.transparent
        : Theme.of(context).primaryColor.withValues(alpha: 0.05);

    final titleStyle = TextStyle(
      fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
      fontSize: 15,
    );

    return InkWell(
      onTap: () async {
        // 1. 읽음 처리
        if (!notification.isRead) {
          await ref
              .read(notificationActionsProvider.notifier)
              .markAsRead(notification.notificationId);
        }

        // 2. 관련 화면으로 이동
        if (notification.relatedSellRequestId != null) {
          if (!context.mounted) return;
          // ✅ Navigator.pushNamed 사용
          Navigator.pushNamed(
            context,
            Routes.sellRequestDetails,
            arguments: notification.relatedSellRequestId,
          );
        }
      },
      child: Container(
        color: backgroundColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIcon(context),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(notification.title, style: titleStyle),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTimestamp(notification.createdAt),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            if (!notification.isRead)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(BuildContext context) {
    IconData iconData;
    Color iconColor;

    switch (notification.type) {
      case NotificationType.statusChanged:
        iconData = Icons.check_circle;
        iconColor = Colors.green;
        break;
      case NotificationType.paymentCompleted:
        iconData = Icons.payment;
        iconColor = Colors.blue;
        break;
      case NotificationType.system:
        iconData = Icons.info;
        iconColor = Colors.orange;
        break;
    }

    return CircleAvatar(
      backgroundColor: iconColor.withValues(alpha:0.1),
      child: Icon(iconData, color: iconColor, size: 20),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    timeago.setLocaleMessages('ko', timeago.KoMessages());
    return timeago.format(timestamp, locale: 'ko');
  }
}
