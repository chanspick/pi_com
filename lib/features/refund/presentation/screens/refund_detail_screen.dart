// lib/features/refund/presentation/screens/refund_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/repositories/refund_repository_impl.dart';
import '../../data/models/refund_request_model.dart';
import '../../domain/entities/refund_request_entity.dart';

/// 환불 상세 화면
class RefundDetailScreen extends StatefulWidget {
  final String refundId;

  const RefundDetailScreen({
    super.key,
    required this.refundId,
  });

  @override
  State<RefundDetailScreen> createState() => _RefundDetailScreenState();
}

class _RefundDetailScreenState extends State<RefundDetailScreen> {
  final _refundRepository = RefundRepositoryImpl();
  RefundRequestEntity? _refund;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRefundData();
  }

  /// 환불 데이터 로드
  Future<void> _loadRefundData() async {
    try {
      final refund = await _refundRepository.getRefundRequest(widget.refundId);
      setState(() {
        _refund = refund;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('환불 상세'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadRefundData();
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('오류: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadRefundData,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    if (_refund == null) {
      return const Center(child: Text('환불 정보를 찾을 수 없습니다'));
    }

    return RefreshIndicator(
      onRefresh: _loadRefundData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 진행 상태 표시
          _buildProgressIndicator(),
          const SizedBox(height: 24),

          // 환불 정보
          _buildRefundInfo(),
          const SizedBox(height: 16),

          // 반품 송장 정보 (있는 경우)
          if (_refund!.trackingNumber != null) ...[
            _buildShippingInfo(),
            const SizedBox(height: 16),
          ],

          // 검수 정보 (있는 경우)
          if (_refund!.inspectionCompletedAt != null) ...[
            _buildInspectionInfo(),
            const SizedBox(height: 16),
          ],

          // 타임라인
          _buildTimeline(),
          const SizedBox(height: 16),

          // 상태별 액션 버튼
          _buildActionButtons(),
        ],
      ),
    );
  }

  /// 진행 상태 표시
  Widget _buildProgressIndicator() {
    final status = _refund!.status;

    // 진행 단계 정의
    final steps = [
      {'status': RefundStatus.pending, 'label': '신청'},
      {'status': RefundStatus.approved, 'label': '승인'},
      {'status': RefundStatus.itemReceived, 'label': '검수'},
      {'status': RefundStatus.refundCompleted, 'label': '완료'},
    ];

    int currentStep = 0;
    if (status == RefundStatus.pending) {
      currentStep = 0;
    } else if (status == RefundStatus.approved || status == RefundStatus.itemShipped) currentStep = 1;
    else if (status == RefundStatus.itemReceived || status == RefundStatus.inspectionInProgress || status == RefundStatus.inspectionPass) currentStep = 2;
    else if (status == RefundStatus.refundProcessing || status == RefundStatus.refundCompleted) currentStep = 3;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: steps.asMap().entries.map((entry) {
                final index = entry.key;
                final step = entry.value;
                final isActive = index <= currentStep;
                final isCompleted = index < currentStep;

                return Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isActive ? Colors.blue : Colors.grey.shade300,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: isCompleted
                              ? const Icon(Icons.check, color: Colors.white, size: 20)
                              : Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: isActive ? Colors.white : Colors.grey.shade600,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        step['label'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          color: isActive ? Colors.black : Colors.grey.shade600,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 4),
            Row(
              children: List.generate(steps.length - 1, (lineIndex) {
                return Expanded(
                  child: Container(
                    height: 2,
                    color: lineIndex < currentStep ? Colors.blue : Colors.grey.shade300,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  /// 환불 정보
  Widget _buildRefundInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '환불 정보',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Divider(),
            _buildInfoRow('환불 번호', widget.refundId),
            _buildInfoRow('주문 번호', _refund!.orderId),
            _buildInfoRow('상태', _refund!.status.displayName),
            _buildInfoRow('환불 사유', _refund!.reason.displayName),
            _buildInfoRow('상세 사유', _refund!.detailReason),
            _buildInfoRow('신청일', _formatDate(_refund!.requestedAt)),
            const Divider(),
            _buildInfoRow('주문 금액', '${_formatCurrency(_refund!.originalAmount)}원'),
            _buildInfoRow('배송비', '${_formatCurrency(_refund!.shippingFee)}원'),
            _buildInfoRow('환불 예정액', '${_formatCurrency(_refund!.refundAmount)}원', isHighlight: true),
            if (_refund!.refundCalculationNote != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '※ ${_refund!.refundCalculationNote}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 반품 송장 정보
  Widget _buildShippingInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '반품 송장 정보',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Divider(),
            _buildInfoRow('택배사', _refund!.courierCompany ?? '-'),
            _buildInfoRow('송장번호', _refund!.trackingNumber ?? '-'),
            if (_refund!.itemShippedAt != null)
              _buildInfoRow('발송일', _formatDate(_refund!.itemShippedAt!)),
            if (_refund!.itemReceivedAt != null)
              _buildInfoRow('수령일', _formatDate(_refund!.itemReceivedAt!)),
          ],
        ),
      ),
    );
  }

  /// 검수 정보
  Widget _buildInspectionInfo() {
    final isPassed = _refund!.status == RefundStatus.inspectionPass;
    final isFailed = _refund!.status == RefundStatus.inspectionFail;

    return Card(
      color: isPassed ? Colors.green.shade50 : (isFailed ? Colors.red.shade50 : null),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isPassed ? Icons.check_circle : (isFailed ? Icons.cancel : Icons.search),
                  color: isPassed ? Colors.green : (isFailed ? Colors.red : Colors.blue),
                ),
                const SizedBox(width: 8),
                Text(
                  isPassed ? '검수 합격' : (isFailed ? '검수 불합격' : '검수 완료'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isPassed ? Colors.green.shade700 : (isFailed ? Colors.red.shade700 : null),
                      ),
                ),
              ],
            ),
            const Divider(),
            if (_refund!.inspectionNote != null)
              _buildInfoRow('검수 내용', _refund!.inspectionNote!),
            if (_refund!.failReason != null)
              _buildInfoRow('불합격 사유', _refund!.failReason!),
            if (_refund!.inspectionCompletedAt != null)
              _buildInfoRow('검수 완료일', _formatDate(_refund!.inspectionCompletedAt!)),
            // 검수 사진
            if (_refund!.inspectionPhotoUrls != null && _refund!.inspectionPhotoUrls!.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('검수 사진', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _refund!.inspectionPhotoUrls!.map((url) {
                  return Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(url, fit: BoxFit.cover),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 타임라인
  Widget _buildTimeline() {
    final events = <Map<String, dynamic>>[];

    // 환불 완료
    if (_refund!.refundCompletedAt != null) {
      events.add({
        'date': _refund!.refundCompletedAt!,
        'title': '환불 완료',
        'description': '${_formatCurrency(_refund!.refundAmount)}원이 환불되었습니다',
      });
    }

    // 검수 완료
    if (_refund!.inspectionCompletedAt != null) {
      if (_refund!.status == RefundStatus.inspectionPass) {
        events.add({
          'date': _refund!.inspectionCompletedAt!,
          'title': '검수 합격',
          'description': _refund!.inspectionNote ?? '검수에 합격하였습니다',
        });
      } else if (_refund!.status == RefundStatus.inspectionFail) {
        events.add({
          'date': _refund!.inspectionCompletedAt!,
          'title': '검수 불합격',
          'description': _refund!.failReason ?? '검수에 불합격하였습니다',
        });
      }
    }

    // 반품 물품 수령
    if (_refund!.itemReceivedAt != null) {
      events.add({
        'date': _refund!.itemReceivedAt!,
        'title': '반품 물품 수령',
        'description': '검수가 진행됩니다',
      });
    }

    // 반품 발송
    if (_refund!.itemShippedAt != null) {
      events.add({
        'date': _refund!.itemShippedAt!,
        'title': '반품 발송',
        'description': '${_refund!.courierCompany} / ${_refund!.trackingNumber}',
      });
    }

    // 환불 승인
    if (_refund!.approvedAt != null) {
      events.add({
        'date': _refund!.approvedAt!,
        'title': '환불 승인',
        'description': '반품 물품을 발송해주세요',
      });
    }

    // 환불 신청
    events.add({
      'date': _refund!.requestedAt,
      'title': '환불 신청',
      'description': '${_refund!.reason.displayName} - ${_refund!.detailReason}',
    });

    // 최신순 정렬 (이미 역순)
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '타임라인',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Divider(),
            ...events.map((event) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.only(top: 5),
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event['title'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            event['description'],
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDate(event['date']),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  /// 상태별 액션 버튼
  Widget _buildActionButtons() {
    // 검수 불합격 시 액션 버튼
    if (_refund!.status == RefundStatus.inspectionFail) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                _showReturnAddressDialog();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('재발송 주소 입력'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: () {
                _showCancelConfirmDialog();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('환불 포기'),
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  /// 재발송 주소 입력 다이얼로그
  void _showReturnAddressDialog() {
    final addressController = TextEditingController();
    final phoneController = TextEditingController();
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('재발송 주소 입력'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '검수 불합격 물품을 다시 받으실 주소를 입력해주세요.',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: '받는 사람',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: '연락처',
                    hintText: '010-1234-5678',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: addressController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: '주소',
                    hintText: '도로명 주소 또는 지번 주소',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange[700], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '왕복 배송비는 구매자 부담입니다',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange[900],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty ||
                    phoneController.text.trim().isEmpty ||
                    addressController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('모든 정보를 입력해주세요')),
                  );
                  return;
                }

                Navigator.pop(context);

                // 재발송 주소 업데이트
                try {
                  await _refundRepository.updateReturnAddress(
                    widget.refundId,
                    name: nameController.text.trim(),
                    phone: phoneController.text.trim(),
                    address: addressController.text.trim(),
                  );

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('재발송 주소가 등록되었습니다'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    setState(() => _isLoading = true);
                    _loadRefundData();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('주소 등록 실패: $e')),
                    );
                  }
                }
              },
              child: const Text('등록'),
            ),
          ],
        );
      },
    );
  }

  /// 환불 취소 확인 다이얼로그
  void _showCancelConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('환불 포기'),
          content: const Text(
            '환불을 포기하시겠습니까?\n\n'
            '포기하시면 다시 복구할 수 없습니다.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _refundRepository.cancelRefund(widget.refundId);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('환불이 취소되었습니다')),
                  );
                  Navigator.pop(context);
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('포기'),
            ),
          ],
        );
      },
    );
  }

  /// 정보 행
  Widget _buildInfoRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
                color: isHighlight ? Colors.blue : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 날짜 포맷
  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd HH:mm').format(date);
  }

  /// 금액 포맷
  String _formatCurrency(int amount) {
    return NumberFormat('#,###').format(amount);
  }
}
