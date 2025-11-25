//lib/features/home/presentation/widgets/circle_category.dart

import 'package:flutter/material.dart';
import '../../../../core/utils/responsive_helper.dart';

class CircleCategory extends StatelessWidget {
  final IconData iconData;
  final String label;
  final VoidCallback onTap;

  const CircleCategory({
    required this.iconData,
    required this.label,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final screenWidth = MediaQuery.of(context).size.width;

    // 반응형 크기 설정
    final containerWidth = screenWidth < 360 ? 64.0 : isMobile ? 72.0 : 80.0;
    final avatarRadius = screenWidth < 360 ? 24.0 : isMobile ? 26.0 : 30.0;
    final iconSize = screenWidth < 360 ? 22.0 : isMobile ? 26.0 : 30.0;
    final fontSize = screenWidth < 360 ? 10.0 : isMobile ? 11.0 : 12.0;
    final margin = screenWidth < 360 ? 2.0 : 4.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: containerWidth,
        margin: EdgeInsets.symmetric(horizontal: margin),
        color: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: avatarRadius,
              backgroundColor: Colors.grey[200],
              child: Icon(iconData, size: iconSize, color: Colors.black87),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(fontSize: fontSize),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
