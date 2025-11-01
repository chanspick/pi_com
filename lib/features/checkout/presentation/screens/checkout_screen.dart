// lib/features/checkout/presentation/screens/checkout_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pi_com/features/auth/presentation/providers/auth_provider.dart';
import 'package:pi_com/features/cart/presentation/providers/cart_provider.dart';
import 'package:pi_com/features/checkout/presentation/providers/checkout_provider.dart';

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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
              const Text('결제 수단', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Text('결제 수단은 현재 지원되지 않습니다.'),
              const Spacer(),
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

    final userId = ref.read(currentUserProvider)!.uid;
    final cartItems = await ref.read(cartItemsStreamProvider.future);
    final shippingAddress = '${_addressController.text}, ${_nameController.text}, ${_phoneController.text}';

    try {
      await ref.read(purchaseUseCaseProvider).call(
        userId: userId,
        items: cartItems,
        shippingAddress: shippingAddress,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('결제가 완료되었습니다.')),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류: $e')),
      );
    }
  }
}