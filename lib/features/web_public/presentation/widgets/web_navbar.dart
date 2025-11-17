// lib/features/web_public/presentation/widgets/web_navbar.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/constants/routes.dart';
import '../../../../core/utils/responsive_helper.dart';

/// Web Navigation Bar
class WebNavBar extends ConsumerWidget implements PreferredSizeWidget {
  const WebNavBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final isDesktop = ResponsiveHelper.isDesktop(context);

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      toolbarHeight: 70,
      title: _buildLogo(context),
      centerTitle: false,
      actions: [
        if (isDesktop) ..._buildDesktopActions(context, currentUser),
        if (!isDesktop) _buildMobileMenu(context, currentUser),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildLogo(BuildContext context) {
    return InkWell(
      onTap: () => context.go('/'),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.computer,
            size: 32,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 12),
          const Text(
            'PiCom',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDesktopActions(BuildContext context, dynamic currentUser) {
    return [
      _buildNavButton(context, 'Shop', Routes.partShop),
      _buildNavButton(context, 'Price', Routes.partsCategory),
      _buildNavButton(context, 'Estimate', Routes.myEstimate),
      const SizedBox(width: 24),

      // Cart icon
      IconButton(
        icon: const Icon(Icons.shopping_cart_outlined),
        onPressed: () => context.go(Routes.cart),
        tooltip: 'Cart',
      ),

      const SizedBox(width: 8),

      // Login/Register or User menu
      if (currentUser == null) ...[
        OutlinedButton(
          onPressed: () => context.go(Routes.auth),
          child: const Text('Login'),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () => context.go(Routes.auth),
          child: const Text('Sign Up'),
        ),
      ] else ...[
        PopupMenuButton<String>(
          icon: const CircleAvatar(
            child: Icon(Icons.person),
          ),
          tooltip: 'My Account',
          onSelected: (value) {
            switch (value) {
              case 'mypage':
                context.go(Routes.myPage);
                break;
              case 'favorites':
                context.go(Routes.favorites);
                break;
              case 'purchase':
                context.go(Routes.purchaseHistory);
                break;
              case 'sell':
                context.go(Routes.sellRequest);
                break;
              case 'logout':
                // TODO: logout
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'mypage',
              child: Text('My Page'),
            ),
            const PopupMenuItem(
              value: 'favorites',
              child: Text('Favorites'),
            ),
            const PopupMenuItem(
              value: 'purchase',
              child: Text('Orders'),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'sell',
              child: Text('Sell Item'),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'logout',
              child: Text('Logout'),
            ),
          ],
        ),
      ],
    ];
  }

  Widget _buildMobileMenu(BuildContext context, dynamic currentUser) {
    return IconButton(
      icon: const Icon(Icons.menu),
      onPressed: () {
        showModalBottomSheet(
          context: context,
          builder: (context) => _MobileMenuSheet(currentUser: currentUser),
        );
      },
    );
  }

  Widget _buildNavButton(BuildContext context, String label, String route) {
    return TextButton(
      onPressed: () => context.go(route),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _MobileMenuSheet extends ConsumerWidget {
  final dynamic currentUser;

  const _MobileMenuSheet({required this.currentUser});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildMenuItem(context, Icons.store, 'Shop', Routes.partShop),
          _buildMenuItem(context, Icons.trending_up, 'Price', Routes.partsCategory),
          _buildMenuItem(context, Icons.build, 'Estimate', Routes.myEstimate),
          _buildMenuItem(context, Icons.shopping_cart, 'Cart', Routes.cart),
          const Divider(),
          if (currentUser == null) ...[
            _buildMenuItem(context, Icons.login, 'Login', Routes.auth),
          ] else ...[
            _buildMenuItem(context, Icons.person, 'My Page', Routes.myPage),
            _buildMenuItem(context, Icons.favorite, 'Favorites', Routes.favorites),
            _buildMenuItem(context, Icons.receipt_long, 'Orders', Routes.purchaseHistory),
            _buildMenuItem(context, Icons.sell, 'Sell', Routes.sellRequest),
            const Divider(),
            _buildMenuItem(context, Icons.logout, 'Logout', null, onTap: () {
              // TODO: logout
              Navigator.pop(context);
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    IconData icon,
    String label,
    String? route, {
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: () {
        Navigator.pop(context);
        if (onTap != null) {
          onTap();
        } else if (route != null) {
          context.go(route);
        }
      },
    );
  }
}
