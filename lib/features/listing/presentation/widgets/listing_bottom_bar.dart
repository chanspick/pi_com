// lib/features/listing/presentation/widgets/listing_bottom_bar.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/listing_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../../checkout/presentation/screens/checkout_screen.dart';
import '../providers/use_case_providers.dart';
import '../../../../core/constants/routes.dart';

class ListingBottomBar extends ConsumerStatefulWidget {
  final ListingEntity listing;

  const ListingBottomBar({super.key, required this.listing});

  @override
  ConsumerState<ListingBottomBar> createState() => _ListingBottomBarState();
}

class _ListingBottomBarState extends ConsumerState<ListingBottomBar> {
  bool _isAddingToCart = false;

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    final bool isSold = widget.listing.isSold;
    final bool isMyItem = currentUser?.uid == widget.listing.sellerId;
    final bool canPurchase = !isSold && !isMyItem && currentUser != null;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: _buildButtons(context, canPurchase, isSold, isMyItem, currentUser),
      ),
    );
  }

  Widget _buildButtons(
    BuildContext context,
    bool canPurchase,
    bool isSold,
    bool isMyItem,
    dynamic currentUser,
  ) {
    if (!canPurchase) {
      // 구매 불가능한 경우 (판매 완료, 내 상품, 로그인 안함)
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: null,
          child: Text(
            isSold ? '판매 완료' : (isMyItem ? '내 판매 상품' : '로그인 필요'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    // 구매 가능한 경우 - "장바구니" + "바로 구매" 버튼
    return Row(
      children: [
        // 장바구니 버튼
        Expanded(
          flex: 1,
          child: OutlinedButton.icon(
            icon: _isAddingToCart
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.shopping_cart_outlined),
            label: const Text('장바구니'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: Theme.of(context).primaryColor),
              foregroundColor: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: _isAddingToCart
                ? null
                : () => _handleAddToCart(context, currentUser.uid),
          ),
        ),
        const SizedBox(width: 12),

        // 바로 구매 버튼
        Expanded(
          flex: 2,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => _handleDirectPurchase(context, currentUser.uid),
            child: const Text(
              '바로 구매',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleAddToCart(BuildContext context, String userId) async {
    setState(() => _isAddingToCart = true);

    try {
      // 1. 장바구니에 이미 있는지 확인
      final cartItemsAsync = ref.read(cartItemsStreamProvider);
      final alreadyInCart = cartItemsAsync.when(
        data: (items) => items.any((item) => item.listingId == widget.listing.listingId),
        loading: () => false,
        error: (_, __) => false,
      );

      if (alreadyInCart) {
        if (!mounted) return;
        _showCartBottomSheet(
          context: context,
          title: '이미 장바구니에 있어요',
          message: '${widget.listing.modelName}',
          isAlreadyInCart: true,
        );
        return;
      }

      // 2. 구매 가능 여부 검증
      final validatePurchaseUseCase = ref.read(validatePurchaseUseCaseProvider);
      validatePurchaseUseCase(widget.listing, userId);

      // 3. CartItem 생성 (async 처리)
      final createCartItemUseCase = ref.read(createCartItemUseCaseProvider);
      final cartItem = await createCartItemUseCase(widget.listing);

      // 4. Firestore에 장바구니 추가
      final addToCart = ref.read(addToCartProvider);
      await addToCart(cartItem);

      // 5. 성공 알림 - 소비자 친화적인 바텀시트
      if (!mounted) return;
      _showCartBottomSheet(
        context: context,
        title: '장바구니에 담았어요',
        message: '${widget.listing.modelName}',
        isAlreadyInCart: false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isAddingToCart = false);
      }
    }
  }

  /// 바로 구매 처리
  Future<void> _handleDirectPurchase(BuildContext context, String userId) async {
    try {
      // 1. 구매 가능 여부 검증
      final validatePurchaseUseCase = ref.read(validatePurchaseUseCaseProvider);
      validatePurchaseUseCase(widget.listing, userId);

      // 2. CartItem 생성 (장바구니에 추가하지 않음)
      final createCartItemUseCase = ref.read(createCartItemUseCaseProvider);
      final cartItem = await createCartItemUseCase(widget.listing);

      // 3. CheckoutScreen으로 직접 이동 (장바구니 우회)
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CheckoutScreen(
            directPurchaseItem: cartItem, // 바로구매 상품 직접 전달
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  /// 장바구니 추가 완료 바텀시트 (소비자 친화적 UX)
  void _showCartBottomSheet({
    required BuildContext context,
    required String title,
    required String message,
    required bool isAlreadyInCart,
  }) {
    final formatter = NumberFormat('#,###');

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 드래그 핸들
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // 체크 아이콘
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: isAlreadyInCart
                      ? Colors.orange.withOpacity(0.1)
                      : Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isAlreadyInCart ? Icons.info_outline : Icons.check_circle,
                  size: 36,
                  color: isAlreadyInCart ? Colors.orange : Colors.green,
                ),
              ),
              const SizedBox(height: 16),

              // 타이틀
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // 상품 정보
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    // 상품 이미지
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: widget.listing.imageUrls.isNotEmpty
                          ? Image.network(
                              widget.listing.imageUrls.first,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 60,
                                height: 60,
                                color: Colors.grey[200],
                                child: const Icon(Icons.image, color: Colors.grey),
                              ),
                            )
                          : Container(
                              width: 60,
                              height: 60,
                              color: Colors.grey[200],
                              child: const Icon(Icons.image, color: Colors.grey),
                            ),
                    ),
                    const SizedBox(width: 12),

                    // 상품 정보
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.listing.brand,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            widget.listing.modelName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${formatter.format(widget.listing.price)}원',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 버튼들
              Row(
                children: [
                  // 계속 쇼핑하기
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.grey[400]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '계속 쇼핑하기',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // 장바구니 보기
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // 바텀시트 닫기
                        if (kIsWeb) {
                          context.go(Routes.cart);
                        } else {
                          Navigator.pushNamed(context, Routes.cart);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '장바구니 보기',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
