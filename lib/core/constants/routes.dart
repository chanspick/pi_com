// lib/core/constants/routes.dart

/// 앱 내 라우트 이름 상수
class Routes {
  Routes._(); // Private constructor

  // Auth
  static const String auth = '/auth';
  static const String consent = '/consent';
  static const String accountDelete = '/settings/account-delete';

  // Home
  static const String home = '/';

  // Notification
  static const String notifications = '/notifications';

  // Sell Request (차후 구현)
  static const String sellRequest = '/sell-request';
  static const String finishedPcSell = '/finished-pc-sell';
  static const String sellRequestDetails = '/sell-request-details';
  static const String sellFinishedPc = '/sell-finished-pc';
  // Marketplace (차후 구현)
  static const String marketplace = '/marketplace';
  static const String productDetails = '/product-details';

  // MyPage
  static const String myPage = '/my-page';
  static const String profile = '/profile';
  static const String profileEdit = '/profile-edit';
  static const String purchaseHistory = '/purchase-history';
  static const String purchaseDetail = '/purchase-detail'; // ✅ 추가
  static const String salesHistory = '/sales-history';
  static const String sellRequestHistory = '/sell-request-history';
  static const String favorites = '/favorites';
  static const String priceAlerts = '/price-alerts';
  static const String settings = '/settings';
  static const String addressList = '/address-list';
  static const String addressForm = '/address-form';

  // Search
  static const String partSearch = '/part-search'; // sell_request용 (parts 컬렉션)
  static const String basePartSearch = '/base-part-search'; // 홈 검색용 (base_parts 컬렉션)
  // ✅ 새로 추가: Listing 피처
  static const String partShop = '/part-shop';
  static const String listingDetail = '/listing-detail';

  // ✅ 새로 추가: Parts Price 피처
  static const String partsCategory = '/parts-category';
  static const String priceHistory = '/price-history';
  static const String partDetail = '/part-detail';
  static const String cart = '/cart';
  static const String checkout = '/checkout';
  static const String paymentSuccess = '/payment/success';
  static const String paymentFailure = '/payment/failure';
  static const String paymentCancel = '/payment/cancel';

  // ✅ 새로 추가: PC 보관함 피처
  static const String pcStorage = '/pc-storage'; // PC 보관함
  static const String dragonBallStorage = '/pc-storage'; // @deprecated: pcStorage 사용 권장
  static const String batchShipmentRequest = '/batch-shipment-request';
  static const String batchShipmentHistory = '/batch-shipment-history';

  // ✅ 새로 추가: Recommendation 피처
  static const String myEstimate = '/my-estimate';
  static const String pcAssembly = '/pc-assembly';

  // ✅ 개발자 전용: Admin Debug
  static const String adminDebug = '/admin-debug';

  // ✅ 약관 및 정책
  static const String terms = '/terms';
  static const String privacy = '/privacy';
  static const String refund = '/refund';
  static const String storageServiceTerms = '/storage-service-terms';

  // ✅ 환불 관리
  static const String refundList = '/refund-list';
  static const String refundRequest = '/refund-request';
  static const String refundDetail = '/refund-detail';
  static const String refundReturnShipping = '/refund-return-shipping';
}
