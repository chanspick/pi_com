// 개선된 사용자 관리 화면
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pi_com/features/auth/presentation/providers/auth_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserListPageImproved extends ConsumerStatefulWidget {
  const UserListPageImproved({super.key});

  @override
  ConsumerState<UserListPageImproved> createState() => _UserListPageImprovedState();
}

class _UserListPageImprovedState extends ConsumerState<UserListPageImproved> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterRole = 'all'; // all, admin, user

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(usersStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('사용자 관리'),
      ),
      body: Column(
        children: [
          // 검색 및 필터
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '이름, 이메일로 검색...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                ),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'all', label: Text('전체')),
                    ButtonSegment(value: 'admin', label: Text('관리자')),
                    ButtonSegment(value: 'user', label: Text('일반 사용자')),
                  ],
                  selected: {_filterRole},
                  onSelectionChanged: (Set<String> selected) {
                    setState(() => _filterRole = selected.first);
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: usersAsync.when(
              data: (users) {
                // 필터 적용
                var filteredUsers = users.where((user) {
                  // 검색 필터
                  if (_searchQuery.isNotEmpty) {
                    final name = user.displayName.toLowerCase();
                    final email = user.email.toLowerCase();
                    if (!name.contains(_searchQuery) && !email.contains(_searchQuery)) {
                      return false;
                    }
                  }
                  // 역할 필터
                  if (_filterRole == 'admin' && !user.isAdmin) return false;
                  if (_filterRole == 'user' && user.isAdmin) return false;
                  return true;
                }).toList();

                if (filteredUsers.isEmpty) {
                  return const Center(child: Text('사용자가 없습니다'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: user.isAdmin ? Colors.red : Colors.blue,
                          child: Text(
                            user.displayName.isNotEmpty
                                ? user.displayName[0].toUpperCase()
                                : user.email[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          user.displayName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.email),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                if (user.isAdmin)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.red[100],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      '관리자',
                                      style: TextStyle(fontSize: 11, color: Colors.red),
                                    ),
                                  ),
                                const SizedBox(width: 8),
                                Text(
                                  'UID: ${user.uid.substring(0, 8)}...',
                                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) => _handleUserAction(value, user.uid, user.isAdmin),
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: user.isAdmin ? 'revoke_admin' : 'grant_admin',
                              child: Row(
                                children: [
                                  Icon(
                                    user.isAdmin ? Icons.remove_moderator : Icons.admin_panel_settings,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(user.isAdmin ? '관리자 권한 해제' : '관리자 권한 부여'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'view_orders',
                              child: Row(
                                children: [
                                  Icon(Icons.shopping_bag, size: 18),
                                  SizedBox(width: 8),
                                  Text('주문 내역 보기'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'view_listings',
                              child: Row(
                                children: [
                                  Icon(Icons.sell, size: 18),
                                  SizedBox(width: 8),
                                  Text('판매 매물 보기'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('오류: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleUserAction(String action, String userId, bool currentAdminStatus) async {
    switch (action) {
      case 'grant_admin':
      case 'revoke_admin':
        await _toggleAdminStatus(userId, !currentAdminStatus);
        break;
      case 'view_orders':
        _showUserOrders(userId);
        break;
      case 'view_listings':
        _showUserListings(userId);
        break;
    }
  }

  Future<void> _toggleAdminStatus(String userId, bool newAdminStatus) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'isAdmin': newAdminStatus,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newAdminStatus ? '관리자 권한이 부여되었습니다' : '관리자 권한이 해제되었습니다'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류: $e')),
        );
      }
    }
  }

  void _showUserOrders(String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('사용자 주문 내역'),
        content: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('orders')
              .where('buyerId', isEqualTo: userId)
              .orderBy('createdAt', descending: true)
              .limit(10)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const CircularProgressIndicator();
            }
            final orders = snapshot.data!.docs;
            if (orders.isEmpty) {
              return const Text('주문 내역이 없습니다');
            }
            return SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index].data() as Map<String, dynamic>;
                  return ListTile(
                    title: Text('주문 ID: ${orders[index].id.substring(0, 8)}...'),
                    subtitle: Text('총액: ₩${order['totalPrice']}'),
                  );
                },
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  void _showUserListings(String userId) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('사용자 매물 보기 기능은 개발 중입니다')),
    );
  }
}
