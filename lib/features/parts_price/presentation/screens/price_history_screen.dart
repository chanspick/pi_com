// lib/features/parts_price/presentation/screens/price_history_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/base_part_entity.dart';
import '../providers/part_provider.dart';
import '../widgets/price_history_chart.dart';
import '../../../listing/presentation/screens/listings_by_base_part_screen.dart';

class PriceHistoryScreen extends ConsumerWidget {
  final BasePartEntity basePart;

  const PriceHistoryScreen({super.key, required this.basePart});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final priceHistoryAsync = ref.watch(priceHistoryFutureProvider(basePart.basePartId));
    final formatter = NumberFormat('#,###');

    return Scaffold(
      appBar: AppBar(
        title: Text(basePart.modelName),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 기본 정보
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      basePart.category.toUpperCase(),
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      basePart.modelName,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '최저가',
                              style: TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                            Text(
                              basePart.priceRangeText,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              '평균가',
                              style: TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                            Text(
                              '${formatter.format(basePart.averagePrice.toInt())}원',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.storefront_outlined, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${basePart.listingCount}개 매물',
                          style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 가격 추이 그래프
            const Text(
              '가격 추이',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  height: 250,
                  child: priceHistoryAsync.when(
                    data: (priceHistory) {
                      if (priceHistory.isEmpty) {
                        return const Center(
                          child: Text('가격 데이터가 충분하지 않습니다.'),
                        );
                      }
                      return PriceHistoryChart(priceHistory: priceHistory);
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, stack) => Center(
                      child: Text('오류: $error'),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 매물 보기 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ListingsByBasePartScreen(
                        basePartId: basePart.basePartId,
                        partName: basePart.modelName,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.shopping_cart),
                label: const Text('매물 보기'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
