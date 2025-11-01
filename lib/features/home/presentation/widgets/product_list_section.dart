// lib/features/home/presentation/widgets/product_list_section.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../listing/presentation/providers/listing_provider.dart';
import '../../../listing/presentation/widgets/listing_card.dart';
import '../../../../core/constants/routes.dart';

class ProductListSection extends ConsumerWidget {
  const ProductListSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 최신 매물 가져오기 (최대 4개만)
    final listingsAsync = ref.watch(
      listingsFutureProvider(
        ListingQueryParams(category: null, sortBy: '최신순'),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '최신 상품',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushNamed(Routes.partShop);
                },
                child: const Text('더보기'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Listing 데이터 표시
          listingsAsync.when(
            data: (listings) {
              if (listings.isEmpty) {
                // 기존 empty state 유지
                return Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '등록된 제품이 없습니다',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '판매할 부품을 등록해보세요!',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                );
              }

              // 최대 4개만 표시
              final displayListings = listings.take(4).toList();

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: displayListings.length,
                itemBuilder: (context, index) {
                  return ListingCard(listing: displayListings[index]);
                },
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, stack) {
              // 에러 발생 시 기존 empty state 표시
              return Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '데이터를 불러올 수 없습니다',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        // 재시도
                        ref.invalidate(listingsFutureProvider(ListingQueryParams(category: null, sortBy: '최신순')));
                      },
                      child: const Text('다시 시도'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
