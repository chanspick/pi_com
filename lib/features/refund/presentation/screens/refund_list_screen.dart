// lib/features/refund/presentation/screens/refund_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/routes.dart';
import '../../domain/entities/refund_request_entity.dart';
import '../../data/models/refund_request_model.dart';
import '../providers/refund_provider.dart';

/// 판매자용 환불 목록 화면
class RefundListScreen extends ConsumerStatefulWidget {
  const RefundListScreen({super.key});

  @override
  ConsumerState<RefundListScreen> createState() => _RefundListScreenState();
}

class _RefundListScreenState extends ConsumerState<RefundListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
        title: const Text('환불 관리'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: '전체'),
            Tab(text: '대기중'),
            Tab(text: '처리중'),
            Tab(text: '완료'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _RefundListTab(statusFilter: null),
          _RefundListTab(
            statusFilter: [RefundStatus.pending, RefundStatus.approved],
          ),
          _RefundListTab(
            statusFilter: [
              RefundStatus.itemShipped,
              RefundStatus.itemReceived,
              RefundStatus.inspectionInProgress,
              RefundStatus.inspectionPass,
              RefundStatus.refundProcessing,
            ],
          ),
          _RefundListTab(
            statusFilter: [
              RefundStatus.refundCompleted,
              RefundStatus.rejected,
              RefundStatus.cancelled,
            ],
          ),
        ],
      ),
    );
  }
}

/// 환불 목록 탭 위젯
class _RefundListTab extends ConsumerWidget {
  final List<RefundStatus>? statusFilter;

  const _RefundListTab({this.statusFilter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sellerRefundsAsync = ref.watch(sellerRefundsProvider);

    return sellerRefundsAsync.when(
      data: (refunds) {
        // 필터링
        final filteredRefunds = statusFilter == null
            ? refunds
            : refunds
                .where((refund) => statusFilter!.contains(refund.status))
                .toList();

        if (filteredRefunds.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  '환불 신청이 없습니다',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(sellerRefundsProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredRefunds.length,
            itemBuilder: (context, index) {
              final refund = filteredRefunds[index];
              return _RefundCard(refund: refund);
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
              onPressed: () => ref.invalidate(sellerRefundsProvider),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 환불 카드 위젯
class _RefundCard extends ConsumerWidget {
  final RefundRequestEntity refund;

  const _RefundCard({required this.refund});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            Routes.refundDetail,
            arguments: refund.refundId,
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상태 및 날짜
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(refund.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getStatusColor(refund.status).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(refund.status),
                          size: 16,
                          color: _getStatusColor(refund.status),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getStatusText(refund.status),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _getStatusColor(refund.status),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _formatDate(refund.requestedAt),
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 환불 ID 및 주문 ID
              _buildInfoRow('환불 ID', refund.refundId.substring(0, 8)),
              const SizedBox(height: 4),
              _buildInfoRow('주문 ID', refund.orderId.substring(0, 8)),
              const SizedBox(height: 12),

              // 환불 사유
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 18, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getReasonText(refund.reason),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (refund.detailReason.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              refund.detailReason,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 환불 금액
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '환불 예정 금액',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    '${_formatPrice(refund.refundAmount)}원',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),

              // 액션 버튼 (pending 상태일 때만)
              if (refund.status == RefundStatus.pending) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _handleReject(context, ref, refund),
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('거부'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _handleApprove(context, ref, refund),
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('승인'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Color _getStatusColor(RefundStatus status) {
    switch (status) {
      case RefundStatus.pending:
        return Colors.orange;
      case RefundStatus.approved:
      case RefundStatus.itemShipped:
        return Colors.blue;
      case RefundStatus.itemReceived:
      case RefundStatus.inspectionInProgress:
        return Colors.purple;
      case RefundStatus.inspectionPass:
      case RefundStatus.refundProcessing:
        return Colors.teal;
      case RefundStatus.refundCompleted:
        return Colors.green;
      case RefundStatus.rejected:
      case RefundStatus.cancelled:
      case RefundStatus.inspectionFail:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(RefundStatus status) {
    switch (status) {
      case RefundStatus.pending:
        return Icons.schedule;
      case RefundStatus.approved:
        return Icons.check_circle;
      case RefundStatus.rejected:
        return Icons.cancel;
      case RefundStatus.itemShipped:
        return Icons.local_shipping;
      case RefundStatus.itemReceived:
        return Icons.inventory;
      case RefundStatus.inspectionInProgress:
        return Icons.search;
      case RefundStatus.inspectionPass:
        return Icons.verified;
      case RefundStatus.inspectionFail:
        return Icons.error;
      case RefundStatus.refundProcessing:
        return Icons.refresh;
      case RefundStatus.refundCompleted:
        return Icons.account_balance_wallet;
      case RefundStatus.cancelled:
        return Icons.block;
    }
  }

  String _getStatusText(RefundStatus status) {
    switch (status) {
      case RefundStatus.pending:
        return '승인 대기';
      case RefundStatus.approved:
        return '승인됨';
      case RefundStatus.rejected:
        return '거부됨';
      case RefundStatus.itemShipped:
        return '반품 발송됨';
      case RefundStatus.itemReceived:
        return '반품 수령';
      case RefundStatus.inspectionInProgress:
        return '검수 진행중';
      case RefundStatus.inspectionPass:
        return '검수 합격';
      case RefundStatus.inspectionFail:
        return '검수 불합격';
      case RefundStatus.refundProcessing:
        return '환불 처리중';
      case RefundStatus.refundCompleted:
        return '환불 완료';
      case RefundStatus.cancelled:
        return '취소됨';
    }
  }

  String _getReasonText(RefundReason reason) {
    switch (reason) {
      case RefundReason.simpleChange:
        return '단순 변심';
      case RefundReason.malfunction:
        return '제품 기능 불량';
      case RefundReason.wrongProduct:
        return '오배송';
      case RefundReason.inspectionError:
        return '검수 오류';
      case RefundReason.damagedDelivery:
        return '배송 중 파손';
    }
  }

  String _formatPrice(int price) {
    return NumberFormat('#,###').format(price);
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy.MM.dd HH:mm').format(date);
  }

  Future<void> _handleApprove(
    BuildContext context,
    WidgetRef ref,
    RefundRequestEntity refund,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('환불 승인'),
        content: Text(
          '환불을 승인하시겠습니까?\n\n'
          '환불 금액: ${_formatPrice(refund.refundAmount)}원\n'
          '승인 후 구매자가 반품 물품을 발송할 수 있습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('승인'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      final refundRepository = ref.read(refundRepositoryProvider);
      await refundRepository.approveRefund(refund.refundId);

      if (context.mounted) {
        Navigator.pop(context); // 로딩 닫기
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('환불이 승인되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // 로딩 닫기
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('환불 승인 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleReject(
    BuildContext context,
    WidgetRef ref,
    RefundRequestEntity refund,
  ) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('환불 거부'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('환불을 거부하시겠습니까?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: '거부 사유',
                hintText: '거부 사유를 입력해주세요',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              maxLength: 200,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('거부 사유를 입력해주세요'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('거부'),
          ),
        ],
      ),
    );

    if (confirmed != true || reasonController.text.trim().isEmpty) return;

    try {
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      final refundRepository = ref.read(refundRepositoryProvider);
      await refundRepository.rejectRefund(
        refund.refundId,
        reasonController.text.trim(),
      );

      if (context.mounted) {
        Navigator.pop(context); // 로딩 닫기
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('환불이 거부되었습니다.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // 로딩 닫기
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('환불 거부 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      reasonController.dispose();
    }
  }
}
