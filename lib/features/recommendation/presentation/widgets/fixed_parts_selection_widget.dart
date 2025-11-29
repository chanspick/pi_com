import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pi_com/core/constants/fixed_price_parts.dart';
import 'package:pi_com/core/models/base_part_model.dart';
import 'package:pi_com/features/recommendation/presentation/providers/recommendation_provider.dart';

/// Phase 2: 정가제 부품 선택 위젯
///
/// 케이스 (고정), 쿨러 (선택), PSU (선택)
class FixedPartsSelectionWidget extends ConsumerStatefulWidget {
  final String usage;
  final String? graphicsQuality;
  final String? resolution;
  final int totalBudget;
  final VoidCallback onConfirm;
  final VoidCallback onBack;

  const FixedPartsSelectionWidget({
    super.key,
    required this.usage,
    this.graphicsQuality,
    this.resolution,
    required this.totalBudget,
    required this.onConfirm,
    required this.onBack,
  });

  @override
  ConsumerState<FixedPartsSelectionWidget> createState() =>
      _FixedPartsSelectionWidgetState();
}

class _FixedPartsSelectionWidgetState
    extends ConsumerState<FixedPartsSelectionWidget> {
  @override
  void initState() {
    super.initState();
    // 용도 기반 쿨러 추천 설정
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final recommendedCooler = getRecommendedCoolerType(
        usage: widget.usage,
        graphicsQuality: widget.graphicsQuality,
        resolution: widget.resolution,
      );
      ref.read(selectedCoolerTypeProvider.notifier).state = recommendedCooler;
    });
  }

  /// 용도 기반 예상 시스템 TDP 계산
  int _getEstimatedSystemTdp() {
    // 기본 시스템 전력 (메인보드, RAM, SSD, 팬 등)
    const basePower = 50;

    switch (widget.usage) {
      case 'G': // 게임
        // 게임용: CPU 65~125W + GPU 150~300W
        if (widget.graphicsQuality == '최고' || widget.graphicsQuality == '레이트레이싱') {
          return basePower + 125 + 300; // 고사양 게임
        } else if (widget.graphicsQuality == '높음') {
          return basePower + 105 + 200; // 중급 게임
        }
        return basePower + 65 + 150; // 라이트 게임

      case 'C': // 창작
        // 창작용: CPU 65~125W + GPU 100~200W
        if (widget.resolution == '4K' || widget.resolution == '8K') {
          return basePower + 125 + 200; // 고해상도 작업
        }
        return basePower + 105 + 150; // 일반 창작

      case 'O': // 사무
      default:
        // 사무용: CPU 65W + 내장그래픽 또는 저전력 GPU 50W
        return basePower + 65 + 50;
    }
  }

  /// 예상 TDP 기반 권장 PSU wattage 계산 (1.3배 여유)
  int _getRecommendedPsuWattage() {
    final estimatedTdp = _getEstimatedSystemTdp();
    // 1.3배 여유 + 50W 단위로 올림
    final recommended = (estimatedTdp * 1.3).ceil();
    return ((recommended + 49) ~/ 50) * 50; // 50W 단위로 올림
  }

  /// PSU 목록에서 권장 wattage 이상인 가장 저렴한 것 선택
  BasePart? _findRecommendedPsu(List<BasePart> psuList) {
    final recommendedWattage = _getRecommendedPsuWattage();

    // wattage가 권장 이상인 것들 필터링
    final suitable = psuList
        .where((psu) => (psu.wattage ?? 0) >= recommendedWattage)
        .toList();

    if (suitable.isEmpty) {
      // 권장 wattage를 만족하는 게 없으면 가장 높은 wattage 선택
      final sorted = [...psuList]
        ..sort((a, b) => (b.wattage ?? 0).compareTo(a.wattage ?? 0));
      return sorted.isNotEmpty ? sorted.first : null;
    }

    // 가장 저렴한 것 선택
    suitable.sort((a, b) => a.lowestPrice.compareTo(b.lowestPrice));
    return suitable.first;
  }

  @override
  Widget build(BuildContext context) {
    final psuListAsync = ref.watch(availablePsuListProvider);
    final selectedCooler = ref.watch(selectedCoolerTypeProvider);
    final selectedPsu = ref.watch(selectedPsuProvider);
    final fixedTotal = ref.watch(fixedPartsTotalProvider);

    final remainingBudget = widget.totalBudget - fixedTotal;

    // PSU 자동 선택 (한 번만 실행)
    ref.listen<AsyncValue<List<BasePart>>>(
      availablePsuListProvider,
      (previous, next) {
        next.whenData((psuList) {
          if (ref.read(selectedPsuProvider) == null && psuList.isNotEmpty) {
            final recommended = _findRecommendedPsu(psuList);
            if (recommended != null) {
              ref.read(selectedPsuProvider.notifier).state = recommended;
            }
          }
        });
      },
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 헤더
          _buildHeader(),
          const SizedBox(height: 24),

          // 케이스 (고정)
          _buildCaseCard(),
          const SizedBox(height: 16),

          // 쿨러 선택
          _buildCoolerCard(selectedCooler),
          const SizedBox(height: 16),

          // PSU 선택
          psuListAsync.when(
            data: (psuList) => _buildPsuCard(psuList, selectedPsu),
            loading: () => _buildLoadingCard('PSU 목록 로딩 중...'),
            error: (e, _) => _buildErrorCard('PSU 목록을 불러올 수 없습니다'),
          ),
          const SizedBox(height: 24),

          // 가격 요약
          _buildPriceSummary(fixedTotal, remainingBudget),
          const SizedBox(height: 24),

          // 버튼
          _buildButtons(selectedPsu != null),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.build_circle,
                size: 48,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '기본 구성 선택',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '케이스, 쿨러, 파워를 먼저 선택해주세요\n나머지 부품은 이 비용을 제외한 예산으로 추천해드립니다',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaseCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.desktop_windows,
                size: 32,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        '케이스',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '고정',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    kFixedCaseModelName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${(kFixedCasePrice / 10000).toStringAsFixed(1)}만원',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoolerCard(CoolerType selectedCooler) {
    final recommendedCooler = getRecommendedCoolerType(
      usage: widget.usage,
      graphicsQuality: widget.graphicsQuality,
      resolution: widget.resolution,
    );

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.ac_unit,
                    size: 32,
                    color: Colors.blue[700],
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  '쿨러',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 쿨러 옵션들
            ...kCoolerOptions.map((cooler) {
              final isSelected = getCoolerInfo(selectedCooler) == cooler;
              final isRecommended = getCoolerInfo(recommendedCooler) == cooler;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () {
                    ref.read(selectedCoolerTypeProvider.notifier).state =
                        cooler == kBudgetCooler
                            ? CoolerType.budget
                            : CoolerType.premium;
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                          : Colors.grey[50],
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : Colors.grey[300]!,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        // 라디오 버튼
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey[400]!,
                              width: 2,
                            ),
                            color: isSelected
                                ? Theme.of(context).primaryColor
                                : Colors.transparent,
                          ),
                          child: isSelected
                              ? const Icon(Icons.check,
                                  size: 16, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        // 쿨러 정보
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    cooler.modelName,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? Theme.of(context).primaryColor
                                          : Colors.black87,
                                    ),
                                  ),
                                  if (isRecommended) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.orange[100],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '추천',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange[800],
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                cooler.description,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // 가격
                        Text(
                          '${(cooler.price / 10000).toStringAsFixed(0)}만원',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Theme.of(context).primaryColor
                                : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPsuCard(List<BasePart> psuList, BasePart? selectedPsu) {
    // PSU를 wattage 기준으로 정렬
    final sortedPsuList = [...psuList]
      ..sort((a, b) => (a.wattage ?? 0).compareTo(b.wattage ?? 0));

    final recommendedWattage = _getRecommendedPsuWattage();
    final estimatedTdp = _getEstimatedSystemTdp();
    final recommendedPsu = _findRecommendedPsu(psuList);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.power,
                    size: 32,
                    color: Colors.amber[700],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '파워서플라이 (PSU)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '예상 소비전력: ${estimatedTdp}W → 권장 ${recommendedWattage}W 이상',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (sortedPsuList.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.orange[700]),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text('현재 구매 가능한 PSU가 없습니다'),
                    ),
                  ],
                ),
              )
            else
              // PSU 드롭다운
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<BasePart>(
                    isExpanded: true,
                    value: selectedPsu,
                    hint: const Text('PSU를 선택해주세요'),
                    items: sortedPsuList.map((psu) {
                      final isRecommended = recommendedPsu?.basePartId == psu.basePartId;
                      final meetsRequirement = (psu.wattage ?? 0) >= recommendedWattage;

                      return DropdownMenuItem<BasePart>(
                        value: psu,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      '${psu.modelName} (${psu.wattage ?? 0}W)',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: meetsRequirement ? Colors.black87 : Colors.grey,
                                      ),
                                    ),
                                  ),
                                  if (isRecommended) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.orange[100],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '추천',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange[800],
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Text(
                              '${(psu.lowestPrice / 10000).toStringAsFixed(1)}만원',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (psu) {
                      ref.read(selectedPsuProvider.notifier).state = psu;
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingCard(String message) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 16),
            Text(message),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red[700]),
            const SizedBox(width: 12),
            Text(message, style: TextStyle(color: Colors.red[700])),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceSummary(int fixedTotal, int remainingBudget) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 정가제 부품 합계
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '기본 구성 합계',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${(fixedTotal / 10000).toStringAsFixed(1)}만원',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            // 남은 예산
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '나머지 부품 예산',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'CPU, GPU, 메인보드, RAM, SSD',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                Text(
                  '${(remainingBudget / 10000).toStringAsFixed(1)}만원',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: remainingBudget > 0
                        ? Theme.of(context).primaryColor
                        : Colors.red,
                  ),
                ),
              ],
            ),
            if (remainingBudget <= 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.red[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '예산이 부족합니다. 예산을 늘리거나 저가 쿨러를 선택해주세요.',
                        style: TextStyle(
                          color: Colors.red[700],
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildButtons(bool canConfirm) {
    final fixedTotal = ref.watch(fixedPartsTotalProvider);
    final remainingBudget = widget.totalBudget - fixedTotal;
    final isValid = canConfirm && remainingBudget > 0;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isValid ? widget.onConfirm : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey[300],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isValid ? '이 구성으로 견적 받기' : 'PSU를 선택해주세요',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isValid) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, size: 20),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: widget.onBack,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: Theme.of(context).primaryColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              '이전으로',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
