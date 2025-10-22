// lib/features/admin/domain/usecases/get_pending_sell_requests.dart

import '../repositories/admin_sell_request_repository.dart';
import '../../../../core/models/sell_request_model.dart';

/// 대기 중인 SellRequest 조회 UseCase
///
/// 역할:
/// - 승인 대기 중인(pending) SellRequest 실시간 조회
/// - Admin 대시보드에서 사용
class GetPendingSellRequests {
  final AdminSellRequestRepository _repository;

  GetPendingSellRequests(this._repository);

  /// 대기 중인 SellRequest Stream 반환
  ///
  /// 반환: Stream<List<SellRequest>> - 실시간 업데이트되는 목록
  ///
  /// 정렬: createdAt 내림차순 (최신순)
  Stream<List<SellRequest>> call() {
    return _repository.getPendingSellRequests();
  }
}
