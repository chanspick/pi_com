// lib/features/home/presentation/widgets/circle_menu_section.dart
import 'package:flutter/material.dart';
import 'circle_category.dart';
import '../../../../core/constants/routes.dart';

class CircleMenuSection extends StatelessWidget {
  const CircleMenuSection({super.key});

  static final _menuItems = [
    {
      'icon': Icons.shopping_cart_outlined,  // ✅ 아이콘 변경
      'label': '부품 샵',
      'route': Routes.partShop,  // ✅ 새로 추가한 라우트 연결
    },
    {
      'icon': Icons.trending_up,  // ✅ 아이콘 변경
      'label': '부품 시세',
      'route': Routes.partsCategory,  // ✅ 새로 추가한 라우트 연결
    },
    {
      'icon': Icons.desktop_mac,
      'label': '나만의 PC',
      'route': null, // 준비 중
    },
    {
      'icon': Icons.add_box_outlined,
      'label': '부품 판매',
      'route': Routes.sellRequest, // ✅ 연결!
    },
    {
      'icon': Icons.desktop_windows,
      'label': '완제품 판매',
      'route': Routes.sellFinishedPc, // ✅ 연결!
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _menuItems.length,
        itemBuilder: (context, index) {
          final item = _menuItems[index];
          return CircleCategory(
            iconData: item['icon']! as IconData,
            label: item['label']! as String,
            onTap: () {
              final route = item['route'] as String?;
              if (route != null) {
                // 라우트가 있으면 이동
                Navigator.of(context).pushNamed(route);
              } else {
                // 준비 중
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${item['label']} 기능은 준비 중입니다.')),
                );
              }
            },
          );
        },
      ),
    );
  }
}
