// lib/core/router/app_router.dart

import 'package:flutter/material.dart';
import '../constants/routes.dart';
import '../../features/notification/presentations/screens/notification_list_screen.dart';
// 차후 추가 import
// import '../../features/sell_request/presentation/screens/...';

/// 앱 내부용 Navigator Route Generator
class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
    // Notification
      case Routes.notifications:
        return MaterialPageRoute(
          builder: (_) => const NotificationListScreen(),
          settings: settings,
        );

    // Sell Request Details (차후 구현)
      case Routes.sellRequestDetails:
        final sellRequestId = settings.arguments as String?;
        if (sellRequestId == null) {
          return _errorRoute('판매 요청 ID가 필요합니다.');
        }
        // TODO: SellRequestDetailsScreen 구현 후 추가
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('판매 요청 상세')),
            body: Center(child: Text('SellRequest ID: $sellRequestId\n(구현 예정)')),
          ),
          settings: settings,
        );

    // Sell Request (차후 구현)
      case Routes.sellRequest:
      // TODO: SellRequestScreen 구현 후 추가
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('판매하기')),
            body: const Center(child: Text('판매하기 화면 (구현 예정)')),
          ),
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
  static Route<dynamic> _errorRoute(String message) {
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
