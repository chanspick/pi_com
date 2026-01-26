// lib/features/warranty/data/repositories/warranty_repository_impl.dart

import '../datasources/warranty_remote_datasource.dart';
import '../models/verification_transaction_model.dart';
import '../models/warranty_model.dart';
import '../models/service_request_model.dart';
import '../../domain/repositories/warranty_repository.dart';

class WarrantyRepositoryImpl implements WarrantyRepository {
  final WarrantyRemoteDatasource _remoteDatasource;

  WarrantyRepositoryImpl({
    required WarrantyRemoteDatasource remoteDatasource,
  }) : _remoteDatasource = remoteDatasource;

  // ============================================================================
  // Transaction
  // ============================================================================

  @override
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
    return await _remoteDatasource.createTransaction({
      'partCategory': partCategory,
      'brand': brand,
      'modelName': modelName,
      'serialNumber': serialNumber,
      'photoUrls': photoUrls ?? [],
      'inspectorId': inspectorId,
      'inspectorName': inspectorName,
      'inspectionNote': inspectionNote,
      'conditionScore': conditionScore,
      'inspectionPhotoUrls': inspectionPhotoUrls ?? [],
      'buyerCompanyName': buyerCompanyName,
      'buyerContactName': buyerContactName,
      'buyerContactPhone': buyerContactPhone,
      'salePrice': salePrice,
    });
  }

  @override
  Future<VerificationTransactionModel> getTransactionById(String transactionId) {
    return _remoteDatasource.getTransactionById(transactionId);
  }

  @override
  Stream<List<VerificationTransactionModel>> watchTransactions({TransactionStatus? status}) {
    return _remoteDatasource.watchTransactions(status: status);
  }

  @override
  Future<void> updateTransactionStatus(String transactionId, TransactionStatus status) {
    return _remoteDatasource.updateTransactionStatus(transactionId, status);
  }

  @override
  Future<String> generateQRCode(String transactionId) {
    return _remoteDatasource.generateQRCode(transactionId);
  }

  @override
  Future<String> generateReport(String transactionId) {
    return _remoteDatasource.generateReport(transactionId);
  }

  // ============================================================================
  // Warranty
  // ============================================================================

  @override
  Stream<List<WarrantyModel>> watchWarranties({WarrantyStatus? status}) {
    return _remoteDatasource.watchWarranties(status: status);
  }

  @override
  Future<WarrantyModel> getWarrantyById(String warrantyId) {
    return _remoteDatasource.getWarrantyById(warrantyId);
  }

  // ============================================================================
  // Service Request
  // ============================================================================

  @override
  Stream<List<ServiceRequestModel>> watchServiceRequests({ServiceRequestStatus? status}) {
    return _remoteDatasource.watchServiceRequests(status: status);
  }

  @override
  Future<ServiceRequestModel> getServiceRequestById(String requestId) {
    return _remoteDatasource.getServiceRequestById(requestId);
  }

  @override
  Future<void> updateServiceRequestStatus(
    String requestId, {
    required ServiceRequestStatus status,
    String? handlerId,
    String? handlerNote,
    String? inboundTrackingNumber,
    String? outboundTrackingNumber,
  }) {
    return _remoteDatasource.updateServiceRequestStatus(
      requestId,
      status: status,
      handlerId: handlerId,
      handlerNote: handlerNote,
      inboundTrackingNumber: inboundTrackingNumber,
      outboundTrackingNumber: outboundTrackingNumber,
    );
  }
}
