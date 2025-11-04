// lib/features/checkout/presentation/screens/checkout_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pi_com/features/auth/presentation/providers/auth_provider.dart';
import 'package:pi_com/features/cart/presentation/providers/cart_provider.dart';
import 'package:pi_com/features/checkout/presentation/providers/checkout_provider.dart';
import 'package:pi_com/features/dragon_ball/presentation/providers/dragon_ball_provider.dart';

enum ShippingMethod {
  immediate,  // 즉시 배송
  dragonBall, // 드래곤볼 보관
}

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

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

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('결제'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
              const Text('결제 수단은 현재 지원되지 않습니다.'),
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
      ),
    );
  }

  Future<void> _purchase() async {
    if (!_formKey.currentState!.validate()) {
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
    final cartItems = await ref.read(cartItemsStreamProvider.future);
    final shippingAddress = _selectedShippingMethod == ShippingMethod.immediate
        ? '${_addressController.text}, ${_nameController.text}, ${_phoneController.text}'
        : 'DragonBall Storage';

    try {
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
            orderId: 'temp_order_id', // 실제로는 주문 ID를 받아야 함
            partName: item.partName,
            imageUrl: item.imageUrl,
            purchasePrice: item.price,
            basePartId: null, // 실제로는 listing에서 가져와야 함
            category: item.category,
            agreedToTerms: true,
          );
        }
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류: $e')),
        );
      }
    }
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