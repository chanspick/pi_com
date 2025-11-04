// lib/core/constants/routes.dart

/// 앱 내 라우트 이름 상수
class Routes {
  Routes._(); // Private constructor

  // Auth
  static const String auth = '/auth';

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
  static const String salesHistory = '/sales-history';
  static const String sellRequestHistory = '/sell-request-history';
  static const String favorites = '/favorites';
  static const String priceAlerts = '/price-alerts';
  static const String settings = '/settings';

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

  // ✅ 새로 추가: DragonBall 피처
  static const String dragonBallStorage = '/dragon-ball-storage';
  static const String batchShipmentRequest = '/batch-shipment-request';
  static const String batchShipmentHistory = '/batch-shipment-history';
}
