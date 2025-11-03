// lib/features/price_alert/presentation/widgets/price_alert_badge_icon.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/price_alert_provider.dart';
import '../../../../core/constants/routes.dart';

/// 가격 알림 배지 아이콘 (활성 알림 개수 표시)
class PriceAlertBadgeIcon extends ConsumerWidget {
  const PriceAlertBadgeIcon({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeCount = ref.watch(activePriceAlertsCountProvider);

    return IconButton(
      icon: Stack(
        children: [
          const Icon(Icons.notifications_outlined),
          if (activeCount > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Text(
                  activeCount > 9 ? '9+' : activeCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      onPressed: () {
        Navigator.of(context).pushNamed(Routes.priceAlerts);
      },
      tooltip: '가격 알림',
    );
  }
}
