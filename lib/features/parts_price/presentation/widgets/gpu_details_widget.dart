// lib/features/parts_price/presentation/widgets/gpu_details_widget.dart
import 'package:flutter/material.dart';
import '../../domain/entities/part_entity.dart';

class GpuDetailsWidget extends StatelessWidget {
  final GpuPartEntity gpuPart;

  const GpuDetailsWidget({super.key, required this.gpuPart});

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
              'GPU 상세 스펙',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 20, thickness: 1),
            _buildSpecRow('칩셋', gpuPart.chipset),
            _buildSpecRow('메모리', '${gpuPart.memoryType} ${gpuPart.memorySizeGb}GB'),
            if (gpuPart.boostClockMhz != null)
              _buildSpecRow('부스트 클럭', '${gpuPart.boostClockMhz}MHz'),
            if (gpuPart.cudaCores != null)
              _buildSpecRow('CUDA 코어', '${gpuPart.cudaCores}'),
            if (gpuPart.interfaceType != null)
              _buildSpecRow('인터페이스', gpuPart.interfaceType!),
            if (gpuPart.powerConsumptionW != null)
              _buildSpecRow('권장 파워', '${gpuPart.powerConsumptionW}W'),
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
