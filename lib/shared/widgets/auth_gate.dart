// lib/shared/widgets/auth_gate.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';  // ✅ Riverpod import
import '../../features/auth/presentation/providers/auth_provider.dart';  // ✅ Provider import
import '../../features/auth/presentation/screens/auth_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';

/// 인증 상태에 따라 화면 분기
/// - 로그인 안 됨 → AuthScreen
/// - 로그인 됨 → HomeScreen
///
/// ⭐️ shared에 위치: auth + home 두 feature를 연결
class AuthGate extends ConsumerWidget {  // ✅ ConsumerWidget으로 변경
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {  // ✅ WidgetRef 추가
    // ✅ authStateChangesProvider 구독
    final authState = ref.watch(authStateChangesProvider);

    return authState.when(
      // 연결 대기 중
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      // 에러
      error: (error, stack) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('인증 오류: $error'),
            ],
          ),
        ),
      ),
      // 로그인 상태 확인
      data: (user) {
        if (user != null) {
          // 로그인 됨 → HomeScreen
          return const HomeScreen();
        } else {
          // 로그인 안 됨 → AuthScreen
          return const AuthScreen();
        }
      },
    );
  }
}
