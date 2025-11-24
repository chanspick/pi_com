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
                                      child: const Icon(
                                        Icons.broken_image,
                                        size: 40,
                                        color: Colors.grey,
                                      ),
                                    );
                                  },
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      color: Colors.grey[200],
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          value: loadingProgress.expectedTotalBytes != null
                                              ? loadingProgress.cumulativeBytesLoaded /
                                                  loadingProgress.expectedTotalBytes!
                                              : null,
                                        ),
                                      ),
                                    );
                                  },
                                )
                              : Container(
                                  color: Colors.grey[200],
                                  child: const Icon(
                                    Icons.image_not_supported,
                                    size: 40,
                                    color: Colors.grey,
                                  ),
                                ))
                          : CachedNetworkImage(
                              imageUrl: widget.listing.imageUrls.isNotEmpty ? widget.listing.imageUrls.first : '',
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              placeholder: (context, url) => Container(color: Colors.grey[200]),
                              errorWidget: (context, url, error) => const Icon(
                                Icons.broken_image,
                                size: 40,
                                color: Colors.grey,
                              ),
                            ),
                    ),
                  ),
                  // 찜 버튼 (우측 상단)
                  if (currentUser != null)
                    Positioned(
                      top: 6,
                      right: 6,
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
                                padding: const EdgeInsets.all(6),
                                child: _isTogglingFavorite
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : Icon(
                                        isFavorite ? Icons.favorite : Icons.favorite_border,
                                        size: 18,
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                          Text(
                            widget.listing.modelName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${formatter.format(widget.listing.price)}원',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
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
