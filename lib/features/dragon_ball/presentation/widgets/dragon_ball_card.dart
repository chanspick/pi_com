// lib/features/dragon_ball/presentation/widgets/dragon_ball_card.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pi_com/features/dragon_ball/domain/entities/dragon_ball_entity.dart';
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

                    // 입고일 & 남은 일수
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
                          Icons.access_time,
                          size: 14,
                          color: dragonBall.isExpiringSoon ? Colors.red : Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${dragonBall.daysUntilExpiration}일 남음',
                          style: TextStyle(
                            fontSize: 12,
                            color: dragonBall.isExpiringSoon ? Colors.red : Colors.grey[600],
                            fontWeight: dragonBall.isExpiringSoon ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
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

    if (dragonBall.isExpiringSoon) {
      backgroundColor = Colors.red[100]!;
      textColor = Colors.red[900]!;
      text = '🔴 만료 임박!';
    } else {
      backgroundColor = Colors.green[100]!;
      textColor = Colors.green[900]!;
      text = '🟢 보관 중';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
