// lib/features/warranty/data/datasources/warranty_remote_datasource.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import '../models/verification_transaction_model.dart';
import '../models/warranty_model.dart';
import '../models/service_request_model.dart';

abstract class WarrantyRemoteDatasource {
  // Transaction
  Future<String> createTransaction(Map<String, dynamic> data);
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

class WarrantyRemoteDatasourceImpl implements WarrantyRemoteDatasource {
  final FirebaseFirestore _firestore;
  final Dio _dio;

  WarrantyRemoteDatasourceImpl({
    FirebaseFirestore? firestore,
    Dio? dio,
    String? apiBaseUrl,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _dio = dio ?? Dio(BaseOptions(
          baseUrl: apiBaseUrl ?? 'https://asia-northeast3-picom-team.cloudfunctions.net/api',
          headers: {'Content-Type': 'application/json'},
        ));

  // ============================================================================
  // Transaction
  // ============================================================================

  @override
  Future<String> createTransaction(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/warranty/transaction', data: data);
      return response.data['transactionId'];
    } on DioException catch (e) {
      throw Exception('Failed to create transaction: ${e.response?.data ?? e.message}');
    }
  }

  @override
  Future<VerificationTransactionModel> getTransactionById(String transactionId) async {
    final doc = await _firestore
        .collection('verification_transactions')
        .doc(transactionId)
        .get();

    if (!doc.exists) {
      throw Exception('Transaction not found');
    }

    return VerificationTransactionModel.fromFirestore(doc);
  }

  @override
  Stream<List<VerificationTransactionModel>> watchTransactions({TransactionStatus? status}) {
    Query<Map<String, dynamic>> query = _firestore
        .collection('verification_transactions')
        .orderBy('createdAt', descending: true);

    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }

    return query.limit(100).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => VerificationTransactionModel.fromFirestore(doc))
          .toList();
    });
  }

  @override
  Future<void> updateTransactionStatus(String transactionId, TransactionStatus status) async {
    try {
      await _dio.put('/warranty/transaction/$transactionId/status', data: {'status': status.name});
    } on DioException catch (e) {
      throw Exception('Failed to update transaction status: ${e.response?.data ?? e.message}');
    }
  }

  @override
  Future<String> generateQRCode(String transactionId) async {
    try {
      final response = await _dio.post('/warranty/generate-qr/$transactionId');
      return response.data['qrCodeImageUrl'];
    } on DioException catch (e) {
      throw Exception('Failed to generate QR code: ${e.response?.data ?? e.message}');
    }
  }

  @override
  Future<String> generateReport(String transactionId) async {
    try {
      final response = await _dio.post('/warranty/generate-report/$transactionId');
      return response.data['reportUrl'];
    } on DioException catch (e) {
      throw Exception('Failed to generate report: ${e.response?.data ?? e.message}');
    }
  }

  // ============================================================================
  // Warranty
  // ============================================================================

  @override
  Stream<List<WarrantyModel>> watchWarranties({WarrantyStatus? status}) {
    Query<Map<String, dynamic>> query = _firestore
        .collection('warranties')
        .orderBy('createdAt', descending: true);

    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }

    return query.limit(100).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => WarrantyModel.fromFirestore(doc))
          .toList();
    });
  }

  @override
  Future<WarrantyModel> getWarrantyById(String warrantyId) async {
    final doc = await _firestore
        .collection('warranties')
        .doc(warrantyId)
        .get();

    if (!doc.exists) {
      throw Exception('Warranty not found');
    }

    return WarrantyModel.fromFirestore(doc);
  }

  // ============================================================================
  // Service Request
  // ============================================================================

  @override
  Stream<List<ServiceRequestModel>> watchServiceRequests({ServiceRequestStatus? status}) {
    Query<Map<String, dynamic>> query = _firestore
        .collection('service_requests')
        .orderBy('createdAt', descending: true);

    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }

    return query.limit(100).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => ServiceRequestModel.fromFirestore(doc))
          .toList();
    });
  }

  @override
  Future<ServiceRequestModel> getServiceRequestById(String requestId) async {
    final doc = await _firestore
        .collection('service_requests')
        .doc(requestId)
        .get();

    if (!doc.exists) {
      throw Exception('Service request not found');
    }

    return ServiceRequestModel.fromFirestore(doc);
  }

  @override
  Future<void> updateServiceRequestStatus(
    String requestId, {
    required ServiceRequestStatus status,
    String? handlerId,
    String? handlerNote,
    String? inboundTrackingNumber,
    String? outboundTrackingNumber,
  }) async {
    final data = <String, dynamic>{
      'status': status.name,
    };

    if (handlerId != null) data['handlerId'] = handlerId;
    if (handlerNote != null) data['handlerNote'] = handlerNote;
    if (inboundTrackingNumber != null) data['inboundTrackingNumber'] = inboundTrackingNumber;
    if (outboundTrackingNumber != null) data['outboundTrackingNumber'] = outboundTrackingNumber;

    try {
      await _dio.put('/warranty/service-request/$requestId/status', data: data);
    } on DioException catch (e) {
      throw Exception('Failed to update service request status: ${e.response?.data ?? e.message}');
    }
  }
}
