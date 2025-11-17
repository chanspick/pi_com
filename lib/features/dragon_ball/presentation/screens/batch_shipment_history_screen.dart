// lib/features/dragon_ball/presentation/screens/batch_shipment_history_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/batch_shipment_entity.dart';
import '../../data/repositories/batch_shipment_repository_impl.dart';
import '../../data/datasources/batch_shipment_remote_datasource.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/models/batch_shipment_model.dart';

/// 일괄 배송 내역 Provider
final batchShipmentHistoryProvider = StreamProvider.autoDispose<List<BatchShipmentEntity>>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) {
    return Stream.value([]);
  }

  final remoteDataSource = BatchShipmentRemoteDataSourceImpl();
  final repository = BatchShipmentRepositoryImpl(remoteDataSource: remoteDataSource);
  return repository.getUserBatchShipments(currentUser.uid);
});

/// 일괄 배송 내역 화면
class BatchShipmentHistoryScreen extends ConsumerWidget {
  const BatchShipmentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shipmentsAsync = ref.watch(batchShipmentHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('일괄 배송 내역'),
      ),
      body: shipmentsAsync.when(
        data: (shipments) {
          if (shipments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.local_shipping_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '일괄 배송 내역이 없습니다',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'PC 보관함에서 부품을 배송 요청해보세요',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          // 최신순 정렬
          final sortedShipments = shipments.toList()
            ..sort((a, b) => b.requestedAt.compareTo(a.requestedAt));

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: sortedShipments.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final shipment = sortedShipments[index];
              return _BatchShipmentCard(shipment: shipment);
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
              Text(
                '오류가 발생했습니다',
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 일괄 배송 카드 위젯
class _BatchShipmentCard extends StatelessWidget {
  final BatchShipmentEntity shipment;

  const _BatchShipmentCard({required this.shipment});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showShipmentDetail(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상태 및 날짜
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _StatusChip(status: shipment.status),
                  Text(
                    DateFormat('yyyy.MM.dd').format(shipment.requestedAt),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 부품 개수
              Row(
                children: [
                  Icon(Icons.inventory_2_outlined, size: 18, color: Colors.grey[700]),
                  const SizedBox(width: 6),
                  Text(
                    '부품 ${shipment.itemCount}개',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // 배송지
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 18, color: Colors.grey[700]),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      shipment.shippingAddress,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[800],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              // 운송장 번호 (있는 경우)
              if (shipment.hasTrackingNumber) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.local_shipping, size: 18, color: Colors.grey[700]),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${shipment.courier ?? '택배'} ${shipment.trackingNumber}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _trackShipment(context),
                      child: const Text('배송조회'),
                    ),
                  ],
                ),
              ],

              const Divider(height: 24),

              // 배송비
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '배송비',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    '${NumberFormat('#,###').format(shipment.shippingCost)}원',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showShipmentDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 핸들
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 제목
              const Text(
                '배송 상세 정보',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // 상태
              _DetailRow(
                label: '상태',
                value: _getStatusText(shipment.status),
              ),
              _DetailRow(
                label: '요청일',
                value: DateFormat('yyyy년 MM월 dd일 HH:mm').format(shipment.requestedAt),
              ),
              if (shipment.shippedAt != null)
                _DetailRow(
                  label: '발송일',
                  value: DateFormat('yyyy년 MM월 dd일 HH:mm').format(shipment.shippedAt!),
                ),
              if (shipment.deliveredAt != null)
                _DetailRow(
                  label: '배송완료일',
                  value: DateFormat('yyyy년 MM월 dd일 HH:mm').format(shipment.deliveredAt!),
                ),

              const Divider(height: 32),

              // 수령인 정보
              const Text(
                '수령인 정보',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _DetailRow(label: '이름', value: shipment.recipientName),
              _DetailRow(label: '연락처', value: shipment.phoneNumber),
              _DetailRow(label: '주소', value: shipment.shippingAddress),

              const Divider(height: 32),

              // 배송 정보
              const Text(
                '배송 정보',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _DetailRow(
                label: '부품 개수',
                value: '${shipment.itemCount}개',
              ),
              if (shipment.courier != null)
                _DetailRow(label: '택배사', value: shipment.courier!),
              if (shipment.trackingNumber != null)
                _DetailRow(label: '운송장 번호', value: shipment.trackingNumber!),

              const Divider(height: 32),

              // 비용
              const Text(
                '비용',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _DetailRow(
                label: '기본 배송비',
                value: '${NumberFormat('#,###').format(shipment.shippingCost)}원',
              ),
              if (shipment.additionalServicesCost > 0)
                _DetailRow(
                  label: '부가 서비스',
                  value: '${NumberFormat('#,###').format(shipment.additionalServicesCost)}원',
                ),
              const Divider(height: 16),
              _DetailRow(
                label: '총 금액',
                value: '${NumberFormat('#,###').format(shipment.shippingCost + shipment.additionalServicesCost)}원',
                isBold: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _trackShipment(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('배송 조회 기능은 준비 중입니다')),
    );
  }

  String _getStatusText(BatchShipmentStatus status) {
    switch (status) {
      case BatchShipmentStatus.pending:
        return '배송 대기';
      case BatchShipmentStatus.processing:
        return '처리 중';
      case BatchShipmentStatus.shipped:
        return '배송 중';
      case BatchShipmentStatus.delivered:
        return '배송 완료';
    }
  }
}

/// 상태 칩 위젯
class _StatusChip extends StatelessWidget {
  final BatchShipmentStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    String label;

    switch (status) {
      case BatchShipmentStatus.pending:
        backgroundColor = Colors.orange[50]!;
        textColor = Colors.orange[700]!;
        label = '배송 대기';
        break;
      case BatchShipmentStatus.processing:
        backgroundColor = Colors.blue[50]!;
        textColor = Colors.blue[700]!;
        label = '처리 중';
        break;
      case BatchShipmentStatus.shipped:
        backgroundColor = Colors.green[50]!;
        textColor = Colors.green[700]!;
        label = '배송 중';
        break;
      case BatchShipmentStatus.delivered:
        backgroundColor = Colors.grey[200]!;
        textColor = Colors.grey[700]!;
        label = '배송 완료';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}

/// 상세 정보 행 위젯
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const _DetailRow({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: isBold ? FontWeight.bold : null,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isBold ? FontWeight.bold : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
