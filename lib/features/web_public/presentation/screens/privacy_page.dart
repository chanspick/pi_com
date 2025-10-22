// lib/features/web_public/presentation/screens/privacy_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('개인정보처리방침'),
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
              '개인정보처리방침',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 24),
            Text(
              '1. 개인정보의 수집 및 이용 목적\n'
                  '회사는 다음의 목적을 위하여 개인정보를 처리합니다:\n'
                  '- 회원 가입 및 관리\n'
                  '- 서비스 제공\n'
                  '- 거래 안전성 확보\n\n'
                  '2. 수집하는 개인정보 항목\n'
                  '- 필수항목: 이메일, 닉네임\n'
                  '- 선택항목: 프로필 사진\n\n'
                  '3. 개인정보의 보유 및 이용기간\n'
                  '회원 탈퇴 시까지 보유하며, 관계 법령에 따라 보존이 필요한 경우\n'
                  '해당 기간 동안 보관합니다.\n\n'
                  '(추가 방침 내용은 사업자등록 후 보완 예정)',
              style: TextStyle(fontSize: 16, height: 1.8),
            ),
          ],
        ),
      ),
    );
  }
}
