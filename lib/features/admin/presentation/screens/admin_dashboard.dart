// lib/features/admin/presentation/screens/admin_dashboard.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import '../../data/admin_auth_repository.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final _authRepo = AdminAuthRepository();
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkAdminAccess();
  }

  Future<void> _checkAdminAccess() async {
    final (userModel, error) = await _authRepo.checkCurrentUserIsAdmin();
    if (!mounted) return;

    if (error.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      context.go('/admin');
      return;
    }

    setState(() => _isChecking = false);
  }

  Future<void> _handleLogout() async {
    await _authRepo.signOut();
    if (mounted) context.go('/admin');
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('관리자 대시보드'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '관리자 대시보드',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),

            // 관리 메뉴 그리드
            Expanded(
              child: GridView.count(
                crossAxisCount: kIsWeb ? 4 : 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _AdminMenuCard(
                    title: '판매 요청 관리',
                    icon: Icons.pending_actions,
                    color: Colors.orange,
                    onTap: () => context.go('/admin/sell-requests'),
                  ),
                  _AdminMenuCard(
                    title: '사용자 관리',
                    icon: Icons.people,
                    color: Colors.blue,
                    onTap: () => context.go('/admin/users'),
                  ),
                  _AdminMenuCard(
                    title: '매물 관리',
                    icon: Icons.inventory,
                    color: Colors.green,
                    onTap: () => context.go('/admin/listings'),
                  ),
                  // 🆕 DB 업데이트 메뉴 추가
                  _AdminMenuCard(
                    title: 'DB 업데이트',
                    icon: Icons.cloud_upload,
                    color: Colors.red,
                    onTap: () => context.go('/admin/db-update'),
                  ),
                  _AdminMenuCard(
                    title: '통계',
                    icon: Icons.analytics,
                    color: Colors.purple,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('개발 예정')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================
// 보조 위젯: 관리 메뉴 카드
// ============================================

class _AdminMenuCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _AdminMenuCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
