/// Advanced Search Widget - 고급 검색 위젯
///
/// 주문/배송 관리에서 사용하는 고급 검색 필터:
/// - 검색어 (주문번호, 주문자명, 상품명)
/// - 기간 (DateRangePicker)
/// - 상태 (MultiSelect Chip)
/// - 금액 범위 (RangeSlider)
/// - 정렬 옵션

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// 검색 필터 데이터
class OrderSearchFilter {
  final String? searchQuery;
  final DateTimeRange? dateRange;
  final List<String> statuses;
  final double? minPrice;
  final double? maxPrice;
  final OrderSortOption sortBy;
  final bool sortDescending;

  const OrderSearchFilter({
    this.searchQuery,
    this.dateRange,
    this.statuses = const [],
    this.minPrice,
    this.maxPrice,
    this.sortBy = OrderSortOption.createdAt,
    this.sortDescending = true,
  });

  OrderSearchFilter copyWith({
    String? searchQuery,
    DateTimeRange? dateRange,
    List<String>? statuses,
    double? minPrice,
    double? maxPrice,
    OrderSortOption? sortBy,
    bool? sortDescending,
  }) {
    return OrderSearchFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      dateRange: dateRange ?? this.dateRange,
      statuses: statuses ?? this.statuses,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      sortBy: sortBy ?? this.sortBy,
      sortDescending: sortDescending ?? this.sortDescending,
    );
  }

  bool get hasActiveFilters =>
      searchQuery?.isNotEmpty == true ||
      dateRange != null ||
      statuses.isNotEmpty ||
      minPrice != null ||
      maxPrice != null;

  OrderSearchFilter reset() {
    return const OrderSearchFilter();
  }
}

enum OrderSortOption {
  createdAt,
  totalPrice,
  status,
}

/// 고급 검색 위젯
class AdvancedSearchWidget extends StatefulWidget {
  final OrderSearchFilter initialFilter;
  final ValueChanged<OrderSearchFilter> onFilterChanged;
  final VoidCallback? onSearch;

  const AdvancedSearchWidget({
    super.key,
    this.initialFilter = const OrderSearchFilter(),
    required this.onFilterChanged,
    this.onSearch,
  });

  @override
  State<AdvancedSearchWidget> createState() => _AdvancedSearchWidgetState();
}

class _AdvancedSearchWidgetState extends State<AdvancedSearchWidget> {
  late OrderSearchFilter _filter;
  final _searchController = TextEditingController();
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;
    _searchController.text = _filter.searchQuery ?? '';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _updateFilter(OrderSearchFilter newFilter) {
    setState(() => _filter = newFilter);
    widget.onFilterChanged(newFilter);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          // 기본 검색바
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: '주문번호, 주문자명, 상품명 검색...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _updateFilter(_filter.copyWith(searchQuery: ''));
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onChanged: (value) {
                      _updateFilter(_filter.copyWith(searchQuery: value));
                    },
                    onSubmitted: (_) => widget.onSearch?.call(),
                  ),
                ),
                const SizedBox(width: 8),
                // 필터 토글 버튼
                Badge(
                  isLabelVisible: _filter.hasActiveFilters,
                  child: IconButton(
                    icon: Icon(
                      _isExpanded ? Icons.filter_list_off : Icons.filter_list,
                    ),
                    onPressed: () {
                      setState(() => _isExpanded = !_isExpanded);
                    },
                    tooltip: '고급 필터',
                  ),
                ),
                // 검색 버튼
                ElevatedButton(
                  onPressed: widget.onSearch,
                  child: const Text('검색'),
                ),
              ],
            ),
          ),

          // 확장된 필터 영역
          if (_isExpanded) ...[
            const Divider(height: 1),
            _buildExpandedFilters(),
          ],

          // 활성 필터 표시
          if (_filter.hasActiveFilters && !_isExpanded)
            _buildActiveFilterChips(),
        ],
      ),
    );
  }

  Widget _buildExpandedFilters() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 기간 선택
          _buildDateRangeFilter(),
          const SizedBox(height: 16),

          // 상태 필터
          _buildStatusFilter(),
          const SizedBox(height: 16),

          // 금액 범위
          _buildPriceRangeFilter(),
          const SizedBox(height: 16),

          // 정렬 옵션
          _buildSortOptions(),
          const SizedBox(height: 16),

          // 필터 초기화 버튼
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('필터 초기화'),
                onPressed: () {
                  _searchController.clear();
                  _updateFilter(_filter.reset());
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangeFilter() {
    final dateFormat = DateFormat('yyyy.MM.dd');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('기간', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.calendar_today, size: 18),
                label: Text(
                  _filter.dateRange != null
                      ? '${dateFormat.format(_filter.dateRange!.start)} ~ ${dateFormat.format(_filter.dateRange!.end)}'
                      : '기간 선택',
                ),
                onPressed: _selectDateRange,
              ),
            ),
            if (_filter.dateRange != null)
              IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () {
                  _updateFilter(OrderSearchFilter(
                    searchQuery: _filter.searchQuery,
                    statuses: _filter.statuses,
                    minPrice: _filter.minPrice,
                    maxPrice: _filter.maxPrice,
                    sortBy: _filter.sortBy,
                    sortDescending: _filter.sortDescending,
                  ));
                },
              ),
          ],
        ),
        const SizedBox(height: 8),
        // 빠른 기간 선택
        Wrap(
          spacing: 8,
          children: [
            _buildQuickDateChip('오늘', 0),
            _buildQuickDateChip('7일', 7),
            _buildQuickDateChip('30일', 30),
            _buildQuickDateChip('90일', 90),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickDateChip(String label, int days) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).subtract(Duration(days: days));
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final isSelected = _filter.dateRange != null &&
        _filter.dateRange!.start.day == start.day &&
        _filter.dateRange!.end.day == end.day;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          _updateFilter(_filter.copyWith(
            dateRange: DateTimeRange(start: start, end: end),
          ));
        }
      },
    );
  }

  Future<void> _selectDateRange() async {
    final now = DateTime.now();
    final result = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now,
      initialDateRange: _filter.dateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: Colors.blue,
                ),
          ),
          child: child!,
        );
      },
    );

    if (result != null) {
      _updateFilter(_filter.copyWith(dateRange: result));
    }
  }

  Widget _buildStatusFilter() {
    final statuses = [
      {'value': 'pending', 'label': '대기중', 'color': Colors.grey},
      {'value': 'processing', 'label': '처리중', 'color': Colors.blue},
      {'value': 'shipped', 'label': '배송중', 'color': Colors.orange},
      {'value': 'delivered', 'label': '배송완료', 'color': Colors.green},
      {'value': 'confirmed', 'label': '구매확정', 'color': Colors.teal},
      {'value': 'cancelled', 'label': '취소됨', 'color': Colors.red},
      {'value': 'refundRequested', 'label': '환불신청', 'color': Colors.purple},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('주문 상태', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: statuses.map((status) {
            final isSelected = _filter.statuses.contains(status['value']);
            return FilterChip(
              label: Text(status['label'] as String),
              selected: isSelected,
              selectedColor: (status['color'] as Color).withOpacity(0.2),
              checkmarkColor: status['color'] as Color,
              onSelected: (selected) {
                final newStatuses = List<String>.from(_filter.statuses);
                if (selected) {
                  newStatuses.add(status['value'] as String);
                } else {
                  newStatuses.remove(status['value']);
                }
                _updateFilter(_filter.copyWith(statuses: newStatuses));
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPriceRangeFilter() {
    final minPrice = _filter.minPrice ?? 0;
    final maxPrice = _filter.maxPrice ?? 1000000;
    final currencyFormat = NumberFormat.currency(locale: 'ko_KR', symbol: '', decimalDigits: 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('금액 범위', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            Text('${currencyFormat.format(minPrice)}원'),
            const Spacer(),
            Text('${currencyFormat.format(maxPrice)}원'),
          ],
        ),
        RangeSlider(
          values: RangeValues(minPrice, maxPrice),
          min: 0,
          max: 1000000,
          divisions: 100,
          labels: RangeLabels(
            '${currencyFormat.format(minPrice)}원',
            '${currencyFormat.format(maxPrice)}원',
          ),
          onChanged: (values) {
            _updateFilter(_filter.copyWith(
              minPrice: values.start,
              maxPrice: values.end,
            ));
          },
        ),
        // 빠른 금액 선택
        Wrap(
          spacing: 8,
          children: [
            _buildQuickPriceChip('전체', null, null),
            _buildQuickPriceChip('~5만원', 0, 50000),
            _buildQuickPriceChip('5~10만원', 50000, 100000),
            _buildQuickPriceChip('10만원~', 100000, null),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickPriceChip(String label, double? min, double? max) {
    final isSelected = _filter.minPrice == min &&
        (_filter.maxPrice == max || (max == null && _filter.maxPrice == 1000000));

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          _updateFilter(_filter.copyWith(
            minPrice: min ?? 0,
            maxPrice: max ?? 1000000,
          ));
        }
      },
    );
  }

  Widget _buildSortOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('정렬', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<OrderSortOption>(
                value: _filter.sortBy,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: const [
                  DropdownMenuItem(
                    value: OrderSortOption.createdAt,
                    child: Text('주문일'),
                  ),
                  DropdownMenuItem(
                    value: OrderSortOption.totalPrice,
                    child: Text('금액'),
                  ),
                  DropdownMenuItem(
                    value: OrderSortOption.status,
                    child: Text('상태'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    _updateFilter(_filter.copyWith(sortBy: value));
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            ToggleButtons(
              isSelected: [_filter.sortDescending, !_filter.sortDescending],
              onPressed: (index) {
                _updateFilter(_filter.copyWith(sortDescending: index == 0));
              },
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(Icons.arrow_downward),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(Icons.arrow_upward),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActiveFilterChips() {
    final chips = <Widget>[];

    if (_filter.dateRange != null) {
      final dateFormat = DateFormat('MM.dd');
      chips.add(Chip(
        label: Text(
          '${dateFormat.format(_filter.dateRange!.start)} ~ ${dateFormat.format(_filter.dateRange!.end)}',
          style: const TextStyle(fontSize: 12),
        ),
        deleteIcon: const Icon(Icons.close, size: 16),
        onDeleted: () {
          _updateFilter(OrderSearchFilter(
            searchQuery: _filter.searchQuery,
            statuses: _filter.statuses,
            minPrice: _filter.minPrice,
            maxPrice: _filter.maxPrice,
            sortBy: _filter.sortBy,
            sortDescending: _filter.sortDescending,
          ));
        },
      ));
    }

    for (final status in _filter.statuses) {
      chips.add(Chip(
        label: Text(_getStatusLabel(status), style: const TextStyle(fontSize: 12)),
        deleteIcon: const Icon(Icons.close, size: 16),
        onDeleted: () {
          final newStatuses = List<String>.from(_filter.statuses)..remove(status);
          _updateFilter(_filter.copyWith(statuses: newStatuses));
        },
      ));
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: chips,
      ),
    );
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return '대기중';
      case 'processing':
        return '처리중';
      case 'shipped':
        return '배송중';
      case 'delivered':
        return '배송완료';
      case 'confirmed':
        return '구매확정';
      case 'cancelled':
        return '취소됨';
      case 'refundRequested':
        return '환불신청';
      default:
        return status;
    }
  }
}
