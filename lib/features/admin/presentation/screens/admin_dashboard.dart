// lib/features/admin/presentation/screens/admin_dashboard.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/repositories/admin_auth_repository.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final _authRepo = AdminAuthRepository();
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkAdminAccess();
  }

  Future<void> _checkAdminAccess() async {
    final (userModel, error) = await _authRepo.checkCurrentUserIsAdmin();
    if (!mounted) return;

    if (error.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      context.go('/admin');
      return;
    }

    setState(() => _isChecking = false);
  }

  Future<void> _handleLogout() async {
    await _authRepo.signOut();
    if (mounted) context.go('/admin');
  }

  /// 광고 알림 전송 (전체 사용자)
  Future<void> _sendMarketingNotification() async {
    final titleController = TextEditingController();
    final messageController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('광고 알림 전송'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: '제목',
                  hintText: '예: 신규 매물 입고!',
                  border: OutlineInputBorder(),
                ),
                maxLength: 50,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: messageController,
                decoration: const InputDecoration(
                  labelText: '내용',
                  hintText: '알림 내용을 입력하세요',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                maxLength: 200,
              ),
              const SizedBox(height: 16),
              const Text(
                '⚠️ 전체 사용자에게 알림이 전송됩니다.',
                style: TextStyle(color: Colors.orange, fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              titleController.dispose();
              messageController.dispose();
              Navigator.pop(context, false);
            },
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.trim().isEmpty ||
                  messageController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('제목과 내용을 모두 입력하세요')),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            child: const Text('전송'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // 로딩 표시
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text('알림을 전송하는 중...'),
              ],
            ),
          ),
        );

        // 모든 사용자 조회
        final usersSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .get();

        int sentCount = 0;

        // 각 사용자에게 알림 전송
        for (final userDoc in usersSnapshot.docs) {
          final notificationId = FirebaseFirestore.instance
              .collection('notifications')
              .doc()
              .id;

          await FirebaseFirestore.instance
              .collection('notifications')
              .doc(notificationId)
              .set({
            'userId': userDoc.id,
            'type': 'marketing',
            'title': titleController.text.trim(),
            'message': messageController.text.trim(),
            'isRead': false,
            'createdAt': FieldValue.serverTimestamp(),
          });

          sentCount++;
        }

        // 다이얼로그 닫기
        if (mounted) Navigator.pop(context);

        // 성공 메시지
        if (mounted) {
          titleController.dispose();
          messageController.dispose();

          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('전송 완료'),
              content: Text('$sentCount명의 사용자에게 알림을 전송했습니다.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('확인'),
                ),
              ],
            ),
          );
        }
      } catch (e) {
        // 다이얼로그 닫기
        if (mounted) Navigator.pop(context);

        // 에러 메시지
        if (mounted) {
          titleController.dispose();
          messageController.dispose();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('전송 실패: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      titleController.dispose();
      messageController.dispose();
    }
  }

  /// searchKeywords 일괄 추가 Cloud Function 호출
  Future<void> _addSearchKeywordsToParts() async {
    try {
      // 로딩 다이얼로그 표시
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('부품 검색 키워드를 추가하는 중...'),
            ],
          ),
        ),
      );

      final functions = FirebaseFunctions.instanceFor(region: 'asia-northeast3');
      final callable = functions.httpsCallable('addSearchKeywordsToParts');

      int totalUpdated = 0;
      String? lastPartId;
      bool hasMore = true;

      // 배치 처리 (500개씩)
      while (hasMore) {
        final result = await callable.call({
          'batchSize': 500,
          'startAfter': lastPartId,
        });

        final data = result.data as Map<String, dynamic>;
        final updatedCount = data['updatedCount'] as int;
        hasMore = data['hasMore'] as bool;
        lastPartId = data['lastPartId'] as String?;

        totalUpdated += updatedCount;

        print('✅ 배치 완료: $updatedCount개 업데이트, 총 $totalUpdated개');
      }

      // 다이얼로그 닫기
      if (mounted) Navigator.pop(context);

      // 성공 메시지
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('완료'),
            content: Text('총 $totalUpdated개 부품에 검색 키워드를 추가했습니다.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('확인'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // 다이얼로그 닫기
      if (mounted) Navigator.pop(context);

      // 에러 메시지
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류 발생: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('관리자 대시보드'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '관리자 대시보드',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),

            // 관리 메뉴 그리드
            Expanded(
              child: GridView.count(
                crossAxisCount: kIsWeb ? 4 : 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _AdminMenuCard(
                    title: '판매 요청 관리',
                    icon: Icons.pending_actions,
                    color: Colors.orange,
                    onTap: () => context.go('/admin/sell-requests'),
                  ),
                  _AdminMenuCard(
                    title: '사용자 관리',
                    icon: Icons.people,
                    color: Colors.blue,
                    onTap: () => context.go('/admin/users'),
                  ),
                  _AdminMenuCard(
                    title: '매물 관리',
                    icon: Icons.inventory,
                    color: Colors.green,
                    onTap: () => context.go('/admin/listings'),
                  ),
                  _AdminMenuCard(
                    title: '통계',
                    icon: Icons.analytics,
                    color: Colors.purple,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('개발 예정')),
                      );
                    },
                  ),
                  _AdminMenuCard(
                    title: '검색 키워드 추가',
                    icon: Icons.search,
                    color: Colors.teal,
                    onTap: () async {
                      // 확인 다이얼로그
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('검색 키워드 추가'),
                          content: const Text(
                            '모든 부품(약 1500개)에 검색 키워드를 추가합니다.\n'
                            '시간이 다소 걸릴 수 있습니다.\n\n'
                            '계속하시겠습니까?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('취소'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('확인'),
                            ),
                          ],
                        ),
                      );

                      if (confirmed == true) {
                        _addSearchKeywordsToParts();
                      }
                    },
                  ),
                  _AdminMenuCard(
                    title: '광고 알림 전송',
                    icon: Icons.campaign,
                    color: Colors.deepOrange,
                    onTap: _sendMarketingNotification,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================
// 보조 위젯: 관리 메뉴 카드
// ============================================

class _AdminMenuCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _AdminMenuCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
