
// lib/features/cart/presentation/widgets/cart_summary.dart

import 'package:flutter/material.dart';
import 'package:pi_com/features/cart/domain/entities/cart_item_entity.dart';

class CartSummary extends StatelessWidget {
  final List<CartItemEntity> items;

  const CartSummary({super.key, required this.items});

  double get _totalPrice {
    return items.fold(0, (total, item) => total + (item.price * item.quantity));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('총 상품 금액', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text('${_totalPrice.toStringAsFixed(0)}원', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.of(context).pushNamed('/checkout');
            },
            child: const Text('구매하기'),
          ),
        ],
      ),
    );
  }
}
