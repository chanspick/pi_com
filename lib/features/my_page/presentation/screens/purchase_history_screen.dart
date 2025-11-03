// lib/features/my_page/presentation/screens/purchase_history_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/routes.dart';

/// 구매 내역 화면
/// TODO: Transaction 컬렉션 완성 후 실제 데이터 연동
class PurchaseHistoryScreen extends ConsumerWidget {
  const PurchaseHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('구매 내역'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '구매 내역이 없습니다',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              '결제 시스템 연동 후 사용 가능합니다',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, Routes.partShop);
              },
              icon: const Icon(Icons.store),
              label: const Text('상품 둘러보기'),
            ),
          ],
        ),
      ),
    );
  }
}

// TODO: 실제 구현
// final purchaseHistoryProvider = StreamProvider.autoDispose<List<Transaction>>((ref) {
//   final currentUser = ref.watch(currentUserProvider);
//   if (currentUser == null) {
//     return Stream.value([]);
//   }
//
//   return FirebaseFirestore.instance
//       .collection('transactions')
//       .where('buyerId', isEqualTo: currentUser.uid)
//       .orderBy('createdAt', descending: true)
//       .snapshots()
//       .map((snapshot) {
//     return snapshot.docs.map((doc) => Transaction.fromFirestore(doc)).toList();
//   });
// });
