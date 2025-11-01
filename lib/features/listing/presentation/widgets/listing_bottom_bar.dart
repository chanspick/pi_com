// lib/features/listing/presentation/widgets/listing_bottom_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/listing_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../providers/use_case_providers.dart';


class ListingBottomBar extends ConsumerWidget {
  final ListingEntity listing;

  const ListingBottomBar({super.key, required this.listing});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);

    final bool isSold = listing.isSold;
    final bool isMyItem = currentUser?.uid == listing.sellerId;
    final bool canPurchase = !isSold && !isMyItem && currentUser != null;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: canPurchase ? Colors.red : Colors.grey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: canPurchase
                  ? () => _handlePurchase(context, ref, listing, currentUser!.uid)
                  : null,
              child: Text(
                isSold ? '판매 완료' : (isMyItem ? '내 판매 상품' : '구매하기'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handlePurchase(
      BuildContext context,
      WidgetRef ref,
      ListingEntity listing,
      String userId,
      ) async { // async 키워드 추가
    try {
      // 구매 가능 여부 검증
      final validatePurchaseUseCase = ref.read(validatePurchaseUseCaseProvider);
      validatePurchaseUseCase(listing, userId);

      // CartItem 생성
      final createCartItemUseCase = ref.read(createCartItemUseCaseProvider);
      final cartItem = createCartItemUseCase(listing);

      // Firestore에 장바구니 아이템 저장
      final cartRepository = ref.read(cartRepositoryProvider);
      await cartRepository.addToCart(cartItem); // await을 사용하여 비동기 완료 대기

      // 장바구니 추가 성공 알림
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${listing.modelName}을(를) 장바구니에 담았습니다.'),
          action: SnackBarAction(
            label: '보기',
                          onPressed: () {
                            Navigator.of(context).pushNamed('/cart');
                          },          ),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('오류: ${e.toString()}'), // 사용자에게 오류 메시지 표시
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
