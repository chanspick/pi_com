// lib/features/price_alert/presentation/widgets/price_alert_setup_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/price_alert_provider.dart';
import '../../../../core/models/price_alert_model.dart';

/// 가격 알림 설정 다이얼로그
class PriceAlertSetupDialog extends ConsumerStatefulWidget {
  final String basePartId;
  final String partName;
  final int currentPrice;
  final PriceAlert? existingAlert; // 기존 알림 (수정 모드)

  const PriceAlertSetupDialog({
    super.key,
    required this.basePartId,
    required this.partName,
    required this.currentPrice,
    this.existingAlert,
  });

  @override
  ConsumerState<PriceAlertSetupDialog> createState() => _PriceAlertSetupDialogState();
}

class _PriceAlertSetupDialogState extends ConsumerState<PriceAlertSetupDialog> {
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();
  int? _targetPrice;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingAlert != null) {
      _priceController.text = widget.existingAlert!.targetPrice.toString();
      _targetPrice = widget.existingAlert!.targetPrice;
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  double _calculateDiscount() {
    if (_targetPrice == null || _targetPrice! >= widget.currentPrice) return 0;
    return ((widget.currentPrice - _targetPrice!) / widget.currentPrice * 100);
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final actions = ref.read(priceAlertActionsProvider);
    if (actions == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인이 필요합니다')),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (widget.existingAlert != null) {
        // 기존 알림 수정
        await actions.updateTargetPrice(widget.existingAlert!.alertId, _targetPrice!);
        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('가격 알림이 수정되었습니다'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // 새 알림 생성
        await actions.addAlert(
          basePartId: widget.basePartId,
          partName: widget.partName,
          targetPrice: _targetPrice!,
          currentPrice: widget.currentPrice,
        );
        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('가격 알림이 설정되었습니다'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류 발생: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleDelete() async {
    if (widget.existingAlert == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('알림 삭제'),
        content: const Text('이 가격 알림을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final actions = ref.read(priceAlertActionsProvider);
      await actions?.deleteAlert(widget.existingAlert!.alertId);
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('가격 알림이 삭제되었습니다')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류 발생: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final discount = _calculateDiscount();

    return AlertDialog(
      title: Text(widget.existingAlert != null ? '가격 알림 수정' : '가격 알림 설정'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 부품명
              Text(
                widget.partName,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // 현재 가격
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '현재 최저가',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    Text(
                      '${_formatPrice(widget.currentPrice)}원',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 목표 가격 입력
              TextFormField(
                controller: _priceController,
                decoration: InputDecoration(
                  labelText: '목표 가격',
                  hintText: '희망하는 가격을 입력하세요',
                  suffixText: '원',
                  border: const OutlineInputBorder(),
                  helperText: '현재가보다 낮을 때 알림을 받습니다',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '목표 가격을 입력해주세요';
                  }
                  final price = int.tryParse(value);
                  if (price == null || price <= 0) {
                    return '올바른 가격을 입력해주세요';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    _targetPrice = int.tryParse(value);
                  });
                },
              ),

              const SizedBox(height: 16),

              // 할인율 표시
              if (_targetPrice != null && discount > 0) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.trending_down, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '현재가 대비 ${discount.toStringAsFixed(1)}% 할인',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // 안내 메시지
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '부품 가격이 목표 가격 이하로 내려가면 알림을 보내드립니다.',
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        // 삭제 버튼 (수정 모드일 때만)
        if (widget.existingAlert != null)
          TextButton(
            onPressed: _isLoading ? null : _handleDelete,
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),

        // 취소 버튼
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('취소'),
        ),

        // 저장 버튼
        ElevatedButton(
          onPressed: _isLoading ? null : _handleSave,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.existingAlert != null ? '수정' : '설정'),
        ),
      ],
    );
  }
}
