// lib/features/my_page/presentation/screens/notification_settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// 알림 설정 Provider
final notificationSettingsProvider = StateNotifierProvider<NotificationSettingsNotifier, NotificationSettings>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  return NotificationSettingsNotifier(userId: currentUser?.uid);
});

/// 알림 설정 상태
class NotificationSettings {
  final bool pushEnabled; // 푸시 알림 전체 활성화
  final bool priceAlerts; // 가격 알림
  final bool orderUpdates; // 주문 상태 업데이트
  final bool promotions; // 프로모션 및 이벤트
  final bool newListings; // 새 상품 알림
  final bool isLoading; // 로딩 상태

  const NotificationSettings({
    required this.pushEnabled,
    required this.priceAlerts,
    required this.orderUpdates,
    required this.promotions,
    required this.newListings,
    this.isLoading = false,
  });

  NotificationSettings copyWith({
    bool? pushEnabled,
    bool? priceAlerts,
    bool? orderUpdates,
    bool? promotions,
    bool? newListings,
    bool? isLoading,
  }) {
    return NotificationSettings(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      priceAlerts: priceAlerts ?? this.priceAlerts,
      orderUpdates: orderUpdates ?? this.orderUpdates,
      promotions: promotions ?? this.promotions,
      newListings: newListings ?? this.newListings,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'pushEnabled': pushEnabled,
      'priceAlerts': priceAlerts,
      'orderUpdates': orderUpdates,
      'promotions': promotions,
      'newListings': newListings,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory NotificationSettings.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return const NotificationSettings(
        pushEnabled: true,
        priceAlerts: true,
        orderUpdates: true,
        promotions: true,
        newListings: true,
      );
    }
    return NotificationSettings(
      pushEnabled: map['pushEnabled'] as bool? ?? true,
      priceAlerts: map['priceAlerts'] as bool? ?? true,
      orderUpdates: map['orderUpdates'] as bool? ?? true,
      promotions: map['promotions'] as bool? ?? true,
      newListings: map['newListings'] as bool? ?? true,
    );
  }
}

/// 알림 설정 Notifier - Firestore에 저장
class NotificationSettingsNotifier extends StateNotifier<NotificationSettings> {
  final String? userId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  NotificationSettingsNotifier({this.userId}) : super(const NotificationSettings(
    pushEnabled: true,
    priceAlerts: true,
    orderUpdates: true,
    promotions: true,
    newListings: true,
    isLoading: true,
  )) {
    _loadSettings();
  }

  /// Firestore에서 설정 로드
  Future<void> _loadSettings() async {
    if (userId == null) {
      state = state.copyWith(isLoading: false);
      return;
    }

    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('notifications')
          .get();

      if (doc.exists) {
        final settings = NotificationSettings.fromMap(doc.data());
        state = settings.copyWith(isLoading: false);
      } else {
        // 기본값 저장
        await _saveSettings();
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      print('알림 설정 로드 실패: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  /// Firestore에 설정 저장
  Future<void> _saveSettings() async {
    if (userId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('notifications')
          .set(state.toMap(), SetOptions(merge: true));
    } catch (e) {
      print('알림 설정 저장 실패: $e');
    }
  }

  Future<void> setPushEnabled(bool value) async {
    state = state.copyWith(pushEnabled: value);

    // 푸시를 끄면 모든 알림 비활성화
    if (!value) {
      state = state.copyWith(
        priceAlerts: false,
        orderUpdates: false,
        promotions: false,
        newListings: false,
      );
    }

    await _saveSettings();
  }

  Future<void> setPriceAlerts(bool value) async {
    state = state.copyWith(priceAlerts: value);
    await _saveSettings();
  }

  Future<void> setOrderUpdates(bool value) async {
    state = state.copyWith(orderUpdates: value);
    await _saveSettings();
  }

  Future<void> setPromotions(bool value) async {
    state = state.copyWith(promotions: value);
    await _saveSettings();
  }

  Future<void> setNewListings(bool value) async {
    state = state.copyWith(newListings: value);
    await _saveSettings();
  }
}

/// 알림 설정 화면
class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(notificationSettingsProvider);
    final notifier = ref.read(notificationSettingsProvider.notifier);
    final currentUser = ref.watch(currentUserProvider);

    // 로그인하지 않은 경우
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('알림 설정'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                '로그인이 필요합니다',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                '알림 설정을 변경하려면 로그인하세요',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

    // 로딩 중
    if (settings.isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('알림 설정'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

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

          // 거래 알림
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
                subtitle: '주문, 배송, 검수 상태가 변경되면 알려드려요',
                value: settings.orderUpdates,
                enabled: settings.pushEnabled,
                onChanged: (value) => notifier.setOrderUpdates(value),
              ),
            ],
          ),

          const Divider(thickness: 8, color: Color(0xFFF5F5F5)),

          // 상품 알림
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

          // 마케팅
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
