// lib/features/checkout/presentation/screens/checkout_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:pi_com/features/auth/presentation/providers/auth_provider.dart';
import 'package:pi_com/features/cart/presentation/providers/cart_provider.dart';
import 'package:pi_com/features/cart/domain/entities/cart_item_entity.dart';
import 'package:pi_com/features/cart/presentation/widgets/cart_item_card.dart';
import 'package:pi_com/features/checkout/presentation/providers/checkout_provider.dart';
import 'package:pi_com/features/dragon_ball/presentation/providers/dragon_ball_provider.dart';
import 'package:pi_com/features/payment/presentation/providers/payment_provider.dart';
import 'package:pi_com/features/payment/presentation/screens/payment_webview_screen.dart';
import 'package:pi_com/features/payment/presentation/screens/payment_success_screen.dart';
import 'package:pi_com/features/payment/presentation/screens/payment_failure_screen.dart';
import 'package:pi_com/features/payment/presentation/screens/payment_cancel_screen.dart';
import 'package:pi_com/features/address/domain/entities/address_entity.dart';
import 'package:pi_com/features/address/data/repositories/address_repository.dart';
import 'package:pi_com/features/address/presentation/screens/address_list_screen.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../web_public/presentation/widgets/web_navbar_v2.dart';

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
  final List<CartItemEntity>? additionalItems; // 추가 구매 상품 (PC 조립 등 여러 부품 동시 구매)

  const CheckoutScreen({
    super.key,
    this.directPurchaseItem,
    this.additionalItems,
  });

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();

  AddressEntity? _selectedAddress;
  bool _isLoadingDefaultAddress = true;

  ShippingMethod _selectedShippingMethod = ShippingMethod.immediate;
  bool _agreedToDragonBallTerms = false;
  PaymentMethod? _selectedPaymentMethod; // null이면 선택하지 않음

  @override
  void initState() {
    super.initState();
    _loadDefaultAddress();
  }

  /// 기본 배송지 자동 로드
  Future<void> _loadDefaultAddress() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      setState(() => _isLoadingDefaultAddress = false);
      return;
    }

    try {
      final defaultAddress = await AddressRepository().getDefaultAddress(currentUser.uid);
      if (mounted) {
        setState(() {
          _selectedAddress = defaultAddress;
          _isLoadingDefaultAddress = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingDefaultAddress = false);
      }
    }
  }

  /// 배송지 선택 화면 열기
  Future<void> _selectAddress() async {
    final selectedAddress = await Navigator.push<AddressEntity>(
      context,
      MaterialPageRoute(
        builder: (context) => const AddressListScreen(isSelectMode: true),
      ),
    );

    if (selectedAddress != null) {
      setState(() => _selectedAddress = selectedAddress);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 바로구매 모드: directPurchaseItem + additionalItems 사용
    // 장바구니 구매 모드: cartItemsStreamProvider 사용
    if (widget.directPurchaseItem != null) {
      final allItems = [
        widget.directPurchaseItem!,
        if (widget.additionalItems != null) ...widget.additionalItems!,
      ];
      return Scaffold(
        appBar: kIsWeb
            ? const WebNavBarV2()
            : AppBar(
                title: Text('결제 (${allItems.length}개 부품)'),
              ),
        body: ResponsiveHelper.centeredMaxWidthContainer(
          context: context,
          child: _buildCheckoutContent(allItems),
        ),
      );
    }

    final cartItemsAsync = ref.watch(cartItemsStreamProvider);

    return Scaffold(
      appBar: kIsWeb
          ? const WebNavBarV2()
          : AppBar(
              title: const Text('결제'),
            ),
      body: ResponsiveHelper.centeredMaxWidthContainer(
        context: context,
        child: cartItemsAsync.when(
          data: (cartItems) {
            return _buildCheckoutContent(cartItems);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('오류: $error')),
        ),
      ),
    );
  }

  /// 케이스/쿨러/파워가 포함되어 있는지 확인
  bool _hasNonStorableParts(List<CartItemEntity> cartItems) {
    final nonStorableCategories = {'CASE', 'COOLER', 'PSU'};
    return cartItems.any((item) =>
      nonStorableCategories.contains(item.category.toUpperCase())
    );
  }

  Widget _buildCheckoutContent(List<CartItemEntity> cartItems) {
    final hasNonStorableParts = _hasNonStorableParts(cartItems);

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
                disableDragonBall: hasNonStorableParts,
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

                // 배송지 선택 카드
                if (_isLoadingDefaultAddress)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_selectedAddress != null)
                  _AddressDisplayCard(
                    address: _selectedAddress!,
                    onChangeAddress: _selectAddress,
                  )
                else
                  _NoAddressCard(onAddAddress: _selectAddress),

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

    // 즉시 배송 시 배송지 선택 확인
    if (_selectedShippingMethod == ShippingMethod.immediate && _selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('배송지를 선택해주세요.')),
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
        ? _selectedAddress!.fullAddressOneLine
        : 'DragonBall Storage';

    // 웹에서는 테스트 모드로 바로 주문 처리
    if (kIsWeb) {
      await _processDirectOrder(userId, cartItems, shippingAddress);
      return;
    }

    // 모바일: 카카오페이 결제 통합
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
      // UUID를 사용하여 중복 결제 방지
      final orderId = 'ORDER_${const Uuid().v4()}';

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
        // 앱 환경: Firebase Functions URL 사용
        // 참고: 카카오페이 결제 완료 후 이 URL로 리다이렉트되지만,
        // WebView 내에서 pg_token을 추출하여 결제 승인 처리합니다
        approvalUrl = 'https://asia-northeast3-picom-team.cloudfunctions.net/api/payment-redirect/approve?order_id=$orderId';
        cancelUrl = 'https://asia-northeast3-picom-team.cloudfunctions.net/api/payment-redirect/cancel';
        failUrl = 'https://asia-northeast3-picom-team.cloudfunctions.net/api/payment-redirect/fail';
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

      final paymentResult = await Navigator.push<dynamic>(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentWebViewScreen(
            paymentUrl: payment.nextRedirectMobileUrl ?? payment.nextRedirectPcUrl ?? '', // 모바일 리디렉션 URL 사용
            tid: payment.tid,
            orderId: orderId,
            userId: userId,
          ),
        ),
      );

      // 7. 결제 결과 처리
      if (!mounted) return;

      if (paymentResult == true) {
        // 결제 성공: 주문 및 드래곤볼 생성 후 성공 페이지로 이동
        try {
          await _completeOrder(userId, cartItems, shippingAddress, orderId);

          final approvedPayment = ref.read(currentPaymentProvider);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentSuccessScreen(
                payment: approvedPayment,
                orderId: orderId,
              ),
            ),
          );
        } catch (orderError) {
          // 주문 생성 실패 시 결제 취소 시도
          final approvedPayment = ref.read(currentPaymentProvider);
          if (approvedPayment != null) {
            try {
              final cancelUseCase = ref.read(cancelPaymentUseCaseProvider);
              await cancelUseCase.call(
                tid: approvedPayment.tid,
                cancelAmount: totalAmount,
              );

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('주문 생성에 실패하여 결제가 자동으로 취소되었습니다.'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            } catch (cancelError) {
              // 결제 취소도 실패한 경우 - 관리자 개입 필요
              print('⚠️ 결제 취소 실패 (수동 처리 필요) - TID: ${approvedPayment.tid}, 에러: $cancelError');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('결제는 완료되었으나 주문 생성에 실패했습니다. 고객센터로 문의해주세요.'),
                    backgroundColor: Colors.red,
                    duration: Duration(seconds: 5),
                  ),
                );
              }
            }
          }

          // 실패 화면으로 이동
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => PaymentFailureScreen(
                  errorMessage: _getUserFriendlyErrorMessage(orderError),
                  orderId: orderId,
                ),
              ),
            );
          }
        }
      } else if (paymentResult == 'cancel') {
        // 결제 취소: 취소 페이지로 이동
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentCancelScreen(
              orderId: orderId,
            ),
          ),
        );
      } else if (paymentResult is String && paymentResult.startsWith('fail:')) {
        // 결제 실패: 실패 페이지로 이동
        final errorMsg = paymentResult.substring(5); // 'fail:' 제거
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentFailureScreen(
              errorMessage: errorMsg,
              orderId: orderId,
            ),
          ),
        );
      }
    } catch (e) {
      ref.read(isPreparingPaymentProvider.notifier).state = false;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getUserFriendlyErrorMessage(e)),
            backgroundColor: Colors.red,
          ),
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
      // UUID를 사용하여 중복 결제 방지
      final orderId = 'ORDER_${const Uuid().v4()}';
      await _completeOrder(userId, cartItems, shippingAddress, orderId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getUserFriendlyErrorMessage(e)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 주문 완료 처리 (결제-주문 트랜잭션 보장)
  Future<void> _completeOrder(
    String userId,
    List<CartItemEntity> cartItems,
    String shippingAddress,
    String orderId,
  ) async {
    try {
      // 1. 주문 생성 (가장 중요 - 실패 시 결제 취소 필요)
      await ref.read(purchaseUseCaseProvider).call(
        userId: userId,
        items: cartItems,
        shippingAddress: shippingAddress,
      );

      // 2. 드래곤볼 선택 시 드래곤볼 생성
      if (_selectedShippingMethod == ShippingMethod.dragonBall) {
        final createDragonBallUseCase = ref.read(createDragonBallUseCaseProvider);

        for (final item in cartItems) {
          try {
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
          } catch (dragonBallError) {
            // 드래곤볼 생성 실패는 로그만 남기고 계속 진행
            // (주문은 이미 생성되었으므로 나중에 수동 처리 가능)
            print('드래곤볼 생성 실패 (orderId: $orderId): $dragonBallError');
          }
        }
      }

      // 3. 장바구니 구매 모드일 때만 장바구니 비우기
      if (widget.directPurchaseItem == null) {
        try {
          await ref.read(clearCartProvider).call();
        } catch (clearCartError) {
          // 장바구니 비우기 실패는 무시 (중요하지 않음)
          print('장바구니 비우기 실패: $clearCartError');
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _selectedShippingMethod == ShippingMethod.dragonBall
                  ? '결제가 완료되었습니다. 부품이 PC 보관함에 보관되었습니다!'
                  : '결제가 완료되었습니다.',
            ),
          ),
        );

        // 웹에서는 GoRouter 사용, 모바일에서는 Navigator 사용
        if (kIsWeb) {
          context.go('/');
        } else {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
    } catch (orderError) {
      // 주문 생성 실패 시 에러를 상위로 전파 (결제 취소 필요)
      print('주문 생성 실패 (orderId: $orderId): $orderError');
      rethrow;
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

  /// 사용자 친화적 에러 메시지 변환
  String _getUserFriendlyErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    // 네트워크 관련 에러
    if (errorString.contains('network') || errorString.contains('네트워크')) {
      return '인터넷 연결을 확인해주세요.';
    }

    // 타임아웃 에러
    if (errorString.contains('timeout') || errorString.contains('시간초과')) {
      return '요청 시간이 초과되었습니다. 다시 시도해주세요.';
    }

    // 연결 에러
    if (errorString.contains('connection') || errorString.contains('연결')) {
      return '서버에 연결할 수 없습니다. 잠시 후 다시 시도해주세요.';
    }

    // Firebase 에러
    if (errorString.contains('firebase') || errorString.contains('firestore')) {
      return '데이터 처리 중 오류가 발생했습니다.';
    }

    // 결제 관련 에러
    if (errorString.contains('payment') || errorString.contains('결제')) {
      return '결제 처리 중 오류가 발생했습니다. 다시 시도해주세요.';
    }

    // 주문 관련 에러
    if (errorString.contains('order') || errorString.contains('주문')) {
      return '주문 처리 중 오류가 발생했습니다.';
    }

    // 기본 메시지
    return '오류가 발생했습니다. 잠시 후 다시 시도해주세요.';
  }
}

/// 배송 방법 선택 위젯
class _ShippingMethodSelector extends StatelessWidget {
  final ShippingMethod selectedMethod;
  final ValueChanged<ShippingMethod> onMethodChanged;
  final bool disableDragonBall; // 케이스/쿨러/파워가 있으면 true

  const _ShippingMethodSelector({
    required this.selectedMethod,
    required this.onMethodChanged,
    this.disableDragonBall = false,
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

        // PC 보관함 (드래곤볼)
        RadioListTile<ShippingMethod>(
          value: ShippingMethod.dragonBall,
          groupValue: selectedMethod,
          onChanged: disableDragonBall ? null : (value) => onMethodChanged(value!),
          title: Row(
            children: [
              Text(
                'PC 보관함',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: disableDragonBall ? Colors.grey : null,
                ),
              ),
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
          subtitle: Text(
            disableDragonBall
                ? '⚠️ 케이스/쿨러/파워는 PC 보관함 서비스를 이용할 수 없습니다.'
                : '배송비: 무료 (보관 후 합배송)\n보관 기간: 180일 (오픈 이벤트)\n💡 다른 부품과 함께 배송받아 배송비를 절약하세요!',
            style: TextStyle(
              color: disableDragonBall ? Colors.red : null,
            ),
          ),
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

/// 배송지 표시 카드 (선택된 경우)
class _AddressDisplayCard extends StatelessWidget {
  final AddressEntity address;
  final VoidCallback onChangeAddress;

  const _AddressDisplayCard({
    required this.address,
    required this.onChangeAddress,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: address.isDefault ? Theme.of(context).primaryColor : Colors.grey[300]!,
          width: address.isDefault ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더: 기본 배송지 표시 & 변경 버튼
            Row(
              children: [
                if (address.isDefault)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '기본 배송지',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                const Spacer(),
                TextButton.icon(
                  onPressed: onChangeAddress,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('변경'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // 수령인 정보
            Row(
              children: [
                const Icon(Icons.person_outline, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  address.recipientName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  address.recipientPhone,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // 주소
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_outlined, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '(${address.zonecode}) ${address.roadAddress}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        address.detailAddress,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 배송지 없음 카드 (선택되지 않은 경우)
class _NoAddressCard extends StatelessWidget {
  final VoidCallback onAddAddress;

  const _NoAddressCard({
    required this.onAddAddress,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      child: InkWell(
        onTap: onAddAddress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.location_off, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(
                '배송지가 선택되지 않았습니다',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '배송지를 선택하거나 새로 추가해주세요',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onAddAddress,
                icon: const Icon(Icons.add_location_outlined),
                label: const Text('배송지 선택'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}