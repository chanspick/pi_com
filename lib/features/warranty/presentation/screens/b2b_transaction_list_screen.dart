// lib/features/warranty/presentation/screens/b2b_transaction_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/models/verification_transaction_model.dart';
import '../providers/warranty_provider.dart';

class B2BTransactionListScreen extends ConsumerStatefulWidget {
  const B2BTransactionListScreen({super.key});

  @override
  ConsumerState<B2BTransactionListScreen> createState() => _B2BTransactionListScreenState();
}

class _B2BTransactionListScreenState extends ConsumerState<B2BTransactionListScreen> {
  TransactionStatus? _selectedStatus;

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = _selectedStatus != null
        ? ref.watch(transactionsStreamProvider(_selectedStatus))
        : ref.watch(allTransactionsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('B2B 거래 관리'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToRegister(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatusFilter(),
          Expanded(
            child: transactionsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('오류: $error'),
              ),
              data: (transactions) {
                if (transactions.isEmpty) {
                  return const Center(
                    child: Text('등록된 거래가 없습니다.'),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    return _TransactionCard(
                      transaction: transactions[index],
                      onTap: () => _navigateToDetail(context, transactions[index]),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToRegister(context),
        icon: const Icon(Icons.add),
        label: const Text('거래 등록'),
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
          ...TransactionStatus.values.map((status) {
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

  void _navigateToRegister(BuildContext context) {
    Navigator.of(context).pushNamed('/admin/b2b/register');
  }

  void _navigateToDetail(BuildContext context, VerificationTransactionModel transaction) {
    Navigator.of(context).pushNamed(
      '/admin/b2b/detail',
      arguments: transaction.transactionId,
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

class _TransactionCard extends StatelessWidget {
  final VerificationTransactionModel transaction;
  final VoidCallback onTap;

  const _TransactionCard({
    required this.transaction,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd');
    final priceFormat = NumberFormat.currency(locale: 'ko_KR', symbol: '₩');

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
                          transaction.modelName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${transaction.partCategory} / ${transaction.brand}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                      ],
                    ),
                  ),
                  _StatusBadge(status: transaction.status),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _InfoItem(
                    icon: Icons.attach_money,
                    label: priceFormat.format(transaction.salePrice),
                  ),
                  const SizedBox(width: 16),
                  _InfoItem(
                    icon: Icons.calendar_today,
                    label: dateFormat.format(transaction.saleDate.toDate()),
                  ),
                  const SizedBox(width: 16),
                  _InfoItem(
                    icon: Icons.star,
                    label: '${transaction.conditionScore}/10',
                  ),
                ],
              ),
              if (transaction.buyerCompanyName != null) ...[
                const SizedBox(height: 8),
                Text(
                  '구매사: ${transaction.buyerCompanyName}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final TransactionStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case TransactionStatus.registered:
        color = Colors.grey;
        break;
      case TransactionStatus.qrGenerated:
        color = Colors.blue;
        break;
      case TransactionStatus.reportIssued:
        color = Colors.orange;
        break;
      case TransactionStatus.delivered:
        color = Colors.purple;
        break;
      case TransactionStatus.warrantyActive:
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

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoItem({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
