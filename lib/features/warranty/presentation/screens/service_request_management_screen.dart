// lib/features/warranty/presentation/screens/service_request_management_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/models/service_request_model.dart';
import '../providers/warranty_provider.dart';

class ServiceRequestManagementScreen extends ConsumerStatefulWidget {
  const ServiceRequestManagementScreen({super.key});

  @override
  ConsumerState<ServiceRequestManagementScreen> createState() =>
      _ServiceRequestManagementScreenState();
}

class _ServiceRequestManagementScreenState
    extends ConsumerState<ServiceRequestManagementScreen> {
  ServiceRequestStatus? _selectedStatus;

  @override
  Widget build(BuildContext context) {
    final requestsAsync = _selectedStatus != null
        ? ref.watch(serviceRequestsStreamProvider(_selectedStatus))
        : ref.watch(allServiceRequestsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AS 요청 관리'),
      ),
      body: Column(
        children: [
          _buildStatusFilter(),
          Expanded(
            child: requestsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('오류: $error'),
              ),
              data: (requests) {
                if (requests.isEmpty) {
                  return const Center(
                    child: Text('AS 요청이 없습니다.'),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    return _ServiceRequestCard(
                      request: requests[index],
                      onTap: () => _showDetailDialog(context, requests[index]),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _FilterChip(
            label: '전체',
            isSelected: _selectedStatus == null,
            onSelected: () => setState(() => _selectedStatus = null),
          ),
          const SizedBox(width: 8),
          ...ServiceRequestStatus.values.map((status) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _FilterChip(
                label: status.displayName,
                isSelected: _selectedStatus == status,
                onSelected: () => setState(() => _selectedStatus = status),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showDetailDialog(BuildContext context, ServiceRequestModel request) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ServiceRequestDetailSheet(request: request),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
    );
  }
}

class _ServiceRequestCard extends StatelessWidget {
  final ServiceRequestModel request;
  final VoidCallback onTap;

  const _ServiceRequestCard({
    required this.request,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.requestId,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${request.serviceType.displayName} 요청',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                      ],
                    ),
                  ),
                  _StatusBadge(status: request.status),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                request.issueDescription,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.person, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    request.customerName,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    dateFormat.format(request.requestedAt.toDate()),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final ServiceRequestStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case ServiceRequestStatus.pending:
        color = Colors.orange;
        break;
      case ServiceRequestStatus.reviewing:
        color = Colors.blue;
        break;
      case ServiceRequestStatus.approved:
        color = Colors.green;
        break;
      case ServiceRequestStatus.rejected:
        color = Colors.red;
        break;
      case ServiceRequestStatus.itemShipping:
      case ServiceRequestStatus.itemReceived:
      case ServiceRequestStatus.repairing:
        color = Colors.purple;
        break;
      case ServiceRequestStatus.repaired:
      case ServiceRequestStatus.returnShipping:
        color = Colors.teal;
        break;
      case ServiceRequestStatus.completed:
        color = Colors.green;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ServiceRequestDetailSheet extends ConsumerStatefulWidget {
  final ServiceRequestModel request;

  const _ServiceRequestDetailSheet({required this.request});

  @override
  ConsumerState<_ServiceRequestDetailSheet> createState() =>
      _ServiceRequestDetailSheetState();
}

class _ServiceRequestDetailSheetState
    extends ConsumerState<_ServiceRequestDetailSheet> {
  final _noteController = TextEditingController();
  final _trackingController = TextEditingController();
  ServiceRequestStatus? _newStatus;
  bool _isLoading = false;

  @override
  void dispose() {
    _noteController.dispose();
    _trackingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    final request = widget.request;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'AS 요청 상세',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 기본 정보
              _DetailSection(
                title: '요청 정보',
                children: [
                  _DetailRow(label: '요청 ID', value: request.requestId),
                  _DetailRow(label: '서비스 유형', value: request.serviceType.displayName),
                  _DetailRow(
                    label: '신청일',
                    value: dateFormat.format(request.requestedAt.toDate()),
                  ),
                  _DetailRow(label: '현재 상태', value: request.status.displayName),
                ],
              ),
              const SizedBox(height: 16),

              // 고객 정보
              _DetailSection(
                title: '고객 정보',
                children: [
                  _DetailRow(label: '이름', value: request.customerName),
                  _DetailRow(label: '연락처', value: request.customerPhone),
                  _DetailRow(label: '주소', value: request.shippingAddress),
                ],
              ),
              const SizedBox(height: 16),

              // 증상 설명
              _DetailSection(
                title: '증상 설명',
                children: [
                  Text(request.issueDescription),
                ],
              ),
              const SizedBox(height: 16),

              // 배송 정보 (있는 경우)
              if (request.inboundTrackingNumber != null ||
                  request.outboundTrackingNumber != null)
                _DetailSection(
                  title: '배송 정보',
                  children: [
                    if (request.inboundTrackingNumber != null)
                      _DetailRow(label: '입고 송장', value: request.inboundTrackingNumber!),
                    if (request.outboundTrackingNumber != null)
                      _DetailRow(label: '반송 송장', value: request.outboundTrackingNumber!),
                  ],
                ),

              const Divider(height: 32),

              // 상태 변경
              Text(
                '상태 변경',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<ServiceRequestStatus>(
                initialValue: _newStatus ?? request.status,
                decoration: const InputDecoration(
                  labelText: '새 상태',
                  border: OutlineInputBorder(),
                ),
                items: ServiceRequestStatus.values.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(status.displayName),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _newStatus = value),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: '처리 메모',
                  border: OutlineInputBorder(),
                  hintText: '처리 내용을 입력하세요',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _trackingController,
                decoration: const InputDecoration(
                  labelText: '송장 번호 (선택)',
                  border: OutlineInputBorder(),
                  hintText: '반송 송장 번호',
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateStatus,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('상태 업데이트'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Future<void> _updateStatus() async {
    if (_newStatus == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('상태를 선택해주세요')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(serviceRequestActionsProvider.notifier).updateStatus(
            widget.request.requestId,
            status: _newStatus!,
            handlerNote: _noteController.text.isNotEmpty ? _noteController.text : null,
            outboundTrackingNumber:
                _trackingController.text.isNotEmpty ? _trackingController.text : null,
          );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('상태가 업데이트되었습니다')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _DetailSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
