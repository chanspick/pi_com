// lib/features/web_public/presentation/screens/landing_page.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/routes.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../shared/widgets/app_footer.dart';
import '../widgets/web_navbar_v2.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const WebNavBarV2(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 히어로 섹션
            _buildHeroSection(context),

            // 주요 기능 카드
            _buildFeaturesSection(context),

            // CTA 섹션
            _buildCTASection(context),

            // 푸터
            const AppFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    final isDesktop = ResponsiveHelper.isDesktop(context);

    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.getPagePadding(context),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor.withValues(alpha: 0.1),
            Colors.purple.withValues(alpha: 0.05),
          ],
        ),
      ),
      child: ResponsiveHelper.centeredMaxWidthContainer(
        context: context,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 80),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'PiCom',
                style: TextStyle(
                  fontSize: isDesktop ? 72 : 48,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Text(
                '중고 컴퓨터 부품 거래의 새로운 기준',
                style: TextStyle(
                  fontSize: isDesktop ? 28 : 20,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                '안전한 거래, 실시간 시세, 최적의 견적 추천까지',
                style: TextStyle(
                  fontSize: isDesktop ? 18 : 16,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // CTA 버튼
              Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => context.go(Routes.partShop),
                    icon: const Icon(Icons.shopping_cart),
                    label: const Text('부품 둘러보기'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 20,
                      ),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => context.go(Routes.myEstimate),
                    icon: const Icon(Icons.build),
                    label: const Text('견적 추천 받기'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 20,
                      ),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturesSection(BuildContext context) {
    return ResponsiveHelper.centeredMaxWidthContainer(
      context: context,
      child: Padding(
        padding: ResponsiveHelper.getPagePadding(context),
        child: Column(
          children: [
            const SizedBox(height: 40),
            const Text(
              '주요 기능',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 48),

            // 기능 카드 그리드
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = ResponsiveHelper.getGridCrossAxisCount(
                  context,
                  twoColumnOnMobile: false,
                );

                final features = [
                  _FeatureData(
                    icon: Icons.store,
                    title: '부품 마켓플레이스',
                    description: '다양한 중고 PC 부품을\n안전하게 거래하세요',
                    route: Routes.partShop,
                  ),
                  _FeatureData(
                    icon: Icons.trending_up,
                    title: '실시간 시세',
                    description: '부품별 실시간 가격을\n한눈에 확인하세요',
                    route: Routes.partsCategory,
                  ),
                  _FeatureData(
                    icon: Icons.computer,
                    title: '견적 추천',
                    description: 'AI 기반 최적의\nPC 조립 견적 추천',
                    route: Routes.myEstimate,
                  ),
                  _FeatureData(
                    icon: Icons.inventory_2,
                    title: 'PC 보관함',
                    description: '구매한 부품을 보관하고\n한번에 배송받으세요',
                    route: Routes.pcStorage,
                  ),
                  _FeatureData(
                    icon: Icons.sell,
                    title: '간편 판매',
                    description: '사용하지 않는 부품을\n빠르게 판매하세요',
                    route: Routes.sellRequest,
                  ),
                  _FeatureData(
                    icon: Icons.security,
                    title: '안전한 거래',
                    description: '카카오페이 결제로\n안전하게 거래하세요',
                    route: Routes.cart,
                  ),
                ];

                if (ResponsiveHelper.isMobile(context)) {
                  // 모바일: Column 레이아웃
                  return Column(
                    children: features
                        .map((feature) => Padding(
                              padding: const EdgeInsets.only(bottom: 24),
                              child: _buildFeatureCard(context, feature),
                            ))
                        .toList(),
                  );
                }

                // 데스크톱/태블릿: Grid 레이아웃
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount.clamp(1, 3),
                    childAspectRatio: 1.2,
                    crossAxisSpacing: 24,
                    mainAxisSpacing: 24,
                  ),
                  itemCount: features.length,
                  itemBuilder: (context, index) {
                    return _buildFeatureCard(context, features[index]);
                  },
                );
              },
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(BuildContext context, _FeatureData feature) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => context.go(feature.route),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                feature.icon,
                size: 56,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 20),
              Text(
                feature.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                feature.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCTASection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.getPagePadding(context).copyWith(
        top: 80,
        bottom: 80,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
      ),
      child: ResponsiveHelper.centeredMaxWidthContainer(
        context: context,
        child: Column(
          children: [
            const Text(
              '지금 바로 시작하세요',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              '회원가입하고 다양한 혜택을 받아보세요',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () => context.go(Routes.auth),
              icon: const Icon(Icons.person_add),
              label: const Text('무료 회원가입'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 48,
                  vertical: 24,
                ),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureData {
  final IconData icon;
  final String title;
  final String description;
  final String route;

  _FeatureData({
    required this.icon,
    required this.title,
    required this.description,
    required this.route,
  });
}
