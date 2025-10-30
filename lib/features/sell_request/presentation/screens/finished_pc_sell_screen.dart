// lib/features/sell_request/presentation/screens/finished_pc_sell_screen.dart

import 'package:flutter/material.dart';
import '../../../../core/models/base_part_model.dart';
import 'sell_request_details_screen.dart';
import 'part_search_screen.dart'; // ⭐️ [추가] 부품 검색 화면 임포트

/// 부품 카테고리 enum
enum PartCategory {
  cpu,
  mainboard,
  ram,
  gpu,
  ssd,
  psu,
  cooler,
  pccase,
}

/// 카테고리 한글 이름 매핑
extension PartCategoryExtension on PartCategory {
  String get displayName {
    switch (this) {
      case PartCategory.cpu:
        return 'CPU';
      case PartCategory.mainboard:
        return '메인보드';
      case PartCategory.ram:
        return 'RAM';
      case PartCategory.gpu:
        return 'GPU';
      case PartCategory.ssd:
        return 'SSD';
      case PartCategory.psu:
        return '파워';
      case PartCategory.cooler:
        return '쿨러';
      case PartCategory.pccase:
        return '케이스';
    }
  }
}

/// 완제품 PC 판매 화면 (부품 선택)
class FinishedPcSellScreen extends StatefulWidget {
  const FinishedPcSellScreen({super.key});

  @override
  State<FinishedPcSellScreen> createState() => _FinishedPcSellScreenState();
}

class _FinishedPcSellScreenState extends State<FinishedPcSellScreen> {
  final Map<PartCategory, BasePart?> _selectedComponents = {
    PartCategory.cpu: null,
    PartCategory.mainboard: null,
    PartCategory.ram: null,
    PartCategory.gpu: null,
    PartCategory.ssd: null,
    PartCategory.psu: null,
    PartCategory.cooler: null,
    PartCategory.pccase: null,
  };

  /// ⭐️ [수정] 부품 검색 화면으로 이동 (카테고리별)
  Future<void> _selectBasePartForCategory(PartCategory category) async {
    // 실제 구현:
    // TODO: PartSearchScreen이 category를 인자로 받도록 추후 확장
    final selectedBasePart = await Navigator.push<BasePart>(
      context,
      MaterialPageRoute(
        builder: (context) => const PartSearchScreen(),
      ),
    );

    if (selectedBasePart != null) {
      setState(() {
        _selectedComponents[category] = selectedBasePart;
        debugPrint('✅ 선택됨: ${category.name} - ${selectedBasePart.modelName}');
      });
    }
  }

  /// 상세 정보 입력 화면으로 이동
  void _goToDetailsScreen() {
    final selectedBaseParts =
    _selectedComponents.values.whereType<BasePart>().toList();

    if (selectedBaseParts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('최소 1개 이상의 부품을 선택해주세요.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SellRequestDetailsScreen(
          selectedBaseParts: selectedBaseParts,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount =
        _selectedComponents.values.where((part) => part != null).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('판매할 PC 구성'),
        actions: [
          if (selectedCount > 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Text(
                  '$selectedCount개 선택됨',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // 안내 메시지
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            color: Colors.blue.shade50,
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '판매할 PC의 부품을 선택해주세요.\n최소 1개 이상 선택하면 다음 단계로 진행할 수 있습니다.',
                    style: TextStyle(
                      color: Colors.blue.shade900,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 부품 선택 목록
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: PartCategory.values.length,
              itemBuilder: (context, index) {
                final category = PartCategory.values[index];
                final selectedPart = _selectedComponents[category];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12.0),
                  child: ListTile(
                    leading: Icon(
                      _getCategoryIcon(category),
                      color: selectedPart != null
                          ? Colors.green
                          : Colors.grey,
                    ),
                    title: Text(category.displayName),
                    subtitle: selectedPart != null
                        ? Text(
                      selectedPart.modelName,
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                        : const Text('선택 안 함'),
                    trailing: Icon(
                      selectedPart != null
                          ? Icons.check_circle
                          : Icons.arrow_forward_ios,
                      color: selectedPart != null
                          ? Colors.green
                          : Colors.grey,
                      size: 20,
                    ),
                    onTap: () => _selectBasePartForCategory(category),
                  ),
                );
              },
            ),
          ),

          // 다음 버튼
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  backgroundColor: selectedCount > 0
                      ? Theme.of(context).primaryColor
                      : Colors.grey.shade300,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: selectedCount > 0 ? _goToDetailsScreen : null,
                child: Text(
                  selectedCount > 0
                      ? '다음 단계 (상세 정보 입력)'
                      : '부품을 선택해주세요',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 카테고리별 아이콘
  IconData _getCategoryIcon(PartCategory category) {
    switch (category) {
      case PartCategory.cpu:
        return Icons.memory;
      case PartCategory.mainboard:
        return Icons.developer_board;
      case PartCategory.ram:
        return Icons.sd_storage;
      case PartCategory.gpu:
        return Icons.videogame_asset;
      case PartCategory.ssd:
        return Icons.storage;
      case PartCategory.psu:
        return Icons.power;
      case PartCategory.cooler:
        return Icons.ac_unit;
      case PartCategory.pccase:
        return Icons.computer;
    }
  }
}