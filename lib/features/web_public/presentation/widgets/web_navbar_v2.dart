// lib/features/web_public/presentation/widgets/web_navbar_v2.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/constants/routes.dart';
import '../../../../core/utils/responsive_helper.dart';

/// 간단한 웹 네비게이션 바
class WebNavBarV2 extends ConsumerStatefulWidget implements PreferredSizeWidget {
  const WebNavBarV2({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  ConsumerState<WebNavBarV2> createState() => _WebNavBarV2State();
}

class _WebNavBarV2State extends ConsumerState<WebNavBarV2> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final isMobile = ResponsiveHelper.isMobile(context);
    final isTablet = ResponsiveHelper.isTablet(context);

    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: ResponsiveHelper.centeredMaxWidthContainer(
        context: context,
        child: Padding(
          padding: ResponsiveHelper.getHorizontalPadding(context),
          child: Row(
            children: [
              // Logo
              _buildLogo(context, isMobile, isTablet),
              const SizedBox(width: 24),

              // Search bar
              if (!isMobile || MediaQuery.of(context).size.width > 400)
                Expanded(child: _buildSearchBar(context, isMobile, isTablet)),
              if (!isMobile || MediaQuery.of(context).size.width > 400)
                const SizedBox(width: 24),

              // Navigation Links (desktop only)
              if (!isMobile && !isTablet) ...[
                _buildNavLink(context, '부품 구매', Routes.partShop),
                _buildNavLink(context, '부품 판매', Routes.sellRequest),
                _buildNavLink(context, '부품 시세', Routes.partsCategory),
                _buildNavLink(context, 'AI 견적', Routes.myEstimate),
                const SizedBox(width: 16),
              ],

              // User menu
              _buildUserMenu(context, currentUser, isMobile, isTablet),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(BuildContext context, bool isMobile, bool isTablet) {
    final logoSize = isMobile ? 32.0 : isTablet ? 36.0 : 40.0;
    final fontSize = isMobile ? 20.0 : isTablet ? 24.0 : 28.0;
    final spacing = isMobile ? 8.0 : 12.0;

    return InkWell(
      onTap: () => context.go('/'),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/photos/app_icon.png',
            width: logoSize,
            height: logoSize,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              // Fallback to icon if image fails to load
              return Icon(
                Icons.computer,
                size: logoSize,
                color: Theme.of(context).primaryColor,
              );
            },
          ),
          SizedBox(width: spacing),
          Text(
            'PiCom',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, bool isMobile, bool isTablet) {
    final height = isMobile ? 38.0 : isTablet ? 42.0 : 45.0;
    final fontSize = isMobile ? 13.0 : isTablet ? 14.0 : 15.0;
    final hintText = isMobile ? '부품 검색' : '부품 검색 (예: RTX 4070, i7-13700K)';
    final buttonWidth = isMobile ? 50.0 : 60.0;
    final iconSize = isMobile ? 20.0 : 24.0;

    return Container(
      constraints: const BoxConstraints(maxWidth: 600),
      height: height,
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).primaryColor, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Center(
              child: TextField(
                controller: _searchController,
                style: TextStyle(fontSize: fontSize),
                textAlignVertical: TextAlignVertical.center,
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: TextStyle(fontSize: fontSize, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 12 : 16,
                  ),
                  isDense: true,
                ),
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    // GoRouter가 자동으로 인코딩 처리
                    context.go('${Routes.partShop}?basePartSearch=${value.trim()}');
                  } else {
                    context.go(Routes.partShop);
                  }
                },
              ),
            ),
          ),
          Container(
            width: buttonWidth,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(6),
                bottomRight: Radius.circular(6),
              ),
            ),
            child: IconButton(
              icon: Icon(Icons.search, color: Colors.white, size: iconSize),
              padding: EdgeInsets.zero,
              onPressed: () {
                final query = _searchController.text.trim();
                if (query.isNotEmpty) {
                  // GoRouter가 자동으로 인코딩 처리
                  context.go('${Routes.partShop}?basePartSearch=$query');
                } else {
                  context.go(Routes.partShop);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavLink(BuildContext context, String label, String route) {
    return InkWell(
      onTap: () => context.go(route),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildUserMenu(BuildContext context, dynamic currentUser, bool isMobile, bool isTablet) {
    final spacing = isMobile ? 8.0 : 16.0;
    final buttonPadding = EdgeInsets.symmetric(
      horizontal: isMobile ? 12.0 : 20.0,
      vertical: isMobile ? 8.0 : 12.0,
    );
    final fontSize = isMobile ? 13.0 : 15.0;

    return Row(
      children: [
        // Cart
        _buildIconButton(
          context: context,
          icon: Icons.shopping_cart_outlined,
          label: isMobile ? '' : '장바구니',
          onTap: () => context.go(Routes.cart),
          isMobile: isMobile,
        ),
        SizedBox(width: spacing),

        // Login or User menu
        if (currentUser == null) ...[
          if (!isMobile) ...[
            TextButton(
              onPressed: () => context.go(Routes.auth),
              child: Text('로그인', style: TextStyle(fontSize: fontSize)),
            ),
            SizedBox(width: spacing / 2),
          ],
          ElevatedButton(
            onPressed: () => context.go(Routes.auth),
            style: ElevatedButton.styleFrom(
              padding: buttonPadding,
            ),
            child: Text(
              isMobile ? '로그인' : '회원가입',
              style: TextStyle(fontSize: fontSize),
            ),
          ),
        ] else ...[
          if (!isMobile)
            _buildIconButton(
              context: context,
              icon: Icons.favorite_outline,
              label: '찜',
              onTap: () => context.go(Routes.favorites),
              isMobile: isMobile,
            ),
          if (!isMobile) SizedBox(width: spacing),
          PopupMenuButton<String>(
            child: _buildIconButton(
              context: context,
              icon: Icons.person_outline,
              label: isMobile ? '' : '마이페이지',
              onTap: null,
              isMobile: isMobile,
            ),
            onSelected: (value) async {
              switch (value) {
                case 'mypage':
                  context.go(Routes.myPage);
                  break;
                case 'orders':
                  context.go(Routes.purchaseHistory);
                  break;
                case 'sell':
                  context.go(Routes.sellRequestHistory);
                  break;
                case 'storage':
                  context.go(Routes.pcStorage);
                  break;
                case 'logout':
                  await ref.read(signOutUseCaseProvider).call();
                  if (context.mounted) {
                    context.go('/');
                  }
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'mypage',
                child: Text('마이페이지'),
              ),
              const PopupMenuItem(
                value: 'orders',
                child: Text('구매 내역'),
              ),
              const PopupMenuItem(
                value: 'sell',
                child: Text('판매 내역'),
              ),
              const PopupMenuItem(
                value: 'storage',
                child: Text('PC 보관함'),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Text('로그아웃'),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildIconButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    bool isMobile = false,
  }) {
    final iconSize = isMobile ? 22.0 : 24.0;
    final fontSize = isMobile ? 10.0 : 11.0;
    final padding = EdgeInsets.symmetric(
      horizontal: isMobile ? 4.0 : 8.0,
      vertical: isMobile ? 6.0 : 8.0,
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: iconSize, color: Colors.black87),
            if (label.isNotEmpty) ...[
              SizedBox(height: isMobile ? 2 : 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: fontSize,
                  color: Colors.black87,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
