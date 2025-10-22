// lib/features/admin/presentation/screens/admin_login_page.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/data/datasources/google_auth_datasource.dart';

class AdminLoginPage extends StatelessWidget {
  const AdminLoginPage({super.key});

  Future<void> _signInWithGoogle(BuildContext context) async {
    try {
      // GoogleAuthDataSource 사용!
      final datasource = GoogleAuthDataSource();
      final user = await datasource.signIn();

      if (user == null) return;

      // ✅ 로그인 성공 → Dashboard로 이동
      if (context.mounted) {
        context.go('/admin/dashboard'); // 🔧 수정: /admin → /admin/dashboard
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('로그인 실패: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(32),
          child: Padding(
            padding: const EdgeInsets.all(48),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '관리자 로그인',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () => _signInWithGoogle(context),
                  icon: const Icon(Icons.login),
                  label: const Text('Google로 로그인'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.go('/'),
                  child: const Text('홈으로 돌아가기'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
