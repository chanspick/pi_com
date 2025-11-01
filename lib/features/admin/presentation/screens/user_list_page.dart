// lib/features/admin/presentation/screens/user_list_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pi_com/core/models/user_model.dart';
import 'package:pi_com/features/auth/presentation/providers/auth_provider.dart';

class UserListPage extends ConsumerWidget {
  const UserListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(usersStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('사용자 관리')),
      body: Column(
        children: [
          // TODO: Add search UI
          Expanded(
            child: usersAsync.when(
              data: (users) {
                if (users.isEmpty) {
                  return const Center(child: Text('사용자가 없습니다.'));
                }
                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return ListTile(
                      title: Text(user.displayName),
                      subtitle: Text(user.email),
                      trailing: user.isAdmin ? const Icon(Icons.admin_panel_settings) : null,
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('에러 발생: $err')),
            ),
          ),
        ],
      ),
    );
  }
}
