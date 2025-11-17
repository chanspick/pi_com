// lib/features/address/presentation/screens/address_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/address_entity.dart';
import '../../data/repositories/address_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'address_form_screen.dart';

/// 배송지 목록 Provider
final addressListProvider = StreamProvider.autoDispose<List<AddressEntity>>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) {
    return Stream.value([]);
  }

  return AddressRepository().getAddressesStream(currentUser.uid);
});

/// 배송지 목록 화면
class AddressListScreen extends ConsumerWidget {
  final bool isSelectMode; // 선택 모드 (결제 시 사용)

  const AddressListScreen({
    super.key,
    this.isSelectMode = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addressesAsync = ref.watch(addressListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(isSelectMode ? '배송지 선택' : '배송지 관리'),
      ),
      body: addressesAsync.when(
        data: (addresses) {
          if (addresses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_off, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    '등록된 배송지가 없습니다',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '새 배송지를 추가해주세요',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _addAddress(context),
                    icon: const Icon(Icons.add),
                    label: const Text('배송지 추가'),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: addresses.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final address = addresses[index];
              return _AddressCard(
                address: address,
                isSelectMode: isSelectMode,
                onTap: () {
                  if (isSelectMode) {
                    Navigator.pop(context, address);
                  }
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('오류: $error'),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addAddress(context),
        icon: const Icon(Icons.add),
        label: const Text('배송지 추가'),
      ),
    );
  }

  Future<void> _addAddress(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddressFormScreen(),
      ),
    );

    if (result == true && context.mounted && isSelectMode) {
      // 추가 후 선택 모드인 경우, 방금 추가한 배송지를 자동으로 선택할 수도 있음
      // 현재는 목록만 새로고침
    }
  }
}

/// 배송지 카드 위젯
class _AddressCard extends ConsumerWidget {
  final AddressEntity address;
  final bool isSelectMode;
  final VoidCallback? onTap;

  const _AddressCard({
    required this.address,
    required this.isSelectMode,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: address.isDefault ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: address.isDefault ? Theme.of(context).primaryColor : Colors.grey[300]!,
          width: address.isDefault ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더: 기본 배송지 표시
              Row(
                children: [
                  if (address.isDefault)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '기본 배송지',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  const Spacer(),
                  if (!isSelectMode) ...[
                    // 수정 버튼
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      onPressed: () => _editAddress(context, ref),
                      tooltip: '수정',
                    ),
                    // 삭제 버튼
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                      onPressed: () => _deleteAddress(context, ref),
                      tooltip: '삭제',
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 12),

              // 수령인 정보
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    address.recipientName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    address.recipientPhone,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // 주소
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on_outlined, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          address.basicAddress,
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          address.detailAddress,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // 기본 배송지로 설정 버튼 (선택 모드가 아니고, 이미 기본 배송지가 아닌 경우)
              if (!isSelectMode && !address.isDefault) ...[
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => _setAsDefault(context, ref),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 40),
                  ),
                  child: const Text('기본 배송지로 설정'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editAddress(BuildContext context, WidgetRef ref) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddressFormScreen(address: address),
      ),
    );
  }

  Future<void> _deleteAddress(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('배송지 삭제'),
        content: const Text('이 배송지를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) return;

      try {
        await AddressRepository().deleteAddress(currentUser.uid, address.addressId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('배송지가 삭제되었습니다'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('삭제 실패: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _setAsDefault(BuildContext context, WidgetRef ref) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    try {
      await AddressRepository().setDefaultAddress(currentUser.uid, address.addressId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('기본 배송지로 설정되었습니다'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('설정 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
