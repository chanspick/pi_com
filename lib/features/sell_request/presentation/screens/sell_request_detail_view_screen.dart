// lib/features/sell_request/presentation/screens/sell_request_detail_view_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../../../core/models/sell_request_model.dart';

/// 판매 요청 상세 조회 Provider (읽기 전용)
final sellRequestDetailProvider = StreamProvider.autoDispose.family<SellRequest, String>((ref, requestId) {
  return FirebaseFirestore.instance
      .collection('sell_requests')  // ✅ 수정: sellRequests → sell_requests
      .doc(requestId)
      .snapshots()
      .map((doc) {
    if (!doc.exists) {
      throw Exception('판매 요청을 찾을 수 없습니다');
    }
    return SellRequest.fromFirestore(doc);
  });
});

/// 판매 요청 상세 보기 화면 (알람에서 접근, 읽기 전용)
class SellRequestDetailViewScreen extends ConsumerWidget {
  final String requestId;

  const SellRequestDetailViewScreen({
    super.key,
    required this.requestId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestAsync = ref.watch(sellRequestDetailProvider(requestId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('판매 요청 상세'),
        elevation: 0,
      ),
      body: requestAsync.when(
        data: (request) => _buildContent(context, request),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('오류: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('돌아가기'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, SellRequest request) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // 상태 헤더
          _buildStatusHeader(context, request),

          // 이미지 갤러리
          if (request.imageUrls.isNotEmpty) _buildImageGallery(request),

          // 부품 정보
          _buildPartInfo(context, request),

          // 가격 정보
          _buildPriceInfo(context, request),

          // 상세 정보
          _buildDetailInfo(context, request),

          // 관리자 메모 (있는 경우)
          if (request.adminNotes != null) _buildAdminNotes(context, request),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildStatusHeader(BuildContext context, SellRequest request) {
    Color bgColor;
    Color textColor;
    String statusText;
    IconData icon;

    switch (request.status) {
      case SellRequestStatus.pending:
        bgColor = Colors.orange.withValues(alpha: 0.1);
        textColor = Colors.orange;
        statusText = '검토 중';
        icon = Icons.schedule;
        break;
      case SellRequestStatus.testing:
        bgColor = Colors.purple.withValues(alpha: 0.1);
        textColor = Colors.purple;
        statusText = '테스트 중';
        icon = Icons.science;
        break;
      case SellRequestStatus.approved:
        bgColor = Colors.green.withValues(alpha: 0.1);
        textColor = Colors.green;
        statusText = '승인됨';
        icon = Icons.check_circle;
        break;
      case SellRequestStatus.rejected:
        bgColor = Colors.red.withValues(alpha: 0.1);
        textColor = Colors.red;
        statusText = '반려됨';
        icon = Icons.cancel;
        break;
      case SellRequestStatus.sold:
        bgColor = Colors.blue.withValues(alpha: 0.1);
        textColor = Colors.blue;
        statusText = '판매완료';
        icon = Icons.verified;
        break;
      case SellRequestStatus.cancelled:
        bgColor = Colors.grey.withValues(alpha: 0.1);
        textColor = Colors.grey;
        statusText = '취소됨';
        icon = Icons.block;
        break;
    }

    return Container(
      width: double.infinity,
      color: bgColor,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(icon, size: 64, color: textColor),
          const SizedBox(height: 12),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _formatDate(request.createdAt),
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGallery(SellRequest request) {
    return Container(
      height: 200,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: request.imageUrls.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: request.imageUrls[index],
                width: 200,
                height: 200,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  width: 200,
                  height: 200,
                  color: Colors.grey[300],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  width: 200,
                  height: 200,
                  color: Colors.grey[300],
                  child: const Icon(Icons.error, size: 40),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPartInfo(BuildContext context, SellRequest request) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '부품 정보',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const Divider(height: 24),
          _buildInfoRow('카테고리', request.category),
          _buildInfoRow('제조사', request.brand),
          _buildInfoRow('모델명', request.modelName),
        ],
      ),
    );
  }

  Widget _buildPriceInfo(BuildContext context, SellRequest request) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor.withValues(alpha: 0.1),
            Theme.of(context).primaryColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '희망 판매가',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[700],
            ),
          ),
          Text(
            '${_formatPrice(request.requestedPrice)}원',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailInfo(BuildContext context, SellRequest request) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '상세 정보',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const Divider(height: 24),
          _buildInfoRow('연식 정보', _getAgeInfoText(request)),
          _buildInfoRow('소유 이력', request.isSecondHand ? '중고 구매' : '신품 직접 구매'),
          _buildInfoRow('AS 정보', request.hasWarranty ? 'AS 기간 ${request.warrantyMonthsLeft}개월 남음' : 'AS 기간 없음'),
          _buildInfoRow('사용 빈도', request.usageFrequency),
          _buildInfoRow('사용 용도', request.purpose),
        ],
      ),
    );
  }

  Widget _buildAdminNotes(BuildContext context, SellRequest request) {
    final isApproved = request.status == SellRequestStatus.approved;
    final color = isApproved ? Colors.green : Colors.red;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isApproved ? Icons.check_circle : Icons.info,
                color: color,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                isApproved ? '승인 안내' : '반려 사유',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            request.adminNotes!,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[800],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getAgeInfoText(SellRequest request) {
    switch (request.ageInfoType) {
      case AgeInfoType.originalPurchaseDate:
        return '구매일: ${request.ageInfoYear}년 ${request.ageInfoMonth}월';
      case AgeInfoType.manufacturDate:
        return '제조일: ${request.ageInfoYear}년 ${request.ageInfoMonth}월';
      case AgeInfoType.unknown:
        return '정보 없음';
    }
  }

  String _formatPrice(int price) {
    final formatter = NumberFormat('#,###');
    return formatter.format(price);
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
