// lib/features/sell_request/presentation/screens/sell_request_screen.dart

import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/models/sell_request_model.dart';
import '../../../../core/models/base_part_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/sell_request_provider.dart';
import 'part_search_screen.dart';

class SellRequestScreen extends ConsumerStatefulWidget {
  const SellRequestScreen({super.key});

  @override
  ConsumerState<SellRequestScreen> createState() =>
      _SellRequestScreenState();
}

class _SellRequestScreenState extends ConsumerState<SellRequestScreen> {
  final _formKey = GlobalKey<FormState>();

  // 선택된 부품
  BasePart? _selectedPart;

  // 이미지
  List<XFile> _images = [];
  final ImagePicker _picker = ImagePicker();

  // 폼 필드
  bool _hasWarranty = false;
  int? _warrantyMonthsLeft;
  int? _usageDaysPerWeek;
  int? _usageHoursPerDay;
  String? _selectedPurpose;
  AgeInfoType _ageInfoType = AgeInfoType.unknown;
  int? _ageInfoYear;
  int? _ageInfoMonth;
  bool _isSecondHand = true;
  final _requestedPriceController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _requestedPriceController.dispose();
    super.dispose();
  }

  // ==================== 부품 선택 ====================
  Future<void> _selectPart() async {
    final selectedPart = await Navigator.push<BasePart>(
      context,
      MaterialPageRoute(
        builder: (context) => const PartSearchScreen(),
      ),
    );

    if (selectedPart != null) {
      setState(() {
        _selectedPart = selectedPart;
      });
    }
  }

  // ==================== 이미지 선택 ====================
  Future<void> _pickImages() async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        imageQuality: 70,
        maxWidth: 1000,
      );

      if (pickedFiles.isNotEmpty) {
        setState(() {
          if (_images.length + pickedFiles.length <= 5) {
            _images.addAll(pickedFiles);
          } else {
            _images.addAll(
              pickedFiles.take(5 - _images.length),
            );
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('이미지는 최대 5장까지 선택 가능합니다')),
            );
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이미지 선택 실패: $e')),
      );
    }
  }

  // ==================== 이미지 삭제 ====================
  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  // ==================== 판매 요청 제출 ====================
  Future<void> _submitSellRequest() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPart == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('부품을 선택해주세요')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) throw Exception('로그인이 필요합니다');

      // 사용 빈도 계산
      String usageFrequency = 'unknown';
      if (_usageDaysPerWeek != null && _usageHoursPerDay != null) {
        usageFrequency = '주 $_usageDaysPerWeek일, 하루 $_usageHoursPerDay시간';
      }

      // SellRequest 생성
      final sellRequest = SellRequest(
        requestId: const Uuid().v4(),
        sellerId: user.uid,
        partId: _selectedPart!.basePartId,
        basePartId: _selectedPart!.basePartId,
        brand: '', // TODO: Part 모델에서 가져오기
        category: _selectedPart!.category,
        modelName: _selectedPart!.modelName,
        ageInfoType: _ageInfoType,
        ageInfoYear: _ageInfoYear,
        ageInfoMonth: _ageInfoMonth,
        isSecondHand: _isSecondHand,
        hasWarranty: _hasWarranty,
        warrantyMonthsLeft: _hasWarranty ? _warrantyMonthsLeft : null,
        usageFrequency: usageFrequency,
        purpose: _selectedPurpose ?? '',
        requestedPrice: int.parse(_requestedPriceController.text),
        imageUrls: [],
        status: SellRequestStatus.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Controller 호출
      await ref
          .read(submitSellRequestControllerProvider.notifier)
          .submitSellRequest(
        sellRequest: sellRequest,
        images: _images,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('판매 요청이 제출되었습니다')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('제출 실패: $e')),
      );
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
        title: const Text('판매 요청'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildPartSelector(),
              const SizedBox(height: 24),
              _buildImagePicker(),
              const SizedBox(height: 24),
              _buildPriceInput(),
              const SizedBox(height: 24),
              _buildAgeInfo(),
              const SizedBox(height: 24),
              _buildWarrantyInfo(),
              const SizedBox(height: 24),
              _buildUsageInfo(),
              const SizedBox(height: 24),
              _buildPurposeInput(),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitSellRequest,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  '판매 요청 제출',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // UI 빌더 메서드 (다음 스텝에서 추가)
  Widget _buildPartSelector() {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.computer),
        title: Text(
          _selectedPart == null ? '부품 선택' : _selectedPart!.modelName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: _selectedPart == null
            ? const Text('판매할 부품을 선택하세요')
            : Text(_selectedPart!.category),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: _selectPart,
      ),
    );
  }

  // 나머지 빌더 메서드는 다음 스텝에서...
  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '상품 이미지',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              '${_images.length}/5',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // 업로드된 이미지들
            ..._images.asMap().entries.map((entry) {
              final index = entry.key;
              final image = entry.value;
              return Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: kIsWeb
                            ? NetworkImage(image.path)
                            : FileImage(File(image.path)) as ImageProvider,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _removeImage(index),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }),

            // 추가 버튼
            if (_images.length < 5)
              GestureDetector(
                onTap: _pickImages,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[400]!),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate, size: 32),
                      SizedBox(height: 4),
                      Text('사진 추가'),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
  Widget _buildPriceInput() {
    return TextFormField(
      controller: _requestedPriceController,
      decoration: const InputDecoration(
        labelText: '희망 판매 가격',
        hintText: '가격을 입력하세요 (원)',
        border: OutlineInputBorder(),
        prefixText: '₩ ',
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty) return '가격을 입력하세요';
        if (int.tryParse(value) == null) return '올바른 숫자를 입력하세요';
        if (int.parse(value) <= 0) return '가격은 0보다 커야 합니다';
        return null;
      },
    );
  }

  Widget _buildAgeInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '부품 연식 정보',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<AgeInfoType>(
          value: _ageInfoType,
          decoration: const InputDecoration(
            labelText: '연식 정보 유형',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(
              value: AgeInfoType.originalPurchaseDate,
              child: Text('구매 시기'),
            ),
            DropdownMenuItem(
              value: AgeInfoType.manufacturDate,
              child: Text('제조 시기'),
            ),
            DropdownMenuItem(
              value: AgeInfoType.unknown,
              child: Text('모름'),
            ),
          ],
          onChanged: (value) {
            setState(() {
              _ageInfoType = value!;
            });
          },
        ),
        if (_ageInfoType != AgeInfoType.unknown) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: '연도',
                    hintText: 'YYYY',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    _ageInfoYear = int.tryParse(value);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: '월',
                    hintText: 'MM',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    _ageInfoMonth = int.tryParse(value);
                  },
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        SwitchListTile(
          title: const Text('중고 제품'),
          value: _isSecondHand,
          onChanged: (value) {
            setState(() {
              _isSecondHand = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildWarrantyInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          title: const Text('AS 가능'),
          value: _hasWarranty,
          onChanged: (value) {
            setState(() {
              _hasWarranty = value;
              if (!value) _warrantyMonthsLeft = null;
            });
          },
        ),
        if (_hasWarranty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: TextFormField(
              decoration: const InputDecoration(
                labelText: '남은 AS 기간 (개월)',
                hintText: '개월 수 입력',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                _warrantyMonthsLeft = int.tryParse(value);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildUsageInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '사용 빈도',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                decoration: const InputDecoration(
                  labelText: '주 사용 일수',
                  hintText: '일/주',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  _usageDaysPerWeek = int.tryParse(value);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                decoration: const InputDecoration(
                  labelText: '하루 사용 시간',
                  hintText: '시간/일',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  _usageHoursPerDay = int.tryParse(value);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPurposeInput() {
    return DropdownButtonFormField<String>(
      value: _selectedPurpose,
      decoration: const InputDecoration(
        labelText: '사용 용도',
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(value: 'gaming', child: Text('게임')),
        DropdownMenuItem(value: 'work', child: Text('업무')),
        DropdownMenuItem(value: 'creative', child: Text('영상/그래픽')),
        DropdownMenuItem(value: 'development', child: Text('개발')),
        DropdownMenuItem(value: 'general', child: Text('일반 사용')),
      ],
      onChanged: (value) {
        setState(() {
          _selectedPurpose = value;
        });
      },
    );
  }
}
