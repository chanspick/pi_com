// lib/features/listing/presentation/screens/listings_by_base_part_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/listing_provider.dart';
import '../widgets/listing_card.dart';
import '../../domain/entities/listing_entity.dart';
import '../../../../core/constants/routes.dart';

/// basePartId로 필터링된 매물 목록 화면
/// 정렬, 카테고리 필터, 검색어 표시, 재검색 기능 포함
class ListingsByBasePartScreen extends ConsumerStatefulWidget {
  final String basePartId;
  final String partName;
  final String? searchKeyword; // 원래 검색어 (옵션)

  const ListingsByBasePartScreen({
    super.key,
    required this.basePartId,
    required this.partName,
    this.searchKeyword,
  });

  @override
  ConsumerState<ListingsByBasePartScreen> createState() => _ListingsByBasePartScreenState();
}

class _ListingsByBasePartScreenState extends ConsumerState<ListingsByBasePartScreen> {
  String _selectedSort = '최신순';
  String _selectedCategory = '전체';

  final List<String> _sortOptions = ['최신순', '낮은가격순', '높은가격순'];
  final List<String> _categories = ['전체', 'CPU', 'GPU', 'RAM', '메인보드', 'SSD'];

  // 카테고리 키 매핑
  final Map<String, String> _categoryKeys = {
    '전체': '',
    'CPU': 'cpu',
    'GPU': 'gpu',
    'RAM': 'ram',
    '메인보드': 'mainboard',
    'SSD': 'ssd',
  };

  List<ListingEntity> _sortListings(List<ListingEntity> listings) {
    final sorted = List<ListingEntity>.from(listings);

    switch (_selectedSort) {
      case '낮은가격순':
        sorted.sort((a, b) => a.price.compareTo(b.price));
        break;
      case '높은가격순':
        sorted.sort((a, b) => b.price.compareTo(a.price));
        break;
      case '최신순':
      default:
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }

    return sorted;
  }

  List<ListingEntity> _filterByCategory(List<ListingEntity> listings) {
    if (_selectedCategory == '전체') {
      return listings;
    }

    final categoryKey = _categoryKeys[_selectedCategory] ?? '';
    if (categoryKey.isEmpty) {
      return listings;
    }

    return listings.where((l) => l.category.toLowerCase() == categoryKey).toList();
  }

  @override
  Widget build(BuildContext context) {
    final listingsAsync = ref.watch(listingsByBasePartIdProvider(widget.basePartId));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.partName),
        actions: [
          // 검색 버튼
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.pushNamed(context, Routes.basePartSearch);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 검색어 표시
          if (widget.searchKeyword != null && widget.searchKeyword!.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              child: Row(
                children: [
                  Icon(Icons.search, size: 18, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    '검색: "${widget.searchKeyword}"',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const Spacer(),
                  // 새로운 검색 버튼
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, Routes.basePartSearch);
                    },
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('검색어 변경'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ),

          // 카테고리 탭
          Container(
            height: 48,
            color: Colors.white,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedCategory = category;
                        });
                      }
                    },
                    selectedColor: Theme.of(context).primaryColor,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),

          const Divider(height: 1),

          // 정렬 옵션 및 결과 개수
          listingsAsync.when(
            data: (listings) {
              final filtered = _filterByCategory(listings);
              final sorted = _sortListings(filtered);

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '총 ${sorted.length}개의 매물',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    // 정렬 드롭다운
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedSort,
                          isDense: true,
                          icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                          items: _sortOptions.map((sort) {
                            return DropdownMenuItem(
                              value: sort,
                              child: Text(
                                sort,
                                style: const TextStyle(fontSize: 13),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedSort = value;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // 매물 목록
          Expanded(
            child: listingsAsync.when(
              data: (listings) {
                final filtered = _filterByCategory(listings);
                final sorted = _sortListings(filtered);

                if (sorted.isEmpty) {
                  return _buildEmptyState(context, filtered.isEmpty && listings.isNotEmpty);
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(listingsByBasePartIdProvider(widget.basePartId));
                  },
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.7,
                    ),
                    itemCount: sorted.length,
                    itemBuilder: (context, index) {
                      final listing = sorted[index];
                      return ListingCard(listing: listing);
                    },
                  ),
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
                        ref.invalidate(listingsByBasePartIdProvider(widget.basePartId));
                      },
                      child: const Text('다시 시도'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isFiltered) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isFiltered ? Icons.filter_list_off : Icons.inventory_2_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            isFiltered ? '해당 카테고리에 매물이 없습니다' : '등록된 매물이 없습니다',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            isFiltered
                ? '다른 카테고리를 선택해보세요'
                : '현재 판매 중인 ${widget.partName} 매물이 없습니다',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          if (isFiltered) ...[
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _selectedCategory = '전체';
                });
              },
              child: const Text('전체 보기'),
            ),
          ],
        ],
      ),
    );
  }
}
