// lib/features/notification/presentation/screens/notification_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/notification_provider.dart';
import '../widgets/notification_item.dart';
import '../widgets/notification_empty_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../price_alert/presentation/providers/price_alert_provider.dart';
import '../../../../core/models/price_alert_model.dart';
import '../../../price_alert/presentation/widgets/price_alert_setup_dialog.dart';

/// 알림 목록 화면 (통합: 일반 알림 + 가격 알림)
class NotificationListScreen extends ConsumerStatefulWidget {
  const NotificationListScreen({super.key});

  @override
  ConsumerState<NotificationListScreen> createState() => _NotificationListScreenState();
}

class _NotificationListScreenState extends ConsumerState<NotificationListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 알림 목록 구독
    final notificationsAsync = ref.watch(currentUserNotificationsStreamProvider);
    final priceAlertsAsync = ref.watch(priceAlertsProvider);

    // 배지 카운트
    final unreadCount = ref.watch(unreadNotificationsCountProvider);
    final activePriceAlertCount = ref.watch(activePriceAlertsCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('알림'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('일반 알림'),
                  if (unreadCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        unreadCount > 9 ? '9+' : '$unreadCount',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('가격 알림'),
                  if (activePriceAlertCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        activePriceAlertCount > 9 ? '9+' : '$activePriceAlertCount',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        actions: [
          // 현재 탭에 따라 다른 액션 표시
          AnimatedBuilder(
            animation: _tabController,
            builder: (context, child) {
              if (_tabController.index == 0) {
                // 일반 알림 탭: 전체 삭제
                return PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'clear_all') {
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
                );
              } else {
                // 가격 알림 탭: 빈 공간
                return const SizedBox.shrink();
              }
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: 일반 알림
          _buildNotificationsTab(notificationsAsync),

          // Tab 2: 가격 알림
          _buildPriceAlertsTab(priceAlertsAsync),
        ],
      ),
    );
  }

  /// 일반 알림 탭
  Widget _buildNotificationsTab(AsyncValue notificationsAsync) {
    return notificationsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            const Text('알림을 불러올 수 없습니다'),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      data: (notifications) {
        if (notifications.isEmpty) {
          return const NotificationEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () async {
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
    );
  }

  /// 가격 알림 탭
  Widget _buildPriceAlertsTab(AsyncValue<List<PriceAlert>> priceAlertsAsync) {
    return priceAlertsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('오류: $error'),
          ],
        ),
      ),
      data: (alerts) {
        if (alerts.isEmpty) {
          return _buildPriceAlertsEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(priceAlertsProvider);
          },
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: alerts.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final alert = alerts[index];
              return _PriceAlertCard(alert: alert);
            },
          ),
        );
      },
    );
  }

  /// 가격 알림 빈 상태
  Widget _buildPriceAlertsEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            '설정된 가격 알림이 없습니다',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            '상품 상세 페이지에서 가격 알림을 설정하세요',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

/// 가격 알림 카드
class _PriceAlertCard extends ConsumerWidget {
  final PriceAlert alert;

  const _PriceAlertCard({required this.alert});

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  Color _getStatusColor() {
    if (!alert.isActive) return Colors.grey;
    if (alert.triggeredAt != null) return Colors.green;
    return Colors.orange;
  }

  IconData _getStatusIcon() {
    if (!alert.isActive) return Icons.notifications_off;
    if (alert.triggeredAt != null) return Icons.check_circle;
    return Icons.notifications_active;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final discount = alert.discountPercentage;

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => _showEditDialog(context, ref),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상태 배지와 부품명
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      alert.partName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_getStatusIcon(), size: 14, color: _getStatusColor()),
                        const SizedBox(width: 4),
                        Text(
                          alert.statusText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // 가격 정보
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '목표 가격',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_formatPrice(alert.targetPrice)}원',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.grey[300],
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '설정 당시 가격',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_formatPrice(alert.priceAtCreation)}원',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // 할인율 표시
              if (discount > 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.trending_down, size: 16, color: Colors.green),
                      const SizedBox(width: 6),
                      Text(
                        '${discount.toStringAsFixed(1)}% 할인 대기',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // 알림 발생 시간
              if (alert.triggeredAt != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Text(
                      '알림 발생: ${_formatDate(alert.triggeredAt!)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _showEditDialog(BuildContext context, WidgetRef ref) async {
    await showDialog(
      context: context,
      builder: (context) => PriceAlertSetupDialog(
        basePartId: alert.basePartId,
        partName: alert.partName,
        currentPrice: alert.priceAtCreation,
        existingAlert: alert,
      ),
    );
  }
}
