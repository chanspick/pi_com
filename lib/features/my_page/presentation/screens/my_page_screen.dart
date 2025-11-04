// lib/features/my_page/presentation/screens/my_page_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/constants/routes.dart';

/// 마이페이지 메인 화면
class MyPageScreen extends ConsumerWidget {
  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('마이페이지')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_outline, size: 80, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('로그인이 필요합니다', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // TODO: 로그인 화면으로 이동
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('로그인 화면으로 이동 - 라우팅 설정 필요')),
                  );
                },
                child: const Text('로그인하기'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('마이페이지'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, Routes.settings);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 사용자 프로필 헤더
            _buildUserProfileHeader(context, currentUser),

            const Divider(thickness: 8, color: Color(0xFFF5F5F5)),

            // 거래 내역 섹션
            _buildSection(
              context,
              title: '거래 관리',
              items: [
                _MenuItem(
                  icon: Icons.shopping_bag_outlined,
                  title: '구매 내역',
                  subtitle: '내가 구매한 상품',
                  onTap: () => Navigator.pushNamed(context, Routes.purchaseHistory),
                ),
                _MenuItem(
                  icon: Icons.sell_outlined,
                  title: '판매 내역',
                  subtitle: '내가 판매한 상품',
                  onTap: () => Navigator.pushNamed(context, Routes.salesHistory),
                ),
                _MenuItem(
                  icon: Icons.request_page_outlined,
                  title: '판매 요청 내역',
                  subtitle: '판매 요청 상태 확인',
                  onTap: () => Navigator.pushNamed(context, Routes.sellRequestHistory),
                ),
              ],
            ),

            const Divider(thickness: 8, color: Color(0xFFF5F5F5)),

            // 드래곤볼 섹션
            _buildSection(
              context,
              title: '드래곤볼',
              items: [
                _MenuItem(
                  icon: Icons.inventory_2_outlined,
                  title: '드래곤볼 보관함',
                  subtitle: '보관 중인 부품 확인 및 배송 요청',
                  onTap: () => Navigator.pushNamed(context, Routes.dragonBallStorage),
                ),
                _MenuItem(
                  icon: Icons.local_shipping_outlined,
                  title: '일괄 배송 내역',
                  subtitle: '배송 요청 상태 확인',
                  onTap: () => Navigator.pushNamed(context, Routes.batchShipmentHistory),
                ),
              ],
            ),

            const Divider(thickness: 8, color: Color(0xFFF5F5F5)),

            // 관심 상품 및 알림
            _buildSection(
              context,
              title: '관심 상품',
              items: [
                _MenuItem(
                  icon: Icons.favorite_outline,
                  title: '찜한 상품',
                  subtitle: '관심 있는 상품 모음',
                  onTap: () => Navigator.pushNamed(context, Routes.favorites),
                ),
                _MenuItem(
                  icon: Icons.notifications_outlined,
                  title: '가격 알림',
                  subtitle: '목표 가격 도달 시 알림',
                  onTap: () => Navigator.pushNamed(context, Routes.priceAlerts),
                ),
              ],
            ),

            const Divider(thickness: 8, color: Color(0xFFF5F5F5)),

            // 설정
            _buildSection(
              context,
              title: '설정',
              items: [
                _MenuItem(
                  icon: Icons.person_outline,
                  title: '회원 정보 수정',
                  subtitle: '프로필 및 계정 정보',
                  onTap: () => Navigator.pushNamed(context, Routes.profileEdit),
                ),
                _MenuItem(
                  icon: Icons.notifications_outlined,
                  title: '알림 설정',
                  subtitle: '알림 수신 관리',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('알림 설정 화면 - 개발 예정')),
                    );
                  },
                ),
                _MenuItem(
                  icon: Icons.logout,
                  title: '로그아웃',
                  subtitle: '',
                  onTap: () => _handleLogout(context, ref),
                  isDestructive: true,
                ),
              ],
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildUserProfileHeader(BuildContext context, dynamic user) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            child: Text(
              user.displayName?.substring(0, 1).toUpperCase() ?? 'U',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName ?? '사용자',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              Navigator.pushNamed(context, Routes.profileEdit);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<_MenuItem> items,
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
        ...items.map((item) => _buildMenuItem(context, item)),
      ],
    );
  }

  Widget _buildMenuItem(BuildContext context, _MenuItem item) {
    return ListTile(
      leading: Icon(
        item.icon,
        color: item.isDestructive ? Colors.red : Colors.black87,
      ),
      title: Text(
        item.title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: item.isDestructive ? Colors.red : Colors.black87,
        ),
      ),
      subtitle: item.subtitle.isNotEmpty
          ? Text(
              item.subtitle,
              style: const TextStyle(fontSize: 12),
            )
          : null,
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: item.onTap,
    );
  }

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃 하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authRepositoryProvider).signOut();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그아웃되었습니다')),
        );
      }
    }
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDestructive;

  _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isDestructive = false,
  });
}
