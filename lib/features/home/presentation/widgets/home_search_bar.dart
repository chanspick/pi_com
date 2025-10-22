//lib/features/home/presentation/widgets/home_search_bar.dart

import 'package:flutter/material.dart';

class HomeSearchBar extends StatelessWidget {
  const HomeSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _navigateToSearch(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).splashColor,
          borderRadius: BorderRadius.circular(30),
        ),
        child: const Row(
          children: [
            Icon(Icons.search, color: Colors.grey),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                '상품을 검색하세요',
                style: TextStyle(color: Colors.grey, fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToSearch(BuildContext context) {
    // TODO: SearchScreen 구현 후 연결
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('검색 기능은 준비 중입니다.')),
    );
  }
}
