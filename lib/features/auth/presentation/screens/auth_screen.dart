// lib/features/auth/presentation/screens/auth_screen.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/utils/snackbar_helper.dart';
import '../providers/auth_provider.dart';
import 'auth_screen_html_web.dart' if (dart.library.io) 'auth_screen_html_mobile.dart';

/// 로그인 화면
/// - 카카오 로그인 (간편 로그인)
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isLoading = false;
  bool _showEmailLogin = false;
  bool _isSignUp = false;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // 웹에서만 localStorage 체크
    if (kIsWeb) {
      _checkLocalStorageForKakaoCode();
    }
  }

  /// localStorage에서 카카오 인가 코드 체크 (리다이렉트 폴백용)
  Future<void> _checkLocalStorageForKakaoCode() async {
    try {
      final code = htmlStorage['kakao_auth_code'];

      if (code != null && code.isNotEmpty) {
        print('🔍 Found Kakao auth code in localStorage: ${code.substring(0, 20)}...');

        // localStorage에서 코드 삭제 (중복 처리 방지)
        htmlStorage.remove('kakao_auth_code');

        // 자동 로그인 처리
        await _handleKakaoSignInWithCode(code);
      }
    } catch (e) {
      print('❌ Failed to check localStorage: $e');
    }
  }

  /// 카카오 인가 코드로 로그인 (리다이렉트 방식)
  Future<void> _handleKakaoSignInWithCode(String code) async {
    setState(() => _isLoading = true);
    try {
      print('🔍 Processing Kakao login with code from localStorage...');

      // Repository를 통해 로그인 처리
      final authRepository = ref.read(authRepositoryProvider);
      await authRepository.signInWithKakaoCode(code);

      if (!mounted) return;
      SnackbarHelper.showSuccess(
        context,
        '카카오 로그인 성공',
      );

      // 홈으로 리다이렉트
      if (kIsWeb) {
        context.go('/');
      } else {
        Navigator.of(context).pushReplacementNamed('/');
      }
    } catch (e) {
      if (!mounted) return;
      SnackbarHelper.showError(
        context,
        '카카오 로그인 실패: ${e.toString()}',
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// 카카오 로그인 처리
  Future<void> _handleKakaoSignIn() async {
    setState(() => _isLoading = true);
    try {
      final useCase = ref.read(signInWithKakaoUseCaseProvider);
      await useCase();

      if (!mounted) return;
      SnackbarHelper.showSuccess(
        context,
        '카카오 로그인 성공',
      );

      // 홈으로 리다이렉트
      if (kIsWeb) {
        context.go('/');
      } else {
        Navigator.of(context).pushReplacementNamed('/');
      }
    } catch (e) {
      if (!mounted) return;
      SnackbarHelper.showError(
        context,
        '카카오 로그인 실패: ${e.toString()}',
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// 이메일 로그인 처리
  Future<void> _handleEmailSignIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final useCase = ref.read(signInWithEmailUseCaseProvider);
      await useCase(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;
      SnackbarHelper.showSuccess(
        context,
        '이메일 로그인 성공',
      );

      // 홈으로 리다이렉트
      if (kIsWeb) {
        context.go('/');
      } else {
        Navigator.of(context).pushReplacementNamed('/');
      }
    } catch (e) {
      if (!mounted) return;
      SnackbarHelper.showError(
        context,
        '이메일 로그인 실패: ${e.toString()}',
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// 이메일 회원가입 처리
  Future<void> _handleEmailSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final useCase = ref.read(signUpWithEmailUseCaseProvider);
      await useCase(
        _emailController.text.trim(),
        _passwordController.text,
        _nameController.text.trim(),
      );

      if (!mounted) return;
      SnackbarHelper.showSuccess(
        context,
        '회원가입 성공',
      );

      // 홈으로 리다이렉트
      if (kIsWeb) {
        context.go('/');
      } else {
        Navigator.of(context).pushReplacementNamed('/');
      }
    } catch (e) {
      if (!mounted) return;
      SnackbarHelper.showError(
        context,
        '회원가입 실패: ${e.toString()}',
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
      body: Stack(
        children: [
          // 메인 로그인 화면
          Center(
            child: _isLoading
                ? const CircularProgressIndicator()
                : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height - 48,
                  ),
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

              // 카카오 로그인 버튼 (공식 디자인 가이드 준수)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _handleKakaoSignIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFEE500), // 카카오 노란색
                    foregroundColor: Colors.black.withOpacity(0.85), // 검은색 85%
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12), // 12픽셀 radius
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 카카오 심볼 (말풍선)
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.chat_bubble,
                            size: 14,
                            color: const Color(0xFFFEE500),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // 레이블
                      Text(
                        '카카오 로그인',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black.withOpacity(0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 구분선 또는 이메일 로그인 토글 버튼
              if (!_showEmailLogin) ...[
                const Text(
                  '카카오 계정으로 간편하게 시작하세요',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _showEmailLogin = true;
                    });
                  },
                  child: const Text(
                    '이메일로 로그인',
                    style: TextStyle(
                      fontSize: 14,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],

              // 이메일 로그인 폼
              if (_showEmailLogin) ...[
                const Divider(height: 32),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // 회원가입일 때만 이름 필드 표시
                      if (_isSignUp) ...[
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: '이름',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                          ),
                          validator: (value) {
                            if (_isSignUp && (value == null || value.trim().isEmpty)) {
                              return '이름을 입력해주세요';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                      ],

                      // 이메일 필드
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: '이메일',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '이메일을 입력해주세요';
                          }
                          if (!value.contains('@')) {
                            return '올바른 이메일 형식이 아닙니다';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // 비밀번호 필드
                      TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(
                          labelText: '비밀번호',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.lock),
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '비밀번호를 입력해주세요';
                          }
                          if (_isSignUp && value.length < 6) {
                            return '비밀번호는 6자 이상이어야 합니다';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // 로그인/회원가입 버튼
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isSignUp ? _handleEmailSignUp : _handleEmailSignIn,
                          child: Text(
                            _isSignUp ? '회원가입' : '로그인',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // 로그인/회원가입 전환 버튼
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _isSignUp ? '이미 계정이 있으신가요?' : '계정이 없으신가요?',
                            style: const TextStyle(fontSize: 14),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _isSignUp = !_isSignUp;
                                _formKey.currentState?.reset();
                              });
                            },
                            child: Text(
                              _isSignUp ? '로그인' : '회원가입',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // 카카오 로그인으로 돌아가기
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _showEmailLogin = false;
                            _isSignUp = false;
                            _formKey.currentState?.reset();
                          });
                        },
                        child: const Text(
                          '← 카카오 로그인으로 돌아가기',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
                  ),
                ),
              ),
            ),
          ),

          // Admin 숨겨진 버튼 (왼쪽 위)
          if (kIsWeb)
            Positioned(
              top: 16,
              left: 16,
              child: IconButton(
                icon: Icon(
                  Icons.shield,
                  color: Colors.grey.withOpacity(0.3),
                  size: 20,
                ),
                onPressed: () {
                  context.go('/admin');
                },
                tooltip: 'Admin',
              ),
            ),
        ],
      ),
    );
  }
}
