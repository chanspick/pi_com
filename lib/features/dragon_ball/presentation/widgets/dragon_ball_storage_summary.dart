// lib/features/dragon_ball/presentation/widgets/dragon_ball_storage_summary.dart

import 'package:flutter/material.dart';
import 'package:pi_com/core/models/batch_shipment_model.dart';

/// 드래곤볼 보관함 요약 정보
class DragonBallStorageSummary extends StatelessWidget {
  final int storedCount;
  final int selectedCount;

  const DragonBallStorageSummary({
    required this.storedCount,
    required this.selectedCount,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final potentialSavings = ShippingCostCalculator.calculateSavings(storedCount);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _SummaryItem(
                icon: Icons.inventory_2_outlined,
                label: '보관 중인 부품',
                value: '$storedCount개',
                color: Colors.blue,
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.blue[200],
              ),
              _SummaryItem(
                icon: Icons.savings_outlined,
                label: '예상 절약액',
                value: '약 ${_formatPrice(potentialSavings)}원',
                color: Colors.green,
              ),
            ],
          ),
          if (storedCount > 0) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '부품들을 모아서 배송받으면 배송비를 절약할 수 있어요!',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
              ],
            ),
          ],
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
}

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
