// lib/features/dragon_ball/presentation/screens/dragon_ball_storage_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pi_com/features/dragon_ball/presentation/providers/dragon_ball_provider.dart';
import 'package:pi_com/features/dragon_ball/presentation/widgets/dragon_ball_card.dart';
import 'package:pi_com/features/dragon_ball/presentation/widgets/dragon_ball_storage_summary.dart';
import 'package:pi_com/core/constants/routes.dart';
import 'package:pi_com/features/listing/presentation/providers/listing_provider.dart';

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

              // 드래곤볼 리스트
              Expanded(
                child: ListView.builder(
                  itemCount: storedDragonBalls.length,
                  itemBuilder: (context, index) {
                    final dragonBall = storedDragonBalls[index];
                    final isSelected = selectedIds.contains(dragonBall.dragonBallId);

                    return DragonBallCard(
                      dragonBall: dragonBall,
                      isSelected: isSelected,
                      onTap: () {
                        ref.read(toggleDragonBallSelectionProvider)(dragonBall.dragonBallId);
                      },
                    );
                  },
                ),
              ),

              // 하단 버튼
              if (selectedCount > 0) _BottomActionBar(
                selectedCount: selectedCount,
                shippingCost: shippingCost,
                savings: savings,
                onRequestShipment: () {
                  Navigator.of(context).pushNamed(
                    Routes.batchShipmentRequest,
                    arguments: selectedIds.toList(),
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

/// 빈 상태 위젯 - 부품 카테고리 슬롯 UI
class _EmptyState extends StatelessWidget {
  final WidgetRef ref;

  const _EmptyState({required this.ref});

  // 부품 카테고리 정의
  static const partCategories = [
    {'name': 'CPU', 'icon': Icons.memory, 'max': 1},
    {'name': 'GPU', 'icon': Icons.videogame_asset, 'max': 1},
    {'name': 'MB', 'icon': Icons.developer_board, 'max': 1},
    {'name': 'RAM', 'icon': Icons.storage, 'max': 99}, // 램은 특수하게 n개
    {'name': 'SSD', 'icon': Icons.disc_full, 'max': 1},
    {'name': 'Power', 'icon': Icons.power, 'max': 1},
    {'name': 'Case', 'icon': Icons.computer, 'max': 1},
    {'name': 'Cooler', 'icon': Icons.ac_unit, 'max': 1},
  ];

  // 서비스 옵션
  static const services = [
    {'name': '윈도우 설치', 'price': 20000},
    {'name': 'PC 조립 공임', 'price': 30000},
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 헤더
          Text(
            '나만의 PC 구성하기',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '부품을 구매할 때 드래곤볼 보관을 선택하면 30일간 무료 보관 후\n여러 부품을 합배송하여 배송비를 절약할 수 있어요!',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),

          // 부품 슬롯 섹션
          _buildSectionTitle(context, '필수 부품'),
          const SizedBox(height: 12),
          ...partCategories.map((category) => _buildPartSlot(
            context,
            category['name'] as String,
            category['icon'] as IconData,
            category['max'] as int,
          )),

          const SizedBox(height: 32),

          // 서비스 선택 섹션
          _buildSectionTitle(context, '추가 서비스 (선택)'),
          const SizedBox(height: 12),
          ...services.map((service) => _buildServiceOption(
            context,
            service['name'] as String,
            service['price'] as int,
          )),

          const SizedBox(height: 32),

          // PC 추천 버튼
          OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('PC 추천 기능은 준비 중입니다')),
              );
            },
            icon: const Icon(Icons.lightbulb_outline),
            label: const Text('AI PC 추천 받기'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: Theme.of(context).primaryColor, width: 2),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildPartSlot(BuildContext context, String categoryName, IconData icon, int maxCount) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[50],
      ),
      child: Row(
        children: [
          // 아이콘
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Icon(icon, size: 28, color: Colors.grey[400]),
          ),
          const SizedBox(width: 16),

          // 카테고리 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  categoryName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  maxCount == 1 ? '1개 선택 가능' : '최대 $maxCount개',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // 구매 버튼
          ElevatedButton(
            onPressed: () {
              // 카테고리 설정 후 부품 샵으로 이동
              ref.read(selectedCategoryProvider.notifier).state = categoryName;
              Navigator.of(context).pushNamed(Routes.partShop);
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('구매', style: TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceOption(BuildContext context, String serviceName, int price) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Row(
        children: [
          // 체크박스
          Checkbox(
            value: false,
            onChanged: (value) {
              // TODO: 서비스 선택 상태 관리
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('서비스 선택 기능은 준비 중입니다')),
              );
            },
          ),
          const SizedBox(width: 8),

          // 서비스 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  serviceName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '+${_formatPrice(price)}원',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
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

/// 하단 액션 바
class _BottomActionBar extends StatelessWidget {
  final int selectedCount;
  final int shippingCost;
  final int savings;
  final VoidCallback onRequestShipment;

  const _BottomActionBar({
    required this.selectedCount,
    required this.shippingCost,
    required this.savings,
    required this.onRequestShipment,
  });

  @override
  Widget build(BuildContext context) {
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '선택한 부품 $selectedCount개',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '배송비: ${_formatPrice(shippingCost)}원',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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
                ElevatedButton(
                  onPressed: onRequestShipment,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  child: const Text(
                    '배송 요청',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
