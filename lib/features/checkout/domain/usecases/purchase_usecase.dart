
// lib/features/checkout/domain/usecases/purchase_usecase.dart

import 'package:pi_com/features/cart/domain/entities/cart_item_entity.dart';
import 'package:pi_com/features/cart/domain/repositories/cart_repository.dart';
import 'package:pi_com/features/listing/domain/repositories/listing_repository.dart';
import 'package:pi_com/features/order/domain/entities/order_entity.dart';
import 'package:pi_com/features/order/domain/repositories/order_repository.dart';
import 'package:pi_com/features/listing/domain/entities/listing_entity.dart';
import 'package:pi_com/features/price_history/data/repositories/price_history_repository.dart';
import 'package:pi_com/core/utils/notification_helper.dart';
import 'package:pi_com/core/constants/app_constants.dart';
import 'package:pi_com/core/utils/app_logger.dart';

class PurchaseUseCase {
  final OrderRepository _orderRepository;
  final ListingRepository _listingRepository;
  final CartRepository _cartRepository;
  // ignore: unused_field
  final PriceHistoryRepository _priceHistoryRepository;
  final NotificationHelper _notificationHelper;

  PurchaseUseCase(
    this._orderRepository,
    this._listingRepository,
    this._cartRepository,
    this._priceHistoryRepository,
    this._notificationHelper,
  );

  Future<void> call({
    required String userId,
    required List<CartItemEntity> items,
    required String shippingAddress,
  }) async {
    AppLogger.d('시작 - userId: $userId, items: ${items.length}개', tag: 'PurchaseUseCase');

    // 판매자별로 아이템 그룹화
    final Map<String, List<CartItemEntity>> itemsBySeller = {};
    for (final item in items) {
      if (!itemsBySeller.containsKey(item.sellerId)) {
        itemsBySeller[item.sellerId] = [];
      }
      itemsBySeller[item.sellerId]!.add(item);
    }

    AppLogger.d('판매자 수: ${itemsBySeller.length}', tag: 'PurchaseUseCase');

    final timestamp = DateTime.now().millisecondsSinceEpoch;

    // 판매자별로 주문 생성
    int orderIndex = 0;
    for (final entry in itemsBySeller.entries) {
      final sellerId = entry.key;
      final sellerItems = entry.value;
      final sellerName = sellerItems.first.sellerName;

      final totalPrice = sellerItems.fold(0.0, (sum, item) => sum + item.price * item.quantity);
      final shippingFee = AppConstants.defaultShippingFee.toDouble(); // 기본 배송비 상수 사용

      final order = OrderEntity(
        orderId: '${timestamp}_$orderIndex', // 판매자별로 고유한 주문 ID
        userId: userId,
        sellerId: sellerId,
        sellerName: sellerName,
        items: sellerItems,
        totalPrice: totalPrice,
        shippingFee: shippingFee,
        status: OrderStatus.pending,
        createdAt: DateTime.now(),
        shippingAddress: shippingAddress,
      );

      // 디버깅: 주문 데이터 확인
      AppLogger.d('주문 생성 시도 - orderId: ${order.orderId}, userId: ${order.userId}, sellerId: ${order.sellerId}, sellerName: ${order.sellerName}, totalPrice: ${order.totalPrice}, shippingFee: ${order.shippingFee}, items: ${order.items.length}개', tag: 'PurchaseUseCase');

      // 1. 판매자별 주문 생성
      try {
        await _orderRepository.createOrder(order);
        AppLogger.i('주문 생성 성공: ${order.orderId}', tag: 'PurchaseUseCase');
      } catch (e) {
        AppLogger.e('주문 생성 실패: ${order.orderId}, 에러: $e', tag: 'PurchaseUseCase');
        rethrow;
      }

      // 구매자에게 결제 완료 알림 발송
      AppLogger.d('구매자 알림 발송 시도...', tag: 'PurchaseUseCase');
      try {
        await _notificationHelper.notifyPaymentCompleted(
          buyerId: userId,
          orderId: order.orderId,
          listingId: sellerItems.first.listingId,
          partName: sellerItems.length == 1
              ? sellerItems.first.partName
              : '${sellerItems.first.partName} 외 ${sellerItems.length - 1}건',
          totalAmount: (totalPrice + shippingFee).toInt(),
        );
        AppLogger.i('구매자 알림 발송 성공', tag: 'PurchaseUseCase');
      } catch (e) {
        AppLogger.e('구매자 알림 발송 실패: $e', tag: 'PurchaseUseCase');
        rethrow;
      }

      // 2. 해당 판매자의 listing 상태 업데이트 + 가격 스냅샷 생성
      for (final item in sellerItems) {
        AppLogger.d('listing 상태 업데이트 시도: ${item.listingId}', tag: 'PurchaseUseCase');
        try {
          await _listingRepository.updateListingStatus(item.listingId, ListingStatus.sold);
          AppLogger.i('listing 상태 업데이트 성공: ${item.listingId}', tag: 'PurchaseUseCase');
        } catch (e) {
          AppLogger.e('listing 상태 업데이트 실패: ${item.listingId}, 에러: $e', tag: 'PurchaseUseCase');
          rethrow;
        }

        // 판매자에게 매물 판매 완료 알림 발송
        AppLogger.d('판매자 알림 발송 시도...', tag: 'PurchaseUseCase');
        try {
          await _notificationHelper.notifyListingSold(
            sellerId: sellerId,
            listingId: item.listingId,
            partName: item.partName,
            soldPrice: (item.price * item.quantity).toInt(),
          );
          AppLogger.i('판매자 알림 발송 성공', tag: 'PurchaseUseCase');
        } catch (e) {
          AppLogger.e('판매자 알림 발송 실패: $e', tag: 'PurchaseUseCase');
          rethrow;
        }

        // NOTE: Cloud Functions의 onListingUpdated 트리거가
        // listing 상태 변경을 감지하여 자동으로 PriceHistory를 업데이트합니다.
      }

      orderIndex++;
    }

    // 4. 장바구니 비우기 (모든 아이템)
    for (final item in items) {
      await _cartRepository.removeFromCart(item.listingId);
    }
  }
}
