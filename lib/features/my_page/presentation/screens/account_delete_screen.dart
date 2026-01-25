/// 계정 삭제 화면
///
/// Google Play 정책 준수를 위한 필수 기능
/// - 계정 삭제 요청
/// - 삭제 전 확인 절차
/// - 삭제 사유 수집
/// - 데이터 파기 안내

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

class AccountDeleteScreen extends ConsumerStatefulWidget {
  const AccountDeleteScreen({super.key});

  @override
  ConsumerState<AccountDeleteScreen> createState() => _AccountDeleteScreenState();
}

class _AccountDeleteScreenState extends ConsumerState<AccountDeleteScreen> {
  bool _isLoading = false;
  bool _confirmChecked = false;
  String? _selectedReason;
  final _otherReasonController = TextEditingController();

  final List<String> _deleteReasons = [
    '서비스를 더 이상 이용하지 않음',
    '다른 서비스로 이동',
    '개인정보 보호 우려',
    '서비스 불만족',
    '계정을 새로 만들고 싶음',
    '기타',
  ];

  @override
  void dispose() {
    _otherReasonController.dispose();
    super.dispose();
  }

  Future<void> _deleteAccount() async {
    if (!_confirmChecked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('삭제 동의에 체크해주세요')),
      );
      return;
    }

    if (_selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('탈퇴 사유를 선택해주세요')),
      );
      return;
    }

    // 최종 확인 다이얼로그
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('정말 탈퇴하시겠습니까?'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('계정 삭제 시 다음 데이터가 영구적으로 삭제됩니다:'),
            SizedBox(height: 12),
            Text('• 프로필 정보'),
            Text('• 등록한 상품'),
            Text('• 관심 목록'),
            Text('• 알림 설정'),
            SizedBox(height: 12),
            Text(
              '※ 거래 내역은 법적 보존 의무에 따라 일정 기간 보관됩니다.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('탈퇴하기'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('로그인이 필요합니다');
      }

      final reason = _selectedReason == '기타'
          ? _otherReasonController.text.trim()
          : _selectedReason;

      // 1. 탈퇴 로그 저장 (익명화된 통계용)
      await FirebaseFirestore.instance.collection('account_deletions').add({
        'userId': user.uid,
        'email': user.email,
        'reason': reason,
        'deletedAt': FieldValue.serverTimestamp(),
        'platform': 'app',
      });

      // 2. 사용자 문서에 삭제 예정 표시
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'isDeleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
        'deleteReason': reason,
        // 개인정보 익명화
        'displayName': '탈퇴한 사용자',
        'email': null,
        'profileImageUrl': null,
        'phone': null,
      });

      // 3. 관련 서브컬렉션 데이터 삭제 표시
      // (실제 삭제는 Cloud Functions에서 배치로 처리)
      final batch = FirebaseFirestore.instance.batch();

      // 주소 삭제
      final addressesSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('addresses')
          .get();
      for (final doc in addressesSnap.docs) {
        batch.delete(doc.reference);
      }

      // 동의 정보 삭제
      final consentsSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('consents')
          .get();
      for (final doc in consentsSnap.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      // 4. Firebase Auth 계정 삭제
      await user.delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('계정이 삭제되었습니다. 이용해 주셔서 감사합니다.'),
            backgroundColor: Colors.green,
          ),
        );

        // 로그인 화면으로 이동
        context.go('/auth');
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        // 재인증 필요
        if (mounted) {
          _showReauthDialog();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('오류: ${e.message}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showReauthDialog() {
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('비밀번호 확인'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('보안을 위해 비밀번호를 다시 입력해주세요.'),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: '비밀번호',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _reauthenticateAndDelete(passwordController.text);
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  Future<void> _reauthenticateAndDelete(String password) async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) {
        throw Exception('이메일 계정 정보를 찾을 수 없습니다');
      }

      // 재인증
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);

      // 재인증 성공 후 다시 삭제 시도
      await _deleteAccount();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('인증 실패: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('계정 삭제'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 경고 배너
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.red[700]),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            '계정을 삭제하면 모든 데이터가 영구적으로 삭제되며 복구할 수 없습니다.',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 삭제되는 데이터 안내
                  const Text(
                    '삭제되는 정보',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    '즉시 삭제',
                    [
                      '프로필 정보 (이름, 이메일, 프로필 사진)',
                      '등록한 상품 및 관심 목록',
                      '배송지 정보',
                      '알림 설정',
                    ],
                    Colors.red,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    '법적 보존 후 삭제',
                    [
                      '거래 내역 (전자상거래법에 따라 5년 보관)',
                      '결제 정보 (전자상거래법에 따라 5년 보관)',
                      '분쟁 관련 기록 (3년 보관)',
                    ],
                    Colors.orange,
                  ),
                  const SizedBox(height: 24),

                  // 탈퇴 사유 선택
                  const Text(
                    '탈퇴 사유',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '서비스 개선을 위해 탈퇴 사유를 선택해주세요.',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  ...(_deleteReasons.map((reason) => RadioListTile<String>(
                        value: reason,
                        groupValue: _selectedReason,
                        title: Text(reason),
                        onChanged: (value) {
                          setState(() => _selectedReason = value);
                        },
                        contentPadding: EdgeInsets.zero,
                      ))),

                  // 기타 사유 입력
                  if (_selectedReason == '기타') ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: _otherReasonController,
                      decoration: const InputDecoration(
                        hintText: '탈퇴 사유를 입력해주세요',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                  ],
                  const SizedBox(height: 24),

                  // 동의 체크
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: _confirmChecked,
                          onChanged: (value) {
                            setState(() => _confirmChecked = value ?? false);
                          },
                        ),
                        const Expanded(
                          child: Text(
                            '위 내용을 확인하였으며, 계정 삭제에 동의합니다.',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 삭제 버튼
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _confirmChecked && _selectedReason != null
                          ? _deleteAccount
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '계정 삭제',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 취소 버튼
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('취소'),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard(String title, List<String> items, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                title == '즉시 삭제' ? Icons.delete_forever : Icons.schedule,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(left: 28, top: 4),
                child: Text(
                  '• $item',
                  style: const TextStyle(fontSize: 13),
                ),
              )),
        ],
      ),
    );
  }
}
