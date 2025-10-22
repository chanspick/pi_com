// lib/features/web_public/presentation/screens/terms_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('이용약관'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '이용약관',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 24),
            Text(
              '제1조 (목적)\n'
                  '본 약관은 PiCom(이하 "회사")이 제공하는 서비스의 이용과 관련하여\n'
                  '회사와 이용자의 권리, 의무 및 책임사항을 규정함을 목적으로 합니다.\n\n'
                  '제2조 (정의)\n'
                  '1. "서비스"란 회사가 제공하는 중고 컴퓨터 부품 거래 플랫폼을 의미합니다.\n'
                  '2. "이용자"란 본 약관에 따라 회사가 제공하는 서비스를 이용하는 자를 말합니다.\n\n'
                  '(추가 약관 내용은 사업자등록 후 보완 예정)',
              style: TextStyle(fontSize: 16, height: 1.8),
            ),
          ],
        ),
      ),
    );
  }
}
