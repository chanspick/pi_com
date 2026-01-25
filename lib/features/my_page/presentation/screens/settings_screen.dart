// lib/features/my_page/presentation/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/theme_provider.dart';

/// 설정 화면
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
      ),
      body: ListView(
        children: [
          // 알림 설정 섹션
          _buildSectionHeader(context, '알림'),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('푸시 알림'),
            subtitle: const Text('중요한 소식을 받아보세요'),
            trailing: Switch(
              value: false,
              onChanged: (value) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('알림 기능은 준비 중입니다')),
                );
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.price_change_outlined),
            title: const Text('가격 알림'),
            subtitle: const Text('관심 부품 가격 변동 알림'),
            trailing: Switch(
              value: false,
              onChanged: (value) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('가격 알림 기능은 준비 중입니다')),
                );
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.chat_outlined),
            title: const Text('커뮤니케이션 알림'),
            subtitle: const Text('채팅 메시지 수신 알림'),
            trailing: Switch(
              value: false,
              onChanged: (value) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('커뮤니케이션 알림 기능은 준비 중입니다')),
                );
              },
            ),
          ),
          const Divider(),

          // 앱 정보 및 버전 섹션
          _buildSectionHeader(context, '앱 정보'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('앱 버전'),
            subtitle: const Text('1.0.0'),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('이용약관'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              context.push('/terms');
            },
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('개인정보 처리방침'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              context.push('/privacy');
            },
          ),
          const Divider(),

          // 계정 관리 섹션
          _buildSectionHeader(context, '계정 관리'),
          ListTile(
            leading: const Icon(Icons.person_remove_outlined, color: Colors.red),
            title: const Text('계정 삭제', style: TextStyle(color: Colors.red)),
            subtitle: const Text('계정 및 모든 데이터를 삭제합니다'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.red),
            onTap: () {
              context.push('/settings/account-delete');
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
