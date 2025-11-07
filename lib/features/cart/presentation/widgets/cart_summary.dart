
// lib/features/cart/presentation/widgets/cart_summary.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pi_com/features/cart/domain/entities/cart_item_entity.dart';
import 'package:pi_com/features/cart/presentation/providers/cart_provider.dart';
import 'package:pi_com/core/constants/routes.dart';

class CartSummary extends ConsumerWidget {
  final List<CartItemEntity> items;

  const CartSummary({
    super.key,
    required this.items,
  });

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  int get _totalProductPrice {
    return items.fold(0, (total, item) => total + item.totalPrice);
  }

  int _getShippingCost(WidgetRef ref) {
    // 판매자 수에 따라 배송비 계산 (판매자당 3000원)
    final totalShippingFee = ref.watch(totalShippingFeeProvider);
    return totalShippingFee;
  }

  int _getFinalTotal(WidgetRef ref) {
    return _totalProductPrice + _getShippingCost(ref);
  }

  int _getSellerCount(WidgetRef ref) {
    final groupedItems = ref.watch(cartItemsBySellerProvider);
    return groupedItems.keys.length;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sellerCount = _getSellerCount(ref);
    final shippingCost = _getShippingCost(ref);
    final finalTotal = _getFinalTotal(ref);

    return Container(
      padding: const EdgeInsets.all(16),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 판매자 수 표시
            if (sellerCount > 1) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 20, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$sellerCount명의 판매자로부터 구매합니다',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // 가격 정보
            _buildPriceRow('상품 금액', _totalProductPrice, isSubtotal: true),
            const SizedBox(height: 8),
            _buildPriceRow(
              sellerCount > 1 ? '배송비 ($sellerCount명 × 3,000원)' : '배송비',
              shippingCost,
              isSubtotal: true,
            ),
            const Divider(height: 24),
            _buildPriceRow('총 결제 금액', finalTotal, isFinal: true),

            const SizedBox(height: 16),

            // 버튼 그룹
            Column(
              children: [
                // 장바구니 비우기 버튼
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('장바구니 비우기'),
                          content: const Text('장바구니의 모든 상품을 삭제하시겠습니까?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('취소'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: const Text('비우기'),
                            ),
                          ],
                        ),
                      );

                      if (confirmed == true) {
                        await ref.read(clearCartProvider).call();
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.grey[400]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('장바구니 비우기', style: TextStyle(fontSize: 14)),
                  ),
                ),
                const SizedBox(height: 8),
                // 결제하기 버튼
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // CheckoutScreen으로 이동
                      Navigator.pushNamed(context, Routes.checkout);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      '${_formatPrice(finalTotal)}원 결제하기',
                      style: const TextStyle(
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
    );
  }

  Widget _buildPriceRow(String label, int price, {bool isSubtotal = false, bool isFinal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isFinal ? 16 : 14,
            fontWeight: isFinal ? FontWeight.bold : FontWeight.normal,
            color: isFinal ? Colors.black : Colors.grey[700],
          ),
        ),
        Text(
          '${_formatPrice(price)}원',
          style: TextStyle(
            fontSize: isFinal ? 20 : 16,
            fontWeight: isFinal ? FontWeight.bold : FontWeight.w600,
            color: isFinal ? Colors.blue : Colors.black87,
          ),
        ),
      ],
    );
  }
}
