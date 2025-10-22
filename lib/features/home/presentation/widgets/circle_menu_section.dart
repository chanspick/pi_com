import 'package:flutter/material.dart';
import 'circle_category.dart';

class CircleMenuSection extends StatelessWidget {
  const CircleMenuSection({super.key});

  static final _menuItems = [
    {
      'icon': Icons.settings,
      'label': '부품 샵',
    },
    {
      'icon': Icons.store,
      'label': '부품 시세',
    },
    {
      'icon': Icons.desktop_mac,
      'label': '나만의 PC',
    },
    {
      'icon': Icons.add_box_outlined,
      'label': '부품 판매',
    },
    {
      'icon': Icons.desktop_windows,
      'label': '완제품 판매',
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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${item['label']} 기능은 준비 중입니다.')),
              );
            },
          );
        },
      ),
    );
  }
}
