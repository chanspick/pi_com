// lib/features/parts_price/presentation/widgets/mainboard_details_widget.dart
import 'package:flutter/material.dart';
import '../../domain/entities/part_entity.dart';

class MainboardDetailsWidget extends StatelessWidget {
  final MainboardPartEntity mainboardPart;

  const MainboardDetailsWidget({super.key, required this.mainboardPart});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '메인보드 상세 스펙',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 20, thickness: 1),
            _buildSpecRow('소켓', mainboardPart.socket),
            _buildSpecRow('칩셋', mainboardPart.chipset),
            _buildSpecRow('폼팩터', mainboardPart.formFactor),
            _buildSpecRow('메모리 타입', mainboardPart.memoryType),
            _buildSpecRow('메모리 슬롯', '${mainboardPart.memorySlots}개'),
            _buildSpecRow('최대 메모리', '${mainboardPart.maxMemoryGb}GB'),
            _buildSpecRow('SATA 포트', '${mainboardPart.sataPorts}개'),
            _buildSpecRow('M.2 슬롯', '${mainboardPart.m2Slots}개'),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
