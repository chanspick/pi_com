// lib/features/listing/presentation/screens/part_shop_screen_enhanced.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/listing_provider.dart';
import '../widgets/listing_card.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../web_public/presentation/widgets/web_navbar_v2.dart';

/// URL 파라미터를 지원하는 개선된 PartShopScreen
class PartShopScreenEnhanced extends ConsumerStatefulWidget {
  final String? initialCategory; // GoRouter에서 전달받을 카테고리

  const PartShopScreenEnhanced({
    super.key,
    this.initialCategory,
  });

  @override
  ConsumerState<PartShopScreenEnhanced> createState() =>
      _PartShopScreenEnhancedState();
}

class _PartShopScreenEnhancedState
    extends ConsumerState<PartShopScreenEnhanced> {
  @override
  void initState() {
    super.initState();
    // URL 파라미터로 받은 카테고리 설정
    _initializeCategory();
  }

  void _initializeCategory() {
    if (kIsWeb) {
      // 웹에서 URL 파라미터 파싱
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final uri = Uri.base;
        final category = uri.queryParameters['category'];

        if (category != null) {
          // 카테고리 매핑 (영문 -> 한글)
          final mappedCategory = _mapCategoryFromUrl(category);
          ref.read(selectedCategoryProvider.notifier).state = mappedCategory;
        } else if (widget.initialCategory != null) {
          // GoRouter에서 전달된 초기 카테고리
          final mappedCategory = _mapCategoryFromUrl(widget.initialCategory!);
          ref.read(selectedCategoryProvider.notifier).state = mappedCategory;
        }
      });
    }
  }

  String _mapCategoryFromUrl(String urlCategory) {
    // URL 파라미터를 내부 카테고리명으로 매핑
    switch (urlCategory.toLowerCase()) {
      case 'cpu':
        return 'CPU';
      case 'gpu':
        return 'GPU';
      case 'ram':
        return 'RAM';
      case 'mainboard':
      case 'motherboard':
        return 'mainboard';
      case 'ssd':
      case 'storage':
        return '저장장치';
      case 'psu':
      case 'power':
        return '파워';
      default:
        return 'All';
    }
  }

  String _getCategoryForUrl(String displayCategory) {
    // 내부 카테고리명을 URL용으로 변환
    switch (displayCategory) {
      case 'CPU':
        return 'cpu';
      case 'GPU':
        return 'gpu';
      case 'RAM':
        return 'ram';
      case 'mainboard':
        return 'mainboard';
      case '저장장치':
        return 'ssd';
      case '파워':
        return 'psu';
      case 'All':
      case '전체':
        return '';
      default:
        return '';
    }
  }

  void _updateUrlWithCategory(String category) {
    if (kIsWeb) {
      // URL 업데이트 (브라우저 히스토리 관리)
      final urlCategory = _getCategoryForUrl(category);
      final newPath = urlCategory.isEmpty
          ? '/part-shop'
          : '/part-shop?category=$urlCategory';

      // GoRouter를 통한 URL 업데이트
      if (context.mounted) {
        context.go(newPath);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final selectedSort = ref.watch(selectedSortProvider);

    final listingsAsync = ref.watch(
      listingsFutureProvider(
        ListingQueryParams(category: selectedCategory, sortBy: selectedSort),
      ),
    );

    return Scaffold(
      appBar: kIsWeb
          ? const WebNavBarV2()
          : AppBar(
              title: Text(
                selectedCategory == 'All'
                    ? '부품 스토어'
                    : '$selectedCategory 부품',
              ),
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    // 검색 기능 구현 예정
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('검색 기능 준비 중')),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.shopping_cart_outlined),
                  onPressed: () {
                    context.go('/cart');
                  },
                ),
              ],
            ),
      body: Column(
        children: [
          _buildFilterRow(context, ref),
          const Divider(height: 1),
          Expanded(
            child: listingsAsync.when(
              data: (listings) {
                if (listings.isEmpty) {
                  return _buildEmptyState(context, selectedCategory);
                }

                return ResponsiveHelper.centeredMaxWidthContainer(
                  context: context,
                  child: RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(
                        listingsFutureProvider(
                          ListingQueryParams(
                            category: selectedCategory,
                            sortBy: selectedSort,
                          ),
                        ),
                      );
                    },
                    child: Column(
                      children: [
                        // 결과 카운트
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          color: Colors.grey[50],
                          child: Text(
                            '${listings.length}개의 상품',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Expanded(
                          child: GridView.builder(
                            padding:
                                ResponsiveHelper.getHorizontalPadding(context)
                                    .copyWith(
                              top: 16,
                              bottom: 16,
                            ),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount:
                                  ResponsiveHelper.getGridCrossAxisCount(
                                      context),
                              childAspectRatio: 0.7,
                              crossAxisSpacing:
                                  ResponsiveHelper.isDesktop(context) ? 24 : 12,
                              mainAxisSpacing:
                                  ResponsiveHelper.isDesktop(context) ? 24 : 12,
                            ),
                            itemCount: listings.length,
                            itemBuilder: (context, index) {
                              return ListingCard(listing: listings[index]);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => _buildErrorState(context, ref, error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow(BuildContext context, WidgetRef ref) {
    final categories = ['All', 'CPU', 'GPU', 'RAM', 'mainboard', '저장장치', '파워', '기타'];
    final sortOptions = ['최신순', '낮은 가격순', '높은 가격순', '인기순'];

    final selectedCategory = ref.watch(selectedCategoryProvider);
    final selectedSort = ref.watch(selectedSortProvider);

    final isMobile = ResponsiveHelper.isMobile(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 16,
        vertical: 12,
      ),
      color: Colors.white,
      child: Column(
        children: [
          // 카테고리 필터
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = selectedCategory == category;

                return Padding(
                  padding: EdgeInsets.only(
                    left: index == 0 ? 0 : 4,
                    right: 4,
                  ),
                  child: FilterChip(
                    label: Text(
                      category == 'All' ? '전체' : (category == 'mainboard' ? '메인보드' : category),
                      style: TextStyle(
                        fontSize: isMobile ? 13 : 14,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        ref.read(selectedCategoryProvider.notifier).state = category;
                        _updateUrlWithCategory(category);
                      }
                    },
                    backgroundColor: Colors.grey[100],
                    selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                    checkmarkColor: Theme.of(context).primaryColor,
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 12 : 16,
                      vertical: 0,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          // 정렬 옵션
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '정렬',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedSort,
                    items: sortOptions.map((option) {
                      return DropdownMenuItem(
                        value: option,
                        child: Text(
                          option,
                          style: const TextStyle(fontSize: 14),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        ref.read(selectedSortProvider.notifier).state = value;
                      }
                    },
                    icon: const Icon(Icons.arrow_drop_down, size: 20),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String selectedCategory) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            selectedCategory == 'All'
                ? '판매중인 상품이 없습니다'
                : '$selectedCategory 카테고리에 상품이 없습니다',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '다른 카테고리를 확인해보세요',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              ref.read(selectedCategoryProvider.notifier).state = 'All';
              _updateUrlWithCategory('All');
            },
            icon: const Icon(Icons.refresh),
            label: const Text('전체 상품 보기'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[300],
          ),
          const SizedBox(height: 16),
          Text(
            '오류가 발생했습니다',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              ref.invalidate(
                listingsFutureProvider(
                  ListingQueryParams(
                    category: ref.read(selectedCategoryProvider),
                    sortBy: ref.read(selectedSortProvider),
                  ),
                ),
              );
            },
            icon: const Icon(Icons.refresh),
            label: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }
}