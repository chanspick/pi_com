// lib/features/auth/presentation/screens/auth_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';  // ✅ Riverpod import
import '../../../../shared/utils/snackbar_helper.dart';
import '../providers/auth_provider.dart';  // ✅ Provider import

/// 로그인 화면
/// - 익명 로그인
/// - Google 로그인
class AuthScreen extends ConsumerStatefulWidget {  // ✅ ConsumerStatefulWidget으로 변경
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();  // ✅ ConsumerState로 변경
}

class _AuthScreenState extends ConsumerState<AuthScreen> {  // ✅ ConsumerState<AuthScreen>으로 변경
  bool _isLoading = false;

  /// 익명 로그인 처리
  Future<void> _handleAnonymousSignIn() async {
    setState(() => _isLoading = true);
    try {
      // ✅ Use Case Provider 사용
      final useCase = ref.read(signInAnonymouslyUseCaseProvider);
      await useCase();

      if (!mounted) return;
      SnackbarHelper.showSuccess(
        context,
        '게스트로 로그인했습니다',
      );
    } catch (e) {
      if (!mounted) return;
      SnackbarHelper.showError(
        context,
        '익명 로그인 실패: ${e.toString()}',
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Google 로그인 처리
  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      // ✅ Use Case Provider 사용
      final useCase = ref.read(signInWithGoogleUseCaseProvider);
      await useCase();

      if (!mounted) return;
      SnackbarHelper.showSuccess(
        context,
        'Google 로그인 성공',
      );
    } catch (e) {
      if (!mounted) return;
      SnackbarHelper.showError(
        context,
        'Google 로그인 실패: ${e.toString()}',
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 로고
              const Icon(
                Icons.computer,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 24),

              // 앱 이름
              const Text(
                'PiCom',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '컴퓨터 부품 중고 거래 플랫폼',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 48),

              // Google 로그인 버튼
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _handleGoogleSignIn,
                  icon: const Icon(Icons.login),
                  label: const Text(
                    'Google로 로그인',
                    style: TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 익명 로그인 버튼
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _handleAnonymousSignIn,
                  icon: const Icon(Icons.person_outline),
                  label: const Text(
                    '게스트로 계속하기',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
