//lib/features/home/presentation/screens/home_screen.dart


import 'package:flutter/material.dart';
import '../widgets/home_app_bar_actions.dart';
import '../widgets/home_search_bar.dart';
import '../widgets/home_banner.dart';
import '../widgets/circle_menu_section.dart';
import '../widgets/product_list_section.dart';
import '../../../../shared/widgets/app_footer.dart';

/// 홈 화면 - PiCom 메인 페이지
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const HomeSearchBar(),
        actions: const [HomeAppBarActions()],
      ),
      body: const _HomeContent(),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const HomeBanner(),
          const SizedBox(height: 24),
          const CircleMenuSection(),
          const SizedBox(height: 24),
          const ProductListSection(),
          const SizedBox(height: 32),
          // ⭐️ 웹 배포용 법정 필수 정보 Footer
          const AppFooter(),
        ],
      ),
    );
  }
}
