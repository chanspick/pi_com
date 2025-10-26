// lib/app.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

// ✅ 앱 내부용 Router
import 'core/router/app_router.dart';

// Shared
import 'shared/widgets/auth_gate.dart';

// ✅ 웹 공개 페이지 (GoRouter 사용)
import 'features/web_public/presentation/screens/landing_page.dart';
import 'features/web_public/presentation/screens/about_page.dart';
import 'features/web_public/presentation/screens/terms_page.dart';
import 'features/web_public/presentation/screens/privacy_page.dart';

// ✅ 관리자 페이지 (GoRouter 사용)
import 'features/admin/presentation/screens/admin_login_page.dart';
import 'features/admin/presentation/screens/admin_dashboard.dart';
import 'features/admin/presentation/screens/user_list_page.dart';
import 'features/admin/presentation/screens/listing_list_page.dart';
import 'features/admin/presentation/screens/admin_sell_request_list_page.dart';
import 'features/admin/presentation/screens/db_update_screen.dart'; // 🆕 추가

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ 웹인 경우: GoRouter 사용 (웹 공개 페이지 + Admin)
    if (kIsWeb) {
      return MaterialApp.router(
        title: 'PiCom',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        routerConfig: _webRouter,
        debugShowCheckedModeBanner: false,
      );
    }

    // ✅ 모바일/데스크톱: MaterialApp + Navigator 사용
    return MaterialApp(
      title: 'PiCom',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
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
        builder: (context, state) => const LandingPage(),
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
      // 🆕 DB 업데이트 추가
      GoRoute(
        path: '/admin/db-update',
        builder: (context, state) => const DbUpdateScreen(),
      ),
    ],
  );
}
