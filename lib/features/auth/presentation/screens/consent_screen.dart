/// 약관 동의 화면
///
/// Google Play 데이터 안전 정책 준수를 위한 필수 동의 화면
/// - 서비스 이용약관 동의 (필수)
/// - 개인정보 처리방침 동의 (필수)
/// - 개인정보 제3자 제공 동의 (필수)
/// - 마케팅 정보 수신 동의 (선택)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// 동의 항목 데이터
class ConsentItem {
  final String id;
  final String title;
  final String description;
  final bool isRequired;
  final String? detailAssetPath;
  bool isAgreed;

  ConsentItem({
    required this.id,
    required this.title,
    required this.description,
    required this.isRequired,
    this.detailAssetPath,
    this.isAgreed = false,
  });
}

class ConsentScreen extends ConsumerStatefulWidget {
  final VoidCallback? onConsentComplete;

  const ConsentScreen({super.key, this.onConsentComplete});

  @override
  ConsumerState<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends ConsumerState<ConsentScreen> {
  bool _isLoading = false;
  bool _allRequiredAgreed = false;

  final List<ConsentItem> _consentItems = [
    ConsentItem(
      id: 'terms',
      title: '서비스 이용약관',
      description: 'PiCom 서비스 이용에 관한 약관입니다.',
      isRequired: true,
      detailAssetPath: 'assets/html/termsofuse.html',
    ),
    ConsentItem(
      id: 'privacy',
      title: '개인정보 처리방침',
      description: '개인정보의 수집, 이용, 보관에 관한 안내입니다.',
      isRequired: true,
      detailAssetPath: 'assets/html/privacy_policy.html',
    ),
    ConsentItem(
      id: 'thirdParty',
      title: '개인정보 제3자 제공 동의',
      description: '결제(카카오페이, 토스) 및 배송을 위한 정보 제공에 동의합니다.',
      isRequired: true,
    ),
    ConsentItem(
      id: 'marketing',
      title: '마케팅 정보 수신 동의',
      description: '이벤트, 할인 정보 등 마케팅 정보를 받아보실 수 있습니다.',
      isRequired: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _checkExistingConsent();
  }

  /// 기존 동의 여부 확인
  Future<void> _checkExistingConsent() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('consents')
          .doc('current')
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        // 이미 필수 동의를 했으면 바로 완료 처리
        if (data['termsAgreed'] == true &&
            data['privacyAgreed'] == true &&
            data['thirdPartyAgreed'] == true) {
          widget.onConsentComplete?.call();
        }
      }
    } catch (e) {
      debugPrint('동의 확인 오류: $e');
    }
  }

  void _updateAllRequiredAgreed() {
    setState(() {
      _allRequiredAgreed = _consentItems
          .where((item) => item.isRequired)
          .every((item) => item.isAgreed);
    });
  }

  void _toggleItem(ConsentItem item) {
    setState(() {
      item.isAgreed = !item.isAgreed;
      _updateAllRequiredAgreed();
    });
  }

  void _toggleAllRequired() {
    final allRequiredAgreed = _consentItems
        .where((item) => item.isRequired)
        .every((item) => item.isAgreed);

    setState(() {
      for (final item in _consentItems) {
        if (item.isRequired) {
          item.isAgreed = !allRequiredAgreed;
        }
      }
      _updateAllRequiredAgreed();
    });
  }

  void _toggleAll() {
    final allAgreed = _consentItems.every((item) => item.isAgreed);

    setState(() {
      for (final item in _consentItems) {
        item.isAgreed = !allAgreed;
      }
      _updateAllRequiredAgreed();
    });
  }

  Future<void> _saveConsent() async {
    if (!_allRequiredAgreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('필수 항목에 모두 동의해주세요')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('로그인이 필요합니다');
      }

      final now = FieldValue.serverTimestamp();
      final consentData = <String, dynamic>{
        'userId': user.uid,
        'termsAgreed': _consentItems.firstWhere((i) => i.id == 'terms').isAgreed,
        'termsAgreedAt': now,
        'privacyAgreed': _consentItems.firstWhere((i) => i.id == 'privacy').isAgreed,
        'privacyAgreedAt': now,
        'thirdPartyAgreed': _consentItems.firstWhere((i) => i.id == 'thirdParty').isAgreed,
        'thirdPartyAgreedAt': now,
        'marketingAgreed': _consentItems.firstWhere((i) => i.id == 'marketing').isAgreed,
        'marketingAgreedAt': _consentItems.firstWhere((i) => i.id == 'marketing').isAgreed ? now : null,
        'consentVersion': '1.0.0',
        'updatedAt': now,
      };

      // Firestore에 동의 정보 저장
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('consents')
          .doc('current')
          .set(consentData);

      // 사용자 문서에도 동의 플래그 업데이트
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'hasAgreedToTerms': true,
        'consentVersion': '1.0.0',
        'lastConsentAt': now,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('동의가 완료되었습니다'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onConsentComplete?.call();
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

  void _showDetailScreen(ConsentItem item) {
    if (item.detailAssetPath == null) {
      // 제3자 제공 동의는 별도 상세 화면
      if (item.id == 'thirdParty') {
        _showThirdPartyDetail();
      }
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConsentDetailScreen(
          title: item.title,
          assetPath: item.detailAssetPath!,
        ),
      ),
    );
  }

  void _showThirdPartyDetail() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('개인정보 제3자 제공 동의'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildProviderInfo(
                '카카오페이',
                '결제 처리 및 정산',
                '결제 정보 (상품명, 금액, 구매자 정보)',
                '거래 완료 후 5년',
              ),
              const Divider(height: 24),
              _buildProviderInfo(
                '토스페이먼츠',
                '결제 처리 및 정산',
                '결제 정보 (상품명, 금액, 구매자 정보)',
                '거래 완료 후 5년',
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '위 정보 제공에 동의하지 않으실 경우 결제 서비스 이용이 제한될 수 있습니다.',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderInfo(
    String provider,
    String purpose,
    String items,
    String period,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(provider, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('제공 목적: $purpose', style: const TextStyle(fontSize: 13)),
        Text('제공 항목: $items', style: const TextStyle(fontSize: 13)),
        Text('보유 기간: $period', style: const TextStyle(fontSize: 13)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final allAgreed = _consentItems.every((item) => item.isAgreed);
    final allRequiredAgreed = _consentItems
        .where((item) => item.isRequired)
        .every((item) => item.isAgreed);

    return Scaffold(
      appBar: AppBar(
        title: const Text('약관 동의'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 안내 메시지
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'PiCom 서비스 이용을 위해 아래 약관에 동의해주세요.',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 전체 동의
                  InkWell(
                    onTap: _toggleAll,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: allAgreed ? Colors.blue : Colors.grey[300]!,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            allAgreed
                                ? Icons.check_circle
                                : Icons.check_circle_outline,
                            color: allAgreed ? Colors.blue : Colors.grey,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '전체 동의',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '필수 및 선택 항목을 모두 포함합니다',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 필수 동의 전체
                  InkWell(
                    onTap: _toggleAllRequired,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Icon(
                            allRequiredAgreed
                                ? Icons.check_box
                                : Icons.check_box_outline_blank,
                            color: allRequiredAgreed ? Colors.blue : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            '필수 항목 전체 동의',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(),

                  // 개별 동의 항목
                  ...(_consentItems.map((item) => _buildConsentItem(item))),
                ],
              ),
            ),
          ),

          // 하단 버튼
          Container(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              16 + MediaQuery.of(context).padding.bottom,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _allRequiredAgreed && !_isLoading ? _saveConsent : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        '동의하고 시작하기',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsentItem(ConsentItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          InkWell(
            onTap: () => _toggleItem(item),
            child: Icon(
              item.isAgreed ? Icons.check_box : Icons.check_box_outline_blank,
              color: item.isAgreed ? Colors.blue : Colors.grey,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: InkWell(
              onTap: () => _toggleItem(item),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        item.isRequired ? '[필수] ' : '[선택] ',
                        style: TextStyle(
                          color: item.isRequired ? Colors.red : Colors.grey,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        item.title,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  Text(
                    item.description,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
          if (item.detailAssetPath != null || item.id == 'thirdParty')
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios, size: 16),
              onPressed: () => _showDetailScreen(item),
              tooltip: '상세 보기',
            ),
        ],
      ),
    );
  }
}

/// 약관 상세 화면
class ConsentDetailScreen extends StatefulWidget {
  final String title;
  final String assetPath;

  const ConsentDetailScreen({
    super.key,
    required this.title,
    required this.assetPath,
  });

  @override
  State<ConsentDetailScreen> createState() => _ConsentDetailScreenState();
}

class _ConsentDetailScreenState extends State<ConsentDetailScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            setState(() => _isLoading = false);
          },
        ),
      )
      ..loadFlutterAsset(widget.assetPath);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
