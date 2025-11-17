//lib/shared/widgets/app_footer.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/routes.dart';

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
          _buildInfoText('통신판매업 신고번호: 2025-서울서대문-1006'),
          _buildInfoText('사업장 주소: 서울특별시 서대문구 연세로2나길 61'), // ⭐️ 실제 주소
          _buildInfoText('창천동 캠퍼스타운 에스큐브'), // ⭐️ 실제 주소

          _buildInfoText('대표전화: 02-6402-0025'),
          _buildInfoText('이메일: wlsrb00g@gmail.com'),

          const SizedBox(height: 12),

          // 호스팅 제공자
          _buildInfoText('호스팅 서비스 제공: Firebase (Google LLC)'),

          const SizedBox(height: 20),

          // 약관 링크
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildLinkButton(context, '이용약관', 'termsofuse.html'),
              _buildLinkButton(context, '개인정보처리방침', 'privacy_policy.html'),
              _buildLinkButton(context, '환불정책', 'refund.html'),
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

  Widget _buildLinkButton(BuildContext context, String label, String htmlFile) {
    return TextButton(
      onPressed: () async {
        if (kIsWeb) {
          // 웹에서는 HTML 파일로 직접 이동
          // Uri.base는 현재 URL (예: http://localhost:8081/)
          final currentUrl = Uri.base;
          final targetUrl = currentUrl.replace(path: '/$htmlFile');

          // 현재 탭에서 HTML 페이지 열기
          await launchUrl(
            targetUrl,
            webOnlyWindowName: '_self', // 현재 탭에서 열기
          );
        } else {
          // 모바일에서는 라우트 사용
          String route = Routes.privacy;
          if (htmlFile.contains('terms')) {
            route = Routes.terms;
          } else if (htmlFile.contains('refund')) {
            route = Routes.refund;
          }
          Navigator.pushNamed(context, route);
        }
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
