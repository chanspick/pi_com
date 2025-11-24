//lib/features/home/presentation/widgets/home_banner.dart

import 'package:flutter/material.dart';
import 'package:pi_com/core/constants/routes.dart';

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
      "image": "assets/images/banner_pc_warranty_mobile.png",
      "route": Routes.dragonBallStorage,
    },
    {
      "image": "assets/images/banner_used_parts_mobile.png",
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
    // 화면 너비에 따른 배너 높이 계산
    final screenWidth = MediaQuery.of(context).size.width;
    final bannerWidth = screenWidth - 32; // 양쪽 마진 16씩
    final bannerHeight = bannerWidth * 0.4; // 5:2 비율

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
              final image = item['image'] as String;

              return GestureDetector(
                onTap: route != null
                    ? () => Navigator.pushNamed(context, route)
                    : null,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(
                    image,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: bannerHeight,
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
