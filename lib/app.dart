// lib/app.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ✅ 앱 내부용 Router
import 'core/router/app_router.dart';
import 'core/providers/theme_provider.dart';

// Shared
import 'shared/widgets/auth_gate.dart';

// ✅ 웹 공개 페이지 (GoRouter 사용)
import 'features/web_public/presentation/screens/landing_page_v2.dart';
import 'features/web_public/presentation/screens/about_page.dart';
import 'features/web_public/presentation/screens/terms_page.dart';
import 'features/web_public/presentation/screens/privacy_page.dart';
import 'features/web_public/presentation/screens/refund_page.dart';

// ✅ 웹 거래 기능 페이지
import 'features/listing/presentation/screens/part_shop_screen.dart';
import 'features/listing/presentation/screens/listing_detail_screen.dart';
import 'features/cart/presentation/screens/cart_screen.dart';
import 'features/checkout/presentation/screens/checkout_screen.dart';
import 'features/parts_price/presentation/screens/part_category_screen.dart'; // PartsCategoryScreen
import 'features/parts_price/presentation/screens/price_history_screen.dart';
import 'features/parts_price/domain/entities/base_part_entity.dart';
import 'features/recommendation/presentation/screens/my_estimate_screen.dart';
import 'features/my_page/presentation/screens/my_page_screen.dart';
import 'features/my_page/presentation/screens/favorites_screen.dart';
import 'features/my_page/presentation/screens/purchase_history_screen.dart';
import 'features/my_page/presentation/screens/profile_edit_screen.dart';
import 'features/my_page/presentation/screens/sell_request_history_screen.dart';
import 'features/my_page/presentation/screens/sales_history_screen.dart';
import 'features/my_page/presentation/screens/settings_screen.dart';
import 'features/sell_request/presentation/screens/sell_request_screen.dart';
import 'features/sell_request/presentation/screens/finished_pc_sell_screen.dart';
import 'features/dragon_ball/presentation/screens/pc_storage_screen.dart';
import 'features/dragon_ball/presentation/screens/batch_shipment_request_screen.dart';
import 'features/dragon_ball/presentation/screens/batch_shipment_history_screen.dart';
import 'features/address/presentation/screens/address_list_screen.dart';
import 'features/price_alert/presentation/screens/price_alerts_screen.dart';
import 'features/auth/presentation/screens/auth_screen.dart';
import 'features/notification/presentations/screens/notification_list_screen.dart';

// ✅ 관리자 페이지 (GoRouter 사용)
import 'features/admin/presentation/screens/admin_login_page.dart';
import 'features/admin/presentation/screens/admin_dashboard.dart';
import 'features/admin/presentation/screens/user_list_page.dart';
import 'features/admin/presentation/screens/listing_list_page.dart';
import 'features/admin/presentation/screens/admin_sell_request_list_page.dart';
import 'features/admin/presentation/screens/user_list_page_improved.dart';
import 'features/admin/presentation/screens/listing_list_page_improved.dart';
import 'features/admin/presentation/screens/statistics_dashboard_page.dart';
import 'features/admin/presentation/screens/shipping_management_page.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    // ✅ 웹인 경우: GoRouter 사용 (웹 공개 페이지 + Admin)
    if (kIsWeb) {
      return MaterialApp.router(
        title: 'PiCom',
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: themeMode,
        routerConfig: _webRouter,
        debugShowCheckedModeBanner: false,
      );
    }

    // ✅ 모바일/데스크톱: MaterialApp + Navigator 사용
    return MaterialApp(
      title: 'PiCom',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      home: const AuthGate(), // 인증 게이트
      onGenerateRoute: AppRouter.generateRoute, // ✅ Navigator 라우트 생성
      debugShowCheckedModeBanner: false,
    );
  }

  /// ✅ 웹용 GoRouter
  static final GoRouter _webRouter = GoRouter(
    initialLocation: '/',
    routes: [
      // === 웹 공개 페이지 ===
      GoRoute(
        path: '/',
        builder: (context, state) => const LandingPageV2(),
      ),
      GoRoute(
        path: '/about',
        builder: (context, state) => const AboutPage(),
      ),
      GoRoute(
        path: '/terms',
        builder: (context, state) => const TermsPage(),
      ),
      GoRoute(
        path: '/privacy',
        builder: (context, state) => const PrivacyPage(),
      ),
      GoRoute(
        path: '/refund',
        builder: (context, state) => const RefundPage(),
      ),

      // === 거래 기능 페이지 ===
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/part-shop',
        builder: (context, state) {
          // ✅ URL 파라미터에서 category와 basePartSearch 추출
          final category = state.uri.queryParameters['category'];
          final basePartSearch = state.uri.queryParameters['basePartSearch'];

          return PartShopScreen(
            initialCategory: category,
            initialBasePartSearch: basePartSearch,  // ✅ 검색어 전달 추가
          );
        },
      ),
      GoRoute(
        path: '/listing-detail/:id',
        builder: (context, state) {
          final listingId = state.pathParameters['id']!;
          return ListingDetailScreen(listingId: listingId);
        },
      ),
      GoRoute(
        path: '/cart',
        builder: (context, state) => const CartScreen(),
      ),
      GoRoute(
        path: '/checkout',
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(
        path: '/parts-category',
        builder: (context, state) => const PartsCategoryScreen(),
      ),
      GoRoute(
        path: '/price-history/:basePartId',
        builder: (context, state) {
          final basePart = state.extra as BasePartEntity?;
          if (basePart == null) {
            return const Scaffold(
              body: Center(child: Text('부품 정보를 찾을 수 없습니다')),
            );
          }
          return PriceHistoryScreen(basePart: basePart);
        },
      ),
      GoRoute(
        path: '/my-estimate',
        builder: (context, state) => const MyEstimateScreen(),
      ),
      GoRoute(
        path: '/pc-assembly',
        builder: (context, state) {
          // SpecProfileEntity를 받아서 SpecProfileModel로 변환할 수 있다면 변환
          // 또는 PcAssemblyScreen이 SpecProfileEntity를 받도록 수정 필요
          // 지금은 일단 에러 처리만
          return const Scaffold(
            body: Center(child: Text('견적 정보를 찾을 수 없습니다\n(SpecProfile 타입 불일치)')),
          );
        },
      ),
      GoRoute(
        path: '/my-page',
        builder: (context, state) => const MyPageScreen(),
      ),
      GoRoute(
        path: '/favorites',
        builder: (context, state) => const FavoritesScreen(),
      ),
      GoRoute(
        path: '/purchase-history',
        builder: (context, state) => const PurchaseHistoryScreen(),
      ),
      GoRoute(
        path: '/sell-request',
        builder: (context, state) => const SellRequestScreen(),
      ),
      GoRoute(
        path: '/pc-storage',
        builder: (context, state) => const PcStorageScreen(),
      ),
      GoRoute(
        path: '/batch-shipment-request',
        builder: (context, state) {
          final dragonBallIds = state.extra as List<String>? ?? [];
          return BatchShipmentRequestScreen(dragonBallIds: dragonBallIds);
        },
      ),
      GoRoute(
        path: '/sell-finished-pc',
        builder: (context, state) => const FinishedPcSellScreen(),
      ),
      GoRoute(
        path: '/sell-request-history',
        builder: (context, state) => const SellRequestHistoryScreen(),
      ),
      GoRoute(
        path: '/profile-edit',
        builder: (context, state) => const ProfileEditScreen(),
      ),
      GoRoute(
        path: '/price-alerts',
        builder: (context, state) => const PriceAlertsScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/address-list',
        builder: (context, state) => const AddressListScreen(),
      ),
      GoRoute(
        path: '/sales-history',
        builder: (context, state) => const SalesHistoryScreen(),
      ),
      GoRoute(
        path: '/batch-shipment-history',
        builder: (context, state) => const BatchShipmentHistoryScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationListScreen(),
      ),

      // === Admin 페이지 ===
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminLoginPage(),
      ),
      GoRoute(
        path: '/admin/dashboard',
        builder: (context, state) => const AdminDashboard(),
      ),
      GoRoute(
        path: '/admin/users',
        builder: (context, state) => const UserListPage(),
      ),
      GoRoute(
        path: '/admin/listings',
        builder: (context, state) => const ListingListPage(),
      ),
      GoRoute(
        path: '/admin/sell-requests',
        builder: (context, state) => const AdminSellRequestListPage(),
      ),
      GoRoute(
        path: '/admin/users-improved',
        builder: (context, state) => const UserListPageImproved(),
      ),
      GoRoute(
        path: '/admin/listings-improved',
        builder: (context, state) => const ListingListPageImproved(),
      ),
      GoRoute(
        path: '/admin/statistics',
        builder: (context, state) => const StatisticsDashboardPage(),
      ),
      GoRoute(
        path: '/admin/shipping',
        builder: (context, state) => const ShippingManagementPage(),
      ),
    ],
  );
}