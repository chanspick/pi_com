// lib/features/my_page/presentation/screens/notification_settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 알림 설정 Provider
final notificationSettingsProvider = StateNotifierProvider<NotificationSettingsNotifier, NotificationSettings>((ref) {
  return NotificationSettingsNotifier();
});

/// 알림 설정 상태
class NotificationSettings {
  final bool pushEnabled; // 푸시 알림 전체 활성화
  final bool priceAlerts; // 가격 알림
  final bool orderUpdates; // 주문 상태 업데이트
  final bool promotions; // 프로모션 및 이벤트
  final bool newListings; // 새 상품 알림
  final bool chatMessages; // 채팅 메시지

  const NotificationSettings({
    required this.pushEnabled,
    required this.priceAlerts,
    required this.orderUpdates,
    required this.promotions,
    required this.newListings,
    required this.chatMessages,
  });

  NotificationSettings copyWith({
    bool? pushEnabled,
    bool? priceAlerts,
    bool? orderUpdates,
    bool? promotions,
    bool? newListings,
    bool? chatMessages,
  }) {
    return NotificationSettings(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      priceAlerts: priceAlerts ?? this.priceAlerts,
      orderUpdates: orderUpdates ?? this.orderUpdates,
      promotions: promotions ?? this.promotions,
      newListings: newListings ?? this.newListings,
      chatMessages: chatMessages ?? this.chatMessages,
    );
  }
}

/// 알림 설정 Notifier
class NotificationSettingsNotifier extends StateNotifier<NotificationSettings> {
  static const String _keyPushEnabled = 'notification_push_enabled';
  static const String _keyPriceAlerts = 'notification_price_alerts';
  static const String _keyOrderUpdates = 'notification_order_updates';
  static const String _keyPromotions = 'notification_promotions';
  static const String _keyNewListings = 'notification_new_listings';
  static const String _keyChatMessages = 'notification_chat_messages';

  NotificationSettingsNotifier() : super(const NotificationSettings(
    pushEnabled: true,
    priceAlerts: true,
    orderUpdates: true,
    promotions: true,
    newListings: true,
    chatMessages: true,
  )) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    state = NotificationSettings(
      pushEnabled: prefs.getBool(_keyPushEnabled) ?? true,
      priceAlerts: prefs.getBool(_keyPriceAlerts) ?? true,
      orderUpdates: prefs.getBool(_keyOrderUpdates) ?? true,
      promotions: prefs.getBool(_keyPromotions) ?? true,
      newListings: prefs.getBool(_keyNewListings) ?? true,
      chatMessages: prefs.getBool(_keyChatMessages) ?? true,
    );
  }

  Future<void> setPushEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPushEnabled, value);
    state = state.copyWith(pushEnabled: value);

    // 푸시를 끄면 모든 알림 비활성화
    if (!value) {
      await _disableAllNotifications();
    }
  }

  Future<void> setPriceAlerts(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPriceAlerts, value);
    state = state.copyWith(priceAlerts: value);
  }

  Future<void> setOrderUpdates(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOrderUpdates, value);
    state = state.copyWith(orderUpdates: value);
  }

  Future<void> setPromotions(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPromotions, value);
    state = state.copyWith(promotions: value);
  }

  Future<void> setNewListings(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNewListings, value);
    state = state.copyWith(newListings: value);
  }

  Future<void> setChatMessages(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyChatMessages, value);
    state = state.copyWith(chatMessages: value);
  }

  Future<void> _disableAllNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPriceAlerts, false);
    await prefs.setBool(_keyOrderUpdates, false);
    await prefs.setBool(_keyPromotions, false);
    await prefs.setBool(_keyNewListings, false);
    await prefs.setBool(_keyChatMessages, false);

    state = NotificationSettings(
      pushEnabled: false,
      priceAlerts: false,
      orderUpdates: false,
      promotions: false,
      newListings: false,
      chatMessages: false,
    );
  }
}

/// 알림 설정 화면
class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(notificationSettingsProvider);
    final notifier = ref.read(notificationSettingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('알림 설정'),
      ),
      body: ListView(
        children: [
          // 푸시 알림 전체 켜기/끄기
          Container(
            color: Colors.blue[50],
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.notifications_active, color: Colors.blue[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '푸시 알림',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[900],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            settings.pushEnabled
                                ? '모든 푸시 알림을 받고 있습니다'
                                : '푸시 알림이 꺼져 있습니다',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: settings.pushEnabled,
                      onChanged: (value) async {
                        if (!value) {
                          // 푸시를 끄려는 경우 확인 다이얼로그 표시
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('푸시 알림 끄기'),
                              content: const Text(
                                '모든 푸시 알림을 받지 않으시겠습니까?\n\n'
                                '중요한 주문 상태 업데이트나 가격 알림을 놓칠 수 있습니다.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('취소'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                                  child: const Text('끄기'),
                                ),
                              ],
                            ),
                          );
                          if (confirmed == true) {
                            await notifier.setPushEnabled(false);
                          }
                        } else {
                          await notifier.setPushEnabled(true);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // 개별 알림 설정
          _buildSection(
            context,
            title: '거래 알림',
            items: [
              _NotificationSettingItem(
                icon: Icons.trending_down,
                title: '가격 알림',
                subtitle: '찜한 상품의 가격이 하락하면 알려드려요',
                value: settings.priceAlerts,
                enabled: settings.pushEnabled,
                onChanged: (value) => notifier.setPriceAlerts(value),
              ),
              _NotificationSettingItem(
                icon: Icons.local_shipping_outlined,
                title: '주문 상태 업데이트',
                subtitle: '주문, 배송 상태가 변경되면 알려드려요',
                value: settings.orderUpdates,
                enabled: settings.pushEnabled,
                onChanged: (value) => notifier.setOrderUpdates(value),
              ),
            ],
          ),

          const Divider(thickness: 8, color: Color(0xFFF5F5F5)),

          _buildSection(
            context,
            title: '상품 알림',
            items: [
              _NotificationSettingItem(
                icon: Icons.new_releases_outlined,
                title: '새 상품 알림',
                subtitle: '관심 카테고리에 새 상품이 등록되면 알려드려요',
                value: settings.newListings,
                enabled: settings.pushEnabled,
                onChanged: (value) => notifier.setNewListings(value),
              ),
            ],
          ),

          const Divider(thickness: 8, color: Color(0xFFF5F5F5)),

          _buildSection(
            context,
            title: '커뮤니케이션',
            items: [
              _NotificationSettingItem(
                icon: Icons.chat_bubble_outline,
                title: '채팅 메시지',
                subtitle: '새로운 채팅 메시지가 도착하면 알려드려요',
                value: settings.chatMessages,
                enabled: settings.pushEnabled,
                onChanged: (value) => notifier.setChatMessages(value),
              ),
            ],
          ),

          const Divider(thickness: 8, color: Color(0xFFF5F5F5)),

          _buildSection(
            context,
            title: '마케팅',
            items: [
              _NotificationSettingItem(
                icon: Icons.campaign_outlined,
                title: '프로모션 및 이벤트',
                subtitle: '특별 할인, 이벤트 정보를 알려드려요',
                value: settings.promotions,
                enabled: settings.pushEnabled,
                onChanged: (value) => notifier.setPromotions(value),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 안내 문구
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '• 푸시 알림은 기기 설정에서도 관리할 수 있습니다.\n'
              '• 중요한 알림은 푸시가 꺼져 있어도 앱 내에서 확인할 수 있습니다.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<_NotificationSettingItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
        ...items,
      ],
    );
  }
}

/// 개별 알림 설정 아이템
class _NotificationSettingItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _NotificationSettingItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: enabled ? Colors.black87 : Colors.grey[400],
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: enabled ? Colors.black87 : Colors.grey[400],
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: enabled ? Colors.grey[600] : Colors.grey[400],
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: enabled ? onChanged : null,
      ),
      enabled: enabled,
    );
  }
}
