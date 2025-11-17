// lib/features/address/presentation/screens/address_form_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/address_entity.dart';
import '../../data/repositories/address_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'daum_postcode_screen.dart';

/// 배송지 추가/수정 화면
class AddressFormScreen extends ConsumerStatefulWidget {
  final AddressEntity? address; // null이면 추가 모드, 있으면 수정 모드

  const AddressFormScreen({
    super.key,
    this.address,
  });

  @override
  ConsumerState<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends ConsumerState<AddressFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _recipientNameController = TextEditingController();
  final _recipientPhoneController = TextEditingController();
  final _zonecodeController = TextEditingController();
  final _roadAddressController = TextEditingController();
  final _detailAddressController = TextEditingController();

  String _jibunAddress = '';
  String _buildingName = '';
  bool _isDefault = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAddressData();
  }

  void _loadAddressData() {
    if (widget.address != null) {
      final address = widget.address!;
      _recipientNameController.text = address.recipientName;
      _recipientPhoneController.text = address.recipientPhone;
      _zonecodeController.text = address.zonecode;
      _roadAddressController.text = address.roadAddress;
      _detailAddressController.text = address.detailAddress;
      _jibunAddress = address.jibunAddress;
      _buildingName = address.buildingName;
      _isDefault = address.isDefault;
    }
  }

  @override
  void dispose() {
    _recipientNameController.dispose();
    _recipientPhoneController.dispose();
    _zonecodeController.dispose();
    _roadAddressController.dispose();
    _detailAddressController.dispose();
    super.dispose();
  }

  Future<void> _searchPostcode() async {
    final result = await Navigator.push<DaumPostcodeResult>(
      context,
      MaterialPageRoute(
        builder: (context) => const DaumPostcodeScreen(),
        fullscreenDialog: true,
      ),
    );

    if (result != null) {
      setState(() {
        _zonecodeController.text = result.zonecode;
        _roadAddressController.text = result.roadAddress;
        _jibunAddress = result.jibunAddress;
        _buildingName = result.buildingName;
      });

      // 상세주소 입력 필드로 포커스 이동
      FocusScope.of(context).nextFocus();
    }
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 우편번호 검증
    if (_zonecodeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('주소 검색 버튼을 눌러 주소를 검색해주세요')),
      );
      return;
    }

    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인이 필요합니다')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repository = AddressRepository();

      if (widget.address == null) {
        // 추가 모드
        final newAddress = AddressEntity(
          addressId: '', // Repository에서 자동 생성
          recipientName: _recipientNameController.text.trim(),
          recipientPhone: _recipientPhoneController.text.trim(),
          zonecode: _zonecodeController.text.trim(),
          roadAddress: _roadAddressController.text.trim(),
          jibunAddress: _jibunAddress,
          buildingName: _buildingName,
          detailAddress: _detailAddressController.text.trim(),
          isDefault: _isDefault,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await repository.addAddress(currentUser.uid, newAddress);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('배송지가 추가되었습니다'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        // 수정 모드
        final updatedAddress = widget.address!.copyWith(
          recipientName: _recipientNameController.text.trim(),
          recipientPhone: _recipientPhoneController.text.trim(),
          zonecode: _zonecodeController.text.trim(),
          roadAddress: _roadAddressController.text.trim(),
          jibunAddress: _jibunAddress,
          buildingName: _buildingName,
          detailAddress: _detailAddressController.text.trim(),
          isDefault: _isDefault,
          updatedAt: DateTime.now(),
        );

        await repository.updateAddress(currentUser.uid, updatedAddress);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('배송지가 수정되었습니다'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
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
    final isEditMode = widget.address != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? '배송지 수정' : '배송지 추가'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveAddress,
              child: const Text('저장', style: TextStyle(fontSize: 16)),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 수령인 이름
            TextFormField(
              controller: _recipientNameController,
              decoration: const InputDecoration(
                labelText: '수령인 이름',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
                hintText: '홍길동',
              ),
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '수령인 이름을 입력해주세요';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // 수령인 전화번호
            TextFormField(
              controller: _recipientPhoneController,
              decoration: const InputDecoration(
                labelText: '수령인 전화번호',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone_outlined),
                hintText: '010-1234-5678',
              ),
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '수령인 전화번호를 입력해주세요';
                }
                // 간단한 전화번호 검증
                final phoneRegex = RegExp(r'^010-?\d{3,4}-?\d{4}$');
                if (!phoneRegex.hasMatch(value.replaceAll('-', ''))) {
                  return '올바른 전화번호 형식이 아닙니다 (예: 010-1234-5678)';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),
            const Divider(thickness: 1),
            const SizedBox(height: 16),

            // 우편번호
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _zonecodeController,
                    decoration: const InputDecoration(
                      labelText: '우편번호',
                      border: OutlineInputBorder(),
                      hintText: '우편번호',
                    ),
                    readOnly: true,
                    enabled: false,
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _searchPostcode,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  ),
                  child: const Text('주소 검색'),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 기본 주소
            TextFormField(
              controller: _roadAddressController,
              decoration: const InputDecoration(
                labelText: '기본 주소',
                border: OutlineInputBorder(),
                hintText: '주소 검색 버튼을 눌러주세요',
              ),
              readOnly: true,
              enabled: false,
              maxLines: 2,
            ),

            const SizedBox(height: 16),

            // 상세 주소 (필수)
            TextFormField(
              controller: _detailAddressController,
              decoration: const InputDecoration(
                labelText: '상세 주소 (필수)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.home_outlined),
                hintText: '동/호수 입력 (예: 101동 1001호)',
              ),
              textInputAction: TextInputAction.done,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '상세 주소를 입력해주세요 (예: 101동 1001호)';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),
            const Divider(thickness: 1),
            const SizedBox(height: 16),

            // 기본 배송지 설정
            CheckboxListTile(
              title: const Text('기본 배송지로 설정'),
              subtitle: const Text('주문 시 자동으로 선택됩니다'),
              value: _isDefault,
              onChanged: (value) {
                setState(() => _isDefault = value ?? false);
              },
              controlAffinity: ListTileControlAffinity.leading,
            ),

            const SizedBox(height: 24),

            // 안내 문구
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, size: 20, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Text(
                        '배송지 입력 안내',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• 우편번호와 상세 주소는 필수 입력 사항입니다.\n'
                    '• 주소 검색 버튼을 눌러 정확한 주소를 입력해주세요.\n'
                    '• 기본 배송지로 설정하면 주문 시 자동으로 선택됩니다.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[700],
                      height: 1.5,
                    ),
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
