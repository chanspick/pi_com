//lib/shared/widgets/app_footer.dart

import 'package:flutter/material.dart';

/// 전자상거래법 필수 정보 표시 Footer
/// 웹 배포 시 사업자등록에 필요
class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 회사명
          const Text(
            '(주) 파이컴퓨터',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),

          // 사업자 정보
          _buildInfoText('대표자: 최진규'), // ⭐️ 실제 이름으로 변경
          _buildInfoText('사업자등록번호: 207-87-03690'), // ⭐️ 실제 번호
          _buildInfoText('통신판매업 신고번호: 제XXXX-서울-XXXX호'), // ⭐️ 신고 후
          _buildInfoText('사업장 주소: 서울특별시 서대문구 연세로2나길 61'), // ⭐️ 실제 주소
          _buildInfoText('창천동 캠퍼스타운 에스큐브'), // ⭐️ 실제 주소

          _buildInfoText('대표전화: 02-XXXX-XXXX'),
          _buildInfoText('이메일: contact@picom.team'),

          const SizedBox(height: 12),

          // 호스팅 제공자
          _buildInfoText('호스팅 서비스 제공: Firebase (Google LLC)'),

          const SizedBox(height: 20),

          // 약관 링크
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildLinkButton(context, '이용약관'),
              _buildLinkButton(context, '개인정보처리방침'),
              _buildLinkButton(context, '환불정책'),
            ],
          ),

          const SizedBox(height: 20),

          // 저작권
          Text(
            '© 2025 PiCom. All rights reserved.',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  Widget _buildLinkButton(BuildContext context, String label) {
    return TextButton(
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$label 페이지는 준비 중입니다.')),
        );
      },
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: const Size(0, 0),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}
