import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pi_com/features/payment/data/datasources/payment_remote_datasource.dart';
import 'package:pi_com/features/payment/data/datasources/payment_remote_datasource_impl.dart';
import 'package:pi_com/features/payment/data/datasources/toss_payment_remote_datasource.dart';
import 'package:pi_com/features/payment/data/repositories/payment_repository_impl.dart';
import 'package:pi_com/features/payment/domain/repositories/payment_repository.dart';
import 'package:pi_com/features/payment/domain/usecases/prepare_payment_usecase.dart';
import 'package:pi_com/features/payment/domain/usecases/approve_payment_usecase.dart';
import 'package:pi_com/features/payment/domain/usecases/cancel_payment_usecase.dart';
import 'package:pi_com/features/payment/domain/usecases/toss_payment_usecases.dart';
import 'package:pi_com/features/payment/domain/entities/payment_entity.dart';
import 'package:pi_com/features/payment/domain/entities/toss_payment_entity.dart';

// ============================================================================
// Data Layer Providers
// ============================================================================

/// Payment Remote DataSource Provider
final paymentRemoteDataSourceProvider = Provider<PaymentRemoteDataSource>((ref) {
  return PaymentRemoteDataSourceImpl(
    // Firebase Functions URL
    baseUrl: 'https://asia-northeast3-picom-team.cloudfunctions.net/api',
  );
});

/// Payment Repository Provider
final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  final remoteDataSource = ref.watch(paymentRemoteDataSourceProvider);
  return PaymentRepositoryImpl(remoteDataSource: remoteDataSource);
});

// ============================================================================
// Use Case Providers
// ============================================================================

/// 결제 준비 Use Case Provider
final preparePaymentUseCaseProvider = Provider<PreparePaymentUseCase>((ref) {
  final repository = ref.watch(paymentRepositoryProvider);
  return PreparePaymentUseCase(repository: repository);
});

/// 결제 승인 Use Case Provider
final approvePaymentUseCaseProvider = Provider<ApprovePaymentUseCase>((ref) {
  final repository = ref.watch(paymentRepositoryProvider);
  return ApprovePaymentUseCase(repository: repository);
});

/// 결제 취소 Use Case Provider
final cancelPaymentUseCaseProvider = Provider<CancelPaymentUseCase>((ref) {
  final repository = ref.watch(paymentRepositoryProvider);
  return CancelPaymentUseCase(repository: repository);
});

// ============================================================================
// State Providers
// ============================================================================

/// 현재 결제 진행 중인 Payment Entity Provider
final currentPaymentProvider = StateProvider<PaymentEntity?>((ref) => null);

/// 결제 준비 중 상태 Provider
final isPreparingPaymentProvider = StateProvider<bool>((ref) => false);

/// 결제 승인 중 상태 Provider
final isApprovingPaymentProvider = StateProvider<bool>((ref) => false);

/// 결제 에러 메시지 Provider
final paymentErrorProvider = StateProvider<String?>((ref) => null);

// ============================================================================
// 토스페이먼츠 Providers
// ============================================================================

/// 토스페이먼츠 Remote DataSource Provider
final tossPaymentRemoteDataSourceProvider = Provider<TossPaymentRemoteDataSource>((ref) {
  return TossPaymentRemoteDataSourceImpl(
    baseUrl: 'https://asia-northeast3-picom-team.cloudfunctions.net/api',
  );
});

/// 토스페이먼츠 결제 승인 UseCase Provider
final approveTossPaymentUseCaseProvider = Provider<ApproveTossPaymentUseCase>((ref) {
  final dataSource = ref.watch(tossPaymentRemoteDataSourceProvider);
  return ApproveTossPaymentUseCase(dataSource: dataSource);
});

/// 토스페이먼츠 결제 취소 UseCase Provider
final cancelTossPaymentUseCaseProvider = Provider<CancelTossPaymentUseCase>((ref) {
  final dataSource = ref.watch(tossPaymentRemoteDataSourceProvider);
  return CancelTossPaymentUseCase(dataSource: dataSource);
});

/// 토스페이먼츠 결제 조회 UseCase Provider
final getTossPaymentUseCaseProvider = Provider<GetTossPaymentUseCase>((ref) {
  final dataSource = ref.watch(tossPaymentRemoteDataSourceProvider);
  return GetTossPaymentUseCase(dataSource: dataSource);
});

/// 현재 토스페이먼츠 결제 정보 Provider
final currentTossPaymentProvider = StateProvider<TossPaymentEntity?>((ref) => null);
