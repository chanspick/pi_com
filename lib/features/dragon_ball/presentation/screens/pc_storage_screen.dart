// lib/features/dragon_ball/presentation/screens/pc_storage_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pi_com/features/dragon_ball/presentation/providers/dragon_ball_provider.dart';
import 'package:pi_com/features/dragon_ball/presentation/screens/batch_shipment_request_screen.dart';
import 'package:pi_com/core/constants/routes.dart';
import 'package:pi_com/core/constants/storage_policy.dart';
import 'package:pi_com/features/dragon_ball/domain/entities/dragon_ball_entity.dart';

/// PC 보관함 화면 (리브랜딩: 드래곤볼 → PC 보관함)
///
/// 개선 사항:
/// - 카테고리 슬롯 제거, 리스트 뷰로 변경
/// - 배송비 정책 명확화 (개별 5,000원, 묶음 6,000원)
class PcStorageScreen extends ConsumerWidget {
  const PcStorageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dragonBallsAsync = ref.watch(userDragonBallsStreamProvider);
    final storedDragonBalls = ref.watch(storedDragonBallsProvider);
    final selectedIds = ref.watch(selectedDragonBallIdsProvider);
    final selectedCount = ref.watch(selectedDragonBallCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('PC 보관함'),
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
          return Column(
            children: [
              // 부품 리스트
              Expanded(
                child: storedDragonBalls.isEmpty
                    ? _EmptyState()
                    : _PartsList(parts: storedDragonBalls, ref: ref),
              ),

              // 하단 배송 요청 버튼
              if (selectedCount > 0)
                _BottomActionBar(
                  selectedCount: selectedCount,
                  selectedIds: selectedIds,
                  ref: ref,
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

/// 빈 상태 화면
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '보관 중인 부품이 없어요',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '부품을 구매하고 PC 보관을 선택하면\n부품을 모아서 완성 PC를 한 번에 받을 수 있어요',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).pushNamed(Routes.myEstimate);
              },
              icon: const Icon(Icons.lightbulb_outline),
              label: const Text('PC 견적 추천받기'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pushNamed(Routes.partShop);
              },
              icon: const Icon(Icons.shopping_bag),
              label: const Text('부품 쇼핑하러 가기'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 부품 리스트
class _PartsList extends ConsumerWidget {
  final List<DragonBallEntity> parts;
  final WidgetRef ref;

  const _PartsList({required this.parts, required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef widgetRef) {
    // 카테고리별 그룹화
    final Map<String, List<DragonBallEntity>> groupedParts = {};
    for (final part in parts) {
      final category = part.category?.toUpperCase() ?? '기타';
      groupedParts.putIfAbsent(category, () => []).add(part);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 안내 메시지
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '부품을 선택하고 일괄 배송을 요청하면 완성 PC를 받을 수 있어요',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.blue[900],
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 보관 부품 개수 및 배송비 정보
        _StorageSummary(totalCount: parts.length),
        const SizedBox(height: 24),

        // 카테고리별 부품 리스트
        ...groupedParts.entries.map((entry) {
          final category = entry.key;
          final categoryParts = entry.value;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Row(
                  children: [
                    Icon(_getCategoryIcon(category), size: 18, color: Colors.grey[700]),
                    const SizedBox(width: 6),
                    Text(
                      '$category (${categoryParts.length}개)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              ),
              ...categoryParts.map((part) => _PartCard(part: part, ref: widgetRef)),
              const SizedBox(height: 16),
            ],
          );
        }),
      ],
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toUpperCase()) {
      case 'CPU':
        return Icons.memory;
      case 'GPU':
        return Icons.videogame_asset;
      case 'MAINBOARD':
        return Icons.developer_board;
      case 'RAM':
        return Icons.storage;
      case 'SSD':
        return Icons.disc_full;
      case 'PSU':
        return Icons.power;
      case 'CASE':
        return Icons.computer;
      case 'COOLER':
        return Icons.ac_unit;
      default:
        return Icons.extension;
    }
  }
}

/// 보관 요약 정보
class _StorageSummary extends StatelessWidget {
  final int totalCount;

  const _StorageSummary({required this.totalCount});

  @override
  Widget build(BuildContext context) {
    final individualCost = StoragePolicy.calculateIndividualShippingCost(totalCount);
    final batchCost = StoragePolicy.calculateBatchShippingCost(totalCount);
    final savings = StoragePolicy.calculateShippingSavings(totalCount);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '보관 중인 부품',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                '$totalCount개',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '개별 배송 시',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                '${_formatPrice(individualCost)}원',
                style: TextStyle(
                  fontSize: 14,
                  decoration: TextDecoration.lineThrough,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '일괄 배송 시',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${_formatPrice(batchCost)}원',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          if (savings > 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Colors.green[700], size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '${_formatPrice(savings)}원 절약!',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
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

/// 부품 카드
class _PartCard extends ConsumerWidget {
  final DragonBallEntity part;
  final WidgetRef ref;

  const _PartCard({required this.part, required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef widgetRef) {
    final selectedIds = widgetRef.watch(selectedDragonBallIdsProvider);
    final isSelected = selectedIds.contains(part.dragonBallId);
    final daysLeft = StoragePolicy.calculateDaysUntilExpiration(part.storedAt);
    final isExpiring = StoragePolicy.isExpiringSoon(part.storedAt);
    final isUrgent = StoragePolicy.isUrgentWarning(part.storedAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () {
          widgetRef.read(toggleDragonBallSelectionProvider)(part.dragonBallId);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // 체크박스
              Checkbox(
                value: isSelected,
                onChanged: (value) {
                  widgetRef.read(toggleDragonBallSelectionProvider)(part.dragonBallId);
                },
              ),
              const SizedBox(width: 12),

              // 부품 이미지
              if (part.imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    part.imageUrl!,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey[200],
                      child: const Icon(Icons.image, color: Colors.grey),
                    ),
                  ),
                )
              else
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.extension, color: Colors.grey),
                ),
              const SizedBox(width: 12),

              // 부품 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      part.partName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_formatDate(part.storedAt)} 입고',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildExpirationBadge(daysLeft, isExpiring, isUrgent),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpirationBadge(int daysLeft, bool isExpiring, bool isUrgent) {
    Color bgColor;
    Color textColor;
    String text;

    if (daysLeft <= 0) {
      bgColor = Colors.red[50]!;
      textColor = Colors.red[700]!;
      text = '만료됨';
    } else if (isUrgent) {
      bgColor = Colors.orange[50]!;
      textColor = Colors.orange[700]!;
      text = '긴급 ($daysLeft일 남음)';
    } else if (isExpiring) {
      bgColor = Colors.yellow[50]!;
      textColor = Colors.orange[800]!;
      text = '$daysLeft일 남음';
    } else {
      bgColor = Colors.green[50]!;
      textColor = Colors.green[700]!;
      text = '$daysLeft일 남음';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}';
  }
}

/// 하단 액션 바
class _BottomActionBar extends ConsumerWidget {
  final int selectedCount;
  final Set<String> selectedIds;
  final WidgetRef ref;

  const _BottomActionBar({
    required this.selectedCount,
    required this.selectedIds,
    required this.ref,
  });

  @override
  Widget build(BuildContext context, WidgetRef widgetRef) {
    final shippingCost = StoragePolicy.calculateBatchShippingCost(selectedCount);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                  Text(
                    '배송비: ${_formatPrice(shippingCost)}원',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => BatchShipmentRequestScreen(
                      dragonBallIds: selectedIds.toList(),
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                '배송 요청',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
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
