// lib/features/admin/presentation/screens/admin_sell_request_list_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/sell_request_model.dart';
import '../providers/admin_sell_request_provider.dart';
import '../widgets/admin_review_dialog.dart';

class AdminSellRequestListPage extends ConsumerStatefulWidget {
  const AdminSellRequestListPage({Key? key}) : super(key: key);

  @override
  ConsumerState<AdminSellRequestListPage> createState() =>
      _AdminSellRequestListPageState();
}

class _AdminSellRequestListPageState
    extends ConsumerState<AdminSellRequestListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('판매 요청 관리'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.pending_actions), text: '대기중'),
            Tab(icon: Icon(Icons.check_circle), text: '승인됨'),
            Tab(icon: Icon(Icons.cancel), text: '반려됨'),
          ],
        ),
        actions: [
          // ID로 직접 조회
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showIdLookupDialog(context),
            tooltip: 'ID로 조회',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _PendingListView(),
          _ApprovedListView(),
          _RejectedListView(),
        ],
      ),
    );
  }

  /// ID 조회 다이얼로그
  void _showIdLookupDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('SellRequest ID 조회'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Request ID',
            hintText: 'req_xxxxx',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: ID로 조회 후 상세 다이얼로그 표시
            },
            child: const Text('조회'),
          ),
        ],
      ),
    );
  }
}

// ============================================
// 🔹 대기중 목록
// ============================================

class _PendingListView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingRequestsAsync = ref.watch(pendingSellRequestsStreamProvider);

    return pendingRequestsAsync.when(
      data: (requests) {
        if (requests.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('대기 중인 요청이 없습니다.'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            return _SellRequestCard(
              request: request,
              onTap: () => _showReviewDialog(context, ref, request),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('에러 발생: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(pendingSellRequestsStreamProvider),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }

  void _showReviewDialog(
      BuildContext context, WidgetRef ref, SellRequest request) {
    showDialog(
      context: context,
      builder: (context) => AdminReviewDialog(request: request),
    );
  }
}

// ============================================
// 🔹 승인됨 목록 (TODO)
// ============================================

class _ApprovedListView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('승인된 요청 목록 (구현 예정)'),
    );
  }
}

// ============================================
// 🔹 반려됨 목록 (TODO)
// ============================================

class _RejectedListView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('반려된 요청 목록 (구현 예정)'),
    );
  }
}

// ============================================
// 🔹 SellRequest 카드
// ============================================

class _SellRequestCard extends StatelessWidget {
  final SellRequest request;
  final VoidCallback onTap;

  const _SellRequestCard({
    required this.request,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 썸네일
              _buildThumbnail(),
              const SizedBox(width: 12),

              // 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 부품명
                    Text(
                      '${request.brand} ${request.modelName}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // 카테고리
                    Text(
                      request.category,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // 가격
                    Row(
                      children: [
                        const Text('희망가: '),
                        Text(
                          '₩${_formatPrice(request.requestedPrice)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // 제출 날짜
                    Text(
                      _formatDate(request.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),

              // 액션 버튼
              Column(
                children: [
                  // 상세보기
                  IconButton(
                    icon: const Icon(Icons.visibility),
                    onPressed: onTap,
                    tooltip: '상세보기',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    if (request.imageUrls.isEmpty) {
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.image_not_supported, color: Colors.grey),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        request.imageUrls[0] as String,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 80,
            height: 80,
            color: Colors.grey[200],
            child: const Icon(Icons.broken_image, color: Colors.grey),
          );
        },
      ),
    );
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
