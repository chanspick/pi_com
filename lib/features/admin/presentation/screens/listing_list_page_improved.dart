// lib/features/admin/presentation/screens/listing_list_page_improved.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pi_com/features/listing/domain/entities/listing_entity.dart';
import 'package:pi_com/features/listing/presentation/providers/listing_provider.dart';
import 'package:pi_com/features/listing/data/repositories/listing_repository_impl.dart';
import 'package:pi_com/features/listing/data/datasources/listing_remote_datasource.dart';

/// 개선된 매물 관리 페이지
///
/// 기능:
/// - 상태별 탭 필터
/// - 검색 (부품명, 브랜드)
/// - 다중 선택 및 일괄 상태 변경
/// - 타 사이트 판매완료 매물 내리기 (sold_external 상태로 변경)
class ListingListPageImproved extends ConsumerStatefulWidget {
  const ListingListPageImproved({super.key});

  @override
  ConsumerState<ListingListPageImproved> createState() => _ListingListPageImprovedState();
}

class _ListingListPageImprovedState extends ConsumerState<ListingListPageImproved>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  // 다중 선택 모드
  bool _isSelectionMode = false;
  final Set<String> _selectedListingIds = {};

  // 필터
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('매물 관리'),
        actions: [
          if (!_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.upload_file),
              tooltip: '엑셀 업로드',
              onPressed: () => _showExcelUploadGuide(context),
            ),
          if (_isSelectionMode && _selectedListingIds.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.more_vert),
              tooltip: '선택한 매물 액션',
              onPressed: () => _showBulkActionsMenu(context),
            ),
          if (!_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.check_box_outlined),
              tooltip: '선택 모드',
              onPressed: () => setState(() => _isSelectionMode = true),
            ),
          if (_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: '선택 취소',
              onPressed: () {
                setState(() {
                  _isSelectionMode = false;
                  _selectedListingIds.clear();
                });
              },
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48 + 56),
          child: Column(
            children: [
              // 탭 바
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: const [
                  Tab(text: '전체'),
                  Tab(text: '판매중'),
                  Tab(text: '예약됨'),
                  Tab(text: '판매완료'),
                  Tab(text: '마킹됨'),
                  Tab(text: '타사이트 판매'),
                ],
              ),
              // 검색바
              Container(
                padding: const EdgeInsets.all(8),
                color: Theme.of(context).scaffoldBackgroundColor,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '부품명 또는 브랜드 검색...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                ),
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildListingList(null),                        // 전체
          _buildListingList(ListingStatus.available),     // 판매중
          _buildListingList(ListingStatus.reserved),      // 예약됨
          _buildListingList(ListingStatus.sold),          // 판매완료
          _buildMarkedForSoldList(),                      // 마킹됨 (available + markedForSold)
          _buildListingList(ListingStatus.sold_external), // 타사이트 판매
        ],
      ),
    );
  }

  Widget _buildListingList(ListingStatus? statusFilter) {
    final listingsAsync = ref.watch(listingsFutureProvider(ListingQueryParams(includeAllStatuses: true)));

    return listingsAsync.when(
      data: (listings) {
        // 상태 필터 적용
        var filteredListings = statusFilter != null
            ? listings.where((l) => l.status == statusFilter).toList()
            : listings;

        // 검색 필터 적용
        if (_searchQuery.isNotEmpty) {
          filteredListings = filteredListings.where((listing) {
            final modelName = listing.modelName.toLowerCase();
            final brand = listing.brand.toLowerCase();
            return modelName.contains(_searchQuery) || brand.contains(_searchQuery);
          }).toList();
        }

        if (filteredListings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isNotEmpty ? '검색 결과가 없습니다' : '매물이 없습니다',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            if (_isSelectionMode)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.blue[50],
                child: Row(
                  children: [
                    Text(
                      '${_selectedListingIds.length}개 선택됨',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      icon: const Icon(Icons.select_all),
                      label: const Text('전체 선택'),
                      onPressed: () {
                        setState(() {
                          _selectedListingIds.addAll(
                            filteredListings.map((l) => l.listingId),
                          );
                        });
                      },
                    ),
                  ],
                ),
              ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: filteredListings.length,
                itemBuilder: (context, index) {
                  final listing = filteredListings[index];
                  final isSelected = _selectedListingIds.contains(listing.listingId);

                  return Card(
                    elevation: isSelected ? 4 : 1,
                    color: isSelected ? Colors.blue[50] : null,
                    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    child: InkWell(
                      onTap: _isSelectionMode
                          ? () => _toggleSelection(listing.listingId)
                          : null,
                      onLongPress: !_isSelectionMode
                          ? () {
                              setState(() {
                                _isSelectionMode = true;
                                _selectedListingIds.add(listing.listingId);
                              });
                            }
                          : null,
                      child: ListTile(
                        leading: _isSelectionMode
                            ? Checkbox(
                                value: isSelected,
                                onChanged: (_) => _toggleSelection(listing.listingId),
                              )
                            : listing.imageUrls.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: Image.network(
                                      listing.imageUrls.first,
                                      width: 56,
                                      height: 56,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 56,
                                        height: 56,
                                        color: Colors.grey[200],
                                        child: const Icon(Icons.broken_image),
                                      ),
                                    ),
                                  )
                                : Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Icon(Icons.image_not_supported),
                                  ),
                        title: Text(
                          listing.modelName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${listing.brand} • ₩${_formatPrice(listing.price)}',
                              style: const TextStyle(fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                _buildStatusChip(listing.status),
                                const SizedBox(width: 8),
                                Text(
                                  'ID: ${listing.listingId.substring(0, 8)}...',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: !_isSelectionMode
                            ? PopupMenuButton<String>(
                                onSelected: (value) => _handleListingAction(value, listing),
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'mark_sold_external',
                                    child: Row(
                                      children: [
                                        Icon(Icons.storefront, size: 18),
                                        SizedBox(width: 8),
                                        Text('타 사이트에서 판매완료'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'mark_available',
                                    child: Row(
                                      children: [
                                        Icon(Icons.check_circle, size: 18, color: Colors.green),
                                        SizedBox(width: 8),
                                        Text('판매중으로 변경'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'mark_sold',
                                    child: Row(
                                      children: [
                                        Icon(Icons.sell, size: 18),
                                        SizedBox(width: 8),
                                        Text('판매완료로 변경'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuDivider(),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, size: 18, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('삭제', style: TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            : null,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('오류 발생: $err'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('다시 시도'),
              onPressed: () => ref.invalidate(listingsFutureProvider),
            ),
          ],
        ),
      ),
    );
  }

  // 마킹됨 탭 (markedForSold == true인 listings)
  Widget _buildMarkedForSoldList() {
    final listingsAsync = ref.watch(listingsFutureProvider(ListingQueryParams(includeAllStatuses: true)));

    return listingsAsync.when(
      data: (listings) {
        // markedForSold가 true인 listings만 필터
        var filteredListings = listings.where((l) => l.markedForSold == true).toList();

        // 검색 필터 적용
        if (_searchQuery.isNotEmpty) {
          filteredListings = filteredListings.where((listing) {
            final modelName = listing.modelName.toLowerCase();
            final brand = listing.brand.toLowerCase();
            return modelName.contains(_searchQuery) || brand.contains(_searchQuery);
          }).toList();
        }

        if (filteredListings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.label_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isNotEmpty ? '검색 결과가 없습니다' : '마킹된 매물이 없습니다',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  '판매완료로 전환할 매물을 마킹하세요',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            if (_isSelectionMode)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.blue[50],
                child: Row(
                  children: [
                    Text(
                      '${_selectedListingIds.length}개 선택됨',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      icon: const Icon(Icons.select_all),
                      label: const Text('전체 선택'),
                      onPressed: () {
                        setState(() {
                          _selectedListingIds.addAll(
                            filteredListings.map((l) => l.listingId),
                          );
                        });
                      },
                    ),
                  ],
                ),
              ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: filteredListings.length,
                itemBuilder: (context, index) {
                  final listing = filteredListings[index];
                  final isSelected = _selectedListingIds.contains(listing.listingId);

                  return Card(
                    elevation: isSelected ? 4 : 1,
                    color: isSelected ? Colors.blue[50] : null,
                    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    child: InkWell(
                      onTap: _isSelectionMode
                          ? () => _toggleSelection(listing.listingId)
                          : null,
                      onLongPress: !_isSelectionMode
                          ? () {
                              setState(() {
                                _isSelectionMode = true;
                                _selectedListingIds.add(listing.listingId);
                              });
                            }
                          : null,
                      child: ListTile(
                        leading: _isSelectionMode
                            ? Checkbox(
                                value: isSelected,
                                onChanged: (_) => _toggleSelection(listing.listingId),
                              )
                            : listing.imageUrls.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: Image.network(
                                      listing.imageUrls.first,
                                      width: 56,
                                      height: 56,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 56,
                                        height: 56,
                                        color: Colors.grey[200],
                                        child: const Icon(Icons.broken_image),
                                      ),
                                    ),
                                  )
                                : Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Icon(Icons.image_not_supported),
                                  ),
                        title: Text(
                          listing.modelName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${listing.brand} • ₩${_formatPrice(listing.price)}',
                              style: const TextStyle(fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                _buildMarkedChip(),
                                const SizedBox(width: 8),
                                Text(
                                  'ID: ${listing.listingId.substring(0, 8)}...',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: !_isSelectionMode
                            ? PopupMenuButton<String>(
                                onSelected: (value) => _handleListingAction(value, listing),
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'mark_sold',
                                    child: Row(
                                      children: [
                                        Icon(Icons.sell, size: 18, color: Colors.orange),
                                        SizedBox(width: 8),
                                        Text('판매완료로 전환'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'unmark',
                                    child: Row(
                                      children: [
                                        Icon(Icons.label_off, size: 18),
                                        SizedBox(width: 8),
                                        Text('마킹 해제'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuDivider(),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, size: 18, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('삭제', style: TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            : null,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('오류 발생: $err'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('다시 시도'),
              onPressed: () => ref.invalidate(listingsFutureProvider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarkedChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.amber),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.label, size: 12, color: Colors.amber),
          SizedBox(width: 4),
          Text(
            '마킹됨',
            style: TextStyle(
              color: Colors.amber,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(ListingStatus status) {
    Color color;
    String label;

    switch (status) {
      case ListingStatus.available:
        color = Colors.green;
        label = '판매중';
        break;
      case ListingStatus.reserved:
        color = Colors.orange;
        label = '예약됨';
        break;
      case ListingStatus.sold:
        color = Colors.grey;
        label = '판매완료';
        break;
      case ListingStatus.sold_external:
        color = Colors.purple;
        label = '타사이트 판매';
        break;
      default:
        color = Colors.blue;
        label = status.name;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _toggleSelection(String listingId) {
    setState(() {
      if (_selectedListingIds.contains(listingId)) {
        _selectedListingIds.remove(listingId);
      } else {
        _selectedListingIds.add(listingId);
      }
    });
  }

  void _showBulkActionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${_selectedListingIds.length}개 매물 일괄 처리',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.storefront, color: Colors.purple),
              title: const Text('타 사이트에서 판매완료로 변경'),
              onTap: () {
                Navigator.pop(context);
                _bulkUpdateStatus(ListingStatus.sold_external);
              },
            ),
            ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: const Text('판매중으로 변경'),
              onTap: () {
                Navigator.pop(context);
                _bulkUpdateStatus(ListingStatus.available);
              },
            ),
            ListTile(
              leading: const Icon(Icons.sell, color: Colors.grey),
              title: const Text('판매완료로 변경'),
              onTap: () {
                Navigator.pop(context);
                _bulkUpdateStatus(ListingStatus.sold);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('선택 항목 삭제', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleListingAction(String action, ListingEntity listing) async {
    switch (action) {
      case 'mark_sold_external':
        await _updateListingStatus(listing.listingId, ListingStatus.sold_external);
        break;
      case 'mark_available':
        await _updateListingStatus(listing.listingId, ListingStatus.available);
        break;
      case 'mark_sold':
        await _updateListingStatus(listing.listingId, ListingStatus.sold);
        break;
      case 'unmark':
        await _unmarkListing(listing.listingId);
        break;
      case 'delete':
        _showDeleteConfirmation(singleListingId: listing.listingId);
        break;
    }
  }

  Future<void> _bulkUpdateStatus(ListingStatus newStatus) async {
    try {
      final dataSource = ListingRemoteDataSourceImpl();
      final repository = ListingRepositoryImpl(remoteDataSource: dataSource);

      for (final listingId in _selectedListingIds) {
        await repository.updateListingStatus(listingId, newStatus);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_selectedListingIds.length}개 매물 상태가 변경되었습니다'),
            backgroundColor: Colors.green,
          ),
        );

        setState(() {
          _isSelectionMode = false;
          _selectedListingIds.clear();
        });

        ref.invalidate(listingsFutureProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류 발생: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateListingStatus(String listingId, ListingStatus newStatus) async {
    try {
      final dataSource = ListingRemoteDataSourceImpl();
      final repository = ListingRepositoryImpl(remoteDataSource: dataSource);
      await repository.updateListingStatus(listingId, newStatus);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('상태가 변경되었습니다'),
            backgroundColor: Colors.green,
          ),
        );

        ref.invalidate(listingsFutureProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류 발생: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _unmarkListing(String listingId) async {
    try {
      // Firestore에서 markedForSold와 markedAt 필드 제거
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('listings').doc(listingId).update({
        'markedForSold': FieldValue.delete(),
        'markedAt': FieldValue.delete(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('마킹이 해제되었습니다'),
            backgroundColor: Colors.green,
          ),
        );

        ref.invalidate(listingsFutureProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류 발생: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteConfirmation({String? singleListingId}) {
    final count = singleListingId != null ? 1 : _selectedListingIds.length;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('삭제 확인'),
        content: Text('$count개 매물을 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: 실제 삭제 로직 구현
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('삭제 기능은 아직 구현되지 않았습니다'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showExcelUploadGuide(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.upload_file, color: Colors.blue),
            SizedBox(width: 8),
            Text('엑셀 파일 업로드'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'datas 폴더의 엑셀 파일을 순차적으로 listings에 업로드합니다.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '각 listing이 50ms 간격으로 업로드되어 자연스러운 timestamp 분포를 생성합니다.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              const Text('📂 업로드 대상 파일:'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• datas/CPU.xlsx'),
                    Text('• datas/GPU.xlsx'),
                    Text('• datas/Mainboard.xlsx'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text('💻 업로드 방법:'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '1. 터미널 열기',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text('2. 명령어 실행:'),
                    SizedBox(height: 4),
                    SelectableText(
                      'node scripts/upload_sequential.js',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        backgroundColor: Colors.black,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '⚠️ 주의사항:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 8),
              const Text('• 엑셀 파일의 "거래완료", "예약중", "판매중" 시트가 순차적으로 업로드됩니다.'),
              const Text('• 업로드 후 Cloud Functions 트리거가 자동으로 base_parts와 priceHistory를 생성합니다.'),
              const Text('• 순차 업로드는 약 35초 소요됩니다 (700개 × 50ms). 중간에 중단하지 마세요.'),
              const Text('• 기존 데이터와 중복되지 않도록 주의하세요.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}
