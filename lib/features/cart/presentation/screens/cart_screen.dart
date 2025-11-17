// lib/features/cart/presentation/screens/cart_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pi_com/features/cart/presentation/providers/cart_provider.dart';
import 'package:pi_com/features/cart/presentation/widgets/cart_item_card.dart';
import 'package:pi_com/features/cart/presentation/widgets/cart_summary.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../web_public/presentation/widgets/web_navbar_v2.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItemsAsync = ref.watch(cartItemsStreamProvider);

    return Scaffold(
      appBar: kIsWeb
          ? const WebNavBarV2()
          : AppBar(
              title: const Text('장바구니'),
            ),
      body: ResponsiveHelper.centeredMaxWidthContainer(
        context: context,
        child: cartItemsAsync.when(
          data: (items) {
            if (items.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shopping_cart_outlined,
                      size: 80,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 20),
                    Text(
                      '장바구니가 비어있습니다.',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: ResponsiveHelper.getPagePadding(context).copyWith(
                      top: 16,
                      bottom: 16,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      return CartItemCard(item: items[index]);
                    },
                  ),
                ),
                CartSummary(items: items),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('오류: $error')),
        ),
      ),
    );
  }

}