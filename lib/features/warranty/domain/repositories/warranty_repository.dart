// lib/features/warranty/domain/repositories/warranty_repository.dart

import '../../data/models/verification_transaction_model.dart';
import '../../data/models/warranty_model.dart';
import '../../data/models/service_request_model.dart';

abstract class WarrantyRepository {
  // Transaction
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
  });

  Future<VerificationTransactionModel> getTransactionById(String transactionId);
  Stream<List<VerificationTransactionModel>> watchTransactions({TransactionStatus? status});
  Future<void> updateTransactionStatus(String transactionId, TransactionStatus status);
  Future<String> generateQRCode(String transactionId);
  Future<String> generateReport(String transactionId);

  // Warranty
  Stream<List<WarrantyModel>> watchWarranties({WarrantyStatus? status});
  Future<WarrantyModel> getWarrantyById(String warrantyId);

  // Service Request
  Stream<List<ServiceRequestModel>> watchServiceRequests({ServiceRequestStatus? status});
  Future<ServiceRequestModel> getServiceRequestById(String requestId);
  Future<void> updateServiceRequestStatus(
    String requestId, {
    required ServiceRequestStatus status,
    String? handlerId,
    String? handlerNote,
    String? inboundTrackingNumber,
    String? outboundTrackingNumber,
  });
}
