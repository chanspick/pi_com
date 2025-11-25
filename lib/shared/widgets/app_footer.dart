//lib/shared/widgets/app_footer.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/routes.dart';
import '../../core/utils/responsive_helper.dart';

/// 전자상거래법 필수 정보 표시 Footer
/// 웹 배포 시 사업자등록에 필요
class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final padding = isMobile ? 16.0 : 24.0;
    final titleFontSize = isMobile ? 14.0 : 16.0;
    final infoFontSize = isMobile ? 11.0 : 13.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(padding),
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
          Text(
            '(주) 파이컴퓨터',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: titleFontSize,
            ),
          ),
          SizedBox(height: isMobile ? 12 : 16),

          // 사업자 정보
          _buildInfoText('대표자: 최진규', infoFontSize),
          _buildInfoText('사업자등록번호: 207-87-03690', infoFontSize),
          _buildInfoText('통신판매업 신고번호: 2025-서울서대문-1006', infoFontSize),
          _buildInfoText('사업장 주소: 서울특별시 서대문구 연세로2나길 61', infoFontSize),
          _buildInfoText('창천동 캠퍼스타운 에스큐브', infoFontSize),
          _buildInfoText('대표전화: 02-6402-0025', infoFontSize),
          _buildInfoText('이메일: wlsrb00g@gmail.com', infoFontSize),

          SizedBox(height: isMobile ? 8 : 12),

          // 호스팅 제공자
          _buildInfoText('호스팅 서비스 제공: Firebase (Google LLC)', infoFontSize),

          SizedBox(height: isMobile ? 16 : 20),

          // 약관 링크
          Wrap(
            spacing: isMobile ? 12 : 16,
            runSpacing: 8,
            children: [
              _buildLinkButton(context, '이용약관', 'termsofuse.html', isMobile),
              _buildLinkButton(context, '개인정보처리방침', 'privacy_policy.html', isMobile),
              _buildLinkButton(context, '환불정책', 'refund.html', isMobile),
            ],
          ),

          SizedBox(height: isMobile ? 16 : 20),

          // 저작권
          Text(
            '© 2025 PiCom. All rights reserved.',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: isMobile ? 10 : 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoText(String text, double fontSize) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        softWrap: true,
        overflow: TextOverflow.visible,
        style: TextStyle(
          fontSize: fontSize,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  Widget _buildLinkButton(BuildContext context, String label, String htmlFile, bool isMobile) {
    return TextButton(
      onPressed: () async {
        if (kIsWeb) {
          // 웹에서는 HTML 파일로 직접 이동
          final currentUrl = Uri.base;
          final targetUrl = currentUrl.replace(path: '/$htmlFile');

          // 현재 탭에서 HTML 페이지 열기
          await launchUrl(
            targetUrl,
            webOnlyWindowName: '_self',
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
        style: TextStyle(
          fontSize: isMobile ? 11 : 13,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}
