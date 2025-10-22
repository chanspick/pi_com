// lib/features/admin/presentation/screens/admin_login_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_web/google_sign_in_web.dart' as web;
import 'package:firebase_auth/firebase_auth.dart';
import '../../../auth/data/datasources/google_auth_datasource.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final GoogleAuthDataSource _authDataSource = GoogleAuthDataSource();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // ✅ public 메서드 호출
      await _authDataSource.initialize();

      setState(() {
        _isInitialized = true;
      });

      // Firebase 인증 상태 리스닝
      _authDataSource.authStateChanges.listen((User? user) {
        if (user != null && mounted) {
          debugPrint('✅ User signed in: ${user.email}');
          context.go('/admin/dashboard');
        }
      });
    } catch (e) {
      debugPrint('❌ Initialization failed: $e');
    }
  }

  Future<void> _handleMobileSignIn() async {
    try {
      final user = await _authDataSource.signIn();

      if (user != null && mounted) {
        context.go('/admin/dashboard');
      }
    } catch (e) {
      if (mounted) {
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

                // 로딩 중
                if (!_isInitialized)
                  const CircularProgressIndicator()
                else
                  kIsWeb ? _buildWebSignInButton() : _buildMobileSignInButton(),

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

  /// 웹: renderButton 사용
  Widget _buildWebSignInButton() {
    return (_authDataSource.instance as web.GoogleSignInPlugin).renderButton(
      configuration: web.GSIButtonConfiguration(
        type: web.GSIButtonType.standard,
        theme: web.GSIButtonTheme.outline,
        size: web.GSIButtonSize.large,
        text: web.GSIButtonText.signinWith,
        shape: web.GSIButtonShape.rectangular,
        logoAlignment: web.GSIButtonLogoAlignment.left,
      ),
    );
  }

  /// 모바일: 커스텀 버튼
  Widget _buildMobileSignInButton() {
    return ElevatedButton.icon(
      onPressed: _handleMobileSignIn,
      icon: const Icon(Icons.login),
      label: const Text('Google로 로그인'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: 32,
          vertical: 16,
        ),
      ),
    );
  }
}
