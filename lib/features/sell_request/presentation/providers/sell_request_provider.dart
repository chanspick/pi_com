// lib/features/sell_request/presentation/providers/sell_request_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/models/sell_request_model.dart';
import '../../../../core/models/base_part_model.dart';
import '../../../../core/data/datasources/image_upload_datasource.dart';
import '../../data/datasources/sell_request_datasource.dart';
import '../../data/repositories/sell_request_repository_impl.dart';
import '../../domain/repositories/sell_request_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

// ==================== DataSource ====================

/// ImageUploadDataSource Provider
final imageUploadDataSourceProvider = Provider((ref) {
  return ImageUploadDataSource(storage: FirebaseStorage.instance);
});

/// SellRequestDataSource Provider
final sellRequestDataSourceProvider = Provider((ref) {
  return SellRequestDataSource(firestore: FirebaseFirestore.instance);
});

// ==================== Repository ====================

/// SellRequestRepository Provider
final sellRequestRepositoryProvider = Provider<SellRequestRepository>((ref) {
  final dataSource = ref.watch(sellRequestDataSourceProvider);
  return SellRequestRepositoryImpl(dataSource);
});

// ==================== Stream Providers ====================

/// 사용자 SellRequest 목록 (실시간)
final userSellRequestsStreamProvider = StreamProvider<List<SellRequest>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return Stream.value([]); // 로그인 안 되어 있으면 빈 리스트
  }

  final repository = ref.watch(sellRequestRepositoryProvider);
  return repository.getUserSellRequestsStream(user.uid);
});

/// 모든 SellRequest 목록 (Admin용)
final allSellRequestsStreamProvider = StreamProvider<List<SellRequest>>((ref) {
  final repository = ref.watch(sellRequestRepositoryProvider);
  return repository.getAllSellRequestsStream();
});

// ==================== 제출 상태 관리 ====================

/// SellRequest 제출 상태
enum SubmitStatus {
  idle, // 초기 상태
  uploading, // 이미지 업로드 중
  submitting, // Firestore 저장 중
  success, // 성공
  error, // 실패
}

/// 제출 상태 State
class SubmitState {
  final SubmitStatus status;
  final double? progress; // 업로드 진행률 (0.0 ~ 1.0)
  final String? errorMessage;

  const SubmitState({
    required this.status,
    this.progress,
    this.errorMessage,
  });

  const SubmitState.idle() : this(status: SubmitStatus.idle);
  const SubmitState.uploading(double progress)
      : this(status: SubmitStatus.uploading, progress: progress);
  const SubmitState.submitting() : this(status: SubmitStatus.submitting);
  const SubmitState.success() : this(status: SubmitStatus.success);
  const SubmitState.error(String message)
      : this(status: SubmitStatus.error, errorMessage: message);
}

// ==================== 단일 SellRequest 제출 ====================

/// SellRequest 제출 Controller (단일 부품)
class SubmitSellRequestController extends StateNotifier<SubmitState> {
  final SellRequestRepository _repository;
  final ImageUploadDataSource _imageUploadDataSource;

  SubmitSellRequestController({
    required SellRequestRepository repository,
    required ImageUploadDataSource imageUploadDataSource,
  })  : _repository = repository,
        _imageUploadDataSource = imageUploadDataSource,
        super(const SubmitState.idle());

  /// SellRequest 제출 (이미지 업로드 + Firestore 저장)
  Future<void> submitSellRequest({
    required SellRequest sellRequest,
    required List<dynamic> images, // XFile 리스트
  }) async {
    try {
      // 1. 이미지 업로드
      state = const SubmitState.uploading(0.0);
      final imageUrls = await _imageUploadDataSource.uploadImages(
        images: images.cast<XFile>(),
        userId: sellRequest.sellerId,
        uploadId: sellRequest.requestId,
      );

      // 2. SellRequest 업데이트 (이미지 URL 추가)
      final updatedRequest = SellRequest(
        requestId: sellRequest.requestId,
        sellerId: sellRequest.sellerId,
        partId: sellRequest.partId,
        basePartId: sellRequest.basePartId,
        brand: sellRequest.brand,
        category: sellRequest.category,
        modelName: sellRequest.modelName,
        ageInfoType: sellRequest.ageInfoType,
        ageInfoYear: sellRequest.ageInfoYear,
        ageInfoMonth: sellRequest.ageInfoMonth,
        isSecondHand: sellRequest.isSecondHand,
        hasWarranty: sellRequest.hasWarranty,
        warrantyMonthsLeft: sellRequest.warrantyMonthsLeft,
        usageFrequency: sellRequest.usageFrequency,
        purpose: sellRequest.purpose,
        requestedPrice: sellRequest.requestedPrice,
        imageUrls: imageUrls, // ← 업로드된 이미지 URL
        status: sellRequest.status,
        createdAt: sellRequest.createdAt,
        updatedAt: sellRequest.updatedAt,
        adminNotes: sellRequest.adminNotes,
      );

      // 3. Firestore에 저장
      state = const SubmitState.submitting();
      await _repository.createSellRequest(updatedRequest);

      // 4. 성공
      state = const SubmitState.success();
    } catch (e) {
      state = SubmitState.error(e.toString());
      rethrow;
    }
  }

  /// 상태 초기화
  void reset() {
    state = const SubmitState.idle();
  }
}

/// SubmitSellRequestController Provider
final submitSellRequestControllerProvider =
StateNotifierProvider<SubmitSellRequestController, SubmitState>((ref) {
  final repository = ref.watch(sellRequestRepositoryProvider);
  final imageUploadDataSource = ref.watch(imageUploadDataSourceProvider);
  return SubmitSellRequestController(
    repository: repository,
    imageUploadDataSource: imageUploadDataSource,
  );
});

// ==================== 다중 SellRequest 제출 ====================

/// 여러 SellRequest 일괄 제출 Controller (완제품 PC 판매용)
class SubmitMultipleSellRequestsController extends StateNotifier<SubmitState> {
  final SellRequestRepository _repository;
  final ImageUploadDataSource _imageUploadDataSource;

  SubmitMultipleSellRequestsController({
    required SellRequestRepository repository,
    required ImageUploadDataSource imageUploadDataSource,
  })  : _repository = repository,
        _imageUploadDataSource = imageUploadDataSource,
        super(const SubmitState.idle());

  /// 여러 SellRequest 일괄 제출
  ///
  /// [baseParts]: 선택된 부품 목록 (예: CPU, GPU, RAM 등)
  /// [prices]: 각 부품별 가격 (baseParts와 동일한 순서)
  /// [userId]: 판매자 ID
  /// [images]: 공통 이미지 (모든 부품에 동일하게 적용)
  /// [ageInfoType], [isSecondHand], [hasWarranty], [usageFrequency], [purpose]: 공통 메타데이터
  Future<void> submitMultipleRequests({
    required List<BasePart> baseParts,
    required List<int> prices,
    required String userId,
    required List<XFile> images,
    required AgeInfoType ageInfoType,
    int? ageInfoYear,
    int? ageInfoMonth,
    required bool isSecondHand,
    required bool hasWarranty,
    int? warrantyMonthsLeft,
    required String usageFrequency,
    required String purpose,
  }) async {
    try {
      // 입력 검증
      if (baseParts.length != prices.length) {
        throw Exception('부품 개수와 가격 개수가 일치하지 않습니다.');
      }

      // 1. 공통 이미지 업로드 (한 번만)
      state = const SubmitState.uploading(0.0);
      final uploadId = const Uuid().v4();
      final imageUrls = await _imageUploadDataSource.uploadImages(
        images: images,
        userId: userId,
        uploadId: uploadId,
      );

      // 2. 여러 SellRequest 생성
      state = const SubmitState.submitting();
      final now = DateTime.now();
      final sellRequests = <SellRequest>[];

      for (int i = 0; i < baseParts.length; i++) {
        final basePart = baseParts[i];
        final price = prices[i];

        final sellRequest = SellRequest(
          requestId: const Uuid().v4(),
          sellerId: userId,
          partId: basePart.basePartId, // TODO: Part ID가 있으면 사용
          basePartId: basePart.basePartId,
          brand: '', // TODO: BasePart에 brand 필드 추가 필요
          category: basePart.category,
          modelName: basePart.modelName,
          ageInfoType: ageInfoType,
          ageInfoYear: ageInfoYear,
          ageInfoMonth: ageInfoMonth,
          isSecondHand: isSecondHand,
          hasWarranty: hasWarranty,
          warrantyMonthsLeft: warrantyMonthsLeft,
          usageFrequency: usageFrequency,
          purpose: purpose,
          requestedPrice: price,
          imageUrls: imageUrls, // 공통 이미지
          status: SellRequestStatus.pending,
          createdAt: now,
          updatedAt: now,
        );

        sellRequests.add(sellRequest);
      }

      // 3. Batch로 Firestore에 저장
      await _repository.createMultipleSellRequests(sellRequests);

      // 4. 성공
      state = const SubmitState.success();
    } catch (e) {
      state = SubmitState.error(e.toString());
      rethrow;
    }
  }

  /// 상태 초기화
  void reset() {
    state = const SubmitState.idle();
  }
}

/// SubmitMultipleSellRequestsController Provider
final submitMultipleSellRequestsControllerProvider =
StateNotifierProvider<SubmitMultipleSellRequestsController, SubmitState>(
        (ref) {
      final repository = ref.watch(sellRequestRepositoryProvider);
      final imageUploadDataSource = ref.watch(imageUploadDataSourceProvider);
      return SubmitMultipleSellRequestsController(
        repository: repository,
        imageUploadDataSource: imageUploadDataSource,
      );
    });
