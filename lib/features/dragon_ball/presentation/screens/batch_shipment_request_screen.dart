// lib/features/dragon_ball/presentation/screens/batch_shipment_request_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'package:pi_com/features/dragon_ball/presentation/providers/dragon_ball_provider.dart';
import 'package:pi_com/features/dragon_ball/domain/entities/dragon_ball_entity.dart';
import 'package:pi_com/core/constants/storage_policy.dart';
import 'package:pi_com/shared/utils/snackbar_helper.dart';
import 'package:pi_com/features/address/domain/entities/address_entity.dart';
import 'package:pi_com/features/address/data/repositories/address_repository.dart';
import 'package:pi_com/features/address/presentation/screens/address_list_screen.dart';
import 'package:pi_com/features/payment/presentation/providers/payment_provider.dart';
import 'package:pi_com/features/payment/presentation/screens/payment_webview_screen.dart';
import 'package:pi_com/features/payment/presentation/screens/payment_success_screen.dart';
import 'package:pi_com/features/payment/presentation/screens/payment_failure_screen.dart';
import 'package:pi_com/features/payment/presentation/screens/payment_cancel_screen.dart';
import 'package:pi_com/features/auth/presentation/providers/auth_provider.dart';

/// 결제 방식
enum PaymentMethod {
  kakaoPay, // 카카오페이
  // 향후 확장: card, bankTransfer 등
}

/// 일괄 배송 요청 화면
class BatchShipmentRequestScreen extends ConsumerStatefulWidget {
  final List<String> dragonBallIds;

  const BatchShipmentRequestScreen({
    required this.dragonBallIds,
    super.key,
  });

  @override
  ConsumerState<BatchShipmentRequestScreen> createState() => _BatchShipmentRequestScreenState();
}

class _BatchShipmentRequestScreenState extends ConsumerState<BatchShipmentRequestScreen> {
  final _formKey = GlobalKey<FormState>();

  // 배송지 관련
  AddressEntity? _selectedAddress;
  bool _isLoadingDefaultAddress = true;

  // 추가 서비스 선택 상태
  final Set<AdditionalService> _selectedServices = {};

  // 결제 방식
  PaymentMethod? _selectedPaymentMethod;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDefaultAddress();
  }

  @override
  void dispose() {
    super.dispose();
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

    if (selectedAddress != null && mounted) {
      setState(() {
        _selectedAddress = selectedAddress;
      });
    }
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  /// 카카오페이 결제 처리
  Future<void> _processPayment() async {
    // 배송지 확인
    if (_selectedAddress == null) {
      SnackbarHelper.showError(context, '배송지를 선택해주세요');
      return;
    }

    // 결제 방식 확인
    if (_selectedPaymentMethod == null) {
      SnackbarHelper.showError(context, '결제 방식을 선택해주세요');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      SnackbarHelper.showError(context, '로그인이 필요합니다');
      return;
    }

    // 59일 초과 아이템 확인
    final dragonBallsAsync = ref.read(userDragonBallsStreamProvider);
    final allDragonBalls = dragonBallsAsync.value ?? [];
    final selectedDragonBalls = allDragonBalls.where((db) => widget.dragonBallIds.contains(db.dragonBallId)).toList();

    final exceededItems = selectedDragonBalls.where((db) => StoragePolicy.hasExceededMaxStorageDays(db.storedAt)).toList();
    if (exceededItems.isNotEmpty) {
      SnackbarHelper.showError(
        context,
        '59일 최대 보관 기간을 초과한 부품이 포함되어 있습니다.\n해당 부품은 위탁판매로 전환됩니다.',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 케이스 포함 여부 확인
      final hasCase = selectedDragonBalls.any((db) =>
        db.category?.toUpperCase() == 'CASE'
      );

      final shippingCost = StoragePolicy.calculateShippingCost(hasCase: hasCase);
      final servicesCost = _selectedServices.fold<int>(0, (sum, service) => sum + service.price);
      final totalAmount = shippingCost + servicesCost;

      // 주문 ID 생성
      final orderId = 'BATCH_${const Uuid().v4()}';

      // 상품명 생성
      final itemName = hasCase
          ? 'PC 합배송 (완제품 ${widget.dragonBallIds.length}개)'
          : 'PC 합배송 (부품 ${widget.dragonBallIds.length}개)';

      // 리다이렉트 URL 설정
      final String approvalUrl;
      final String cancelUrl;
      final String failUrl;

      if (kIsWeb) {
        approvalUrl = '${Uri.base.origin}/payment/approve?order_id=$orderId';
        cancelUrl = '${Uri.base.origin}/payment/cancel';
        failUrl = '${Uri.base.origin}/payment/fail';
      } else {
        approvalUrl = 'https://asia-northeast3-picom-team.cloudfunctions.net/api/payment-redirect/approve?order_id=$orderId';
        cancelUrl = 'https://asia-northeast3-picom-team.cloudfunctions.net/api/payment-redirect/cancel';
        failUrl = 'https://asia-northeast3-picom-team.cloudfunctions.net/api/payment-redirect/fail';
      }

      // 카카오페이 결제 준비
      final payment = await ref.read(preparePaymentUseCaseProvider).call(
        orderId: orderId,
        userId: user.uid,
        itemName: itemName,
        quantity: widget.dragonBallIds.length,
        totalAmount: totalAmount,
        approvalUrl: approvalUrl,
        cancelUrl: cancelUrl,
        failUrl: failUrl,
      );

      ref.read(currentPaymentProvider.notifier).state = payment;

      if (mounted) {
        // 결제 화면 이동
        final paymentResult = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentWebViewScreen(
              paymentUrl: payment.nextRedirectMobileUrl ?? payment.nextRedirectPcUrl ?? '',
              tid: payment.tid,
              orderId: orderId,
              userId: user.uid,
            ),
          ),
        );

        // 결제 결과 처리
        await _handlePaymentResult(paymentResult, orderId, user.uid, selectedDragonBalls, shippingCost, servicesCost);
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, '결제 준비 중 오류가 발생했습니다: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// 결제 결과 처리
  Future<void> _handlePaymentResult(
    dynamic paymentResult,
    String orderId,
    String userId,
    List<DragonBallEntity> selectedDragonBalls,
    int shippingCost,
    int servicesCost,
  ) async {
    if (paymentResult == true) {
      // 결제 성공: 배송 요청 생성
      try {
        final createBatchShipmentUseCase = ref.read(createBatchShipmentUseCaseProvider);
        await createBatchShipmentUseCase(
          userId: userId,
          dragonBallIds: widget.dragonBallIds,
          recipientName: _selectedAddress!.recipientName,
          shippingAddress: _selectedAddress!.fullAddressOneLine,
          phoneNumber: _selectedAddress!.recipientPhone,
          shippingCost: shippingCost,
          additionalServices: _selectedServices.map((s) => s.title).toList(),
          additionalServicesCost: servicesCost,
        );

        // 선택 초기화
        ref.read(clearDragonBallSelectionProvider)();

        final approvedPayment = ref.read(currentPaymentProvider);
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentSuccessScreen(
                payment: approvedPayment,
                orderId: orderId,
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentFailureScreen(
                errorMessage: '배송 요청 생성에 실패했습니다: $e',
                orderId: orderId,
              ),
            ),
          );
        }
      }
    } else if (paymentResult == 'cancel') {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentCancelScreen(orderId: orderId),
          ),
        );
      }
    } else if (paymentResult is String && paymentResult.startsWith('fail:')) {
      final errorMsg = paymentResult.substring(5);
      if (mounted) {
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final dragonBallsAsync = ref.watch(userDragonBallsStreamProvider);

    // 선택된 드래곤볼 목록
    final allDragonBalls = dragonBallsAsync.value ?? [];
    final selectedDragonBalls = allDragonBalls
        .where((db) => widget.dragonBallIds.contains(db.dragonBallId))
        .toList();

    // 케이스 포함 여부 확인
    final hasCase = selectedDragonBalls.any((db) =>
      db.category?.toUpperCase() == 'CASE'
    );

    final shippingCost = StoragePolicy.calculateShippingCost(hasCase: hasCase);
    final servicesCost = _selectedServices.fold<int>(0, (sum, service) => sum + service.price);

    return Scaffold(
      appBar: AppBar(
        title: const Text('일괄 배송 요청'),
      ),
      body: dragonBallsAsync.when(
        data: (allDragonBalls) {
          final selectedDragonBalls = allDragonBalls
              .where((db) => widget.dragonBallIds.contains(db.dragonBallId))
              .toList();

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 선택한 부품 요약
                    _SelectedItemsSummary(
                      dragonBalls: selectedDragonBalls,
                      hasCase: hasCase,
                      shippingCost: shippingCost,
                    ),
                    const SizedBox(height: 24),

                    // 배송지 선택
                    const Text(
                      '배송 정보',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (_isLoadingDefaultAddress)
                      const Center(child: CircularProgressIndicator())
                    else if (_selectedAddress != null)
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _selectedAddress!.recipientName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: _selectAddress,
                                    child: const Text('변경'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.phone, size: 16, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(
                                    _selectedAddress!.recipientPhone,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      _selectedAddress!.fullAddressMultiLine,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      OutlinedButton.icon(
                        onPressed: _selectAddress,
                        icon: const Icon(Icons.add_location_alt),
                        label: const Text('배송지 선택'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    const SizedBox(height: 24),

                    // 추가 서비스 선택
                    _AdditionalServicesSection(
                      selectedServices: _selectedServices,
                      onServiceToggle: (service) {
                        setState(() {
                          if (_selectedServices.contains(service)) {
                            _selectedServices.remove(service);
                          } else {
                            _selectedServices.add(service);
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    // 배송비 정보
                    _ShippingCostInfo(
                      hasCase: hasCase,
                      shippingCost: shippingCost,
                      servicesCost: servicesCost,
                    ),
                    const SizedBox(height: 24),

                    // 결제 방식 선택
                    const Text(
                      '결제 방식',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _PaymentMethodSelector(
                      selectedMethod: _selectedPaymentMethod,
                      onMethodChanged: (method) {
                        setState(() {
                          _selectedPaymentMethod = method;
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    // 결제하기 버튼
                    ElevatedButton(
                      onPressed: (_isLoading || _selectedPaymentMethod == null) ? null : _processPayment,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: _selectedPaymentMethod == PaymentMethod.kakaoPay
                            ? Colors.yellow[700]
                            : Colors.grey[400],
                        foregroundColor: Colors.black,
                        disabledBackgroundColor: Colors.grey[300],
                        disabledForegroundColor: Colors.grey[600],
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                            )
                          : Text(
                              _selectedPaymentMethod == null
                                  ? '결제 방식을 선택해주세요'
                                  : '${_formatPrice(shippingCost + servicesCost)}원 결제하기',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('오류가 발생했습니다: $error'),
        ),
      ),
    );
  }
}

/// 선택한 부품 요약
class _SelectedItemsSummary extends StatelessWidget {
  final List<DragonBallEntity> dragonBalls;
  final bool hasCase;
  final int shippingCost;

  const _SelectedItemsSummary({
    required this.dragonBalls,
    required this.hasCase,
    required this.shippingCost,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '선택한 부품',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '총 ${dragonBalls.length}개',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            ...dragonBalls.map((db) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.circle, size: 8, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          db.partName,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

/// 배송비 정보
class _ShippingCostInfo extends StatelessWidget {
  final bool hasCase;
  final int shippingCost;
  final int servicesCost;

  const _ShippingCostInfo({
    required this.hasCase,
    required this.shippingCost,
    this.servicesCost = 0,
  });

  @override
  Widget build(BuildContext context) {
    final totalCost = shippingCost + servicesCost;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                hasCase ? '배송비 (완제품)' : '배송비 (부품)',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                '${_formatPrice(shippingCost)}원',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (servicesCost > 0) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '추가 서비스',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${_formatPrice(servicesCost)}원',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '총 결제금액',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                '${_formatPrice(totalCost)}원',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
}

/// 결제 방식 선택 위젯
class _PaymentMethodSelector extends StatelessWidget {
  final PaymentMethod? selectedMethod;
  final void Function(PaymentMethod) onMethodChanged;

  const _PaymentMethodSelector({
    required this.selectedMethod,
    required this.onMethodChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // 카카오페이
          InkWell(
            onTap: () => onMethodChanged(PaymentMethod.kakaoPay),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: selectedMethod == PaymentMethod.kakaoPay
                    ? Colors.yellow[50]
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: selectedMethod == PaymentMethod.kakaoPay
                    ? Border.all(color: Colors.yellow[700]!, width: 2)
                    : null,
              ),
              child: Row(
                children: [
                  Radio<PaymentMethod>(
                    value: PaymentMethod.kakaoPay,
                    groupValue: selectedMethod,
                    onChanged: (value) => onMethodChanged(value!),
                    activeColor: Colors.yellow[700],
                  ),
                  const SizedBox(width: 12),
                  Image.asset(
                    'assets/images/kakaopay_logo.png',
                    height: 24,
                    errorBuilder: (context, error, stackTrace) =>
                        Icon(Icons.payment, size: 24, color: Colors.yellow[700]),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '카카오페이',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '간편하고 안전한 카카오페이 결제',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (selectedMethod == PaymentMethod.kakaoPay)
                    Icon(Icons.check_circle, color: Colors.yellow[700], size: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 추가 서비스 선택 섹션
class _AdditionalServicesSection extends StatelessWidget {
  final Set<AdditionalService> selectedServices;
  final void Function(AdditionalService) onServiceToggle;

  const _AdditionalServicesSection({
    required this.selectedServices,
    required this.onServiceToggle,
  });

  @override
  Widget build(BuildContext context) {
    final totalCost = selectedServices.fold<int>(0, (sum, service) => sum + service.price);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '추가 서비스',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (totalCost > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Text(
                  '+${_formatPrice(totalCost)}원',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildServiceItem(
                context,
                service: AdditionalService.windowsHome,
                icon: Icons.window,
              ),
              Divider(height: 1, color: Colors.grey[300]),
              _buildServiceItem(
                context,
                service: AdditionalService.windowsPro,
                icon: Icons.window_outlined,
              ),
              Divider(height: 1, color: Colors.grey[300]),
              _buildServiceItem(
                context,
                service: AdditionalService.windowsInstallOnly,
                icon: Icons.download,
              ),
              Divider(height: 1, color: Colors.grey[300]),
              _buildServiceItem(
                context,
                service: AdditionalService.assembly,
                icon: Icons.build,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildServiceItem(
    BuildContext context, {
    required AdditionalService service,
    required IconData icon,
  }) {
    final isSelected = selectedServices.contains(service);

    return InkWell(
      onTap: () => onServiceToggle(service),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Checkbox(
              value: isSelected,
              onChanged: (value) => onServiceToggle(service),
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 12),
            Icon(icon, size: 24, color: isSelected ? Colors.blue : Colors.grey[600]),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.black : Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    service.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '+${_formatPrice(service.price)}원',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.blue : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
}
