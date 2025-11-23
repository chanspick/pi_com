// lib/features/refund/presentation/screens/refund_request_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

import '../../data/repositories/refund_repository_impl.dart';
import '../../data/models/refund_request_model.dart';
import '../../../order/domain/entities/order_entity.dart';
import '../../../order/data/datasources/order_remote_datasource_impl.dart';
import '../../../../core/utils/refund_calculator.dart';
import '../../../../core/constants/routes.dart';

/// 환불 신청 화면
class RefundRequestScreen extends ConsumerStatefulWidget {
  final String orderId;

  const RefundRequestScreen({
    super.key,
    required this.orderId,
  });

  @override
  ConsumerState<RefundRequestScreen> createState() => _RefundRequestScreenState();
}

class _RefundRequestScreenState extends ConsumerState<RefundRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _detailReasonController = TextEditingController();
  final _refundRepository = RefundRepositoryImpl();
  final _orderDataSource = OrderRemoteDataSourceImpl();
  final _imagePicker = ImagePicker();

  OrderEntity? _order;
  RefundReason _selectedReason = RefundReason.simpleChange;
  bool _sealIntact = true;
  final List<File> _selectedImages = [];
  List<String> _uploadedImageUrls = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOrderData();
  }

  @override
  void dispose() {
    _detailReasonController.dispose();
    super.dispose();
  }

  /// 주문 데이터 로드
  Future<void> _loadOrderData() async {
    try {
      final orderModel = await _orderDataSource.getOrder(widget.orderId);
      setState(() {
        _order = orderModel?.toEntity();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /// 이미지 선택
  Future<void> _pickImages() async {
    try {
      final pickedFiles = await _imagePicker.pickMultiImage();
      if (pickedFiles.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(
            pickedFiles.map((xFile) => File(xFile.path)).toList(),
          );
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이미지 선택 실패: $e')),
        );
      }
    }
  }

  /// 이미지 업로드
  Future<List<String>> _uploadImages() async {
    final urls = <String>[];

    for (final image in _selectedImages) {
      try {
        final fileName = 'refund_${DateTime.now().millisecondsSinceEpoch}_${urls.length}.jpg';
        final ref = FirebaseStorage.instance.ref().child('refund_photos/$fileName');

        await ref.putFile(image);
        final url = await ref.getDownloadURL();
        urls.add(url);
      } catch (e) {
        print('이미지 업로드 실패: $e');
      }
    }

    return urls;
  }

  /// 환불 신청 제출
  Future<void> _submitRefundRequest() async {
    if (!_formKey.currentState!.validate()) return;
    if (_order == null) return;

    // 환불 가능 여부 검증
    final validation = RefundCalculator.validateRefundRequest(
      deliveredAt: _order!.deliveredAt!,
      reason: _selectedReason,
      sealIntact: _sealIntact,
    );

    if (!validation['canRefund']) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('환불 불가'),
          content: Text(
            (validation['issues'] as List<String>).join('\n\n'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('확인'),
            ),
          ],
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // 1. 이미지 업로드
      if (_selectedImages.isNotEmpty) {
        _uploadedImageUrls = await _uploadImages();
      }

      // 2. 환불 금액 계산
      final refundCalc = RefundCalculator.calculateRefund(
        reason: _selectedReason,
        originalAmount: _order!.totalPrice.toInt(),
        shippingFee: _order!.shippingFee.toInt(),
      );

      // 3. 환불 신청 생성
      final refundId = await _refundRepository.createRefundRequest(
        orderId: widget.orderId,
        userId: _order!.userId,
        sellerId: _order!.sellerId,
        reason: _selectedReason,
        detailReason: _detailReasonController.text.trim(),
        photoUrls: _uploadedImageUrls,
        sealIntact: _sealIntact,
        originalAmount: _order!.totalPrice.toInt(),
        shippingFee: _order!.shippingFee.toInt(),
        refundAmount: refundCalc['refundAmount'],
        refundCalculationNote: refundCalc['note'],
      );

      if (mounted) {
        // 성공 다이얼로그
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('환불 신청 완료'),
            content: const Text(
              '환불 신청이 접수되었습니다.\n'
              '영업일 기준 1~2일 이내에 승인 여부를 알려드립니다.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  context.pop(); // 다이얼로그 닫기
                  context.pop(); // 환불 신청 화면 닫기
                  // 환불 상세로 이동
                  context.push(
                    Routes.refundDetail,
                    extra: refundId,
                  );
                },
                child: const Text('확인'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('환불 신청 실패: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('반품/환불 신청'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('오류: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadOrderData,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    if (_order == null) {
      return const Center(child: Text('주문 정보를 찾을 수 없습니다'));
    }

    // 환불 가능 여부 확인
    if (_order!.deliveredAt == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, size: 64, color: Colors.orange[700]),
              const SizedBox(height: 16),
              const Text(
                '배송 완료 후 환불 신청이 가능합니다',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '현재 주문 상태: ${_getOrderStatusText(_order!.status)}',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 주문 정보
          _buildOrderInfo(),
          const SizedBox(height: 24),

          // 환불 가능 기한 안내
          _buildRefundDeadlineInfo(),
          const SizedBox(height: 24),

          // 환불 사유 선택
          _buildReasonSelector(),
          const SizedBox(height: 24),

          // 상세 사유 입력
          _buildDetailReasonInput(),
          const SizedBox(height: 24),

          // 봉인 씰 확인
          _buildSealCheckbox(),
          const SizedBox(height: 24),

          // 사진 첨부
          _buildPhotoUpload(),
          const SizedBox(height: 24),

          // 환불 예상 금액
          _buildRefundAmountPreview(),
          const SizedBox(height: 32),

          // 제출 버튼
          _buildSubmitButton(),
          const SizedBox(height: 16),

          // 안내사항
          _buildNotice(),
        ],
      ),
    );
  }

  /// 주문 정보
  Widget _buildOrderInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '주문 정보',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Divider(),
            _buildInfoRow('주문 번호', widget.orderId),
            _buildInfoRow('주문 금액', '${_formatCurrency(_order!.totalPrice.toInt())}원'),
            _buildInfoRow('배송비', '${_formatCurrency(_order!.shippingFee.toInt())}원'),
            _buildInfoRow('배송 완료일', _formatDate(_order!.deliveredAt!)),
          ],
        ),
      ),
    );
  }

  /// 환불 가능 기한 안내
  Widget _buildRefundDeadlineInfo() {
    final daysSinceDelivery = DateTime.now().difference(_order!.deliveredAt!).inDays;
    final simpleChangeDaysRemaining = 7 - daysSinceDelivery;
    final defectDaysRemaining = 30 - daysSinceDelivery;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border.all(color: Colors.blue[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.access_time, size: 20, color: Colors.blue[700]),
              const SizedBox(width: 8),
              Text(
                '환불 가능 기한',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[900],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('• 단순 변심: ${simpleChangeDaysRemaining > 0 ? "$simpleChangeDaysRemaining일 남음" : "기한 만료"} (7일 이내)'),
          const SizedBox(height: 4),
          Text('• 제품 불량/오배송: ${defectDaysRemaining > 0 ? "$defectDaysRemaining일 남음" : "기한 만료"} (30일 이내)'),
        ],
      ),
    );
  }

  /// 환불 사유 선택
  Widget _buildReasonSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '환불 사유 선택 *',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '※ 선택하신 사유에 따라 환불 금액이 달라집니다',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const Divider(),
            ...RefundReason.values.map((reason) {
              final daysSinceDelivery = DateTime.now().difference(_order!.deliveredAt!).inDays;
              final isExpired = daysSinceDelivery > reason.returnPeriodDays;

              return RadioListTile<RefundReason>(
                title: Text(reason.displayName),
                subtitle: Text(
                  '${reason.returnPeriodDays}일 이내 ${isExpired ? "(기한 만료)" : ""}',
                  style: TextStyle(
                    color: isExpired ? Colors.red : Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                value: reason,
                groupValue: _selectedReason,
                onChanged: isExpired
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() => _selectedReason = value);
                        }
                      },
              );
            }),
          ],
        ),
      ),
    );
  }

  /// 상세 사유 입력
  Widget _buildDetailReasonInput() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '상세 사유 *',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _detailReasonController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: '환불 사유를 상세히 입력해주세요\n(예: CPU 쿨러 팬이 회전하지 않습니다)',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '상세 사유를 입력해주세요';
                }
                if (value.trim().length < 10) {
                  return '10자 이상 입력해주세요';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 봉인 씰 확인
  Widget _buildSealCheckbox() {
    return Card(
      color: _sealIntact ? null : Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '봉인 씰 확인 *',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Divider(),
            CheckboxListTile(
              title: const Text('봉인 씰이 온전합니다'),
              subtitle: const Text(
                '홀로그램 봉인 씰이 파손되지 않은 상태여야 반품이 가능합니다',
                style: TextStyle(fontSize: 12),
              ),
              value: _sealIntact,
              onChanged: (value) {
                setState(() => _sealIntact = value ?? false);
              },
            ),
            if (!_sealIntact)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red[900], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '봉인 씰이 파손된 경우 환불이 거부될 수 있습니다',
                        style: TextStyle(
                          color: Colors.red[900],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
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

  /// 사진 첨부
  Widget _buildPhotoUpload() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '사진 첨부 *',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '봉인 씰, 외관 상태, 불량 부분 등을 촬영해주세요',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            if (_selectedImages.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selectedImages.asMap().entries.map((entry) {
                  final index = entry.key;
                  final image = entry.value;
                  return Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(image, fit: BoxFit.cover),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedImages.removeAt(index);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],
            OutlinedButton.icon(
              onPressed: _pickImages,
              icon: const Icon(Icons.add_photo_alternate),
              label: Text(_selectedImages.isEmpty ? '사진 추가' : '사진 더 추가'),
            ),
          ],
        ),
      ),
    );
  }

  /// 환불 예상 금액
  Widget _buildRefundAmountPreview() {
    final refundCalc = RefundCalculator.calculateRefund(
      reason: _selectedReason,
      originalAmount: _order!.totalPrice.toInt(),
      shippingFee: _order!.shippingFee.toInt(),
    );

    final refundAmount = refundCalc['refundAmount'] as int;

    return Card(
      color: Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '환불 예상 금액',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Divider(),
            _buildInfoRow('주문 금액', '${_formatCurrency(_order!.totalPrice.toInt())}원'),
            if (_selectedReason.isBuyerFault) ...[
              _buildInfoRow(
                '차감: 왕복 배송비',
                '-${_formatCurrency(_order!.shippingFee.toInt() * 2)}원',
                valueColor: Colors.red,
              ),
            ] else ...[
              _buildInfoRow(
                '추가: 왕복 배송비',
                '+${_formatCurrency(_order!.shippingFee.toInt() * 2)}원',
                valueColor: Colors.green,
              ),
            ],
            const Divider(),
            _buildInfoRow(
              '환불 예정액',
              '${_formatCurrency(refundAmount)}원',
              isHighlight: true,
            ),
            const SizedBox(height: 8),
            Text(
              _selectedReason.isBuyerFault
                  ? '※ 단순 변심으로 인한 환불은 왕복 배송비가 차감됩니다'
                  : '※ 제품 귀책으로 인한 환불은 왕복 배송비가 추가됩니다',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  /// 제출 버튼
  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitRefundRequest,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                '환불 신청',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  /// 안내사항
  Widget _buildNotice() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 20, color: Colors.grey[700]),
              const SizedBox(width: 8),
              Text(
                '환불 절차 안내',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[900],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text('1. 환불 신청 접수 (지금)', style: TextStyle(fontSize: 12)),
          const SizedBox(height: 4),
          const Text('2. 회사 승인 (1~2영업일)', style: TextStyle(fontSize: 12)),
          const SizedBox(height: 4),
          const Text('3. 반품 물품 발송 (승인 후 7일 이내)', style: TextStyle(fontSize: 12)),
          const SizedBox(height: 4),
          const Text('4. 회사 검수 (물품 수령 후 3영업일)', style: TextStyle(fontSize: 12)),
          const SizedBox(height: 4),
          const Text('5. 환불 완료 (검수 합격 후 3영업일)', style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  /// 정보 행
  Widget _buildInfoRow(
    String label,
    String value, {
    bool isHighlight = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
              color: valueColor ?? (isHighlight ? Colors.green[700] : Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(int amount) {
    return NumberFormat('#,###').format(amount);
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  String _getOrderStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return '결제 완료';
      case OrderStatus.processing:
        return '배송 준비중';
      case OrderStatus.shipped:
        return '배송중';
      case OrderStatus.delivered:
        return '배송 완료';
      case OrderStatus.confirmed:
        return '구매 확정';
      case OrderStatus.cancelled:
        return '취소됨';
      default:
        return status.toString();
    }
  }
}
