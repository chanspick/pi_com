// lib/features/admin/presentation/widgets/admin_review_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/sell_request_model.dart';
import '../providers/admin_sell_request_provider.dart';
import 'image_gallery_viewer.dart';

class AdminReviewDialog extends ConsumerStatefulWidget {
  final SellRequest request;

  const AdminReviewDialog({
    Key? key,
    required this.request,
  }) : super(key: key);

  @override
  ConsumerState<AdminReviewDialog> createState() => _AdminReviewDialogState();
}

class _AdminReviewDialogState extends ConsumerState<AdminReviewDialog> {
  final _formKey = GlobalKey<FormState>();
  final _finalPriceController = TextEditingController();
  final _conditionScoreController = TextEditingController();
  final _adminNotesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 기본값 설정
    _finalPriceController.text = widget.request.requestedPrice.toString();
    _conditionScoreController.text = '7';
  }

  @override
  void dispose() {
    _finalPriceController.dispose();
    _conditionScoreController.dispose();
    _adminNotesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final request = widget.request;

    // 승인/반려 상태 리스닝
    ref.listen<AdminActionState>(
      adminActionControllerProvider,
          (previous, next) {
        if (next.status == AdminActionStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.successMessage!),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context); // 다이얼로그 닫기
        } else if (next.status == AdminActionStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.errorMessage!),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
    );

    final actionState = ref.watch(adminActionControllerProvider);
    final isLoading = actionState.status == AdminActionStatus.loading;

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.9,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Row(
              children: [
                const Text(
                  '판매 요청 검토',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),

            // 내용 (스크롤 가능)
            Expanded(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. 기본 정보
                      _buildInfoSection(request),
                      const SizedBox(height: 24),

                      // 2. 이미지 갤러리
                      _buildImageGallery(request),
                      const SizedBox(height: 24),

                      // 3. 부품 상세 정보
                      _buildDetailSection(request),
                      const SizedBox(height: 24),

                      // 4. Admin 입력 폼
                      _buildAdminInputSection(),
                    ],
                  ),
                ),
              ),
            ),

            // 하단 버튼
            const Divider(),
            _buildActionButtons(isLoading),
          ],
        ),
      ),
    );
  }

  // ============================================
  // 섹션 1: 기본 정보
  // ============================================

  Widget _buildInfoSection(SellRequest request) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '기본 정보',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _InfoRow(label: 'Request ID', value: request.requestId),
        _InfoRow(label: '부품명', value: '${request.brand} ${request.modelName}'),
        _InfoRow(label: '카테고리', value: request.category),
        _InfoRow(
          label: '희망 가격',
          value: '₩${_formatPrice(request.requestedPrice)}',
          valueStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        _InfoRow(
          label: '제출 날짜',
          value: _formatDate(request.createdAt),
        ),
      ],
    );
  }

  // ============================================
  // 섹션 2: 이미지 갤러리
  // ============================================

  Widget _buildImageGallery(SellRequest request) {
    if (request.imageUrls.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text('이미지 없음'),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '제품 이미지',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: request.imageUrls.length,
            itemBuilder: (context, index) {
              final imageUrl = request.imageUrls[index] as String;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => _showImageGallery(context, request.imageUrls, index),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      imageUrl,
                      width: 200,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 200,
                          height: 200,
                          color: Colors.grey[300],
                          child: const Icon(Icons.broken_image),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showImageGallery(BuildContext context, List imageUrls, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageGalleryViewer(
          imageUrls: imageUrls.cast<String>(),
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  // ============================================
  // 섹션 3: 부품 상세 정보
  // ============================================

  Widget _buildDetailSection(SellRequest request) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '상세 정보',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _InfoRow(
          label: '중고 여부',
          value: request.isSecondHand ? '중고' : '새 제품',
        ),
        _InfoRow(
          label: '보증',
          value: request.hasWarranty
              ? '${request.warrantyMonthsLeft}개월 남음'
              : '보증 없음',
        ),
        _InfoRow(label: '사용 빈도', value: request.usageFrequency),
        _InfoRow(label: '사용 목적', value: request.purpose),
        if (request.ageInfoType != AgeInfoType.unknown)
          _InfoRow(
            label: '제품 연식',
            value: _formatAgeInfo(request),
          ),
      ],
    );
  }

  String _formatAgeInfo(SellRequest request) {
    if (request.ageInfoYear == null) return '정보 없음';

    final type = request.ageInfoType == AgeInfoType.originalPurchaseDate
        ? '구매일'
        : '제조일';
    final month = request.ageInfoMonth != null
        ? '${request.ageInfoMonth}월'
        : '';

    return '$type: ${request.ageInfoYear}년 $month';
  }

  // ============================================
  // 섹션 4: Admin 입력 폼
  // ============================================

  Widget _buildAdminInputSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Admin 평가',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        // 최종 가격
        TextFormField(
          controller: _finalPriceController,
          decoration: const InputDecoration(
            labelText: '최종 판매 가격 (₩)',
            border: OutlineInputBorder(),
            helperText: '희망 가격 기준으로 조정',
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '가격을 입력하세요';
            }
            if (int.tryParse(value) == null) {
              return '숫자만 입력하세요';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // 상태 점수
        TextFormField(
          controller: _conditionScoreController,
          decoration: const InputDecoration(
            labelText: '상태 점수 (1-10)',
            border: OutlineInputBorder(),
            helperText: '1=매우 나쁨, 10=매우 좋음',
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '점수를 입력하세요';
            }
            final score = int.tryParse(value);
            if (score == null || score < 1 || score > 10) {
              return '1-10 사이 숫자를 입력하세요';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Admin 노트
        TextFormField(
          controller: _adminNotesController,
          decoration: const InputDecoration(
            labelText: 'Admin 노트 (선택)',
            border: OutlineInputBorder(),
            helperText: '내부 검토 메모',
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  // ============================================
  // 하단 버튼
  // ============================================

  Widget _buildActionButtons(bool isLoading) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: isLoading ? null : _handleReject,
            icon: const Icon(Icons.cancel, color: Colors.red),
            label: const Text('반려', style: TextStyle(color: Colors.red)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: Colors.red),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: isLoading ? null : _handleApprove,
            icon: isLoading
                ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : const Icon(Icons.check_circle),
            label: Text(isLoading ? '처리 중...' : '승인'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.green,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================
  // 액션 핸들러
  // ============================================

  void _handleApprove() {
    if (!_formKey.currentState!.validate()) return;

    final finalPrice = int.parse(_finalPriceController.text);
    final conditionScore = int.parse(_conditionScoreController.text);
    final adminNotes = _adminNotesController.text.trim();

    ref.read(adminActionControllerProvider.notifier).approve(
      requestId: widget.request.requestId,
      finalPrice: finalPrice,
      finalConditionScore: conditionScore,
      adminNotes: adminNotes.isEmpty ? null : adminNotes,
    );
  }

  void _handleReject() {
    showDialog(
      context: context,
      builder: (context) => _RejectDialog(
        requestId: widget.request.requestId,
      ),
    );
  }

  // ============================================
  // 유틸리티
  // ============================================

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

// ============================================
// 보조 위젯: InfoRow
// ============================================

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? valueStyle;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: valueStyle,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// 보조 위젯: 반려 다이얼로그
// ============================================

class _RejectDialog extends ConsumerStatefulWidget {
  final String requestId;

  const _RejectDialog({required this.requestId});

  @override
  ConsumerState<_RejectDialog> createState() => _RejectDialogState();
}

class _RejectDialogState extends ConsumerState<_RejectDialog> {
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('반려 사유 입력'),
      content: TextField(
        controller: _reasonController,
        decoration: const InputDecoration(
          labelText: '반려 사유',
          hintText: '예: 이미지가 불선명하여 검토가 어렵습니다.',
          border: OutlineInputBorder(),
        ),
        maxLines: 3,
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: () {
            final reason = _reasonController.text.trim();
            if (reason.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('반려 사유를 입력하세요')),
              );
              return;
            }

            ref.read(adminActionControllerProvider.notifier).reject(
              requestId: widget.requestId,
              reason: reason,
            );

            Navigator.pop(context); // 반려 다이얼로그 닫기
            Navigator.pop(context); // 검토 다이얼로그 닫기
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('반려'),
        ),
      ],
    );
  }
}
