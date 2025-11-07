import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pi_com/features/payment/data/datasources/payment_remote_datasource.dart';
import 'package:pi_com/features/payment/data/datasources/payment_remote_datasource_impl.dart';
import 'package:pi_com/features/payment/data/repositories/payment_repository_impl.dart';
import 'package:pi_com/features/payment/domain/repositories/payment_repository.dart';
import 'package:pi_com/features/payment/domain/usecases/prepare_payment_usecase.dart';
import 'package:pi_com/features/payment/domain/usecases/approve_payment_usecase.dart';
import 'package:pi_com/features/payment/domain/usecases/cancel_payment_usecase.dart';
import 'package:pi_com/features/payment/domain/entities/payment_entity.dart';

// ============================================================================
// Data Layer Providers
// ============================================================================

/// Payment Remote DataSource Provider
final paymentRemoteDataSourceProvider = Provider<PaymentRemoteDataSource>((ref) {
  return PaymentRemoteDataSourceImpl(
    // TODO: 실제 백엔드 URL 설정
    baseUrl: 'http://localhost:3000', // 개발 환경
    // baseUrl: 'https://yourapi.com', // 프로덕션 환경
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
