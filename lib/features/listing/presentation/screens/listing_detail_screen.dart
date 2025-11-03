// lib/features/listing/presentation/screens/listing_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/listing_provider.dart';
import '../widgets/listing_image_carousel.dart';
import '../widgets/listing_header.dart';
import '../widgets/listing_price_info.dart';
import '../widgets/listing_bottom_bar.dart';
import '../../../my_page/presentation/providers/favorites_provider.dart';
import '../../../price_alert/presentation/widgets/price_alert_setup_dialog.dart';
import '../../../price_alert/presentation/providers/price_alert_provider.dart';

class ListingDetailScreen extends ConsumerWidget {
  final String listingId;

  const ListingDetailScreen({super.key, required this.listingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingAsync = ref.watch(listingProvider(listingId));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: listingAsync.when(
          data: (listing) => [
            // 공유 버튼
            IconButton(
              icon: const Icon(Icons.share_outlined, color: Colors.black),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('공유 기능은 준비 중입니다.')),
                );
              },
            ),

            // 가격 알림 버튼
            IconButton(
              icon: const Icon(Icons.notifications_outlined, color: Colors.black),
              onPressed: () => _showPriceAlertDialog(context, ref, listing),
              tooltip: '가격 알림',
            ),

            // 찜 버튼
            _buildFavoriteButton(ref, listing),
          ],
          loading: () => [],
          error: (_, __) => [],
        ),
      ),
      body: listingAsync.when(
        data: (listing) => SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListingImageCarousel(imageUrls: listing.imageUrls),
              ListingHeader(listing: listing),
              ListingPriceInfo(listing: listing),
              Divider(thickness: 8, color: Colors.grey[100]),
              // 추가 정보 섹션
              _buildAdditionalInfo(listing),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  '상품 정보를 불러올 수 없습니다.',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('돌아가기'),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: listingAsync.when(
        data: (listing) => ListingBottomBar(listing: listing),
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildAdditionalInfo(dynamic listing) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '상품 정보',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildInfoRow('등록일', _formatDate(listing.createdAt)),
          _buildInfoRow('상태', '${listing.conditionScore}점'),
          if (listing.category != null)
            _buildInfoRow('카테고리', listing.category!),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  /// 찜 버튼 위젯
  Widget _buildFavoriteButton(WidgetRef ref, dynamic listing) {
    final isFavAsync = ref.watch(isFavoriteProvider(listingId));

    return isFavAsync.when(
      data: (isFav) => IconButton(
        icon: Icon(
          isFav ? Icons.favorite : Icons.favorite_border,
          color: isFav ? Colors.red : Colors.black,
        ),
        onPressed: () => _toggleFavorite(ref, listing),
        tooltip: '찜',
      ),
      loading: () => const IconButton(
        icon: Icon(Icons.favorite_border, color: Colors.black),
        onPressed: null,
      ),
      error: (_, __) => const IconButton(
        icon: Icon(Icons.favorite_border, color: Colors.black),
        onPressed: null,
      ),
    );
  }

  /// 찜 추가/제거
  Future<void> _toggleFavorite(WidgetRef ref, dynamic listing) async {
    final actions = ref.read(favoritesActionsProvider);
    if (actions == null) {
      return;
    }

    try {
      await actions.toggleFavorite(listingId);
    } catch (e) {
      // 에러 무시 (사용자 경험 우선)
    }
  }

  /// 가격 알림 다이얼로그 표시
  Future<void> _showPriceAlertDialog(
    BuildContext context,
    WidgetRef ref,
    dynamic listing,
  ) async {
    // basePartId가 없으면 알림 설정 불가
    if (listing.basePartId == null || listing.basePartId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('이 상품은 가격 알림을 설정할 수 없습니다'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final actions = ref.read(priceAlertActionsProvider);
    if (actions == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인이 필요합니다')),
      );
      return;
    }

    // 기존 알림 확인
    final existingAlert = await actions.getAlertForBasePart(listing.basePartId);

    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (context) => PriceAlertSetupDialog(
        basePartId: listing.basePartId,
        partName: '${listing.brand} ${listing.modelName}',
        currentPrice: listing.price,
        existingAlert: existingAlert,
      ),
    );
  }
}
