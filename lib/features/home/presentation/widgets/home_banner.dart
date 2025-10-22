//lib/features/home/presentation/widgets/home_banner.dart

import 'package:flutter/material.dart';

class HomeBanner extends StatefulWidget {
  const HomeBanner({super.key});

  @override
  State<HomeBanner> createState() => _HomeBannerState();
}

class _HomeBannerState extends State<HomeBanner> {
  int _current = 0;
  final PageController _controller = PageController();

  final List<Map<String, String>> bannerItems = [
    {
      "title": "신뢰의 시작, PiCom 보증",
      "description": "엄격한 검수를 통과한 중고 컴퓨터, 안심하고 구매하세요.",
      "color": "purple",
    },
    {
      "title": "어떤 컴퓨터를 살지 고민되나요?",
      "description": "PiCom의 전문가가 당신에게 딱 맞는 PC를 찾아드립니다.",
      "color": "blue",
    },
    {
      "title": "PiCom이 처음이라면?",
      "description": "바로 거래 가이드라인 확인!",
      "color": "green",
    },
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 200,
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
              final color = item['color'] == 'purple'
                  ? Colors.deepPurple
                  : item['color'] == 'blue'
                  ? Colors.blue
                  : Colors.green;

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color,
                      color.withValues(alpha: 0.7),
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['title']!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item['description']!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
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
