// lib/features/parts_price/presentation/screens/base_part_search_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/part_provider.dart';
import '../../domain/entities/base_part_entity.dart';
import '../../../listing/presentation/screens/listings_by_base_part_screen.dart';

/// 홈 화면 검색바용 - base_part 검색 화면
class BasePartSearchScreen extends ConsumerStatefulWidget {
  const BasePartSearchScreen({super.key});

  @override
  ConsumerState<BasePartSearchScreen> createState() => _BasePartSearchScreenState();
}

class _BasePartSearchScreenState extends ConsumerState<BasePartSearchScreen> {
  final _searchController = TextEditingController();
  List<BasePartEntity> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();

    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('검색어를 입력하세요')),
      );
      return;
    }

    setState(() {
      _isSearching = true;
      _hasSearched = false;
    });

    try {
      final useCase = ref.read(searchBasePartsUseCaseProvider);
      final results = await useCase(query);

      setState(() {
        _searchResults = results;
        _isSearching = false;
        _hasSearched = true;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
        _hasSearched = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('검색 중 오류 발생: $e')),
        );
      }
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchResults = [];
      _hasSearched = false;
    });
  }

  void _navigateToListings(BasePartEntity basePart) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ListingsByBasePartScreen(
          basePartId: basePart.basePartId,
          partName: basePart.modelName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('부품 검색'),
      ),
      body: Column(
        children: [
          // 검색바
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '부품 모델명을 입력하세요 (예: RTX 4090)',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: _clearSearch,
                          )
                        : null,
                  ),
                  onSubmitted: (_) => _performSearch(),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),

                // 검색 버튼
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSearching ? null : _performSearch,
                    icon: _isSearching
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.search),
                    label: Text(_isSearching ? '검색 중...' : '검색'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 검색 결과
          Expanded(
            child: _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    // 검색 전
    if (!_hasSearched && !_isSearching) {
      return _buildEmptyState(
        icon: Icons.search,
        title: '검색어를 입력하고\n검색 버튼을 눌러주세요',
        subtitle: '찾고 계신 부품의 모델명을 입력하세요',
      );
    }

    // 검색 중
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    // 검색 결과 없음
    if (_searchResults.isEmpty) {
      return _buildEmptyState(
        icon: Icons.search_off,
        title: '검색 결과가 없습니다',
        subtitle: '다른 검색어로 다시 시도해보세요',
      );
    }

    // 검색 결과 있음
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 결과 개수
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            '검색 결과 ${_searchResults.length}개',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ),

        // 결과 리스트
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              final basePart = _searchResults[index];
              return _buildBasePartCard(basePart);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBasePartCard(BasePartEntity basePart) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _navigateToListings(basePart),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 카테고리 아이콘
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getCategoryIcon(basePart.category),
                  size: 32,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(width: 16),

              // 부품 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 카테고리
                    Text(
                      basePart.category.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // 모델명
                    Text(
                      basePart.modelName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // 가격 및 매물 정보
                    Row(
                      children: [
                        if (basePart.hasPriceInfo) ...[
                          Icon(Icons.attach_money, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            basePart.priceRangeText,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Icon(Icons.inventory_2_outlined, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${basePart.listingCount}개 매물',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 화살표 아이콘
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'cpu':
        return Icons.memory;
      case 'gpu':
        return Icons.videogame_asset;
      case 'mainboard':
      case 'mb':
        return Icons.developer_board;
      case 'ram':
        return Icons.storage;
      case 'ssd':
      case 'hdd':
        return Icons.disc_full;
      case 'psu':
      case 'power':
        return Icons.power;
      case 'case':
        return Icons.computer;
      case 'cooler':
        return Icons.ac_unit;
      default:
        return Icons.inventory_2;
    }
  }
}
