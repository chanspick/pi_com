/// 배송비 관련 상수
///
/// 결제, 장바구니 등에서 사용되는 배송비 상수를 정의합니다.
/// 하드코딩된 4500원을 이 상수로 대체합니다.

class ShippingConstants {
  ShippingConstants._(); // Private constructor

  /// 기본 배송비 (원)
  static const int defaultShippingFee = 4500;

  /// 무료 배송 기준 금액 (원)
  /// 이 금액 이상 주문 시 배송비 무료
  static const int freeShippingThreshold = 50000;

  /// 도서산간 추가 배송비 (원)
  static const int remoteAreaExtraFee = 3000;

  /// 배송비 계산
  /// [subtotal] 상품 금액 합계
  /// [isRemoteArea] 도서산간 지역 여부
  static int calculateShippingFee(int subtotal, {bool isRemoteArea = false}) {
    // 무료 배송 기준 이상이면 배송비 무료
    if (subtotal >= freeShippingThreshold) {
      return isRemoteArea ? remoteAreaExtraFee : 0;
    }

    // 기본 배송비 + 도서산간 추가 배송비
    return defaultShippingFee + (isRemoteArea ? remoteAreaExtraFee : 0);
  }

  /// 배송비 메시지 생성
  static String getShippingMessage(int subtotal) {
    if (subtotal >= freeShippingThreshold) {
      return '무료배송';
    }

    final remaining = freeShippingThreshold - subtotal;
    return '${_formatPrice(remaining)}원 추가 주문 시 무료배송';
  }

  static String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );
  }
}
