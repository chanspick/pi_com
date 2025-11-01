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

  // Profile (차후 구현)
  static const String profile = '/profile';
  static const String settings = '/settings';
  // ✅ 새로 추가: Listing 피처
  static const String partShop = '/part-shop';
  static const String listingDetail = '/listing-detail';

  // ✅ 새로 추가: Parts Price 피처
  static const String partsCategory = '/parts-category';
  static const String priceHistory = '/price-history';
  static const String partDetail = '/part-detail';
  static const String cart = '/cart';
  static const String checkout = '/checkout';
}
