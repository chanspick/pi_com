// lib/features/web_public/presentation/screens/about_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../../core/utils/responsive_helper.dart';
import '../widgets/web_navbar_v2.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: kIsWeb
          ? const WebNavBarV2()
          : AppBar(
              title: const Text('회사 소개'),
            ),
      body: ResponsiveHelper.centeredMaxWidthContainer(
        context: context,
        child: Padding(
          padding: ResponsiveHelper.getPagePadding(context),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '회사 소개',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 24),
              Text(
                'PiCom은 중고 컴퓨터 부품 거래를 위한 플랫폼입니다.\n'
                    '안전하고 편리한 거래 환경을 제공하여 사용자들이 신뢰할 수 있는\n'
                    '부품 매매 경험을 할 수 있도록 돕습니다.',
                style: TextStyle(fontSize: 16, height: 1.8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
