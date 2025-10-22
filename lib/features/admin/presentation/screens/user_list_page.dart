// lib/features/admin/presentation/screens/user_list_page.dart
import 'package:flutter/material.dart';

class UserListPage extends StatelessWidget {
  const UserListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('사용자 관리')),
      body: const Center(child: Text('사용자 목록 (개발 예정)')),
    );
  }
}
