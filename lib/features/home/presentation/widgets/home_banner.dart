//lib/features/home/presentation/widgets/home_banner.dart

import 'package:flutter/material.dart';
import 'package:pi_com/core/constants/routes.dart';
import '../../../../core/utils/responsive_helper.dart';

class HomeBanner extends StatefulWidget {
  const HomeBanner({super.key});

  @override
  State<HomeBanner> createState() => _HomeBannerState();
}

class _HomeBannerState extends State<HomeBanner> {
  int _current = 0;
  final PageController _controller = PageController();

  final List<Map<String, dynamic>> bannerItems = [
    {
      "title": "나만의 PC, 이제 안전하게 시작하세요",
      "description": "원하는 부품 먼저 결제! 안전 보관부터 일괄 배송까지 책임집니다.",
      "gradient": [Color(0xFF1976D2), Color(0xFF42A5F5)],
      "route": Routes.dragonBallStorage,
    },
    {
      "title": "중고 부품, 고장 걱정 없이 구매하세요",
      "description": "전문 엔지니어의 완벽한 테스트로 성능 보증까지 완료된 부품만 판매합니다.",
      "gradient": [Color(0xFF7B1FA2), Color(0xFFBA68C8)],
      "route": Routes.partShop,
    },
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final isTablet = ResponsiveHelper.isTablet(context);
    final screenWidth = MediaQuery.of(context).size.width;

    // 반응형 배너 높이
    final bannerHeight = isMobile ? 180.0 : isTablet ? 200.0 : 220.0;
    // 반응형 마진
    final horizontalMargin = isMobile ? 12.0 : 16.0;
    // 반응형 패딩
    final contentPadding = isMobile ? 16.0 : 24.0;
    // 반응형 폰트 크기
    final titleFontSize = isMobile ? 16.0 : isTablet ? 18.0 : 20.0;
    final descFontSize = isMobile ? 12.0 : isTablet ? 13.0 : 14.0;

    return Column(
      children: [
        SizedBox(
          height: bannerHeight,
          child: PageView.builder(
            controller: _controller,
            onPageChanged: (index) {
              setState(() {
                _current = index;
              });
            },
            itemCount: bannerItems.length,
            itemBuilder: (context, index) {
              final item = bannerItems[index];
              final route = item['route'] as String?;
              final gradient = item['gradient'] as List<Color>;

              return GestureDetector(
                onTap: route != null
                    ? () => Navigator.pushNamed(context, route)
                    : null,
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: horizontalMargin),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(contentPadding),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flexible(
                          child: Text(
                            item['title']!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: titleFontSize,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(height: isMobile ? 6 : 8),
                        Flexible(
                          child: Text(
                            item['description']!,
                            maxLines: isMobile ? 2 : 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: descFontSize,
                            ),
                          ),
                        ),
                        if (route != null) ...[
                          SizedBox(height: isMobile ? 8 : 12),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 10 : 12,
                              vertical: isMobile ? 4 : 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              '지금 시작하기',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isMobile ? 11 : 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: bannerItems.asMap().entries.map((entry) {
            return Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _current == entry.key
                    ? Colors.deepPurple
                    : Colors.grey[300],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
