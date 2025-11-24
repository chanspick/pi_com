// lib/features/my_page/presentation/screens/sell_request_history_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/models/sell_request_model.dart';
import '../../../../core/constants/routes.dart';

/// 판매 요청 내역 Provider
final sellRequestHistoryProvider = StreamProvider.autoDispose<List<SellRequest>>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) {
    return Stream.value([]);
  }

  return FirebaseFirestore.instance
      .collection('sell_requests')  // ✅ 수정: sellRequests → sell_requests
      .where('sellerId', isEqualTo: currentUser.uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) => SellRequest.fromFirestore(doc)).toList();
  });
});

/// 판매 요청 내역 화면
class SellRequestHistoryScreen extends ConsumerWidget {
  const SellRequestHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(sellRequestHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('판매 요청 내역'),
      ),
      body: historyAsync.when(
        data: (requests) {
          if (requests.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    '판매 요청 내역이 없습니다',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, Routes.sellRequest);
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('판매 요청하기'),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final request = requests[index];
              return _SellRequestCard(request: request);
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
              Text('오류: $error'),
            ],
          ),
        ),
      ),
    );
  }
}

class _SellRequestCard extends ConsumerStatefulWidget {
  final SellRequest request;

  const _SellRequestCard({required this.request});

  @override
  ConsumerState<_SellRequestCard> createState() => _SellRequestCardState();
}

class _SellRequestCardState extends ConsumerState<_SellRequestCard> {
  bool _isCancelling = false;

  Future<void> _cancelRequest() async {
    // 확인 대화상자 표시
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('판매 요청 취소'),
        content: const Text('정말로 이 판매 요청을 취소하시겠습니까?\n취소 후에는 다시 되돌릴 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('아니오'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('취소하기'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isCancelling = true);

    try {
      // Firestore에서 상태 업데이트
      await FirebaseFirestore.instance
          .collection('sell_requests')
          .doc(widget.request.requestId)
          .update({
        'status': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('판매 요청이 취소되었습니다'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('취소 중 오류가 발생했습니다: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isCancelling = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canCancel = widget.request.status == SellRequestStatus.pending && !_isCancelling;

    return Card(
      elevation: 2,
      child: Column(
        children: [
          InkWell(
            onTap: () {
              Navigator.pushNamed(
                context,
                Routes.sellRequestDetails,
                arguments: widget.request.requestId,
              );
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 상태 배지와 날짜
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatusBadge(),
                      Text(
                        _formatDate(widget.request.createdAt),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
              const SizedBox(height: 12),

              // 부품 정보
                  Row(
                    children: [
                      // 이미지
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 60,
                          height: 60,
                          child: widget.request.imageUrls.isNotEmpty
                              ? Image.network(
                                  widget.request.imageUrls.first,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.image, size: 30),
                                    );
                                  },
                                )
                              : Container(
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.image, size: 30),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // 부품명과 희망가
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${widget.request.brand} ${widget.request.modelName}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '희망가: ${_formatPrice(widget.request.requestedPrice)}원',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // 승인된 경우 Admin 메모 표시
                  if (widget.request.status == SellRequestStatus.approved && widget.request.adminNotes != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '승인 안내',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.request.adminNotes!,
                            style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // 반려된 경우 사유 표시
                  if (widget.request.status == SellRequestStatus.rejected && widget.request.adminNotes != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '반려 사유',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.request.adminNotes!,
                            style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // 취소 버튼 (pending 상태일 때만 표시)
          if (canCancel)
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: InkWell(
                onTap: _cancelRequest,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cancel_outlined,
                        size: 18,
                        color: Colors.red[700],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '판매 요청 취소',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.red[700],
                        ),
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

  Widget _buildStatusBadge() {
    Color bgColor;
    Color textColor;
    String text;

    switch (widget.request.status) {
      case SellRequestStatus.pending:
        bgColor = Colors.orange.withValues(alpha: 0.1);
        textColor = Colors.orange;
        text = '검토 중';
        break;
      case SellRequestStatus.testing:
        bgColor = Colors.purple.withValues(alpha: 0.1);
        textColor = Colors.purple;
        text = '테스트 중';
        break;
      case SellRequestStatus.approved:
        bgColor = Colors.green.withValues(alpha: 0.1);
        textColor = Colors.green;
        text = '승인됨';
        break;
      case SellRequestStatus.rejected:
        bgColor = Colors.red.withValues(alpha: 0.1);
        textColor = Colors.red;
        text = '반려됨';
        break;
      case SellRequestStatus.sold:
        bgColor = Colors.blue.withValues(alpha: 0.1);
        textColor = Colors.blue;
        text = '판매완료';
        break;
      case SellRequestStatus.cancelled:
        bgColor = Colors.grey.withValues(alpha: 0.1);
        textColor = Colors.grey;
        text = '취소됨';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
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
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }
}
