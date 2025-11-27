// lib/features/listing/presentation/screens/listings_by_base_part_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/listing_provider.dart';
import '../widgets/listing_card.dart';

/// basePartId로 필터링된 매물 목록 화면
class ListingsByBasePartScreen extends ConsumerWidget {
  final String basePartId;
  final String partName;

  const ListingsByBasePartScreen({
    super.key,
    required this.basePartId,
    required this.partName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingsAsync = ref.watch(listingsByBasePartIdProvider(basePartId));

    return Scaffold(
      appBar: AppBar(
        title: Text(partName),
      ),
      body: listingsAsync.when(
        data: (listings) {
          if (listings.isEmpty) {
            return _buildEmptyState(context);
          }

          return Column(
            children: [
              // 매물 개수 표시
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Colors.grey[100],
                child: Text(
                  '총 ${listings.length}개의 매물',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),

              // 매물 목록
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.7,
                  ),
                  itemCount: listings.length,
                  itemBuilder: (context, index) {
                    final listing = listings[index];
                    return ListingCard(listing: listing);
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('오류: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(listingsByBasePartIdProvider(basePartId));
                },
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            '등록된 매물이 없습니다',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            '현재 판매 중인 $partName 매물이 없습니다',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
