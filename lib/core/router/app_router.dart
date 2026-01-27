// lib/core/router/app_router.dart
import 'package:flutter/material.dart';
import '../constants/routes.dart';
import '../../features/notification/presentation/screens/notification_list_screen.dart';
import '../../features/sell_request/presentation/screens/sell_request_screen.dart';
import '../../features/sell_request/presentation/screens/finished_pc_sell_screen.dart';
import '../../features/sell_request/presentation/screens/sell_request_detail_view_screen.dart'; // ✅ 추가

// ✅ 새로 추가: Listing 피처 imports
import '../../features/listing/presentation/screens/part_shop_screen.dart';
import '../../features/listing/presentation/screens/listing_detail_screen.dart';

// ✅ 새로 추가: Parts Price 피처 imports
import '../../features/parts_price/presentation/screens/part_category_screen.dart';
import '../../features/parts_price/presentation/screens/price_history_screen.dart';
import '../../features/parts_price/domain/entities/base_part_entity.dart';
import '../../features/cart/presentation/screens/cart_screen.dart';
import '../../features/checkout/presentation/screens/checkout_screen.dart';

// ✅ 새로 추가: MyPage 피처 imports
import '../../features/my_page/presentation/screens/my_page_screen.dart';
import '../../features/my_page/presentation/screens/profile_edit_screen.dart';
import '../../features/my_page/presentation/screens/purchase_history_screen.dart';
import '../../features/my_page/presentation/screens/sales_history_screen.dart';
import '../../features/my_page/presentation/screens/sell_request_history_screen.dart';
import '../../features/my_page/presentation/screens/favorites_screen.dart';

// ✅ 새로 추가: Order 피처 imports
import '../../features/order/presentation/screens/purchase_detail_screen.dart'; // ✅ 추가

// ✅ 새로 추가: PriceAlert 피처 imports
import '../../features/price_alert/presentation/screens/price_alerts_screen.dart';

// ✅ 새로 추가: PC Storage (DragonBall) 피처 imports
import '../../features/dragon_ball/presentation/screens/pc_storage_screen.dart';
import '../../features/dragon_ball/presentation/screens/batch_shipment_request_screen.dart';
import '../../features/dragon_ball/presentation/screens/batch_shipment_history_screen.dart';

// ✅ 새로 추가: Search 피처 imports
import '../../features/sell_request/presentation/screens/part_search_screen.dart';
import '../../features/parts_price/presentation/screens/base_part_search_screen.dart';

// ✅ 새로 추가: Settings 피처 imports
import '../../features/my_page/presentation/screens/settings_screen.dart';
import '../../features/my_page/presentation/screens/account_delete_screen.dart';

// ✅ 새로 추가: Auth 피처 imports (Consent)
import '../../features/auth/presentation/screens/consent_screen.dart';

// ✅ 새로 추가: Address 피처 imports
import '../../features/address/presentation/screens/address_list_screen.dart';
import '../../features/address/presentation/screens/address_form_screen.dart';

// ✅ 새로 추가: Recommendation 피처 imports
import '../../features/recommendation/presentation/screens/my_estimate_screen.dart';
import '../../features/recommendation/presentation/screens/pc_assembly_screen.dart';
import '../../features/recommendation/data/models/spec_profile_model.dart';

// ✅ 새로 추가: Web Public 피처 imports
import '../../features/web_public/presentation/screens/terms_page.dart';
import '../../features/web_public/presentation/screens/privacy_page.dart';
import '../../features/web_public/presentation/screens/refund_page.dart';
import '../../features/web_public/presentation/screens/storage_service_terms_page.dart';

// ✅ 새로 추가: Refund 피처 imports
import '../../features/refund/presentation/screens/refund_request_screen.dart';
import '../../features/refund/presentation/screens/refund_return_shipping_screen.dart';
import '../../features/refund/presentation/screens/refund_detail_screen.dart';
import '../../features/refund/presentation/screens/refund_list_screen.dart';

// Warranty Admin은 Next.js 웹으로 이전됨 (/admin/*)

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
          builder: (_) => SellRequestDetailViewScreen(requestId: sellRequestId), // ✅ 수정
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

    // ✅ 새로 추가: MyPage 피처
      case Routes.myPage:
        return MaterialPageRoute(
          builder: (_) => const MyPageScreen(),
          settings: settings,
        );

      case Routes.profileEdit:
        return MaterialPageRoute(
          builder: (_) => const ProfileEditScreen(),
          settings: settings,
        );

      case Routes.purchaseHistory:
        return MaterialPageRoute(
          builder: (_) => const PurchaseHistoryScreen(),
          settings: settings,
        );

      // ✅ 새로 추가: 구매 상세
      case Routes.purchaseDetail:
        final orderId = settings.arguments as String?;
        if (orderId == null) {
          return _errorRoute('주문 ID가 필요합니다.');
        }
        return MaterialPageRoute(
          builder: (_) => PurchaseDetailScreen(orderId: orderId),
          settings: settings,
        );

      case Routes.salesHistory:
        return MaterialPageRoute(
          builder: (_) => const SalesHistoryScreen(),
          settings: settings,
        );

      case Routes.sellRequestHistory:
        return MaterialPageRoute(
          builder: (_) => const SellRequestHistoryScreen(),
          settings: settings,
        );

      case Routes.favorites:
        return MaterialPageRoute(
          builder: (_) => const FavoritesScreen(),
          settings: settings,
        );

      case Routes.priceAlerts:
        return MaterialPageRoute(
          builder: (_) => const PriceAlertsScreen(),
          settings: settings,
        );

      case Routes.partSearch:
        return MaterialPageRoute(
          builder: (_) => const PartSearchScreen(),
          settings: settings,
        );

      case Routes.basePartSearch:
        return MaterialPageRoute(
          builder: (_) => const BasePartSearchScreen(),
          settings: settings,
        );

      case Routes.settings:
        return MaterialPageRoute(
          builder: (_) => const SettingsScreen(),
          settings: settings,
        );

      case Routes.accountDelete:
        return MaterialPageRoute(
          builder: (_) => const AccountDeleteScreen(),
          settings: settings,
        );

      case Routes.consent:
        return MaterialPageRoute(
          builder: (context) => ConsentScreen(
            onConsentComplete: () {
              Navigator.of(context).pushReplacementNamed('/');
            },
          ),
          settings: settings,
        );

      // ✅ 새로 추가: 배송지 관리
      case Routes.addressList:
        return MaterialPageRoute(
          builder: (_) => const AddressListScreen(),
          settings: settings,
        );

      case Routes.addressForm:
        return MaterialPageRoute(
          builder: (_) => const AddressFormScreen(),
          settings: settings,
        );

    // ✅ 새로 추가: PC 보관함 (DragonBall) 피처
      case Routes.dragonBallStorage:
        return MaterialPageRoute(
          builder: (_) => const PcStorageScreen(),
          settings: settings,
        );

      case Routes.batchShipmentRequest:
        final dragonBallIds = settings.arguments as List<String>?;
        if (dragonBallIds == null || dragonBallIds.isEmpty) {
          return _errorRoute('선택한 드래곤볼이 없습니다.');
        }
        return MaterialPageRoute(
          builder: (_) => BatchShipmentRequestScreen(dragonBallIds: dragonBallIds),
          settings: settings,
        );

      case Routes.batchShipmentHistory:
        return MaterialPageRoute(
          builder: (_) => const BatchShipmentHistoryScreen(),
          settings: settings,
        );

    // ✅ 새로 추가: Recommendation 피처
      case Routes.myEstimate:
        return MaterialPageRoute(
          builder: (_) => const MyEstimateScreen(),
          settings: settings,
        );

      case Routes.pcAssembly:
        final specProfile = settings.arguments as SpecProfileModel?;
        return MaterialPageRoute(
          builder: (_) => PcAssemblyScreen(specProfile: specProfile),
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

    // ✅ 새로 추가: 약관 및 정책
      case Routes.terms:
        return MaterialPageRoute(
          builder: (_) => const TermsPage(),
          settings: settings,
        );

      case Routes.privacy:
        return MaterialPageRoute(
          builder: (_) => const PrivacyPage(),
          settings: settings,
        );

      case Routes.refund:
        return MaterialPageRoute(
          builder: (_) => const RefundPage(),
          settings: settings,
        );

      case Routes.storageServiceTerms:
        return MaterialPageRoute(
          builder: (_) => const StorageServiceTermsPage(),
          settings: settings,
        );

    // ✅ 새로 추가: 환불 관련
      case Routes.refundRequest:
        final orderId = settings.arguments as String?;
        if (orderId == null) {
          return _errorRoute('주문 ID가 필요합니다.');
        }
        return MaterialPageRoute(
          builder: (_) => RefundRequestScreen(orderId: orderId),
          settings: settings,
        );

      case Routes.refundReturnShipping:
        final refundId = settings.arguments as String?;
        if (refundId == null) {
          return _errorRoute('환불 ID가 필요합니다.');
        }
        return MaterialPageRoute(
          builder: (_) => RefundReturnShippingScreen(refundId: refundId),
          settings: settings,
        );

      case Routes.refundDetail:
        final refundId = settings.arguments as String?;
        if (refundId == null) {
          return _errorRoute('환불 ID가 필요합니다.');
        }
        return MaterialPageRoute(
          builder: (_) => RefundDetailScreen(refundId: refundId),
          settings: settings,
        );

      case Routes.refundList:
        return MaterialPageRoute(
          builder: (_) => const RefundListScreen(),
          settings: settings,
        );

    // B2B 보증 관리는 Next.js 웹으로 이전됨 (/admin/*)

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
