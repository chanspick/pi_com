// lib/features/parts_price/presentation/screens/price_history_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/base_part_entity.dart';
import '../providers/part_provider.dart';
import '../widgets/price_history_chart.dart';
import '../../../listing/presentation/screens/listings_by_base_part_screen.dart';
import '../../../price_alert/presentation/widgets/price_alert_setup_dialog.dart';
import '../../../price_alert/presentation/providers/price_alert_provider.dart';

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
        actions: [
          // 가격 알림 설정 버튼
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: '가격 알림 설정',
            onPressed: () async {
              final actions = ref.read(priceAlertActionsProvider);
              if (actions == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('로그인이 필요합니다')),
                );
                return;
              }

              // 기존 알림 확인
              final existingAlert = await actions.getAlertForBasePart(basePart.basePartId);

              if (context.mounted) {
                await showDialog(
                  context: context,
                  builder: (context) => PriceAlertSetupDialog(
                    basePartId: basePart.basePartId,
                    partName: basePart.modelName,
                    currentPrice: basePart.lowestPrice,
                    existingAlert: existingAlert,
                  ),
                );
              }
            },
          ),
        ],
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
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.show_chart,
                                size: 64,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '아직 판매 완료된 거래가 없습니다',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '거래가 누적되면 가격 추이를 확인할 수 있습니다',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }
                      return PriceHistoryChart(priceHistory: priceHistory);
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, stack) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                          const SizedBox(height: 16),
                          Text(
                            '가격 정보를 불러올 수 없습니다',
                            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$error',
                            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
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
