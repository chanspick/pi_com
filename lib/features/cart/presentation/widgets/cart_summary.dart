
// lib/features/cart/presentation/widgets/cart_summary.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pi_com/features/cart/domain/entities/cart_item_entity.dart';
import 'package:pi_com/features/cart/presentation/providers/cart_provider.dart';
import 'package:pi_com/core/constants/routes.dart';
import 'package:pi_com/features/dragon_ball/presentation/providers/dragon_ball_provider.dart';
import 'package:pi_com/features/auth/presentation/providers/auth_provider.dart';
import 'package:pi_com/features/listing/presentation/providers/listing_provider.dart';
import 'package:pi_com/features/listing/domain/entities/listing_entity.dart';

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
                Row(
                  children: [
                    Expanded(
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
                        child: const Text('비우기', style: TextStyle(fontSize: 14)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.auto_awesome, size: 18),
                        label: const Text('드래곤볼', style: TextStyle(fontSize: 14)),
                        onPressed: () => _showDragonBallAgreement(context, ref),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: Colors.orange[700]!),
                          foregroundColor: Colors.orange[700],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
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

  Future<void> _showDragonBallAgreement(BuildContext context, WidgetRef ref) async {
    final agreed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.auto_awesome, color: Colors.orange[700]),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('드래곤볼 보관 서비스 약관'),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '드래곤볼 보관 서비스 이용 약관',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildAgreementItem(
                '1. 보관 기간 및 비용',
                '• 처음 60일간 무료 보관\n'
                '• 60일 이후 하루 1% 보관료 부과 (부품 구매가 기준)',
              ),
              const SizedBox(height: 12),
              _buildAgreementItem(
                '2. 보관 조건',
                '• 보관 기간 동안 회사가 부품을 자유롭게 이용할 수 있습니다\n'
                '• 테스트, 대여 등의 목적으로 사용될 수 있습니다',
              ),
              const SizedBox(height: 12),
              _buildAgreementItem(
                '3. 연체료 및 소유권 이전',
                '• 보관료는 누적되어 일괄 배송 신청 시 청구됩니다\n'
                '• 누적 보관료가 부품 구매가의 100%를 초과하면\n'
                '  부품의 소유권이 회사로 이전됩니다',
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '위 약관에 동의하시면 결제 후 드래곤볼 보관함에 저장됩니다.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[700],
              foregroundColor: Colors.white,
            ),
            child: const Text('동의하고 결제하기'),
          ),
        ],
      ),
    );

    if (agreed == true && context.mounted) {
      // 드래곤볼 결제 처리
      await _processDragonBallPayment(context, ref);
    }
  }

  Widget _buildAgreementItem(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
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
    );
  }

  Future<void> _processDragonBallPayment(BuildContext context, WidgetRef ref) async {
    try {
      // 1. 현재 사용자 가져오기
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) {
        throw Exception('로그인이 필요합니다');
      }

      // 2. 로딩 다이얼로그 표시
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('드래곤볼 결제 처리 중...'),
                  ],
                ),
              ),
            ),
          ),
        );
      }

      // 3. 판매자별로 아이템 그룹화 후 DragonBall 생성 및 Listing 상태 업데이트
      final createDragonBallUseCase = ref.read(createDragonBallUseCaseProvider);
      final listingRepository = ref.read(listingRepositoryProvider);
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // 판매자별로 그룹화
      final Map<String, List<CartItemEntity>> itemsBySeller = {};
      for (final item in items) {
        if (!itemsBySeller.containsKey(item.sellerId)) {
          itemsBySeller[item.sellerId] = [];
        }
        itemsBySeller[item.sellerId]!.add(item);
      }

      // 판매자별로 처리
      int sellerIndex = 0;
      for (final entry in itemsBySeller.entries) {
        final sellerItems = entry.value;

        for (int i = 0; i < sellerItems.length; i++) {
          final item = sellerItems[i];
          final orderId = 'DB_${timestamp}_S${sellerIndex}_${i}'; // 판매자별로 다른 주문 ID

          // DragonBall 생성
          await createDragonBallUseCase(
            userId: currentUser.uid,
            listingId: item.listingId,
            orderId: orderId,
            partName: item.partName,
            imageUrl: item.imageUrl.isNotEmpty ? item.imageUrl : null,
            purchasePrice: item.price,
            basePartId: null, // TODO: 나중에 basePartId 추가 시 매핑
            category: item.category,
            agreedToTerms: true,
          );

          // Listing 상태를 sold로 업데이트
          await listingRepository.updateListingStatus(item.listingId, ListingStatus.sold);
        }

        sellerIndex++;
      }

      // 4. 장바구니 비우기
      await ref.read(clearCartProvider).call();

      // 5. 로딩 다이얼로그 닫기
      if (context.mounted) {
        Navigator.pop(context);
      }

      // 6. 성공 메시지 및 드래곤볼 화면 이동 옵션
      if (context.mounted) {
        final goToStorage = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.orange[700]),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('결제 완료'),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${items.length}개의 상품이 드래곤볼 보관함에 저장되었습니다.'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '처음 60일간 무료 보관',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        '원하실 때 일괄 배송을 신청하실 수 있습니다.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('확인'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[700],
                  foregroundColor: Colors.white,
                ),
                child: const Text('보관함 보기'),
              ),
            ],
          ),
        );

        // 드래곤볼 보관함으로 이동
        if (goToStorage == true && context.mounted) {
          Navigator.pushNamed(context, Routes.dragonBallStorage);
        }
      }
    } catch (e) {
      // 로딩 다이얼로그 닫기
      if (context.mounted) {
        Navigator.pop(context);
      }

      // 에러 메시지 표시
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('결제 실패'),
                ),
              ],
            ),
            content: Text(e.toString().replaceAll('Exception: ', '')),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('확인'),
              ),
            ],
          ),
        );
      }
    }
  }
}
