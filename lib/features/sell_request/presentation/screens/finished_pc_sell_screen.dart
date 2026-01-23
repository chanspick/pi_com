// lib/features/sell_request/presentation/screens/finished_pc_sell_screen.dart

import 'package:flutter/material.dart';
import '../../../../core/models/base_part_model.dart';
import '../../../../core/utils/app_logger.dart';
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
    // PartCategory.psu는 제외 (_includePower와 _selectedPowerWattage로 관리)
    PartCategory.cooler: null, // 체크박스로 관리
    PartCategory.pccase: null, // 체크박스로 관리
  };

  // 쿨러/케이스 포함 여부 (기본값: true)
  bool _includeCooler = true;
  bool _includeCase = true;

  // 파워 포함 여부 및 선택된 용량 (기본값: false, 없음)
  bool _includePower = false;
  String? _selectedPowerWattage;

  /// 고정 가격 쿨러 BasePart 생성
  BasePart _createFixedCoolerPart() {
    return BasePart(
      basePartId: 'virtual_cooler_fixed_20000',
      modelName: '임의 매집 쿨러',
      category: 'COOLER',
      brand: '기본',
      lowestPrice: 20000,
      averagePrice: 20000.0,
      listingCount: 999,
    );
  }

  /// 고정 가격 케이스 BasePart 생성
  BasePart _createFixedCasePart() {
    return BasePart(
      basePartId: 'virtual_case_fixed_20000',
      modelName: '임의 매집 케이스',
      category: 'CASE',
      brand: '기본',
      lowestPrice: 20000,
      averagePrice: 20000.0,
      listingCount: 999,
    );
  }

  /// 파워 용량별 BasePart 생성
  BasePart _createPowerPart(String wattage) {
    final price = _getPowerPrice(wattage);
    return BasePart(
      basePartId: 'virtual_power_$wattage',
      modelName: '파워 $wattage',
      category: 'POWER',
      brand: '기본',
      lowestPrice: price,
      averagePrice: price.toDouble(),
      listingCount: 999,
    );
  }

  /// 파워 용량별 가격 책정 (내부 관리용, 사용자에게 보이지 않음)
  int _getPowerPrice(String wattage) {
    switch (wattage) {
      case '500W':
        return 30000;
      case '600W':
        return 40000;
      case '700W':
        return 50000;
      case '750W':
        return 55000;
      case '800W':
        return 60000;
      case '850W':
        return 70000;
      case '1000W':
        return 80000;
      default:
        return 30000;
    }
  }

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
        AppLogger.i('선택됨: ${category.name} - ${selectedBasePart.modelName}', tag: 'SellRequest');
      });
    }
  }

  /// 상세 정보 입력 화면으로 이동
  void _goToDetailsScreen() {
    final selectedBaseParts =
    _selectedComponents.values.whereType<BasePart>().toList();

    // 쿨러/케이스 체크 시 고정 가격 부품 추가
    if (_includeCooler) {
      selectedBaseParts.add(_createFixedCoolerPart());
    }
    if (_includeCase) {
      selectedBaseParts.add(_createFixedCasePart());
    }
    // 파워 체크 및 용량 선택 시 파워 부품 추가
    if (_includePower && _selectedPowerWattage != null) {
      selectedBaseParts.add(_createPowerPart(_selectedPowerWattage!));
    }

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
    // 선택된 부품 개수 (쿨러/케이스/파워는 제외, 대신 체크 상태 반영)
    final selectedCount =
        _selectedComponents.values.where((part) => part != null).length +
        (_includeCooler ? 1 : 0) +
        (_includeCase ? 1 : 0) +
        (_includePower && _selectedPowerWattage != null ? 1 : 0);

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

                // 파워는 용량 선택 체크박스로 표시
                if (category == PartCategory.psu) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12.0),
                    color: _includePower ? Colors.green.shade50 : null,
                    child: Column(
                      children: [
                        CheckboxListTile(
                          secondary: Icon(
                            _getCategoryIcon(category),
                            color: _includePower ? Colors.green : Colors.grey,
                          ),
                          title: Text(category.displayName),
                          subtitle: Text(
                            _includePower && _selectedPowerWattage != null
                                ? '매집 보기 - $_selectedPowerWattage'
                                : '파워 없음 (상태 보고 가격 제시)',
                            style: TextStyle(
                              color: _includePower ? Colors.green : Colors.grey,
                              fontWeight: _includePower ? FontWeight.w500 : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                          value: _includePower,
                          onChanged: (bool? value) {
                            setState(() {
                              _includePower = value ?? false;
                              if (!_includePower) {
                                _selectedPowerWattage = null;
                              }
                            });
                          },
                        ),
                        if (_includePower)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '파워 용량 선택:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  constraints: const BoxConstraints(maxHeight: 200),
                                  child: ListView(
                                    shrinkWrap: true,
                                    children: ['500W', '600W', '700W', '750W', '800W', '850W', '1000W'].map((wattage) {
                                      return RadioListTile<String>(
                                        dense: true,
                                        contentPadding: EdgeInsets.zero,
                                        title: Text(wattage),
                                        value: wattage,
                                        groupValue: _selectedPowerWattage,
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedPowerWattage = value;
                                          });
                                        },
                                      );
                                    }).toList(),
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],
                            ),
                          ),
                      ],
                    ),
                  );
                }

                // 쿨러와 케이스는 체크박스로 표시
                if (category == PartCategory.cooler) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12.0),
                    color: _includeCooler ? Colors.green.shade50 : null,
                    child: CheckboxListTile(
                      secondary: Icon(
                        _getCategoryIcon(category),
                        color: _includeCooler ? Colors.green : Colors.grey,
                      ),
                      title: Text(category.displayName),
                      subtitle: Text(
                        _includeCooler
                            ? '매집 보기 (상태 보고 가격 제시)'
                            : '쿨러 없음 (상태 보고 가격 제시)',
                        style: TextStyle(
                          color: _includeCooler ? Colors.green : Colors.grey,
                          fontWeight: _includeCooler ? FontWeight.w500 : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                      value: _includeCooler,
                      onChanged: (bool? value) {
                        setState(() {
                          _includeCooler = value ?? true;
                        });
                      },
                    ),
                  );
                }

                if (category == PartCategory.pccase) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12.0),
                    color: _includeCase ? Colors.green.shade50 : null,
                    child: CheckboxListTile(
                      secondary: Icon(
                        _getCategoryIcon(category),
                        color: _includeCase ? Colors.green : Colors.grey,
                      ),
                      title: Text(category.displayName),
                      subtitle: Text(
                        _includeCase
                            ? '매집 보기 (상태 보고 가격 제시)'
                            : '케이스 없음 (상태 보고 가격 제시)',
                        style: TextStyle(
                          color: _includeCase ? Colors.green : Colors.grey,
                          fontWeight: _includeCase ? FontWeight.w500 : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                      value: _includeCase,
                      onChanged: (bool? value) {
                        setState(() {
                          _includeCase = value ?? true;
                        });
                      },
                    ),
                  );
                }

                // 일반 부품 (CPU, GPU, RAM, SSD, Mainboard)
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