// lib/features/checkout/presentation/screens/checkout_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart';
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
import 'package:pi_com/features/payment/presentation/screens/toss_payment_webview_screen.dart';
// 웹 전용 결제 화면 (조건부 import - 웹에서는 dart:html 사용, 모바일에서는 스텁)
import 'package:pi_com/features/payment/presentation/screens/toss_payment_web_screen_stub.dart'
    if (dart.library.html) 'package:pi_com/features/payment/presentation/screens/toss_payment_web_screen.dart';
import 'package:pi_com/features/address/domain/entities/address_entity.dart';
import 'package:pi_com/features/address/data/repositories/address_repository.dart';
import 'package:pi_com/features/address/presentation/screens/address_list_screen.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/models/dragon_ball_model.dart';
import '../../../../core/constants/routes.dart';
import '../../../web_public/presentation/widgets/web_navbar_v2.dart';

enum ShippingMethod {
  immediate,  // 즉시 배송
  dragonBall, // 드래곤볼 보관
}

enum PaymentMethod {
  kakaoPay,      // 카카오페이
  tossPayments,  // 토스페이먼츠 (카드, 간편결제, 계좌이체 등)
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
  StorageType _selectedStorageType = StorageType.general; // 기본값: 일반 보관
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
                  selectedStorageType: _selectedStorageType,
                  onAgreementChanged: (agreed) {
                    setState(() => _agreedToDragonBallTerms = agreed ?? false);
                  },
                  onStorageTypeChanged: (type) {
                    setState(() => _selectedStorageType = type);
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

              // 결제 금액 요약
              _PaymentSummary(
                cartItems: cartItems,
                shippingFee: _selectedShippingMethod == ShippingMethod.immediate ? 10000 : 0,
              ),
              const SizedBox(height: 24),

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

    // 🔒 결제 전 sold 상품 검증 및 제거
    try {
      final removedItems = await ref.read(removeSoldItemsProvider).call();
      if (removedItems.isNotEmpty) {
        if (mounted) {
          final itemNames = removedItems.map((e) => e.partName).join(', ');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('이미 판매된 상품이 장바구니에서 제거되었습니다: $itemNames'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        // 장바구니가 비었으면 결제 중단
        final remainingItems = await ref.read(cartItemsStreamProvider.future);
        if (remainingItems.isEmpty && widget.directPurchaseItem == null) {
          return;
        }
      }
    } catch (e) {
      print('⚠️ [Checkout] Error checking sold items: $e');
      // 검증 실패해도 결제 진행 (Firestore 규칙에서 최종 검증)
    }

    // 바로구매 모드 또는 장바구니 모드에 따라 상품 목록 가져오기
    final cartItems = widget.directPurchaseItem != null
        ? [widget.directPurchaseItem!]
        : await ref.read(cartItemsStreamProvider.future);

    final shippingAddress = _selectedShippingMethod == ShippingMethod.immediate
        ? _selectedAddress!.fullAddressOneLine
        : 'DragonBall Storage';

    // 모바일/웹 공통: 결제 수단별 처리
    if (_selectedPaymentMethod == PaymentMethod.kakaoPay) {
      await _processKakaoPayment(userId, cartItems, shippingAddress);
    } else if (_selectedPaymentMethod == PaymentMethod.tossPayments) {
      await _processTossPayment(userId, cartItems, shippingAddress);
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

  /// 토스페이먼츠 결제 처리
  Future<void> _processTossPayment(
    String userId,
    List<CartItemEntity> cartItems,
    String shippingAddress,
  ) async {
    try {
      // 1. 주문 번호 생성
      final orderId = 'ORDER_${const Uuid().v4()}';

      // 2. 결제 금액 계산
      final totalAmount = _calculateTotalAmount(cartItems);

      // 3. 상품명 생성
      final itemName = _getItemName(cartItems);

      // 4. 리다이렉트 URL 설정 (Firebase Functions 사용)
      final successUrl = 'https://asia-northeast3-picom-team.cloudfunctions.net/api/toss-payment-redirect/success';
      final failUrl = 'https://asia-northeast3-picom-team.cloudfunctions.net/api/toss-payment-redirect/fail';

      // 5. 사용자 정보 가져오기
      final currentUser = ref.read(currentUserProvider);
      final customerName = currentUser?.displayName ?? '고객';
      final customerEmail = currentUser?.email ?? '';
      final customerPhone = _selectedAddress?.recipientPhone ?? '';

      // 6. 토스페이먼츠 결제 화면 열기 (웹/모바일 분기)
      if (!mounted) return;

      // 디버깅: 결제 화면으로 전달할 값 확인
      print('💰 [Checkout] === 토스페이먼츠 결제 시작 ===');
      print('💰 [Checkout] orderId: $orderId');
      print('💰 [Checkout] userId: $userId');
      print('💰 [Checkout] orderName: $itemName');
      print('💰 [Checkout] amount: $totalAmount');
      print('💰 [Checkout] customerName: $customerName');
      print('💰 [Checkout] customerEmail: $customerEmail');
      print('💰 [Checkout] customerPhone: $customerPhone');

      final Map<String, dynamic>? paymentResult;

      if (kIsWeb) {
        // 웹: iframe 기반 결제 화면
        paymentResult = await Navigator.push<Map<String, dynamic>>(
          context,
          MaterialPageRoute(
            builder: (context) => TossPaymentWebScreen(
              orderId: orderId,
              userId: userId,
              orderName: itemName,
              amount: totalAmount,
              customerName: customerName,
              customerEmail: customerEmail,
              customerPhone: customerPhone,
              successUrl: successUrl,
              failUrl: failUrl,
            ),
          ),
        );
      } else {
        // 모바일: WebView 기반 결제 화면
        paymentResult = await Navigator.push<Map<String, dynamic>>(
          context,
          MaterialPageRoute(
            builder: (context) => TossPaymentWebViewScreen(
              orderId: orderId,
              userId: userId,
              orderName: itemName,
              amount: totalAmount,
              customerName: customerName,
              customerEmail: customerEmail,
              customerPhone: customerPhone,
              successUrl: successUrl,
              failUrl: failUrl,
            ),
          ),
        );
      }

      // 7. 결제 결과 처리
      if (!mounted) return;

      if (paymentResult != null && paymentResult['success'] == true) {
        // 결제 성공: 주문 생성
        try {
          await _completeOrder(userId, cartItems, shippingAddress, orderId);

          // 성공 화면으로 이동
          final payment = ref.read(currentPaymentProvider);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentSuccessScreen(
                payment: payment,
                orderId: orderId,
              ),
            ),
          );
        } catch (orderError) {
          // 주문 생성 실패 시 결제 취소 시도
          final paymentKey = paymentResult['paymentKey'] as String?;
          if (paymentKey != null) {
            try {
              final cancelUseCase = ref.read(cancelTossPaymentUseCaseProvider);
              await cancelUseCase.call(
                paymentKey: paymentKey,
                cancelReason: '주문 생성 실패로 인한 자동 취소',
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
              print('⚠️ 결제 취소 실패 (수동 처리 필요) - PaymentKey: $paymentKey, 에러: $cancelError');
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
      } else if (paymentResult != null && paymentResult['errorCode'] == 'USER_CANCEL') {
        // 사용자가 결제 취소
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentCancelScreen(
              orderId: orderId,
            ),
          ),
        );
      } else if (paymentResult != null) {
        // 결제 실패
        final errorMsg = paymentResult['errorMessage'] as String? ?? '알 수 없는 오류';
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
      // 🔍 디버깅: 주문 생성 전 상태 확인
      final currentUser = ref.read(currentUserProvider);
      print('═══════════════════════════════════════════════════════');
      print('🛒 주문 생성 시작');
      print('📋 Order ID: $orderId');
      print('👤 userId (파라미터): $userId');
      print('👤 currentUser?.uid: ${currentUser?.uid}');
      print('🔐 인증 상태: ${currentUser != null ? "로그인됨" : "로그아웃됨"}');
      print('📍 배송지: $shippingAddress');
      print('📦 장바구니 아이템 수: ${cartItems.length}');
      for (int i = 0; i < cartItems.length; i++) {
        final item = cartItems[i];
        print('  [$i] ${item.partName}');
        print('      - listingId: ${item.listingId}');
        print('      - sellerId: ${item.sellerId}');
        print('      - sellerName: ${item.sellerName}');
        print('      - price: ${item.price}');
        print('      - quantity: ${item.quantity}');
      }
      print('═══════════════════════════════════════════════════════');

      // userId 불일치 체크
      if (currentUser?.uid != userId) {
        print('⚠️ 경고: userId 불일치! 파라미터($userId) != currentUser(${currentUser?.uid})');
      }

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
              storageType: _selectedStorageType, // 사용자가 선택한 보관 타입 전달
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

    // 배송비 추가 (즉시 배송 시 4,500원, PC 보관함은 합배송 시 부과)
    final shippingFee = _selectedShippingMethod == ShippingMethod.immediate ? 4500 : 0;

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
          subtitle: const Text('배송비: 4,500원 (부품)\n예상 도착: 2-3일'),
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
                : '합배송비: 4,500원 (부품만) / 5,000원 (케이스 포함)\n보관 기간: 7일 무료\n💡 여러 부품을 조립하고 싶으세요? PC 보관함에서 조립 요청이 가능합니다!',
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

        // 토스페이먼츠
        RadioListTile<PaymentMethod>(
          value: PaymentMethod.tossPayments,
          groupValue: selectedMethod,
          onChanged: onMethodChanged,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF0064FF), // 토스 블루
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.credit_card,
                  size: 20,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              const Text('토스페이먼츠', style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          subtitle: const Padding(
            padding: EdgeInsets.only(left: 38),
            child: Text('카드, 간편결제, 계좌이체, 휴대폰'),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: selectedMethod == PaymentMethod.tossPayments ? const Color(0xFF0064FF) : Colors.grey[300]!,
              width: selectedMethod == PaymentMethod.tossPayments ? 2 : 1,
            ),
          ),
          tileColor: selectedMethod == PaymentMethod.tossPayments
              ? const Color(0xFF0064FF).withOpacity(0.1)
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

/// 드래곤볼(보관 서비스) 약관 동의 위젯
class _DragonBallTermsAgreement extends StatelessWidget {
  final bool agreedToTerms;
  final StorageType selectedStorageType;
  final ValueChanged<bool?> onAgreementChanged;
  final ValueChanged<StorageType> onStorageTypeChanged;

  const _DragonBallTermsAgreement({
    required this.agreedToTerms,
    required this.selectedStorageType,
    required this.onAgreementChanged,
    required this.onStorageTypeChanged,
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
            // 제목
            Row(
              children: [
                const Text(
                  '보관 서비스 약관',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () async {
                    if (kIsWeb) {
                      // 웹에서는 HTML 파일로 직접 이동
                      final currentUrl = Uri.base;
                      final targetUrl = currentUrl.replace(path: '/storage_service_terms.html');
                      await launchUrl(
                        targetUrl,
                        webOnlyWindowName: '_blank', // 새 탭에서 열기
                      );
                    } else {
                      // 모바일에서는 라우트 사용
                      Navigator.of(context).pushNamed(Routes.storageServiceTerms);
                    }
                  },
                  child: const Text('전문 보기'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 보관 타입 선택
            const Text(
              '보관 타입 선택',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),

            // 일반 보관 옵션
            RadioListTile<StorageType>(
              value: StorageType.general,
              groupValue: selectedStorageType,
              onChanged: (type) => onStorageTypeChanged(type!),
              title: const Text('일반 보관'),
              subtitle: const Text(
                '• 7일 무료, 이후 하루 0.5% 보관료 (최대 30%)\n'
                '• 최대 59일 보관 가능\n'
                '• 60일 초과 시 위탁판매 전환',
                style: TextStyle(fontSize: 12),
              ),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),

            // 임대 보관 옵션
            RadioListTile<StorageType>(
              value: StorageType.rental,
              groupValue: selectedStorageType,
              onChanged: (type) => onStorageTypeChanged(type!),
              title: const Text('임대 보관 (무료)'),
              subtitle: const Text(
                '• 보관 기간 동안 완전 무료\n'
                '• 회사가 렌탈 서비스에 활용 가능\n'
                '• 부품 보호 보험 100% 보상',
                style: TextStyle(fontSize: 12),
              ),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),

            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),

            // 약관 요약
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📋 주요 약관 요약',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• 7일 무료 보관 후 일일 보관료 부과 (일반 보관)\n'
                    '• 임대 보관 선택 시 무료이나 렌탈 활용 동의 필요\n'
                    '• 59일 최대 보관 기간 (카카오페이 제약)\n'
                    '• 60일 초과 시 자동 위탁판매 전환',
                    style: TextStyle(fontSize: 12, height: 1.5),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 동의 체크박스
            CheckboxListTile(
              value: agreedToTerms,
              onChanged: onAgreementChanged,
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

/// 결제 금액 요약 위젯
class _PaymentSummary extends StatelessWidget {
  final List<CartItemEntity> cartItems;
  final int shippingFee;

  const _PaymentSummary({
    required this.cartItems,
    required this.shippingFee,
  });

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  @override
  Widget build(BuildContext context) {
    // 상품 금액 계산
    int subtotal = 0;
    for (final item in cartItems) {
      subtotal += (item.price * item.quantity).toInt();
    }

    // 총 결제 금액
    final totalAmount = subtotal + shippingFee;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).primaryColor.withOpacity(0.3), width: 2),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Theme.of(context).primaryColor.withOpacity(0.05),
            ],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 제목
            Row(
              children: [
                Icon(Icons.receipt_long, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  '결제 금액',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),

            // 상품 금액
            _buildPriceRow('상품 금액', subtotal, isSubtotal: true),
            const SizedBox(height: 12),

            // 배송비
            _buildPriceRow(
              '배송비',
              shippingFee,
              isSubtotal: true,
              isFree: shippingFee == 0,
            ),
            const SizedBox(height: 16),
            const Divider(thickness: 2),
            const SizedBox(height: 16),

            // 총 결제 금액 (강조)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).primaryColor,
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '총 결제 금액',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${_formatPrice(totalAmount)}원',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, int amount, {bool isSubtotal = false, bool isFree = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: isSubtotal ? FontWeight.w500 : FontWeight.normal,
            color: Colors.grey[700],
          ),
        ),
        if (isFree)
          const Text(
            '무료',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.green,
            ),
          )
        else
          Text(
            '${_formatPrice(amount)}원',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
      ],
    );
  }
}