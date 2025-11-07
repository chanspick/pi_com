// lib/features/checkout/presentation/screens/checkout_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pi_com/features/auth/presentation/providers/auth_provider.dart';
import 'package:pi_com/features/cart/presentation/providers/cart_provider.dart';
import 'package:pi_com/features/cart/domain/entities/cart_item_entity.dart';
import 'package:pi_com/features/cart/presentation/widgets/cart_item_card.dart';
import 'package:pi_com/features/checkout/presentation/providers/checkout_provider.dart';
import 'package:pi_com/features/dragon_ball/presentation/providers/dragon_ball_provider.dart';
import 'package:pi_com/features/payment/presentation/providers/payment_provider.dart';
import 'package:pi_com/features/payment/presentation/screens/payment_webview_screen.dart';

enum ShippingMethod {
  immediate,  // 즉시 배송
  dragonBall, // 드래곤볼 보관
}

enum PaymentMethod {
  kakaoPay,   // 카카오페이
  // 향후 확장 가능: card, bankTransfer 등
}

class CheckoutScreen extends ConsumerStatefulWidget {
  final CartItemEntity? directPurchaseItem; // 바로구매 상품 (null이면 장바구니 전체 구매)

  const CheckoutScreen({
    super.key,
    this.directPurchaseItem,
  });

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();

  ShippingMethod _selectedShippingMethod = ShippingMethod.immediate;
  bool _agreedToDragonBallTerms = false;
  PaymentMethod? _selectedPaymentMethod; // null이면 선택하지 않음

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 바로구매 모드: directPurchaseItem 사용
    // 장바구니 구매 모드: cartItemsStreamProvider 사용
    if (widget.directPurchaseItem != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('결제'),
        ),
        body: _buildCheckoutContent([widget.directPurchaseItem!]),
      );
    }

    final cartItemsAsync = ref.watch(cartItemsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('결제'),
      ),
      body: cartItemsAsync.when(
        data: (cartItems) {
          return _buildCheckoutContent(cartItems);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('오류: $error')),
      ),
    );
  }

  Widget _buildCheckoutContent(List<CartItemEntity> cartItems) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
                  // 주문 상품 정보
                  const Text('주문 상품', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: cartItems.length,
                      separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[200]),
                      itemBuilder: (context, index) {
                        return CartItemCard(
                          item: cartItems[index],
                          showDeleteButton: false,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 배송 방법 선택
                  const Text('배송 방법', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _ShippingMethodSelector(
                selectedMethod: _selectedShippingMethod,
                onMethodChanged: (method) {
                  setState(() => _selectedShippingMethod = method);
                },
              ),
              const SizedBox(height: 24),

              // 드래곤볼 약관 동의 (드래곤볼 선택 시에만 표시)
              if (_selectedShippingMethod == ShippingMethod.dragonBall) ...[
                _DragonBallTermsAgreement(
                  agreedToTerms: _agreedToDragonBallTerms,
                  onChanged: (agreed) {
                    setState(() => _agreedToDragonBallTerms = agreed ?? false);
                  },
                ),
                const SizedBox(height: 24),
              ],

              // 배송 정보 (즉시 배송인 경우에만 표시)
              if (_selectedShippingMethod == ShippingMethod.immediate) ...[
                const Text('배송 정보', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: '이름',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value!.isEmpty ? '이름을 입력하세요.' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: '주소',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value!.isEmpty ? '주소를 입력하세요.' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: '연락처',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value!.isEmpty ? '연락처를 입력하세요.' : null,
                ),
                const SizedBox(height: 32),
              ],

              const Text('결제 수단', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _PaymentMethodSelector(
                selectedMethod: _selectedPaymentMethod,
                onMethodChanged: (method) {
                  setState(() => _selectedPaymentMethod = method);
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _purchase,
                child: const Text('결제하기'),
              ),
            ],
          ),
        ),
      );
  }

  Future<void> _purchase() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 결제 수단 선택 확인
    if (_selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('결제 방법을 선택하세요.')),
      );
      return;
    }

    // 드래곤볼 선택 시 약관 동의 확인
    if (_selectedShippingMethod == ShippingMethod.dragonBall && !_agreedToDragonBallTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('드래곤볼 서비스 약관에 동의해주세요.')),
      );
      return;
    }

    final userId = ref.read(currentUserProvider)!.uid;

    // 바로구매 모드 또는 장바구니 모드에 따라 상품 목록 가져오기
    final cartItems = widget.directPurchaseItem != null
        ? [widget.directPurchaseItem!]
        : await ref.read(cartItemsStreamProvider.future);

    final shippingAddress = _selectedShippingMethod == ShippingMethod.immediate
        ? '${_addressController.text}, ${_nameController.text}, ${_phoneController.text}'
        : 'DragonBall Storage';

    // 카카오페이 결제 통합
    if (_selectedPaymentMethod == PaymentMethod.kakaoPay) {
      await _processKakaoPayment(userId, cartItems, shippingAddress);
    } else {
      // 다른 결제 수단 처리 (향후 확장)
      await _processDirectOrder(userId, cartItems, shippingAddress);
    }
  }

  /// 카카오페이 결제 처리
  Future<void> _processKakaoPayment(
    String userId,
    List<CartItemEntity> cartItems,
    String shippingAddress,
  ) async {
    try {
      // 1. 주문 번호 생성
      final orderId = 'ORDER_${DateTime.now().millisecondsSinceEpoch}';

      // 2. 결제 금액 계산
      final totalAmount = _calculateTotalAmount(cartItems);

      // 3. 상품명 생성
      final itemName = _getItemName(cartItems);

      // 4. 리다이렉트 URL 설정
      final String approvalUrl;
      final String cancelUrl;
      final String failUrl;

      if (kIsWeb) {
        // 웹 환경: 웹 URL 사용
        approvalUrl = '${Uri.base.origin}/payment/approve?order_id=$orderId';
        cancelUrl = '${Uri.base.origin}/payment/cancel';
        failUrl = '${Uri.base.origin}/payment/fail';
      } else {
        // 앱 환경: 백엔드 URL 사용 (Deep Link 처리)
        approvalUrl = 'http://localhost:3000/payment/approve?order_id=$orderId';
        cancelUrl = 'http://localhost:3000/payment/cancel';
        failUrl = 'http://localhost:3000/payment/fail';
      }

      // 5. 결제 준비 API 호출
      ref.read(isPreparingPaymentProvider.notifier).state = true;

      final payment = await ref.read(preparePaymentUseCaseProvider).call(
        orderId: orderId,
        userId: userId,
        itemName: itemName,
        quantity: cartItems.length,
        totalAmount: totalAmount,
        approvalUrl: approvalUrl,
        cancelUrl: cancelUrl,
        failUrl: failUrl,
      );

      ref.read(isPreparingPaymentProvider.notifier).state = false;
      ref.read(currentPaymentProvider.notifier).state = payment;

      // 6. WebView로 결제 페이지 열기
      if (!mounted) return;

      final paymentSuccess = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentWebViewScreen(
            paymentUrl: payment.tid, // TODO: 실제로는 redirect URL을 사용해야 함
            tid: payment.tid,
            orderId: orderId,
            userId: userId,
          ),
        ),
      );

      // 7. 결제 성공 시 주문 및 드래곤볼 생성
      if (paymentSuccess == true) {
        await _completeOrder(userId, cartItems, shippingAddress, orderId);
      }
    } catch (e) {
      ref.read(isPreparingPaymentProvider.notifier).state = false;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('결제 준비 실패: $e')),
        );
      }
    }
  }

  /// 직접 주문 처리 (테스트 모드)
  Future<void> _processDirectOrder(
    String userId,
    List<CartItemEntity> cartItems,
    String shippingAddress,
  ) async {
    try {
      final orderId = 'ORDER_${DateTime.now().millisecondsSinceEpoch}';
      await _completeOrder(userId, cartItems, shippingAddress, orderId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류: $e')),
        );
      }
    }
  }

  /// 주문 완료 처리
  Future<void> _completeOrder(
    String userId,
    List<CartItemEntity> cartItems,
    String shippingAddress,
    String orderId,
  ) async {
    // 주문 생성
    await ref.read(purchaseUseCaseProvider).call(
      userId: userId,
      items: cartItems,
      shippingAddress: shippingAddress,
    );

    // 드래곤볼 선택 시 드래곤볼 생성
    if (_selectedShippingMethod == ShippingMethod.dragonBall) {
      final createDragonBallUseCase = ref.read(createDragonBallUseCaseProvider);

      for (final item in cartItems) {
        await createDragonBallUseCase(
          userId: userId,
          listingId: item.listingId,
          orderId: orderId,
          partName: item.partName,
          imageUrl: item.imageUrl,
          purchasePrice: item.price,
          basePartId: null,
          category: item.category,
          agreedToTerms: true,
        );
      }
    }

    // 장바구니 구매 모드일 때만 장바구니 비우기 (바로구매는 비우지 않음)
    if (widget.directPurchaseItem == null) {
      await ref.read(clearCartProvider).call();
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _selectedShippingMethod == ShippingMethod.dragonBall
                ? '결제가 완료되었습니다. 부품이 드래곤볼에 보관되었습니다!'
                : '결제가 완료되었습니다.',
          ),
        ),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  /// 총 결제 금액 계산
  int _calculateTotalAmount(List<CartItemEntity> cartItems) {
    double subtotal = 0;
    for (final item in cartItems) {
      subtotal += item.price * item.quantity;
    }

    // 배송비 추가
    final shippingFee = _selectedShippingMethod == ShippingMethod.immediate ? 10000 : 0;

    return (subtotal + shippingFee).toInt();
  }

  /// 상품명 생성
  String _getItemName(List<CartItemEntity> cartItems) {
    if (cartItems.isEmpty) return '상품';
    if (cartItems.length == 1) return cartItems[0].partName;
    return '${cartItems[0].partName} 외 ${cartItems.length - 1}개';
  }
}

/// 배송 방법 선택 위젯
class _ShippingMethodSelector extends StatelessWidget {
  final ShippingMethod selectedMethod;
  final ValueChanged<ShippingMethod> onMethodChanged;

  const _ShippingMethodSelector({
    required this.selectedMethod,
    required this.onMethodChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 즉시 배송
        RadioListTile<ShippingMethod>(
          value: ShippingMethod.immediate,
          groupValue: selectedMethod,
          onChanged: (value) => onMethodChanged(value!),
          title: const Text('즉시 배송', style: TextStyle(fontWeight: FontWeight.w600)),
          subtitle: const Text('배송비: 10,000원\n예상 도착: 2-3일'),
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: selectedMethod == ShippingMethod.immediate ? Colors.blue : Colors.grey[300]!,
            ),
          ),
          tileColor: selectedMethod == ShippingMethod.immediate
              ? Colors.blue.withOpacity(0.1)
              : Colors.transparent,
        ),
        const SizedBox(height: 12),

        // 드래곤볼 보관
        RadioListTile<ShippingMethod>(
          value: ShippingMethod.dragonBall,
          groupValue: selectedMethod,
          onChanged: (value) => onMethodChanged(value!),
          title: Row(
            children: [
              const Text('드래곤볼 보관', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '추천',
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          subtitle: const Text('배송비: 무료 (보관 후 합배송)\n보관 기간: 30일\n💡 다른 부품과 함께 배송받아 배송비를 절약하세요!'),
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: selectedMethod == ShippingMethod.dragonBall ? Colors.green : Colors.grey[300]!,
            ),
          ),
          tileColor: selectedMethod == ShippingMethod.dragonBall
              ? Colors.green.withOpacity(0.1)
              : Colors.transparent,
        ),
      ],
    );
  }
}

/// 결제 수단 선택 위젯
class _PaymentMethodSelector extends StatelessWidget {
  final PaymentMethod? selectedMethod;
  final ValueChanged<PaymentMethod?> onMethodChanged;

  const _PaymentMethodSelector({
    required this.selectedMethod,
    required this.onMethodChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 카카오페이
        RadioListTile<PaymentMethod>(
          value: PaymentMethod.kakaoPay,
          groupValue: selectedMethod,
          onChanged: onMethodChanged,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE500), // 카카오 노란색
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.chat_bubble,
                  size: 20,
                  color: Color(0xFF3C1E1E),
                ),
              ),
              const SizedBox(width: 12),
              const Text('카카오페이', style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          subtitle: const Padding(
            padding: EdgeInsets.only(left: 38),
            child: Text('간편하고 안전한 결제'),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: selectedMethod == PaymentMethod.kakaoPay ? const Color(0xFFFEE500) : Colors.grey[300]!,
              width: selectedMethod == PaymentMethod.kakaoPay ? 2 : 1,
            ),
          ),
          tileColor: selectedMethod == PaymentMethod.kakaoPay
              ? const Color(0xFFFEE500).withOpacity(0.1)
              : Colors.transparent,
        ),
        const SizedBox(height: 8),

        // 안내 메시지
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.grey[600], size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '현재는 결제가 바로 완료됩니다. (테스트 모드)',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 드래곤볼 약관 동의 위젯
class _DragonBallTermsAgreement extends StatelessWidget {
  final bool agreedToTerms;
  final ValueChanged<bool?> onChanged;

  const _DragonBallTermsAgreement({
    required this.agreedToTerms,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '드래곤볼 서비스 약관',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              height: 150,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const SingleChildScrollView(
                child: Text(
                  '제1조 (서비스 개요)\n'
                  '파이컴퓨터는 고객님의 부품을 최대 30일간 완전 무료로 보관하며, 합배송 서비스를 제공합니다.\n\n'
                  '제2조 (부품 운용 동의) ⭐ 중요\n'
                  '- 보관 기간 동안 파이컴퓨터는 부품을 렌탈/대여 서비스에 활용할 수 있습니다.\n'
                  '- 부품 보호 보험에 가입하여 손상 시 100% 보상합니다.\n'
                  '- 배송 요청 시 24시간 내 준비를 완료합니다.\n\n'
                  '제3조 (보관 기간)\n'
                  '- 기본 보관 기간: 30일 (입고일 기준)\n'
                  '- 만료 3일 전 알림을 발송합니다.\n'
                  '- 만료 시: 기본 배송지로 자동 배송\n\n'
                  '제4조 (배송비)\n'
                  '- 일괄 배송 기본: 10,000원\n'
                  '- 부품 2개 이상: 개당 3,000원 추가\n'
                  '- 개별 배송 대비 최대 50% 절감',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              value: agreedToTerms,
              onChanged: onChanged,
              title: const Text(
                '위 약관을 모두 읽었으며 이에 동의합니다.',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
}