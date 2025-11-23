// lib/features/refund/presentation/screens/refund_return_shipping_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/courier_companies.dart';
import '../../data/repositories/refund_repository_impl.dart';

/// 환불 반품 송장 입력 화면
class RefundReturnShippingScreen extends StatefulWidget {
  final String refundId;

  const RefundReturnShippingScreen({
    super.key,
    required this.refundId,
  });

  @override
  State<RefundReturnShippingScreen> createState() =>
      _RefundReturnShippingScreenState();
}

class _RefundReturnShippingScreenState
    extends State<RefundReturnShippingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _trackingNumberController = TextEditingController();
  final _refundRepository = RefundRepositoryImpl();

  CourierCompany? _selectedCourier;
  bool _isLoading = false;

  @override
  void dispose() {
    _trackingNumberController.dispose();
    super.dispose();
  }

  /// 반품 신청 제출
  Future<void> _submitReturnShipping() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCourier == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('택배사를 선택해주세요'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Firestore 업데이트
      await _refundRepository.markItemShipped(
        widget.refundId,
        _trackingNumberController.text,
        _selectedCourier!.displayName,
      );

      if (!mounted) return;

      // 성공 메시지
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('반품 신청이 완료되었습니다'),
          backgroundColor: Colors.green,
        ),
      );

      // 화면 닫기
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('반품 신청 중 오류가 발생했습니다: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('반품 송장 정보 입력'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 안내 카드
            Card(
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning_amber, color: Colors.orange.shade700),
                        const SizedBox(width: 8),
                        Text(
                          '반품 안내',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '• 환불 승인 후 3일 이내 반품 물품을 발송해주세요\n'
                      '• 반품 주소는 아래 주소로 발송해주세요\n'
                      '• 포장 상태를 최대한 유지해주세요\n'
                      '• 반품 택배비는 고객 부담입니다',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 반품 주소
            const Text(
              '반품 주소',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '서울특별시 강남구 테헤란로 123\n'
                '파이콤 반품센터\n'
                '(우: 06234)',
                style: TextStyle(fontSize: 14),
              ),
            ),

            const SizedBox(height: 32),

            // 택배사 선택
            const Text(
              '택배사 선택 *',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<CourierCompany>(
              value: _selectedCourier,
              decoration: InputDecoration(
                hintText: '택배사를 선택하세요',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.local_shipping),
              ),
              items: CourierCompany.values.map((courier) {
                return DropdownMenuItem(
                  value: courier,
                  child: Text(courier.displayName),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedCourier = value);
              },
              validator: (value) {
                if (value == null) {
                  return '택배사를 선택해주세요';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // 송장번호 입력
            const Text(
              '송장번호 *',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _trackingNumberController,
              decoration: InputDecoration(
                hintText: '송장번호를 입력하세요 (숫자만)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.qr_code),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '송장번호를 입력해주세요';
                }
                if (value.length < 10) {
                  return '송장번호는 10자 이상이어야 합니다';
                }
                return null;
              },
            ),

            const SizedBox(height: 32),

            // 제출 버튼
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitReturnShipping,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        '반품 신청 완료',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // 안내 텍스트
            Text(
              '※ 송장번호 입력 후 반품 물품을 발송해주세요',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
