// lib/features/sell_request/data/repositories/sell_request_repository_impl.dart

import '../../../../core/models/sell_request_model.dart';
import '../../domain/repositories/sell_request_repository.dart';
import '../datasources/sell_request_datasource.dart';

class SellRequestRepositoryImpl implements SellRequestRepository {
  final SellRequestDataSource _dataSource;

  SellRequestRepositoryImpl(this._dataSource);

  @override
  Future<void> createSellRequest(SellRequest sellRequest) async {
    return await _dataSource.createSellRequest(sellRequest);
  }

  @override
  Future<SellRequest?> getSellRequest(String requestId) async {
    return await _dataSource.getSellRequest(requestId);
  }

  @override
  Stream<List<SellRequest>> getUserSellRequestsStream(String userId) {
    return _dataSource.getUserSellRequestsStream(userId);
  }

  @override
  Future<void> deleteSellRequest(String requestId) async {
    return await _dataSource.deleteSellRequest(requestId);
  }

  @override
  Stream<List<SellRequest>> getAllSellRequestsStream() {
    return _dataSource.getAllSellRequestsStream();
  }

  @override
  Stream<List<SellRequest>> getSellRequestsByStatusStream(
      SellRequestStatus status,
      ) {
    return _dataSource.getSellRequestsByStatusStream(status);
  }

  @override
  Future<void> updateSellRequestStatus({
    required String requestId,
    required SellRequestStatus status,
    String? listingId,
    String? adminNotes,
  }) async {
    return await _dataSource.updateSellRequestStatus(
      requestId: requestId,
      status: status,
      listingId: listingId,
      adminNotes: adminNotes,
    );
  }
}
