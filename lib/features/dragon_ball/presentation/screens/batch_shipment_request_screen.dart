// lib/features/dragon_ball/presentation/screens/batch_shipment_request_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pi_com/features/dragon_ball/presentation/providers/dragon_ball_provider.dart';
import 'package:pi_com/features/dragon_ball/domain/entities/dragon_ball_entity.dart';
import 'package:pi_com/core/models/batch_shipment_model.dart';
import 'package:pi_com/shared/utils/snackbar_helper.dart';

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
  final _recipientController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _recipientController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      SnackbarHelper.showError(context, '로그인이 필요합니다');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final shippingCost = ShippingCostCalculator.calculateBatchShippingCost(widget.dragonBallIds.length);

      final createBatchShipmentUseCase = ref.read(createBatchShipmentUseCaseProvider);
      await createBatchShipmentUseCase(
        userId: user.uid,
        dragonBallIds: widget.dragonBallIds,
        recipientName: _recipientController.text.trim(),
        shippingAddress: _addressController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        shippingCost: shippingCost,
      );

      // 선택 초기화
      ref.read(clearDragonBallSelectionProvider)();

      if (mounted) {
        SnackbarHelper.showSuccess(context, '배송 요청이 완료되었습니다');
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, '배송 요청 중 오류가 발생했습니다: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dragonBallsAsync = ref.watch(userDragonBallsStreamProvider);
    final shippingCost = ShippingCostCalculator.calculateBatchShippingCost(widget.dragonBallIds.length);
    final savings = ShippingCostCalculator.calculateSavings(widget.dragonBallIds.length);

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
                      shippingCost: shippingCost,
                      savings: savings,
                    ),
                    const SizedBox(height: 24),

                    // 배송 정보 입력
                    const Text(
                      '배송 정보',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _recipientController,
                      decoration: const InputDecoration(
                        labelText: '수령인',
                        hintText: '받으실 분의 성함을 입력하세요',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '수령인을 입력해주세요';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: '배송지',
                        hintText: '상세 주소를 입력하세요',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '배송지를 입력해주세요';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: '연락처',
                        hintText: '010-1234-5678',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '연락처를 입력해주세요';
                        }
                        // 간단한 전화번호 유효성 검사
                        final phoneRegex = RegExp(r'^[0-9-]+$');
                        if (!phoneRegex.hasMatch(value)) {
                          return '올바른 전화번호 형식이 아닙니다';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // 배송비 정보
                    _ShippingCostInfo(
                      itemCount: widget.dragonBallIds.length,
                      shippingCost: shippingCost,
                      savings: savings,
                    ),
                    const SizedBox(height: 24),

                    // 배송 요청 버튼
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitRequest,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              '배송 요청하기',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
  final int shippingCost;
  final int savings;

  const _SelectedItemsSummary({
    required this.dragonBalls,
    required this.shippingCost,
    required this.savings,
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
  final int itemCount;
  final int shippingCost;
  final int savings;

  const _ShippingCostInfo({
    required this.itemCount,
    required this.shippingCost,
    required this.savings,
  });

  @override
  Widget build(BuildContext context) {
    final individualCost = ShippingCostCalculator.calculateIndividualShippingCost(itemCount);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('개별 배송 시', style: TextStyle(color: Colors.grey)),
              Text(
                '${_formatPrice(individualCost)}원',
                style: const TextStyle(
                  decoration: TextDecoration.lineThrough,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '일괄 배송비',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                '${_formatPrice(shippingCost)}원',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          if (savings > 0) ...[
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.savings, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Text(
                  '${_formatPrice(savings)}원 절약!',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
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
