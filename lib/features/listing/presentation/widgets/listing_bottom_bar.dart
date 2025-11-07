// lib/features/listing/presentation/widgets/listing_bottom_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      // 1. 구매 가능 여부 검증
      final validatePurchaseUseCase = ref.read(validatePurchaseUseCaseProvider);
      validatePurchaseUseCase(widget.listing, userId);

      // 2. CartItem 생성 (async 처리)
      final createCartItemUseCase = ref.read(createCartItemUseCaseProvider);
      final cartItem = await createCartItemUseCase(widget.listing);

      // 3. Firestore에 장바구니 추가
      final addToCart = ref.read(addToCartProvider);
      await addToCart(cartItem);

      // 4. 성공 알림
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.listing.modelName}을(를) 장바구니에 담았습니다'),
          action: SnackBarAction(
            label: '장바구니 보기',
            onPressed: () {
              Navigator.pushNamed(context, Routes.cart);
            },
          ),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.green,
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
}
