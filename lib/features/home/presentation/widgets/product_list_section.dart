// lib/features/home/presentation/widgets/product_list_section.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../listing/presentation/providers/listing_provider.dart';
import '../../../listing/presentation/widgets/listing_card.dart';
import '../../../../core/constants/routes.dart';
import '../../../../core/utils/responsive_helper.dart';

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

    final horizontalPadding = ResponsiveHelper.isDesktop(context)
        ? 80.0
        : ResponsiveHelper.isTablet(context)
            ? 40.0
            : 16.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
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
              // 🔍 디버그: Home 화면에 표시되는 listings 확인
              AppLogger.d('Loaded ${listings.length} listings', tag: 'Home');
              for (var listing in listings) {
                AppLogger.d('- ${listing.listingId}: ${listing.brand} ${listing.modelName}', tag: 'Home');
              }

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

              // 홈에서는 최대 4개만 표시하므로 열 개수를 적절히 조정
              // 모바일: 2열, 태블릿: 2열, 데스크톱: 4열
              final crossAxisCount = ResponsiveHelper.isDesktop(context)
                  ? 4
                  : 2;
              final spacing = ResponsiveHelper.isDesktop(context) ? 24.0 : 12.0;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: 0.7,
                  crossAxisSpacing: spacing,
                  mainAxisSpacing: spacing,
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
