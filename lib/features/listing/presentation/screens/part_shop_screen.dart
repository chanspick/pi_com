// lib/features/listing/presentation/screens/part_shop_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/listing_provider.dart';
import '../widgets/listing_card.dart';
import '../../../../core/constants/routes.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../web_public/presentation/widgets/web_navbar_v2.dart';
import '../../../parts_price/presentation/providers/part_provider.dart';

/// URL 파라미터를 지원하는 개선된 PartShopScreen
class PartShopScreen extends ConsumerStatefulWidget {
  final String? initialCategory; // GoRouter에서 전달받을 카테고리
  final String? initialBasePartSearch; // ✅ GoRouter에서 전달받을 검색어

  const PartShopScreen({
    super.key,
    this.initialCategory,
    this.initialBasePartSearch, // ✅ 추가
  });

  @override
  ConsumerState<PartShopScreen> createState() =>
      _PartShopScreenState();
}

class _PartShopScreenState
    extends ConsumerState<PartShopScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  // 이전 검색어를 저장하여 변경 여부 확인
  String? _previousBasePartSearch;
  String? _previousCategory;

  @override
  void initState() {
    super.initState();
    _previousBasePartSearch = widget.initialBasePartSearch;
    _previousCategory = widget.initialCategory;
    // URL 파라미터로 받은 카테고리 및 검색어 설정
    _initializeCategory();
    // 무한 스크롤 리스너 추가
    _scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant PartShopScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // URL 파라미터가 변경되었는지 확인
    final searchChanged = widget.initialBasePartSearch != _previousBasePartSearch;
    final categoryChanged = widget.initialCategory != _previousCategory;

    if (searchChanged || categoryChanged) {
      _previousBasePartSearch = widget.initialBasePartSearch;
      _previousCategory = widget.initialCategory;
      // 검색어 또는 카테고리가 변경되면 다시 초기화
      _initializeCategory();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// 무한 스크롤 핸들러
  void _onScroll() {
    if (_isLoadingMore) return;

    // 스크롤이 80% 이상일 때 다음 페이지 로드
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadMore();
    }
  }

  /// 다음 페이지 로드
  void _loadMore() {
    final selectedBasePartIds = ref.read(selectedBasePartIdsProvider);

    // basePartIds 검색이 아닐 때만 페이지네이션 적용
    if (selectedBasePartIds.isEmpty) {
      final selectedCategory = ref.read(selectedCategoryProvider);
      final selectedSort = ref.read(selectedSortProvider);
      final searchQuery = ref.read(searchQueryProvider);
      final firestoreCategory = _getCategoryForFirestore(selectedCategory);

      final params = ListingQueryParams(
        category: firestoreCategory,
        sortBy: selectedSort,
        searchQuery: searchQuery,
      );

      setState(() => _isLoadingMore = true);

      ref.read(paginatedListingsProvider(params).notifier).loadMore().then((_) {
        if (mounted) {
          setState(() => _isLoadingMore = false);
        }
      });
    }
  }

  void _initializeCategory() {
    if (kIsWeb) {
      // 웹에서 URL 파라미터 처리
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        // ✅ 1순위: GoRouter에서 전달받은 파라미터 사용 (가장 신뢰할 수 있는 소스)
        String? category = widget.initialCategory;
        String? basePartSearch = widget.initialBasePartSearch;

        // ✅ 2순위: Uri.base에서 직접 파싱 (fallback)
        // GoRouter가 파라미터를 전달하지 못한 경우를 대비
        if (category == null && basePartSearch == null) {
          final uri = Uri.base;
          category = uri.queryParameters['category'];
          basePartSearch = uri.queryParameters['basePartSearch'];

          print('🔍 [PartShopScreen] Fallback to Uri.base parsing');
        }

        print('🔍 [PartShopScreen] Category: $category');
        print('🔍 [PartShopScreen] BasePartSearch: $basePartSearch');

        // base_parts 검색어 처리
        if (basePartSearch != null && basePartSearch.isNotEmpty) {
          print('🔍 [PartShopScreen] Starting search: $basePartSearch');
          ref.read(basePartSearchQueryProvider.notifier).state = basePartSearch;

          // base_parts에서 검색
          try {
            final useCase = ref.read(searchBasePartsUseCaseProvider);
            final results = await useCase(basePartSearch);

            if (results.isNotEmpty) {
              // 모든 결과의 basePartId 사용
              final basePartIds = results.map((part) => part.basePartId).toList();
              ref.read(selectedBasePartIdsProvider.notifier).state = basePartIds;
              ref.read(selectedCategoryProvider.notifier).state = 'All'; // 카테고리 초기화

              print('✅ Base parts 검색 완료: ${results.length}개 발견');
              print('✅ BasePartIds: $basePartIds');
            } else {
              // 검색 결과가 없을 때
              ref.read(selectedBasePartIdsProvider.notifier).state = [];
              print('⚠️ Base parts 검색 결과 없음: $basePartSearch');
            }
          } catch (e) {
            print('❌ Base parts 검색 실패: $e');
            ref.read(selectedBasePartIdsProvider.notifier).state = [];
          }
        } else if (category != null) {
          // 카테고리 매핑 (영문 -> 한글)
          final mappedCategory = _mapCategoryFromUrl(category);
          ref.read(selectedCategoryProvider.notifier).state = mappedCategory;
          ref.read(selectedBasePartIdProvider.notifier).state = null;
          ref.read(selectedBasePartIdsProvider.notifier).state = [];
          ref.read(basePartSearchQueryProvider.notifier).state = null;
        } else {
          // 파라미터가 없으면 기본 상태 유지
          print('🔍 [PartShopScreen] No parameters, showing all listings');
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

  String _getCategoryForFirestore(String displayCategory) {
    // 화면 표시용 카테고리명을 Firestore용으로 변환
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
        return 'ssd';  // ← Firestore에는 'ssd'로 저장
      case '파워':
        return 'psu';
      case 'All':
      case '전체':
        return 'All';
      default:
        return displayCategory;
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
    final searchQuery = ref.watch(searchQueryProvider);
    final selectedBasePartIds = ref.watch(selectedBasePartIdsProvider);
    final basePartSearchQuery = ref.watch(basePartSearchQueryProvider);

    // ✅ 화면용 카테고리 → Firestore용 카테고리로 변환
    final firestoreCategory = _getCategoryForFirestore(selectedCategory);

    // 🆕 basePartIds가 비어있으면 페이지네이션 사용, 있으면 기존 방식
    final usePagination = selectedBasePartIds.isEmpty;

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
              // GoRouter를 안전하게 사용
              try {
                context.go(Routes.cart);
              } catch (e) {
                // GoRouter가 없는 경우 (모바일 등) Navigator 사용
                Navigator.pushNamed(context, Routes.cart);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterRow(context, ref),
          const Divider(height: 1),
          Expanded(
            child: usePagination
                ? _buildPaginatedListings(
                    context,
                    ref,
                    firestoreCategory,
                    selectedSort,
                    searchQuery,
                    selectedCategory,
                    basePartSearchQuery,
                  )
                : _buildBasePartIdListings(
                    context,
                    ref,
                    selectedBasePartIds,
                    selectedCategory,
                    basePartSearchQuery,
                  ),
          ),
        ],
      ),
    );
  }

  /// 페이지네이션 리스트 (basePartIds 검색이 아닐 때)
  Widget _buildPaginatedListings(
    BuildContext context,
    WidgetRef ref,
    String firestoreCategory,
    String selectedSort,
    String? searchQuery,
    String selectedCategory,
    String? basePartSearchQuery,
  ) {
    final params = ListingQueryParams(
      category: firestoreCategory,
      sortBy: selectedSort,
      searchQuery: searchQuery,
    );

    final paginatedState = ref.watch(paginatedListingsProvider(params));

    if (paginatedState.error != null) {
      return Center(child: Text('오류 발생: ${paginatedState.error}'));
    }

    if (paginatedState.listings.isEmpty && paginatedState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (paginatedState.listings.isEmpty) {
      return _buildEmptyState(context, selectedCategory, basePartSearchQuery);
    }

    return ResponsiveHelper.centeredMaxWidthContainer(
      context: context,
      child: RefreshIndicator(
        onRefresh: () async {
          ref.read(paginatedListingsProvider(params).notifier).refresh();
        },
        child: GridView.builder(
          controller: _scrollController, // ✅ 무한 스크롤용 컨트롤러
          padding: ResponsiveHelper.getHorizontalPadding(context).copyWith(
            top: 16,
            bottom: 16,
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: ResponsiveHelper.getGridCrossAxisCount(context),
            childAspectRatio: 0.7,
            crossAxisSpacing: ResponsiveHelper.isDesktop(context) ? 24 : 12,
            mainAxisSpacing: ResponsiveHelper.isDesktop(context) ? 24 : 12,
          ),
          itemCount: paginatedState.listings.length + (paginatedState.hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= paginatedState.listings.length) {
              // 로딩 인디케이터
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            return ListingCard(listing: paginatedState.listings[index]);
          },
        ),
      ),
    );
  }

  /// BasePartIds 검색 결과 리스트
  Widget _buildBasePartIdListings(
    BuildContext context,
    WidgetRef ref,
    List<String> selectedBasePartIds,
    String selectedCategory,
    String? basePartSearchQuery,
  ) {
    final listingsAsync = ref.watch(listingsByMultipleBasePartIdsProvider(selectedBasePartIds));

    return listingsAsync.when(
      data: (listings) {
        if (listings.isEmpty) {
          return _buildEmptyState(context, selectedCategory, basePartSearchQuery);
        }

        return ResponsiveHelper.centeredMaxWidthContainer(
          context: context,
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(listingsByMultipleBasePartIdsProvider(selectedBasePartIds));
            },
            child: GridView.builder(
              padding: ResponsiveHelper.getHorizontalPadding(context).copyWith(
                top: 16,
                bottom: 16,
              ),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: ResponsiveHelper.getGridCrossAxisCount(context),
                childAspectRatio: 0.7,
                crossAxisSpacing: ResponsiveHelper.isDesktop(context) ? 24 : 12,
                mainAxisSpacing: ResponsiveHelper.isDesktop(context) ? 24 : 12,
              ),
              itemCount: listings.length,
              itemBuilder: (context, index) {
                return ListingCard(listing: listings[index]);
              },
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(context, ref, error),
    );
  }

  /// 결과 헤더 (카운트 + 검색 초기화 버튼)
  // ignore: unused_element
  Widget _buildResultHeader(
    int count,
    String? searchQuery,
    String? basePartSearchQuery,
    bool hasMore,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      color: Colors.grey[50],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            basePartSearchQuery != null && basePartSearchQuery.isNotEmpty
                ? '"$basePartSearchQuery" 검색 결과 $count개${hasMore ? '+' : ''}'
                : searchQuery != null && searchQuery.isNotEmpty
                    ? '"$searchQuery" 검색 결과 $count개${hasMore ? '+' : ''}'
                    : '$count개의 상품${hasMore ? '+' : ''}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          if ((searchQuery != null && searchQuery.isNotEmpty) ||
              (basePartSearchQuery != null && basePartSearchQuery.isNotEmpty))
            TextButton.icon(
              onPressed: () {
                ref.read(searchQueryProvider.notifier).state = null;
                ref.read(selectedBasePartIdProvider.notifier).state = null;
                ref.read(selectedBasePartIdsProvider.notifier).state = [];
                ref.read(basePartSearchQueryProvider.notifier).state = null;
                // URL 업데이트
                if (kIsWeb) {
                  final category = ref.read(selectedCategoryProvider);
                  final urlCategory = _getCategoryForUrl(category);
                  final newPath = urlCategory.isEmpty
                      ? '/part-shop'
                      : '/part-shop?category=$urlCategory';
                  context.go(newPath);
                }
              },
              icon: const Icon(Icons.clear, size: 18),
              label: const Text('검색 초기화'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[700],
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterRow(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final selectedSort = ref.watch(selectedSortProvider);
    final isMobile = ResponsiveHelper.isMobile(context);

    final categories = [
      'All',
      'CPU',
      'GPU',
      'RAM',
      'mainboard',
      '저장장치',
    ];

    final sortOptions = [
      '최신순',
      '낮은 가격순',
      '높은 가격순',
    ];

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
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '정렬',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 12),
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

  Widget _buildEmptyState(BuildContext context, String selectedCategory, String? searchQuery) {
    // 검색 결과가 없는 경우
    if (searchQuery != null && searchQuery.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '"$searchQuery" 검색 결과가 없습니다',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '다른 검색어를 시도해보세요',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(selectedBasePartIdsProvider.notifier).state = [];
                ref.read(basePartSearchQueryProvider.notifier).state = null;
                if (kIsWeb) {
                  context.go(Routes.partShop);
                }
              },
              icon: const Icon(Icons.refresh),
              label: const Text('전체 상품 보기'),
            ),
          ],
        ),
      );
    }

    // 일반적인 빈 상태
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