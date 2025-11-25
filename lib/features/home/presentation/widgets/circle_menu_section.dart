// lib/features/home/presentation/widgets/circle_menu_section.dart
import 'package:flutter/material.dart';
import 'circle_category.dart';
import '../../../../core/constants/routes.dart';
import '../../../../core/utils/responsive_helper.dart';

class CircleMenuSection extends StatelessWidget {
  const CircleMenuSection({super.key});

  static final _menuItems = [
    {
      'icon': Icons.shopping_cart_outlined,
      'label': '부품 샵',
      'route': Routes.partShop,
    },
    {
      'icon': Icons.trending_up,
      'label': '부품 시세',
      'route': Routes.partsCategory,
    },
    {
      'icon': Icons.inventory_2_outlined,
      'label': 'PC 보관함',
      'route': Routes.pcStorage,
    },
    {
      'icon': Icons.add_box_outlined,
      'label': '부품 판매',
      'route': Routes.sellRequest,
    },
    {
      'icon': Icons.desktop_windows,
      'label': '완제품 판매',
      'route': Routes.sellFinishedPc,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final screenWidth = MediaQuery.of(context).size.width;

    // 반응형 높이 및 패딩
    final sectionHeight = screenWidth < 360 ? 80.0 : isMobile ? 90.0 : 100.0;
    final horizontalPadding = screenWidth < 360 ? 8.0 : 12.0;

    return SizedBox(
      height: sectionHeight,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        itemCount: _menuItems.length,
        itemBuilder: (context, index) {
          final item = _menuItems[index];
          return CircleCategory(
            iconData: item['icon']! as IconData,
            label: item['label']! as String,
            onTap: () {
              final route = item['route'] as String?;
              if (route != null) {
                Navigator.of(context).pushNamed(route);
              } else {
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
