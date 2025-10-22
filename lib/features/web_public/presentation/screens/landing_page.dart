// lib/features/web_public/presentation/screens/landing_page.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; // 🆕 추가

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PiCom', style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        )),
        actions: [
          TextButton(
            onPressed: () {
              context.go('/about'); // 🔧 GoRouter 사용
            },
            child: const Text('회사 소개'),
          ),
          TextButton(
            onPressed: () {
              context.go('/terms'); // 🔧 GoRouter 사용
            },
            child: const Text('이용약관'),
          ),
          TextButton(
            onPressed: () {
              context.go('/privacy'); // 🔧 GoRouter 사용
            },
            child: const Text('개인정보처리방침'),
          ),
          // 🆕 Admin 버튼 (아이콘만, 작게)
          IconButton(
            onPressed: () {
              context.go('/admin'); // Admin 로그인으로 이동
            },
            icon: Icon(Icons.admin_panel_settings, color: Colors.grey[600]),
            tooltip: 'Admin',
            iconSize: 20, // 작게
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 히어로 섹션
            Container(
              width: double.infinity,
              height: 500,
              color: Colors.deepPurple[50],
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'PiCom',
                      style: TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '중고 컴퓨터 부품 거래 플랫폼',
                      style: TextStyle(
                        fontSize: 24,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.download),
                      label: const Text('앱 다운로드 (준비 중)'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 48,
                          vertical: 20,
                        ),
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 서비스 소개
            Container(
              padding: const EdgeInsets.all(64),
              child: Column(
                children: [
                  const Text(
                    '서비스 소개',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 48),
                  Wrap(
                    spacing: 32,
                    runSpacing: 32,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildFeatureCard(
                        icon: Icons.computer,
                        title: '부품 거래',
                        description: '안전하고 편리한\n중고 부품 거래',
                      ),
                      _buildFeatureCard(
                        icon: Icons.trending_up,
                        title: '실시간 시세',
                        description: '정확한 부품\n시세 정보 제공',
                      ),
                      _buildFeatureCard(
                        icon: Icons.build,
                        title: 'PC 조립',
                        description: '최적의 조립\n견적 추천',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Footer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(48),
              color: Colors.grey[100],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    '사업자 정보',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('상호: (사업자등록 후 업데이트 예정)'),
                  const Text('대표: (사업자등록 후 업데이트 예정)'),
                  const Text('사업자등록번호: (사업자등록 후 업데이트 예정)'),
                  const Text('통신판매업신고번호: (신고 후 업데이트 예정)'),
                  const Text('주소: (사업자등록 후 업데이트 예정)'),
                  const Text('이메일: contact@picom.com'),
                  const SizedBox(height: 24),
                  Text(
                    'Copyright © 2025 PiCom. All rights reserved.',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  // 🆕 숨겨진 Admin 링크 (Footer 맨 아래)
                  TextButton(
                    onPressed: () {
                      context.go('/admin');
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[400],
                      textStyle: const TextStyle(fontSize: 10),
                    ),
                    child: const Text('Admin'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return SizedBox(
      width: 250,
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(icon, size: 64, color: Colors.deepPurple),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
