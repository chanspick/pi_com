// lib/features/listing/presentation/widgets/listing_card.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../domain/entities/listing_entity.dart';
import '../screens/listing_detail_screen.dart';
import '../../../my_page/presentation/providers/favorites_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/utils/responsive_helper.dart';

class ListingCard extends ConsumerStatefulWidget {
  final ListingEntity listing;

  const ListingCard({super.key, required this.listing});

  @override
  ConsumerState<ListingCard> createState() => _ListingCardState();
}

class _ListingCardState extends ConsumerState<ListingCard> {
  bool _isTogglingFavorite = false;

  Future<void> _toggleFavorite() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('찜 기능은 로그인 후 이용할 수 있습니다'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_isTogglingFavorite) return;

    setState(() => _isTogglingFavorite = true);

    try {
      final actions = ref.read(favoritesActionsProvider);
      if (actions != null) {
        await actions.toggleFavorite(widget.listing.listingId);
        if (!mounted) return;

        // 현재 찜 상태 확인
        final isFav = await ref.read(favoritesRepositoryProvider).isFavorite(
          currentUser.uid,
          widget.listing.listingId
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isFav ? '찜 목록에 추가했습니다' : '찜 목록에서 제거했습니다'),
            duration: const Duration(seconds: 2),
            backgroundColor: isFav ? Colors.green : Colors.grey[700],
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('오류가 발생했습니다: $e'),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isTogglingFavorite = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###');
    final currentUser = ref.watch(currentUserProvider);
    final isMobile = ResponsiveHelper.isMobile(context);
    final screenWidth = MediaQuery.of(context).size.width;

    // 반응형 폰트 크기
    final brandFontSize = isMobile ? 9.0 : 10.0;
    final modelFontSize = isMobile ? 11.0 : 12.0;
    final priceFontSize = isMobile ? 12.0 : 14.0;
    // 반응형 패딩
    final cardPadding = isMobile ? 6.0 : 8.0;
    // 반응형 아이콘 크기
    final iconSize = screenWidth < 360 ? 14.0 : 18.0;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 6,
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ListingDetailScreen(listingId: widget.listing.listingId),
          ));
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      child: kIsWeb
                          ? (widget.listing.imageUrls.isNotEmpty
                              ? Image.network(
                                  widget.listing.imageUrls.first,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey[200],
                                      child: Icon(
                                        Icons.broken_image,
                                        size: iconSize * 2,
                                        color: Colors.grey,
                                      ),
                                    );
                                  },
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      color: Colors.grey[200],
                                      child: Center(
                                        child: SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            value: loadingProgress.expectedTotalBytes != null
                                                ? loadingProgress.cumulativeBytesLoaded /
                                                    loadingProgress.expectedTotalBytes!
                                                : null,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                )
                              : Container(
                                  color: Colors.grey[200],
                                  child: Icon(
                                    Icons.image_not_supported,
                                    size: iconSize * 2,
                                    color: Colors.grey,
                                  ),
                                ))
                          : CachedNetworkImage(
                              imageUrl: widget.listing.imageUrls.isNotEmpty ? widget.listing.imageUrls.first : '',
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              placeholder: (context, url) => Container(color: Colors.grey[200]),
                              errorWidget: (context, url, error) => Icon(
                                Icons.broken_image,
                                size: iconSize * 2,
                                color: Colors.grey,
                              ),
                            ),
                    ),
                  ),
                  // 찜 버튼 (우측 상단)
                  if (currentUser != null)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Consumer(
                        builder: (context, ref, child) {
                          final favoritesIdsAsync = ref.watch(favoritesIdsProvider);
                          final isFavorite = favoritesIdsAsync.when(
                            data: (ids) => ids.contains(widget.listing.listingId),
                            loading: () => false,
                            error: (_, __) => false,
                          );

                          return Material(
                            color: Colors.white.withOpacity(0.9),
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: _isTogglingFavorite ? null : _toggleFavorite,
                              child: Padding(
                                padding: EdgeInsets.all(isMobile ? 4 : 6),
                                child: _isTogglingFavorite
                                    ? SizedBox(
                                        width: iconSize,
                                        height: iconSize,
                                        child: const CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : Icon(
                                        isFavorite ? Icons.favorite : Icons.favorite_border,
                                        size: iconSize,
                                        color: isFavorite ? Colors.red : Colors.grey[700],
                                      ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: cardPadding, vertical: cardPadding / 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.listing.brand,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: brandFontSize, color: Colors.grey),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.listing.modelName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: modelFontSize,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${formatter.format(widget.listing.price)}원',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: priceFontSize,
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
