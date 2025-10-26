// lib/features/sell_request/presentation/screens/part_search_screen.dart

import 'package:flutter/material.dart';
import '../../../../core/models/base_part_model.dart';

/// 임시 부품 검색 화면 (TODO: Algolia 또는 자체 검색 구현 예정)
class PartSearchScreen extends StatelessWidget {
  const PartSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('부품 검색'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              '부품 검색 기능 개발 중',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Algolia 또는 자체 검색 구현 예정',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),

            // 임시 테스트용 더미 부품 선택 버튼
            ElevatedButton(
              onPressed: () {
                // 더미 BasePart 반환 (테스트용)
                final dummyPart = BasePart(
                  basePartId: 'test-cpu-001',
                  modelName: 'Intel Core i7-13700K (테스트)',
                  category: 'CPU',
                  lowestPrice: 450000,
                  averagePrice: 480000,
                  listingCount: 12,
                );
                Navigator.pop(context, dummyPart);
              },
              child: const Text('테스트용 더미 부품 선택'),
            ),
          ],
        ),
      ),
    );
  }
}
