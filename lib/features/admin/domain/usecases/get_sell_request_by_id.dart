
// lib/features/admin/domain/usecases/get_sell_request_by_id.dart

import '../../../../core/models/sell_request_model.dart';
import '../repositories/admin_sell_request_repository.dart';

class GetSellRequestById {
  final AdminSellRequestRepository repository;

  GetSellRequestById(this.repository);

  Future<SellRequest?> call(String requestId) {
    return repository.getSellRequestById(requestId);
  }
}
