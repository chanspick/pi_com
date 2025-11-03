
// lib/features/cart/presentation/widgets/cart_summary.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pi_com/features/cart/domain/entities/cart_item_entity.dart';
import 'package:pi_com/features/cart/presentation/providers/cart_provider.dart';

class CartSummary extends ConsumerWidget {
  final List<CartItemEntity> items;
  final int estimatedShippingCost; // 예상 배송비 (기본값 3000원)

  const CartSummary({
    super.key,
    required this.items,
    this.estimatedShippingCost = 3000,
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

  int get _buyerShippingCost {
    if (items.isEmpty) return 0;
    // 장바구니의 모든 상품은 같은 판매자이므로 첫 번째 상품의 배송비 비율 사용
    return items.first.calculateBuyerShippingCost(estimatedShippingCost);
  }

  int get _finalTotal {
    return _totalProductPrice + _buyerShippingCost;
  }

  String? get _sellerName {
    return items.isNotEmpty ? items.first.sellerName : null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            // 판매자 정보
            if (_sellerName != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.store, size: 20, color: Colors.grey[700]),
                    const SizedBox(width: 8),
                    Text(
                      '판매자: $_sellerName',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
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
            _buildPriceRow('배송비 (구매자 부담)', _buyerShippingCost, isSubtotal: true),
            const Divider(height: 24),
            _buildPriceRow('총 결제 금액', _finalTotal, isFinal: true),

            const SizedBox(height: 16),

            // 버튼 그룹
            Row(
              children: [
                Expanded(
                  flex: 1,
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
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.grey[400]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('비우기', style: TextStyle(fontSize: 15)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: 체크아웃 화면으로 이동
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('결제 기능은 개발 예정입니다')),
                      );
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
                      '${_formatPrice(_finalTotal)}원 결제하기',
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
