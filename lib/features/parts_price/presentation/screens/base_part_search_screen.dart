// lib/features/parts_price/presentation/screens/base_part_search_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/part_provider.dart';
import '../../domain/entities/base_part_entity.dart';
import '../screens/price_history_screen.dart';
import '../../../../core/utils/responsive_helper.dart';

/// 홈 화면 검색바용 - base_part 검색 화면
class BasePartSearchScreen extends ConsumerStatefulWidget {
  final String? initialQuery; // 웹에서 URL 파라미터로 전달받을 검색어

  const BasePartSearchScreen({
    super.key,
    this.initialQuery,
  });

  @override
  ConsumerState<BasePartSearchScreen> createState() => _BasePartSearchScreenState();
}

class _BasePartSearchScreenState extends ConsumerState<BasePartSearchScreen> {
  final _searchController = TextEditingController();
  List<BasePartEntity> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  String? _previousQuery;

  @override
  void initState() {
    super.initState();
    _previousQuery = widget.initialQuery;
    // 웹에서 URL 파라미터로 검색어가 전달된 경우 자동 검색
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
      // 화면이 빌드된 후에 검색 실행
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _performSearch();
      });
    }
  }

  @override
  void didUpdateWidget(covariant BasePartSearchScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // URL 파라미터가 변경되었는지 확인
    if (widget.initialQuery != _previousQuery) {
      _previousQuery = widget.initialQuery;
      if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
        _searchController.text = widget.initialQuery!;
        _performSearch();
      }
    }
  }

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

  void _navigateToPriceHistory(BasePartEntity basePart) async {
    // 시세 화면으로 이동 (시세 화면에서 "매물 보기" 버튼으로 매물 목록으로 이동 가능)
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PriceHistoryScreen(basePart: basePart),
      ),
    );
    // 돌아왔을 때 검색 결과가 그대로 유지됨 (상태 보존)
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
        // 검색 키워드 표시 (검색 후 표시하여 사용자가 현재 검색어를 쉽게 확인 가능)
        if (_hasSearched && _searchController.text.isNotEmpty)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).primaryColor.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.search,
                  size: 16,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  '검색: "${_searchController.text}"',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ),

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

        // 결과 리스트 (부품 구매와 동일한 그리드 형식)
        Expanded(
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
    // Listing card와 동일한 규격의 세로형 카드
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 6,
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToPriceHistory(basePart),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 상단: 카테고리 아이콘 영역 (Listing card의 이미지 영역과 동일 비율)
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Center(
                  child: Icon(
                    _getCategoryIcon(basePart.category),
                    size: 48,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ),

            // 하단: 부품 정보 영역 (Listing card의 정보 영역과 동일 비율)
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 카테고리
                          Text(
                            basePart.category.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                          // 모델명
                          Text(
                            basePart.modelName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 매물 개수 (가격 위치에 표시)
                    Text(
                      '${basePart.listingCount}개 매물',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
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
