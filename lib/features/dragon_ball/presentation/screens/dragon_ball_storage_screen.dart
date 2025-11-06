// lib/features/dragon_ball/presentation/screens/dragon_ball_storage_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pi_com/features/dragon_ball/presentation/providers/dragon_ball_provider.dart';
import 'package:pi_com/features/dragon_ball/presentation/widgets/dragon_ball_card.dart';
import 'package:pi_com/features/dragon_ball/presentation/widgets/dragon_ball_storage_summary.dart';
import 'package:pi_com/features/dragon_ball/presentation/screens/batch_shipment_request_screen.dart';
import 'package:pi_com/core/constants/routes.dart';
import 'package:pi_com/features/listing/presentation/providers/listing_provider.dart';
import 'package:pi_com/features/dragon_ball/domain/entities/dragon_ball_entity.dart';

/// 드래곤볼 보관함 화면
class DragonBallStorageScreen extends ConsumerWidget {
  const DragonBallStorageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dragonBallsAsync = ref.watch(userDragonBallsStreamProvider);
    final storedDragonBalls = ref.watch(storedDragonBallsProvider);
    final selectedIds = ref.watch(selectedDragonBallIdsProvider);
    final selectedCount = ref.watch(selectedDragonBallCountProvider);
    final shippingCost = ref.watch(selectedDragonBallShippingCostProvider);
    final savings = ref.watch(selectedDragonBallSavingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('드래곤볼 보관함'),
        actions: [
          if (storedDragonBalls.isNotEmpty)
            TextButton(
              onPressed: () {
                final isAllSelected = selectedIds.length == storedDragonBalls.length;
                ref.read(toggleSelectAllDragonBallsProvider)(!isAllSelected);
              },
              child: Text(
                selectedIds.length == storedDragonBalls.length ? '전체 해제' : '전체 선택',
                style: const TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: dragonBallsAsync.when(
        data: (allDragonBalls) {
          if (storedDragonBalls.isEmpty) {
            return _EmptyState(ref: ref);
          }

          return Column(
            children: [
              // 요약 정보
              DragonBallStorageSummary(
                storedCount: storedDragonBalls.length,
                selectedCount: selectedCount,
              ),

              // 드래곤볼 리스트 + 추가 서비스
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // 드래곤볼 카드들
                      ...storedDragonBalls.map((dragonBall) {
                        final isSelected = selectedIds.contains(dragonBall.dragonBallId);
                        return DragonBallCard(
                          dragonBall: dragonBall,
                          isSelected: isSelected,
                          onTap: () {
                            ref.read(toggleDragonBallSelectionProvider)(dragonBall.dragonBallId);
                          },
                        );
                      }).toList(),

                      // 추가 서비스 섹션
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: _AdditionalServicesSection(),
                      ),
                    ],
                  ),
                ),
              ),

              // 하단 버튼
              if (selectedCount > 0) _BottomActionBar(
                ref: ref,
                selectedCount: selectedCount,
                shippingCost: shippingCost,
                savings: savings,
                onRequestShipment: () {
                  final selectedServices = ref.read(selectedAdditionalServicesProvider);
                  final servicesCost = ref.read(selectedServicesCostProvider);

                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => BatchShipmentRequestScreen(
                        dragonBallIds: selectedIds.toList(),
                        additionalServices: selectedServices.map((s) => s.name).toList(),
                        additionalServicesCost: servicesCost,
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('오류가 발생했습니다: $error'),
            ],
          ),
        ),
      ),
    );
  }
}

/// 빈 상태 위젯 - 부품 카테고리 슬롯 테이블 UI
class _EmptyState extends StatelessWidget {
  final WidgetRef ref;

  const _EmptyState({required this.ref});

  // 부품 카테고리 정의
  static const partCategories = [
    {'name': 'CPU', 'icon': Icons.memory},
    {'name': 'GPU', 'icon': Icons.videogame_asset},
    {'name': 'MAINBOARD', 'icon': Icons.developer_board, 'displayName': '메인보드'},
    {'name': 'RAM', 'icon': Icons.storage},
    {'name': 'SSD', 'icon': Icons.disc_full},
    {'name': 'PSU', 'icon': Icons.power, 'displayName': '파워'},
    {'name': 'CASE', 'icon': Icons.computer, 'displayName': '케이스'},
    {'name': 'COOLER', 'icon': Icons.ac_unit, 'displayName': '쿨러'},
  ];

  @override
  Widget build(BuildContext context) {
    final storedDragonBalls = ref.watch(storedDragonBallsProvider);

    // 카테고리별 드래곤볼 매핑
    final Map<String, DragonBallEntity?> categoryMap = {};
    for (var category in partCategories) {
      categoryMap[category['name'] as String] = null;
    }
    for (var db in storedDragonBalls) {
      if (db.category != null) {
        categoryMap[db.category!.toUpperCase()] = db;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 헤더
          Text(
            '드래곤볼 보관함',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '부품 구매 시 드래곤볼 보관을 선택하면 30일간 무료 보관 후 합배송으로 배송비를 절약할 수 있어요!',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[900],
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 부품 슬롯 테이블
          _buildPartSlotsTable(context, categoryMap),

          const SizedBox(height: 24),

          // 추가 서비스 섹션
          const _AdditionalServicesSection(),

          const SizedBox(height: 24),

          // 안내 메시지
          if (storedDragonBalls.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    '아직 보관 중인 부품이 없어요',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '부품 쇼핑몰에서 부품을 구매하고\n드래곤볼 보관을 선택해보세요',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushNamed(Routes.partShop);
                    },
                    icon: const Icon(Icons.shopping_bag),
                    label: const Text('부품 쇼핑하러 가기'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPartSlotsTable(BuildContext context, Map<String, DragonBallEntity?> categoryMap) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // 테이블 헤더
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                const SizedBox(width: 40), // 체크박스 공간
                const SizedBox(
                  width: 80,
                  child: Text('부품', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
                const Expanded(
                  flex: 3,
                  child: Text('모델명', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
                const Expanded(
                  flex: 2,
                  child: Text('입고일', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
                const Expanded(
                  flex: 2,
                  child: Text('남은기간', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ],
            ),
          ),

          // 테이블 바디
          ...partCategories.asMap().entries.map((entry) {
            final index = entry.key;
            final category = entry.value;
            final categoryName = category['name'] as String;
            final displayName = category['displayName'] as String? ?? categoryName;
            final icon = category['icon'] as IconData;
            final dragonBall = categoryMap[categoryName];

            return Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: index < partCategories.length - 1
                      ? BorderSide(color: Colors.grey[300]!)
                      : BorderSide.none,
                ),
              ),
              child: _buildPartSlotRow(
                context,
                categoryName,
                displayName,
                icon,
                dragonBall,
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildPartSlotRow(
    BuildContext context,
    String categoryName,
    String displayName,
    IconData icon,
    DragonBallEntity? dragonBall,
  ) {
    final selectedIds = ref.watch(selectedDragonBallIdsProvider);
    final isSelected = dragonBall != null && selectedIds.contains(dragonBall.dragonBallId);

    return InkWell(
      onTap: dragonBall != null
          ? () => ref.read(toggleDragonBallSelectionProvider)(dragonBall.dragonBallId)
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // 체크박스
            SizedBox(
              width: 40,
              child: dragonBall != null
                  ? Checkbox(
                      value: isSelected,
                      onChanged: (value) {
                        ref.read(toggleDragonBallSelectionProvider)(dragonBall.dragonBallId);
                      },
                    )
                  : null,
            ),

            // 부품 카테고리 아이콘
            SizedBox(
              width: 80,
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 20,
                    color: dragonBall != null ? Theme.of(context).primaryColor : Colors.grey[400],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    displayName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: dragonBall != null ? FontWeight.w600 : FontWeight.normal,
                      color: dragonBall != null ? Colors.black87 : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),

            // 모델명
            Expanded(
              flex: 3,
              child: dragonBall != null
                  ? Text(
                      dragonBall.partName,
                      style: const TextStyle(fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  : Text(
                      '-',
                      style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                    ),
            ),

            // 입고일
            Expanded(
              flex: 2,
              child: dragonBall != null
                  ? Text(
                      _formatDate(dragonBall.storedAt),
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    )
                  : Text(
                      '-',
                      style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                    ),
            ),

            // 남은 기간
            Expanded(
              flex: 2,
              child: dragonBall != null
                  ? _buildDaysRemaining(dragonBall)
                  : Text(
                      '-',
                      style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDaysRemaining(DragonBallEntity dragonBall) {
    final days = dragonBall.daysUntilExpiration;
    final isExpiringSoon = dragonBall.isExpiringSoon;
    final isExpired = dragonBall.isExpired;

    Color textColor;
    if (isExpired) {
      textColor = Colors.red;
    } else if (isExpiringSoon) {
      textColor = Colors.orange[700]!;
    } else {
      textColor = Colors.green[700]!;
    }

    return Text(
      isExpired ? '만료됨' : '$days일',
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return '오늘';
    } else if (diff.inDays == 1) {
      return '어제';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}일 전';
    } else {
      return '${date.month}/${date.day}';
    }
  }
}

/// 추가 서비스 섹션
class _AdditionalServicesSection extends ConsumerWidget {
  const _AdditionalServicesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedServices = ref.watch(selectedAdditionalServicesProvider);
    final totalCost = ref.watch(selectedServicesCostProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 섹션 헤더
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '추가 서비스',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (selectedServices.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Text(
                  '+${_formatPrice(totalCost)}원',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange[700], size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '완제품 배송 시 추가 서비스를 선택할 수 있습니다',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.orange[900],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 추가 서비스 리스트
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildServiceItem(
                context,
                ref,
                service: AdditionalService.windowsHome,
                icon: Icons.window,
              ),
              Divider(height: 1, color: Colors.grey[300]),
              _buildServiceItem(
                context,
                ref,
                service: AdditionalService.windowsPro,
                icon: Icons.window_outlined,
              ),
              Divider(height: 1, color: Colors.grey[300]),
              _buildServiceItem(
                context,
                ref,
                service: AdditionalService.windowsInstallOnly,
                icon: Icons.download,
              ),
              Divider(height: 1, color: Colors.grey[300]),
              _buildServiceItem(
                context,
                ref,
                service: AdditionalService.assembly,
                icon: Icons.build,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildServiceItem(
    BuildContext context,
    WidgetRef ref, {
    required AdditionalService service,
    required IconData icon,
  }) {
    final selectedServices = ref.watch(selectedAdditionalServicesProvider);
    final isSelected = selectedServices.contains(service);

    return InkWell(
      onTap: () {
        ref.read(toggleAdditionalServiceProvider)(service);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            // 체크박스
            Checkbox(
              value: isSelected,
              onChanged: (value) {
                ref.read(toggleAdditionalServiceProvider)(service);
              },
              visualDensity: VisualDensity.compact,
            ),

            // 아이콘
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue[50] : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 22,
                color: isSelected ? Colors.blue[700] : Colors.grey[500],
              ),
            ),
            const SizedBox(width: 12),

            // 서비스 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.black87 : Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    service.description,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            // 가격
            Text(
              '+${_formatPrice(service.price)}원',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.blue[700] : Colors.grey[600],
              ),
            ),
          ],
        ),
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

/// 하단 액션 바
class _BottomActionBar extends ConsumerWidget {
  final WidgetRef ref;
  final int selectedCount;
  final int shippingCost;
  final int savings;
  final VoidCallback onRequestShipment;

  const _BottomActionBar({
    required this.ref,
    required this.selectedCount,
    required this.shippingCost,
    required this.savings,
    required this.onRequestShipment,
  });

  @override
  Widget build(BuildContext context, WidgetRef widgetRef) {
    final additionalServicesCost = widgetRef.watch(selectedServicesCostProvider);
    final totalCost = shippingCost + additionalServicesCost;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 배송비 정보
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '선택한 부품 $selectedCount개',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '배송비: ${_formatPrice(shippingCost)}원',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (additionalServicesCost > 0) ...[
                            const SizedBox(width: 8),
                            Text(
                              '+${_formatPrice(additionalServicesCost)}원',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue[700],
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (savings > 0)
                        Text(
                          '${_formatPrice(savings)}원 절약!',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: onRequestShipment,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  ),
                  child: Text(
                    '${_formatPrice(totalCost)}원\n배송 요청',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
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
