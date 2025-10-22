// lib/features/home/presentation/widgets/home_app_bar_actions.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';  // ✅ Riverpod import
import '../../../auth/presentation/providers/auth_provider.dart';  // ✅ Provider import
import '../../../notification/presentations/widgets/notification_badge_icon.dart';

class HomeAppBarActions extends ConsumerWidget {  // ✅ ConsumerWidget으로 변경
  const HomeAppBarActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {  // ✅ WidgetRef 추가
    // ✅ Provider에서 현재 사용자 정보 가져오기
    final user = ref.watch(currentUserProvider);


    return Row(
      children: [
        const NotificationBadgeIcon(),

        // 장바구니 아이콘
        IconButton(
          icon: const Icon(Icons.shopping_bag_outlined),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('장바구니 기능은 준비 중입니다.')),
            );
          },
        ),

        // 프로필 메뉴
        PopupMenuButton<String>(
          onSelected: (value) async {
            // ✅ Use Case Provider 사용
            if (value == 'profile') {
              if (user != null && !user.isAnonymous) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('프로필 기능은 준비 중입니다.')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('로그인 후 프로필을 볼 수 있습니다.')),
                );
              }
            } else if (value == 'settings') {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('설정 기능은 준비 중입니다.')),
              );
            } else if (value == 'logout' || value == 'login') {
              // ✅ Use Case로 로그아웃
              final signOutUseCase = ref.read(signOutUseCaseProvider);
              await signOutUseCase();
            }
          },
          itemBuilder: (BuildContext context) {
            final isAnonymous = user?.isAnonymous ?? true;

            return <PopupMenuEntry<String>>[
              const PopupMenuItem(
                value: 'profile',
                child: ListTile(
                  leading: Icon(Icons.person_outline),
                  title: Text('프로필'),
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings_outlined),
                  title: Text('설정'),
                ),
              ),
              const PopupMenuDivider(),
              if (isAnonymous)
                const PopupMenuItem(
                  value: 'login',
                  child: ListTile(
                    leading: Icon(Icons.login, color: Colors.blue),
                    title: Text('로그인', style: TextStyle(color: Colors.blue)),
                  ),
                )
              else
                const PopupMenuItem(
                  value: 'logout',
                  child: ListTile(
                    leading: Icon(Icons.logout, color: Colors.red),
                    title: Text('로그아웃', style: TextStyle(color: Colors.red)),
                  ),
                ),
            ];
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: CircleAvatar(
              radius: 16,
              backgroundImage: user?.photoURL != null
                  ? NetworkImage(user!.photoURL!)
                  : null,
              child: user?.photoURL == null
                  ? const Icon(Icons.person, size: 20)
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}
