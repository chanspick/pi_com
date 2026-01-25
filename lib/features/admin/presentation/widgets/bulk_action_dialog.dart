/// 일괄 처리 다이얼로그
///
/// Admin용 일괄 작업 수행 다이얼로그:
/// - 일괄 송장 생성
/// - 일괄 상태 변경

import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';

enum BulkActionType {
  generateInvoices,
  updateStatus,
}

class BulkActionDialog extends StatefulWidget {
  final List<String> selectedOrderIds;
  final BulkActionType actionType;
  final String? newStatus; // updateStatus인 경우 필요

  const BulkActionDialog({
    super.key,
    required this.selectedOrderIds,
    required this.actionType,
    this.newStatus,
  });

  /// 일괄 송장 생성 다이얼로그 표시
  static Future<BulkActionResult?> showGenerateInvoices(
    BuildContext context,
    List<String> orderIds,
  ) {
    return showDialog<BulkActionResult>(
      context: context,
      barrierDismissible: false,
      builder: (context) => BulkActionDialog(
        selectedOrderIds: orderIds,
        actionType: BulkActionType.generateInvoices,
      ),
    );
  }

  /// 일괄 상태 변경 다이얼로그 표시
  static Future<BulkActionResult?> showUpdateStatus(
    BuildContext context,
    List<String> orderIds,
    String newStatus,
  ) {
    return showDialog<BulkActionResult>(
      context: context,
      barrierDismissible: false,
      builder: (context) => BulkActionDialog(
        selectedOrderIds: orderIds,
        actionType: BulkActionType.updateStatus,
        newStatus: newStatus,
      ),
    );
  }

  @override
  State<BulkActionDialog> createState() => _BulkActionDialogState();
}

class _BulkActionDialogState extends State<BulkActionDialog> {
  bool _isProcessing = false;
  BulkActionResult? _result;
  String _statusMessage = '';
  double _progress = 0;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            _getActionIcon(),
            color: Colors.blue,
          ),
          const SizedBox(width: 8),
          Text(_getActionTitle()),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_isProcessing && _result == null) ...[
              Text(
                _getConfirmMessage(),
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      '선택된 주문: ${widget.selectedOrderIds.length}건',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
            if (_isProcessing) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(value: _progress > 0 ? _progress : null),
              const SizedBox(height: 16),
              Text(
                _statusMessage,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
            if (_result != null) ...[
              _buildResultWidget(),
            ],
          ],
        ),
      ),
      actions: [
        if (!_isProcessing && _result == null) ...[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: _executeAction,
            child: const Text('실행'),
          ),
        ],
        if (_result != null)
          ElevatedButton(
            onPressed: () => Navigator.pop(context, _result),
            child: const Text('확인'),
          ),
      ],
    );
  }

  IconData _getActionIcon() {
    switch (widget.actionType) {
      case BulkActionType.generateInvoices:
        return Icons.receipt_long;
      case BulkActionType.updateStatus:
        return Icons.sync;
    }
  }

  String _getActionTitle() {
    switch (widget.actionType) {
      case BulkActionType.generateInvoices:
        return '일괄 송장 발행';
      case BulkActionType.updateStatus:
        return '일괄 상태 변경';
    }
  }

  String _getConfirmMessage() {
    switch (widget.actionType) {
      case BulkActionType.generateInvoices:
        return '선택한 주문들에 대해 송장을 일괄 발행하시겠습니까?\n이미 송장이 있는 주문은 건너뜁니다.';
      case BulkActionType.updateStatus:
        final statusLabel = _getStatusLabel(widget.newStatus ?? '');
        return '선택한 주문들의 상태를 "$statusLabel"(으)로 일괄 변경하시겠습니까?';
    }
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
      default:
        return status;
    }
  }

  Future<void> _executeAction() async {
    setState(() {
      _isProcessing = true;
      _statusMessage = '처리 중...';
      _progress = 0;
    });

    try {
      final functions = FirebaseFunctions.instanceFor(region: 'asia-northeast3');

      Map<String, dynamic> response;

      switch (widget.actionType) {
        case BulkActionType.generateInvoices:
          setState(() => _statusMessage = '송장 생성 중...');
          final callable = functions.httpsCallable('bulkGenerateInvoices');
          final result = await callable.call({'orderIds': widget.selectedOrderIds});
          response = Map<String, dynamic>.from(result.data);
          break;

        case BulkActionType.updateStatus:
          setState(() => _statusMessage = '상태 변경 중...');
          final callable = functions.httpsCallable('bulkUpdateStatus');
          final result = await callable.call({
            'orderIds': widget.selectedOrderIds,
            'newStatus': widget.newStatus,
          });
          response = Map<String, dynamic>.from(result.data);
          break;
      }

      setState(() {
        _isProcessing = false;
        _result = BulkActionResult.fromMap(response);
        _progress = 1.0;
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _result = BulkActionResult(
          success: [],
          failed: [
            BulkActionError(orderId: 'all', error: e.toString()),
          ],
          totalProcessed: widget.selectedOrderIds.length,
          successCount: 0,
          failedCount: widget.selectedOrderIds.length,
        );
      });
    }
  }

  Widget _buildResultWidget() {
    final result = _result!;
    final isSuccess = result.failedCount == 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSuccess ? Colors.green[50] : Colors.orange[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSuccess ? Colors.green : Colors.orange,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isSuccess ? Icons.check_circle : Icons.warning,
                    color: isSuccess ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isSuccess ? '처리 완료' : '일부 실패',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSuccess ? Colors.green[700] : Colors.orange[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('총 처리: ${result.totalProcessed}건'),
              Text('성공: ${result.successCount}건', style: const TextStyle(color: Colors.green)),
              if (result.failedCount > 0)
                Text('실패: ${result.failedCount}건', style: const TextStyle(color: Colors.red)),
            ],
          ),
        ),
        if (result.failed.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text(
            '실패 목록:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Container(
            constraints: const BoxConstraints(maxHeight: 150),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: result.failed.length,
              itemBuilder: (context, index) {
                final error = result.failed[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    '${error.orderId.substring(0, 8)}...: ${error.error}',
                    style: TextStyle(fontSize: 12, color: Colors.red[700]),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

/// 일괄 처리 결과
class BulkActionResult {
  final List<String> success;
  final List<BulkActionError> failed;
  final int totalProcessed;
  final int successCount;
  final int failedCount;

  BulkActionResult({
    required this.success,
    required this.failed,
    required this.totalProcessed,
    required this.successCount,
    required this.failedCount,
  });

  factory BulkActionResult.fromMap(Map<String, dynamic> map) {
    return BulkActionResult(
      success: List<String>.from(map['success'] ?? []),
      failed: (map['failed'] as List?)
              ?.map((e) => BulkActionError.fromMap(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      totalProcessed: map['totalProcessed'] ?? 0,
      successCount: map['successCount'] ?? 0,
      failedCount: map['failedCount'] ?? 0,
    );
  }
}

class BulkActionError {
  final String orderId;
  final String error;

  BulkActionError({required this.orderId, required this.error});

  factory BulkActionError.fromMap(Map<String, dynamic> map) {
    return BulkActionError(
      orderId: map['orderId'] ?? '',
      error: map['error'] ?? 'Unknown error',
    );
  }
}

/// 상태 선택 다이얼로그
class StatusSelectionDialog extends StatelessWidget {
  const StatusSelectionDialog({super.key});

  static Future<String?> show(BuildContext context) {
    return showDialog<String>(
      context: context,
      builder: (context) => const StatusSelectionDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statuses = [
      {'value': 'processing', 'label': '처리중', 'icon': Icons.hourglass_empty},
      {'value': 'shipped', 'label': '배송중', 'icon': Icons.local_shipping},
      {'value': 'delivered', 'label': '배송완료', 'icon': Icons.check_circle},
      {'value': 'confirmed', 'label': '구매확정', 'icon': Icons.verified},
      {'value': 'cancelled', 'label': '취소됨', 'icon': Icons.cancel},
    ];

    return AlertDialog(
      title: const Text('상태 선택'),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: statuses.map((status) {
            return ListTile(
              leading: Icon(status['icon'] as IconData),
              title: Text(status['label'] as String),
              onTap: () => Navigator.pop(context, status['value'] as String),
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
      ],
    );
  }
}
