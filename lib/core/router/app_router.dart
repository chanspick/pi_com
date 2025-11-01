// lib/core/router/app_router.dart
import 'package:flutter/material.dart';
import '../constants/routes.dart';
import '../../features/notification/presentations/screens/notification_list_screen.dart';
import '../../features/sell_request/presentation/screens/sell_request_screen.dart';
import '../../features/sell_request/presentation/screens/finished_pc_sell_screen.dart';

// ✅ 새로 추가: Listing 피처 imports
import '../../features/listing/presentation/screens/part_shop_screen.dart';
import '../../features/listing/presentation/screens/listing_detail_screen.dart';

// ✅ 새로 추가: Parts Price 피처 imports
import '../../features/parts_price/presentation/screens/part_category_screen.dart';
import '../../features/parts_price/presentation/screens/price_history_screen.dart';
import '../../features/parts_price/domain/entities/base_part_entity.dart';
import '../../features/cart/presentation/screens/cart_screen.dart';
import '../../features/checkout/presentation/screens/checkout_screen.dart';

/// 앱 내부용 Navigator Route Generator
class AppRouter {
  static Route generateRoute(RouteSettings settings) {
    switch (settings.name) {
    // Notification
      case Routes.notifications:
        return MaterialPageRoute(
          builder: (_) => const NotificationListScreen(),
          settings: settings,
        );

    // Sell Request Details
      case Routes.sellRequestDetails:
        final sellRequestId = settings.arguments as String?;
        if (sellRequestId == null) {
          return _errorRoute('판매 요청 ID가 필요합니다.');
        }
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('판매 요청 상세')),
            body: Center(child: Text('SellRequest ID: $sellRequestId\n(구현 예정)')),
          ),
          settings: settings,
        );

    // Sell Request (부품 판매)
      case Routes.sellRequest:
        return MaterialPageRoute(
          builder: (_) => const SellRequestScreen(),
          settings: settings,
        );

    // 완제품 판매
      case Routes.sellFinishedPc:
        return MaterialPageRoute(
          builder: (_) => const FinishedPcSellScreen(),
          settings: settings,
        );

    // ✅ 새로 추가: 부품 스토어 (Listing)
      case Routes.partShop:
        return MaterialPageRoute(
          builder: (_) => const PartShopScreen(),
          settings: settings,
        );

    // ✅ 새로 추가: Listing 상세
      case Routes.listingDetail:
        final listingId = settings.arguments as String?;
        if (listingId == null) {
          return _errorRoute('상품 ID가 필요합니다.');
        }
        return MaterialPageRoute(
          builder: (_) => ListingDetailScreen(listingId: listingId),
          settings: settings,
        );

    // ✅ 새로 추가: 부품 시세 (Parts Price)
      case Routes.partsCategory:
        return MaterialPageRoute(
          builder: (_) => const PartsCategoryScreen(),
          settings: settings,
        );

    // ✅ 새로 추가: 가격 이력
      case Routes.priceHistory:
        final basePart = settings.arguments as BasePartEntity?;
        if (basePart == null) {
          return _errorRoute('부품 정보가 필요합니다.');
        }
        return MaterialPageRoute(
          builder: (_) => PriceHistoryScreen(basePart: basePart),
          settings: settings,
        );

      case Routes.cart:
        return MaterialPageRoute(
          builder: (_) => const CartScreen(),
          settings: settings,
        );

      case Routes.checkout:
        return MaterialPageRoute(
          builder: (_) => const CheckoutScreen(),
          settings: settings,
        );

    // Marketplace (차후 구현)
      case Routes.marketplace:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('마켓플레이스')),
            body: const Center(child: Text('마켓플레이스 (구현 예정)')),
          ),
          settings: settings,
        );

    // 기본: 404 에러
      default:
        return _errorRoute('페이지를 찾을 수 없습니다: ${settings.name}');
    }
  }

  /// 에러 라우트
  static Route _errorRoute(String message) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('오류')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
