// lib/features/parts_price/presentation/widgets/cpu_details_widget.dart
import 'package:flutter/material.dart';
import '../../domain/entities/part_entity.dart';

class CpuDetailsWidget extends StatelessWidget {
  final CpuPartEntity cpuPart;

  const CpuDetailsWidget({super.key, required this.cpuPart});

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
              'CPU 상세 스펙',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 20, thickness: 1),
            _buildSpecRow('소켓', cpuPart.socket),
            _buildSpecRow('코어', '${cpuPart.cores}코어'),
            _buildSpecRow('스레드', '${cpuPart.threads}스레드'),
            _buildSpecRow('기본 클럭', '${cpuPart.baseClockGhz}GHz'),
            _buildSpecRow('부스트 클럭', '${cpuPart.boostClockGhz}GHz'),
            _buildSpecRow('L3 캐시', '${cpuPart.l3CacheMb}MB'),
            _buildSpecRow(
              '내장그래픽',
              cpuPart.hasIntegratedGraphics
                  ? '있음 (${cpuPart.igpuName ?? ''})'
                  : '없음',
            ),
            if (cpuPart.powerConsumptionW != null)
              _buildSpecRow('설계전력', '${cpuPart.powerConsumptionW}W'),
            _buildSpecRow('메모리 타입', cpuPart.memory.type),
            _buildSpecRow('메모리 속도', '${cpuPart.memory.maxSpeedMhz}MHz'),
            _buildSpecRow('쿨러 포함', cpuPart.coolerIncluded ? '예' : '아니오'),
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
