// 송장 관리 화면
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/advanced_search_widget.dart';
import '../widgets/bulk_action_dialog.dart';
import '../../data/services/excel_export_service.dart';

/// 송장 관리 페이지
///
/// 기능:
/// - 결제 완료된 주문 목록
/// - 배송 주소 자동 표시
/// - 송장 번호 입력
/// - 배송 상태 관리
class ShippingManagementPage extends ConsumerStatefulWidget {
  const ShippingManagementPage({super.key});

  @override
  ConsumerState<ShippingManagementPage> createState() => _ShippingManagementPageState();
}

class _ShippingManagementPageState extends ConsumerState<ShippingManagementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  OrderSearchFilter _searchFilter = const OrderSearchFilter();
  final Set<String> _selectedOrderIds = {};
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onFilterChanged(OrderSearchFilter filter) {
    setState(() => _searchFilter = filter);
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedOrderIds.clear();
      }
    });
  }

  void _toggleOrderSelection(String orderId) {
    setState(() {
      if (_selectedOrderIds.contains(orderId)) {
        _selectedOrderIds.remove(orderId);
      } else {
        _selectedOrderIds.add(orderId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isSelectionMode
            ? '${_selectedOrderIds.length}개 선택됨'
            : '송장 관리'),
        actions: [
          if (_isSelectionMode) ...[
            IconButton(
              icon: const Icon(Icons.receipt_long),
              onPressed: _selectedOrderIds.isNotEmpty
                  ? () => _bulkGenerateInvoices()
                  : null,
              tooltip: '일괄 송장 발행',
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _selectedOrderIds.isNotEmpty
                  ? () => _bulkUpdateStatus()
                  : null,
              tooltip: '일괄 상태 변경',
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _toggleSelectionMode,
              tooltip: '선택 취소',
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.checklist),
              onPressed: _toggleSelectionMode,
              tooltip: '일괄 선택',
            ),
            IconButton(
              icon: const Icon(Icons.file_download_outlined),
              onPressed: _exportToExcel,
              tooltip: '엑셀 내보내기',
            ),
          ],
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: '전체'),
            Tab(text: '발송 대기'),
            Tab(text: '발송 완료'),
            Tab(text: '배송 중'),
            Tab(text: '배송 완료'),
          ],
        ),
      ),
      body: Column(
        children: [
          // 고급 검색 위젯 (전체 탭에서만 표시)
          if (_tabController.index == 0)
            AdvancedSearchWidget(
              initialFilter: _searchFilter,
              onFilterChanged: _onFilterChanged,
              onSearch: () => setState(() {}),
            ),
          // 탭 콘텐츠
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFilteredOrderList(),
                _buildOrderList('pending_shipment'),
                _buildOrderList('shipped'),
                _buildOrderList('in_transit'),
                _buildOrderList('delivered'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilteredOrderList() {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('orders')
        .where('paymentStatus', isEqualTo: 'completed');

    // 상태 필터
    if (_searchFilter.statuses.isNotEmpty) {
      query = query.where('status', whereIn: _searchFilter.statuses);
    }

    // 정렬
    switch (_searchFilter.sortBy) {
      case OrderSortOption.createdAt:
        query = query.orderBy('createdAt', descending: _searchFilter.sortDescending);
        break;
      case OrderSortOption.totalPrice:
        query = query.orderBy('totalPrice', descending: _searchFilter.sortDescending);
        break;
      case OrderSortOption.status:
        query = query.orderBy('status', descending: _searchFilter.sortDescending);
        break;
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.limit(100).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('오류: ${snapshot.error}'));
        }

        var orders = snapshot.data?.docs ?? [];

        // 클라이언트 사이드 필터링
        orders = orders.where((doc) {
          final order = doc.data() as Map<String, dynamic>;

          // 검색어 필터
          if (_searchFilter.searchQuery?.isNotEmpty == true) {
            final query = _searchFilter.searchQuery!.toLowerCase();
            final orderId = doc.id.toLowerCase();
            final buyerName = (order['buyerName'] ?? '').toString().toLowerCase();
            final items = order['items'] as List? ?? [];
            final itemNames = items.map((e) => (e['partName'] ?? '').toString().toLowerCase()).join(' ');

            if (!orderId.contains(query) &&
                !buyerName.contains(query) &&
                !itemNames.contains(query)) {
              return false;
            }
          }

          // 기간 필터
          if (_searchFilter.dateRange != null) {
            final createdAt = (order['createdAt'] as Timestamp?)?.toDate();
            if (createdAt != null) {
              if (createdAt.isBefore(_searchFilter.dateRange!.start) ||
                  createdAt.isAfter(_searchFilter.dateRange!.end)) {
                return false;
              }
            }
          }

          // 금액 필터
          final price = (order['totalPrice'] as num?)?.toDouble() ?? 0;
          if (_searchFilter.minPrice != null && price < _searchFilter.minPrice!) {
            return false;
          }
          if (_searchFilter.maxPrice != null && price > _searchFilter.maxPrice!) {
            return false;
          }

          return true;
        }).toList();

        if (orders.isEmpty) {
          return _buildEmptyState('조건에 맞는 주문이 없습니다');
        }

        return _buildOrderListView(orders);
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_shipping_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildOrderListView(List<QueryDocumentSnapshot> orders) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index].data() as Map<String, dynamic>;
        final orderId = orders[index].id;
        final isSelected = _selectedOrderIds.contains(orderId);

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          color: isSelected ? Colors.blue[50] : null,
          child: InkWell(
            onLongPress: () {
              if (!_isSelectionMode) {
                _toggleSelectionMode();
              }
              _toggleOrderSelection(orderId);
            },
            child: ExpansionTile(
              leading: _isSelectionMode
                  ? Checkbox(
                      value: isSelected,
                      onChanged: (_) => _toggleOrderSelection(orderId),
                    )
                  : CircleAvatar(child: Text('${index + 1}')),
              title: Text(
                '주문번호: ${orderId.substring(0, 8)}...',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text('구매자: ${order['buyerName'] ?? '알 수 없음'}'),
                  Text('결제일: ${_formatTimestamp(order['createdAt'])}'),
                  Text('총액: ₩${_formatPrice(order['totalPrice'] ?? 0)}'),
                ],
              ),
              children: [
                const Divider(),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoSection('📦 배송 주소', order['shippingAddress'] ?? {}),
                      const SizedBox(height: 16),
                      _buildItemsSection(order['items'] ?? []),
                      const SizedBox(height: 16),
                      _buildTrackingSection(orderId, order),
                      const SizedBox(height: 16),
                      _buildInvoiceSection(orderId, order),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _bulkGenerateInvoices() async {
    final result = await BulkActionDialog.showGenerateInvoices(
      context,
      _selectedOrderIds.toList(),
    );

    if (result != null && result.successCount > 0) {
      setState(() {
        _selectedOrderIds.clear();
        _isSelectionMode = false;
      });
    }
  }

  Future<void> _bulkUpdateStatus() async {
    final newStatus = await StatusSelectionDialog.show(context);
    if (newStatus == null) return;

    final result = await BulkActionDialog.showUpdateStatus(
      context,
      _selectedOrderIds.toList(),
      newStatus,
    );

    if (result != null && result.successCount > 0) {
      setState(() {
        _selectedOrderIds.clear();
        _isSelectionMode = false;
      });
    }
  }

  Future<void> _exportToExcel() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('paymentStatus', isEqualTo: 'completed')
          .orderBy('createdAt', descending: true)
          .limit(500)
          .get();

      final orders = snapshot.docs.map((d) {
        final data = d.data();
        data['orderId'] = d.id;
        return data;
      }).toList();

      await ExcelExportService.exportOrders(orders);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('엑셀 파일이 생성되었습니다'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류: $e')),
        );
      }
    }
  }

  Widget _buildOrderList(String statusFilter) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('paymentStatus', isEqualTo: 'completed')
          .where('shippingStatus', isEqualTo: statusFilter)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('오류: ${snapshot.error}'));
        }

        final orders = snapshot.data?.docs ?? [];

        if (orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.local_shipping_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text('주문이 없습니다', style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index].data() as Map<String, dynamic>;
            final orderId = orders[index].id;

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: ExpansionTile(
                leading: CircleAvatar(
                  child: Text('${index + 1}'),
                ),
                title: Text(
                  '주문번호: ${orderId.substring(0, 8)}...',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text('구매자: ${order['buyerName'] ?? '알 수 없음'}'),
                    Text('결제일: ${_formatTimestamp(order['createdAt'])}'),
                    Text('총액: ₩${_formatPrice(order['totalPrice'] ?? 0)}'),
                  ],
                ),
                children: [
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 배송 주소
                        _buildInfoSection(
                          '📦 배송 주소',
                          order['shippingAddress'] ?? {},
                        ),
                        const SizedBox(height: 16),

                        // 주문 상품 목록
                        _buildItemsSection(order['items'] ?? []),
                        const SizedBox(height: 16),

                        // 송장 정보
                        _buildTrackingSection(orderId, order),
                        const SizedBox(height: 16),

                        // 송장(Invoice) 관리
                        _buildInvoiceSection(orderId, order),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInvoiceSection(String orderId, Map<String, dynamic> order) {
    final invoiceId = order['invoiceId'];
    final invoiceUrl = order['invoiceUrl'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '영수증/송장',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (invoiceId != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.receipt_long, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '송장번호: $invoiceId',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.download, size: 18),
                        label: const Text('다운로드'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => _downloadInvoice(invoiceUrl),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('재발행'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.orange,
                          side: const BorderSide(color: Colors.orange),
                        ),
                        onPressed: () => _showRegenerateDialog(orderId),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.receipt_long_outlined, color: Colors.grey, size: 20),
                    SizedBox(width: 8),
                    Text(
                      '송장이 발행되지 않았습니다',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('송장 발행'),
                    onPressed: () => _generateInvoice(orderId),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _downloadInvoice(String? invoiceUrl) async {
    if (invoiceUrl == null || invoiceUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('송장 URL이 없습니다')),
      );
      return;
    }

    try {
      final uri = Uri.parse(invoiceUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('송장을 열 수 없습니다')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류: $e')),
        );
      }
    }
  }

  Future<void> _generateInvoice(String orderId) async {
    try {
      // 로딩 표시
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final functions = FirebaseFunctions.instanceFor(region: 'asia-northeast3');
      final callable = functions.httpsCallableFromUrl(
        'https://asia-northeast3-picom-team.cloudfunctions.net/api/invoice/generate',
      );

      await callable.call({'orderId': orderId});

      if (mounted) {
        Navigator.pop(context); // 로딩 닫기
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('송장이 발행되었습니다'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // 로딩 닫기
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('송장 발행 실패: $e')),
        );
      }
    }
  }

  void _showRegenerateDialog(String orderId) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('송장 재발행'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '기존 송장이 무효화되고 새 송장이 발행됩니다.',
              style: TextStyle(color: Colors.orange),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: '재발행 사유',
                hintText: '예: 배송지 변경, 금액 수정 등',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('재발행 사유를 입력하세요')),
                );
                return;
              }

              Navigator.pop(context);
              await _regenerateInvoice(orderId, reason);
            },
            child: const Text('재발행'),
          ),
        ],
      ),
    );
  }

  Future<void> _regenerateInvoice(String orderId, String reason) async {
    try {
      // 로딩 표시
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final functions = FirebaseFunctions.instanceFor(region: 'asia-northeast3');
      final callable = functions.httpsCallableFromUrl(
        'https://asia-northeast3-picom-team.cloudfunctions.net/api/invoice/regenerate',
      );

      await callable.call({'orderId': orderId, 'reason': reason});

      if (mounted) {
        Navigator.pop(context); // 로딩 닫기
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('송장이 재발행되었습니다'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // 로딩 닫기
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('송장 재발행 실패: $e')),
        );
      }
    }
  }

  Widget _buildInfoSection(String title, Map<String, dynamic> address) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('받는 사람: ${address['recipientName'] ?? '-'}'),
              Text('연락처: ${address['phone'] ?? '-'}'),
              const SizedBox(height: 4),
              Text('주소: ${address['fullAddress'] ?? '-'}'),
              if (address['detailAddress'] != null && address['detailAddress'].toString().isNotEmpty)
                Text('상세주소: ${address['detailAddress']}'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildItemsSection(List items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📝 주문 상품',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...items.map((item) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                if (item['imageUrl'] != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      item['imageUrl'],
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 50,
                        height: 50,
                        color: Colors.grey[200],
                        child: const Icon(Icons.image),
                      ),
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['partName'] ?? '알 수 없음',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '수량: ${item['quantity']} • ₩${_formatPrice(item['price'] ?? 0)}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTrackingSection(String orderId, Map<String, dynamic> order) {
    final trackingNumber = order['trackingNumber'];
    final shippingCompany = order['shippingCompany'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🚚 송장 정보',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (trackingNumber != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('택배사: $shippingCompany'),
                Text('송장번호: $trackingNumber'),
              ],
            ),
          )
        else
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('송장 번호 입력'),
            onPressed: () => _showTrackingInputDialog(orderId),
          ),
      ],
    );
  }

  void _showTrackingInputDialog(String orderId) {
    final companyController = TextEditingController();
    final numberController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('송장 정보 입력'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: companyController,
              decoration: const InputDecoration(
                labelText: '택배사',
                hintText: '예: CJ대한통운',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: numberController,
              decoration: const InputDecoration(
                labelText: '송장번호',
                hintText: '예: 123456789012',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              final company = companyController.text.trim();
              final number = numberController.text.trim();

              if (company.isEmpty || number.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('모든 필드를 입력하세요')),
                );
                return;
              }

              try {
                await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
                  'shippingCompany': company,
                  'trackingNumber': number,
                  'shippingStatus': 'shipped',
                  'shippedAt': FieldValue.serverTimestamp(),
                });

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('송장 정보가 등록되었습니다'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('오류: $e')),
                  );
                }
              }
            },
            child: const Text('등록'),
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

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '-';
    try {
      final date = (timestamp as Timestamp).toDate();
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return '-';
    }
  }
}
