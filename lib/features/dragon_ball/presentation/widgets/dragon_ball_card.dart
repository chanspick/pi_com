// lib/features/dragon_ball/presentation/widgets/dragon_ball_card.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pi_com/features/dragon_ball/domain/entities/dragon_ball_entity.dart';
import 'package:pi_com/core/models/dragon_ball_model.dart';
import 'package:pi_com/core/constants/storage_policy.dart';
import 'package:intl/intl.dart';

/// 드래곤볼 카드 위젯
class DragonBallCard extends StatelessWidget {
  final DragonBallEntity dragonBall;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const DragonBallCard({
    required this.dragonBall,
    required this.isSelected,
    required this.onTap,
    this.onLongPress,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: Theme.of(context).primaryColor, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // 체크박스
              Checkbox(
                value: isSelected,
                onChanged: (_) => onTap(),
                shape: const CircleBorder(),
              ),
              const SizedBox(width: 8),

              // 이미지
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: dragonBall.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: dragonBall.imageUrl!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey[200],
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey[200],
                          child: const Icon(Icons.memory, color: Colors.grey),
                        ),
                      )
                    : Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[200],
                        child: const Icon(Icons.memory, color: Colors.grey),
                      ),
              ),
              const SizedBox(width: 12),

              // 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 부품명
                    Text(
                      dragonBall.partName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // 입고일 & 보관 일수
                    Row(
                      children: [
                        Text(
                          '입고: ${dateFormat.format(dragonBall.storedAt)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '|',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${StoragePolicy.calculateStorageDays(dragonBall.storedAt)}일 보관 중',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // 무료 기간 남은 일수 (7일 이내)
                    if (dragonBall.daysUntilExpiration > 0)
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: dragonBall.isExpiringSoon ? Colors.red : Colors.green[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '무료 기간 ${dragonBall.daysUntilExpiration}일 남음',
                            style: TextStyle(
                              fontSize: 12,
                              color: dragonBall.isExpiringSoon ? Colors.red : Colors.green[700],
                              fontWeight: dragonBall.isExpiringSoon ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 4),

                    // 위탁판매 경고 (50일 이상)
                    if (StoragePolicy.shouldShowConsignmentWarning(dragonBall.storedAt))
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange[300]!),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.warning_amber, size: 14, color: Colors.orange[900]),
                            const SizedBox(width: 4),
                            Text(
                              '위탁판매까지 ${StoragePolicy.getDaysUntilConsignment(dragonBall.storedAt)}일',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.orange[900],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (StoragePolicy.shouldShowConsignmentWarning(dragonBall.storedAt))
                      const SizedBox(height: 4),

                    // 30일 초과 경고
                    if (StoragePolicy.hasExceededMaxStorageDays(dragonBall.storedAt))
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red[300]!),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.error_outline, size: 14, color: Colors.red[900]),
                            const SizedBox(width: 4),
                            Text(
                              '최대 보관 기간 초과 - 위탁판매 전환 중',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.red[900],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (StoragePolicy.hasExceededMaxStorageDays(dragonBall.storedAt))
                      const SizedBox(height: 4),

                    // 상태 배지
                    _StatusBadge(dragonBall: dragonBall),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 상태 배지
class _StatusBadge extends StatelessWidget {
  final DragonBallEntity dragonBall;

  const _StatusBadge({required this.dragonBall});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    String text;
    String icon;

    // 위탁판매 상태
    if (dragonBall.status == DragonBallStatus.consignment) {
      backgroundColor = Colors.purple[100]!;
      textColor = Colors.purple[900]!;
      text = '위탁판매 중';
      icon = '🏪';
    }
    // 매각 완료 상태
    else if (dragonBall.status == DragonBallStatus.sold) {
      backgroundColor = Colors.teal[100]!;
      textColor = Colors.teal[900]!;
      text = '매각 완료';
      icon = '✅';
    }
    // 배송 완료
    else if (dragonBall.status == DragonBallStatus.delivered) {
      backgroundColor = Colors.grey[200]!;
      textColor = Colors.grey[800]!;
      text = '배송 완료';
      icon = '📦';
    }
    // 배송 중
    else if (dragonBall.status == DragonBallStatus.shipping) {
      backgroundColor = Colors.blue[100]!;
      textColor = Colors.blue[900]!;
      text = '배송 중';
      icon = '🚚';
    }
    // 배송 준비 중
    else if (dragonBall.status == DragonBallStatus.packing) {
      backgroundColor = Colors.orange[100]!;
      textColor = Colors.orange[900]!;
      text = '배송 준비 중';
      icon = '📋';
    }
    // 보관 중 - 만료 임박
    else if (dragonBall.isExpiringSoon) {
      backgroundColor = Colors.red[100]!;
      textColor = Colors.red[900]!;
      text = '만료 임박!';
      icon = '🔴';
    }
    // 보관 중 - 정상
    else {
      backgroundColor = Colors.green[100]!;
      textColor = Colors.green[900]!;
      text = '보관 중';
      icon = '🟢';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$icon $text',
        style: TextStyle(
          fontSize: 11,
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
