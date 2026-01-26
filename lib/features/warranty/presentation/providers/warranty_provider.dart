// lib/features/warranty/presentation/providers/warranty_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/warranty_remote_datasource.dart';
import '../../data/repositories/warranty_repository_impl.dart';
import '../../data/models/verification_transaction_model.dart';
import '../../data/models/warranty_model.dart';
import '../../data/models/service_request_model.dart';
import '../../domain/repositories/warranty_repository.dart';

// ============================================================================
// Repository Provider
// ============================================================================

final warrantyRemoteDatasourceProvider = Provider<WarrantyRemoteDatasource>((ref) {
  return WarrantyRemoteDatasourceImpl();
});

final warrantyRepositoryProvider = Provider<WarrantyRepository>((ref) {
  final datasource = ref.watch(warrantyRemoteDatasourceProvider);
  return WarrantyRepositoryImpl(remoteDatasource: datasource);
});

// ============================================================================
// Transaction Providers
// ============================================================================

final transactionsStreamProvider = StreamProvider.autoDispose
    .family<List<VerificationTransactionModel>, TransactionStatus?>((ref, status) {
  final repository = ref.watch(warrantyRepositoryProvider);
  return repository.watchTransactions(status: status);
});

final allTransactionsStreamProvider = StreamProvider.autoDispose<List<VerificationTransactionModel>>((ref) {
  final repository = ref.watch(warrantyRepositoryProvider);
  return repository.watchTransactions();
});

final transactionByIdProvider = FutureProvider.autoDispose
    .family<VerificationTransactionModel, String>((ref, transactionId) {
  final repository = ref.watch(warrantyRepositoryProvider);
  return repository.getTransactionById(transactionId);
});

// ============================================================================
// Warranty Providers
// ============================================================================

final warrantiesStreamProvider = StreamProvider.autoDispose
    .family<List<WarrantyModel>, WarrantyStatus?>((ref, status) {
  final repository = ref.watch(warrantyRepositoryProvider);
  return repository.watchWarranties(status: status);
});

final allWarrantiesStreamProvider = StreamProvider.autoDispose<List<WarrantyModel>>((ref) {
  final repository = ref.watch(warrantyRepositoryProvider);
  return repository.watchWarranties();
});

final warrantyByIdProvider = FutureProvider.autoDispose
    .family<WarrantyModel, String>((ref, warrantyId) {
  final repository = ref.watch(warrantyRepositoryProvider);
  return repository.getWarrantyById(warrantyId);
});

// ============================================================================
// Service Request Providers
// ============================================================================

final serviceRequestsStreamProvider = StreamProvider.autoDispose
    .family<List<ServiceRequestModel>, ServiceRequestStatus?>((ref, status) {
  final repository = ref.watch(warrantyRepositoryProvider);
  return repository.watchServiceRequests(status: status);
});

final allServiceRequestsStreamProvider = StreamProvider.autoDispose<List<ServiceRequestModel>>((ref) {
  final repository = ref.watch(warrantyRepositoryProvider);
  return repository.watchServiceRequests();
});

final serviceRequestByIdProvider = FutureProvider.autoDispose
    .family<ServiceRequestModel, String>((ref, requestId) {
  final repository = ref.watch(warrantyRepositoryProvider);
  return repository.getServiceRequestById(requestId);
});

// ============================================================================
// Action Providers (Notifiers)
// ============================================================================

class TransactionActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final WarrantyRepository _repository;

  TransactionActionsNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<String> createTransaction({
    required String partCategory,
    required String brand,
    required String modelName,
    String? serialNumber,
    List<String>? photoUrls,
    required String inspectorId,
    required String inspectorName,
    required String inspectionNote,
    required int conditionScore,
    List<String>? inspectionPhotoUrls,
    String? buyerCompanyName,
    String? buyerContactName,
    String? buyerContactPhone,
    required int salePrice,
  }) async {
    state = const AsyncValue.loading();
    try {
      final transactionId = await _repository.createTransaction(
        partCategory: partCategory,
        brand: brand,
        modelName: modelName,
        serialNumber: serialNumber,
        photoUrls: photoUrls,
        inspectorId: inspectorId,
        inspectorName: inspectorName,
        inspectionNote: inspectionNote,
        conditionScore: conditionScore,
        inspectionPhotoUrls: inspectionPhotoUrls,
        buyerCompanyName: buyerCompanyName,
        buyerContactName: buyerContactName,
        buyerContactPhone: buyerContactPhone,
        salePrice: salePrice,
      );
      state = const AsyncValue.data(null);
      return transactionId;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<String> generateQRCode(String transactionId) async {
    state = const AsyncValue.loading();
    try {
      final url = await _repository.generateQRCode(transactionId);
      state = const AsyncValue.data(null);
      return url;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<String> generateReport(String transactionId) async {
    state = const AsyncValue.loading();
    try {
      final url = await _repository.generateReport(transactionId);
      state = const AsyncValue.data(null);
      return url;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final transactionActionsProvider =
    StateNotifierProvider<TransactionActionsNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(warrantyRepositoryProvider);
  return TransactionActionsNotifier(repository);
});

class ServiceRequestActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final WarrantyRepository _repository;

  ServiceRequestActionsNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<void> updateStatus(
    String requestId, {
    required ServiceRequestStatus status,
    String? handlerId,
    String? handlerNote,
    String? inboundTrackingNumber,
    String? outboundTrackingNumber,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateServiceRequestStatus(
        requestId,
        status: status,
        handlerId: handlerId,
        handlerNote: handlerNote,
        inboundTrackingNumber: inboundTrackingNumber,
        outboundTrackingNumber: outboundTrackingNumber,
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final serviceRequestActionsProvider =
    StateNotifierProvider<ServiceRequestActionsNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(warrantyRepositoryProvider);
  return ServiceRequestActionsNotifier(repository);
});
