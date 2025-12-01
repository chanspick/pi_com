// lib/features/listing/presentation/screens/listing_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/listing_provider.dart';
import '../widgets/listing_image_carousel.dart';
import '../widgets/listing_header.dart';
import '../widgets/listing_price_info.dart';
import '../widgets/listing_bottom_bar.dart';
import '../../../my_page/presentation/providers/favorites_provider.dart';
import '../../../price_alert/presentation/widgets/price_alert_setup_dialog.dart';
import '../../../price_alert/presentation/providers/price_alert_provider.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/constants/routes.dart';
import '../../../../shared/utils/app_notification.dart';
import '../../../web_public/presentation/widgets/web_navbar_v2.dart';

class ListingDetailScreen extends ConsumerWidget {
  final String listingId;

  const ListingDetailScreen({super.key, required this.listingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingAsync = ref.watch(listingProvider(listingId));

    return Scaffold(
      appBar: kIsWeb
        ? const WebNavBarV2()
        : AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => context.pop(),
            ),
            actions: listingAsync.when(
              data: (listing) => [
                // 공유 버튼
                IconButton(
                  icon: const Icon(Icons.share_outlined, color: Colors.black),
                  onPressed: () {
                    AppNotification.showInfo(context, '공유 기능은 준비 중입니다.');
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
        data: (listing) => ResponsiveHelper.centeredMaxWidthContainer(
          context: context,
          child: ResponsiveHelper.isDesktop(context)
            ? _buildDesktopLayout(context, listing)
            : _buildMobileLayout(context, listing),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) {
          // 🔥 에러 발생 시 자동으로 favorites에서 제거
          _autoRemoveFromFavoritesOnError(ref, error);

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    '상품 정보를 불러올 수 없습니다',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getUserFriendlyErrorMessage(error),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('돌아가기'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    // 에러 상세 정보 다이얼로그
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('에러 상세 정보'),
                        content: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Listing ID: $listingId'),
                              const SizedBox(height: 8),
                              Text('에러: $error'),
                              const SizedBox(height: 8),
                              Text(
                                '💡 개발자용 팁:\n'
                                '1. Firebase Console에서 listings/$listingId 확인\n'
                                '2. 콘솔 로그 확인 (VSCode/Android Studio)\n'
                                '3. Firestore Rules 확인',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => context.pop(),
                            child: const Text('닫기'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text('상세 정보'),
                ),
              ],
            ),
          ),
        );
        },
      ),
      bottomNavigationBar: listingAsync.when(
        data: (listing) => ListingBottomBar(listing: listing),
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }

  // 데스크톱 레이아웃 (2단)
  Widget _buildDesktopLayout(BuildContext context, dynamic listing) {
    return SingleChildScrollView(
      padding: ResponsiveHelper.getHorizontalPadding(context).copyWith(
        top: 24,
        bottom: 100, // 하단 바 공간
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 좌측: 이미지 + 상세 정보
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListingImageCarousel(imageUrls: listing.imageUrls),
                const SizedBox(height: 32),
                _buildAdditionalInfo(listing),
                const SizedBox(height: 24),
                _buildPiComFeeInfo(context, listing),
                const SizedBox(height: 32),
                _buildPolicySection(context),
              ],
            ),
          ),
          const SizedBox(width: 32),

          // 우측: 헤더 + 가격 정보만 (구매 버튼은 하단 바에만)
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListingHeader(listing: listing),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 24),
                      ListingPriceInfo(listing: listing),
                      const SizedBox(height: 24),
                      // 구매 안내 메시지
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '구매는 하단의 버튼을 이용해주세요',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.blue[900],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 모바일 레이아웃 (세로 스택)
  Widget _buildMobileLayout(BuildContext context, dynamic listing) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListingImageCarousel(imageUrls: listing.imageUrls),
          ListingHeader(listing: listing),
          ListingPriceInfo(listing: listing),
          Divider(thickness: 8, color: Colors.grey[100]),
          _buildAdditionalInfo(listing),
          _buildPiComFeeInfo(context, listing),
          Divider(thickness: 8, color: Colors.grey[100]),
          _buildPolicySection(context),
        ],
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

  Widget _buildPiComFeeInfo(BuildContext context, dynamic listing) {
    // 가격에 따른 수수료 계산
    final price = listing.price;
    final feePercentage = price < 100000 ? 10 : 5;
    final feeAmount = (price * feePercentage / 100).round();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.orange[50],
          border: Border.all(color: Colors.orange[200]!),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange[700], size: 22),
                const SizedBox(width: 8),
                const Text(
                  'PiCom 이용 수수료',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '수수료 ($feePercentage%)',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                      Text(
                        '${feeAmount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Divider(color: Colors.grey[300], height: 1),
                  const SizedBox(height: 8),
                  Text(
                    '포함 내용:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildFeeIncludeItem('스트레스 테스트'),
                  const SizedBox(height: 4),
                  _buildFeeIncludeItem('3개월 기본 보증'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              price < 100000
                  ? '※ 10만원 미만 상품: 10% 수수료'
                  : '※ 10만원 이상 상품: 5% 수수료',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () {
                if (kIsWeb) {
                  context.push(Routes.terms);
                } else {
                  Navigator.pushNamed(context, Routes.terms);
                }
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '이용약관에서 자세히 보기',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue[700],
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: Colors.blue[700],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeeIncludeItem(String text) {
    return Row(
      children: [
        Icon(Icons.check_circle, size: 16, color: Colors.green[600]),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[700],
          ),
        ),
      ],
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

  Widget _buildPolicySection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '배송 및 반품 정보',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // 배송 정보
          _buildPolicyItem(
            '배송',
            '판매자 확인 후 1-3일 이내 배송\n배송비는 상품에 따라 다를 수 있습니다.',
            Icons.local_shipping_outlined,
          ),
          const SizedBox(height: 12),

          // 교환/환불 정책
          _buildPolicyItem(
            '교환/환불',
            '상품 수령 후 7일 이내 교환/환불 가능\n상품 하자 또는 오배송의 경우 30일 이내 환불 가능\n중고 부품 특성상 단순 변심 환불은 제한될 수 있습니다.',
            Icons.sync_outlined,
          ),
          const SizedBox(height: 12),

          // 환불 불가 사항
          _buildPolicyItem(
            '환불 불가',
            '상품 포장 훼손 또는 사용 흔적이 있는 경우\n구매자 책임으로 상품이 멸실/훼손된 경우',
            Icons.block_outlined,
          ),
          const SizedBox(height: 16),

          // 상세 정책 링크
          TextButton.icon(
            onPressed: () {
              if (kIsWeb) {
                context.push(Routes.refund);
              } else {
                Navigator.pushNamed(context, Routes.refund);
              }
            },
            icon: const Icon(Icons.info_outline, size: 18),
            label: const Text('환불 정책 자세히 보기'),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyItem(String title, String content, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 24, color: Colors.blue[700]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                content,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 에러 발생 시 자동으로 favorites에서 제거
  void _autoRemoveFromFavoritesOnError(WidgetRef ref, Object error) {
    final errorStr = error.toString().toLowerCase();

    // "listing not found" 에러인 경우에만 자동 제거
    if (errorStr.contains('listing not found') || errorStr.contains('document not found')) {
      print('🧹 [ListingDetailScreen] Auto-removing missing listing from favorites: $listingId');

      final actions = ref.read(favoritesActionsProvider);
      if (actions != null) {
        // 비동기 처리 (에러 무시)
        actions.removeFavorite(listingId).catchError((e) {
          print('  ❌ Failed to remove from favorites: $e');
        });
      }
    }
  }

  /// 사용자 친화적 에러 메시지 변환
  String _getUserFriendlyErrorMessage(Object error) {
    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('listing not found')) {
      return '이 상품은 현재 조회할 수 없습니다.\n삭제되었거나 판매 완료되었을 수 있습니다.';
    } else if (errorStr.contains('parse')) {
      return '상품 정보를 읽는 중 오류가 발생했습니다.\n잠시 후 다시 시도해주세요.';
    } else if (errorStr.contains('permission') || errorStr.contains('denied')) {
      return '상품 정보에 접근할 수 없습니다.\n로그인이 필요할 수 있습니다.';
    } else if (errorStr.contains('network') || errorStr.contains('connection')) {
      return '네트워크 연결을 확인해주세요.\n인터넷 연결이 필요합니다.';
    } else {
      return '일시적인 오류가 발생했습니다.\n잠시 후 다시 시도해주세요.';
    }
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
      AppNotification.showWarning(context, '이 상품은 가격 알림을 설정할 수 없습니다.');
      return;
    }

    final actions = ref.read(priceAlertActionsProvider);
    if (actions == null) {
      AppNotification.showWarning(context, '로그인이 필요합니다.');
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
