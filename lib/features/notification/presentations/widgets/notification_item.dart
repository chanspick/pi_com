// lib/features/notification/presentation/widgets/notification_item.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../../core/models/notification_model.dart';
import '../../../../core/utils/notification_handler.dart'; // ✅ 추가
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
        // NotificationHandler를 사용하여 알림 처리
        final handler = NotificationHandler(context);
        await handler.handleNotificationTap(notification);
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
      // 기존 타입
      case NotificationType.statusChanged:
        iconData = Icons.check_circle;
        iconColor = Colors.green;
        break;
      case NotificationType.paymentCompleted:
        iconData = Icons.payment;
        iconColor = Colors.blue;
        break;
      case NotificationType.listingSold:
        iconData = Icons.sell;
        iconColor = Colors.purple;
        break;
      case NotificationType.purchaseConfirmed:
        iconData = Icons.verified;
        iconColor = Colors.teal;
        break;
      case NotificationType.shipping:
        iconData = Icons.local_shipping;
        iconColor = Colors.indigo;
        break;
      case NotificationType.priceAlert:
        iconData = Icons.trending_down;
        iconColor = Colors.red;
        break;
      case NotificationType.marketing:
        iconData = Icons.campaign;
        iconColor = Colors.deepOrange;
        break;
      case NotificationType.system:
        iconData = Icons.info;
        iconColor = Colors.orange;
        break;

      // 검수/QC Flow
      case NotificationType.inspectionStarted:
        iconData = Icons.search;
        iconColor = Colors.blue;
        break;
      case NotificationType.inspectionPassed:
        iconData = Icons.check_circle;
        iconColor = Colors.green;
        break;
      case NotificationType.inspectionFailed:
        iconData = Icons.cancel;
        iconColor = Colors.red;
        break;
      case NotificationType.returnAddressExpiring:
        iconData = Icons.warning_amber;
        iconColor = Colors.orange;
        break;
      case NotificationType.penaltyIssued:
        iconData = Icons.gavel;
        iconColor = Colors.red;
        break;

      // 보관 서비스 Flow
      case NotificationType.storageCreated:
        iconData = Icons.inventory_2;
        iconColor = Colors.blue;
        break;
      case NotificationType.storageFeeStart:
        iconData = Icons.attach_money;
        iconColor = Colors.orange;
        break;
      case NotificationType.storageExpiring:
        iconData = Icons.access_time;
        iconColor = Colors.orange;
        break;
      case NotificationType.consignmentWarning:
        iconData = Icons.warning;
        iconColor = Colors.deepOrange;
        break;
      case NotificationType.consignmentConverted:
        iconData = Icons.swap_horiz;
        iconColor = Colors.purple;
        break;
      case NotificationType.consignmentSold:
        iconData = Icons.account_balance_wallet;
        iconColor = Colors.green;
        break;

      // 환불 Flow
      case NotificationType.refundRequested:
        iconData = Icons.assignment_return;
        iconColor = Colors.amber;
        break;
      case NotificationType.refundApproved:
        iconData = Icons.check_circle;
        iconColor = Colors.green;
        break;
      case NotificationType.refundRejected:
        iconData = Icons.cancel;
        iconColor = Colors.red;
        break;
      case NotificationType.returnShippingRequired:
        iconData = Icons.local_shipping;
        iconColor = Colors.blue;
        break;
      case NotificationType.returnItemReceived:
        iconData = Icons.inventory;
        iconColor = Colors.blue;
        break;
      case NotificationType.refundInspecting:
        iconData = Icons.search;
        iconColor = Colors.blue;
        break;
      case NotificationType.refundInspectionPass:
        iconData = Icons.verified;
        iconColor = Colors.green;
        break;
      case NotificationType.refundInspectionFail:
        iconData = Icons.error;
        iconColor = Colors.red;
        break;
      case NotificationType.refundProcessing:
        iconData = Icons.refresh;
        iconColor = Colors.blue;
        break;
      case NotificationType.refundCompleted:
        iconData = Icons.account_balance_wallet;
        iconColor = Colors.teal;
        break;

      // 정산 Flow
      case NotificationType.purchaseConfirmReminder:
        iconData = Icons.notifications_active;
        iconColor = Colors.amber;
        break;
      case NotificationType.autoConfirmed:
        iconData = Icons.check_circle_outline;
        iconColor = Colors.green;
        break;
      case NotificationType.settlementPending:
        iconData = Icons.schedule;
        iconColor = Colors.blue;
        break;
      case NotificationType.settlementCompleted:
        iconData = Icons.account_balance_wallet;
        iconColor = Colors.green;
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
