// lib/features/sell_request/presentation/screens/sell_request_details_screen.dart

import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/models/base_part_model.dart';
import '../../../../core/models/sell_request_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/sell_request_provider.dart';

/// 판매 요청 상세 정보 입력 화면 (완제품 PC용)
class SellRequestDetailsScreen extends ConsumerStatefulWidget {
  final List<BasePart> selectedBaseParts;

  const SellRequestDetailsScreen({
    super.key,
    required this.selectedBaseParts,
  });

  @override
  ConsumerState<SellRequestDetailsScreen> createState() =>
      _SellRequestDetailsScreenState();
}

class _SellRequestDetailsScreenState
    extends ConsumerState<SellRequestDetailsScreen> {
  final _formKey = GlobalKey<FormState>();

  // State
  List<XFile> _images = [];
  final ImagePicker _picker = ImagePicker();
  AgeInfoType _selectedAgeInfoType = AgeInfoType.unknown;
  bool _isSecondHand = false;
  bool _hasWarranty = false;
  bool _isUnused = false;
  int? _usageDaysPerWeek;
  int? _usageHoursPerDay;
  String? _selectedPurpose;

  // Controllers
  final _yearController = TextEditingController();
  final _monthController = TextEditingController();
  final _warrantyMonthsController = TextEditingController();
  final _otherPurposeController = TextEditingController();
  late List<TextEditingController> _priceControllers;

  final List<String> _purposes = ['일상용', '게임용', '개발용', '사무용', '기타'];

  @override
  void initState() {
    super.initState();
    // 각 부품별 가격 입력 컨트롤러 생성
    _priceControllers = List.generate(
      widget.selectedBaseParts.length,
          (index) => TextEditingController(),
    );
  }

  @override
  void dispose() {
    _yearController.dispose();
    _monthController.dispose();
    _warrantyMonthsController.dispose();
    _otherPurposeController.dispose();
    for (var controller in _priceControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  /// 이미지 선택
  Future<void> _pickImages() async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        imageQuality: 50,
        maxWidth: 800,
      );
      if (pickedFiles.isNotEmpty) {
        setState(() {
          _images = pickedFiles.take(5).toList(); // 최대 5장
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('이미지 선택 오류: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 판매 요청 제출 (Provider 사용)
  Future<void> _submitRequests() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('입력되지 않은 필수 항목이 있습니다.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedPurpose == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('주 사용 용도를 선택해주세요.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('사진을 1장 이상 추가해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 로그인 확인
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인이 필요합니다.')),
      );
      return;
    }

    try {
      // 용도 처리
      String purpose = _selectedPurpose!;
      if (purpose == '기타') {
        purpose = _otherPurposeController.text;
      }

      // 연식 정보
      final int? year = _selectedAgeInfoType != AgeInfoType.unknown
          ? int.tryParse(_yearController.text)
          : null;
      final int? month = _selectedAgeInfoType != AgeInfoType.unknown
          ? int.tryParse(_monthController.text)
          : null;

      // 사용 빈도
      final String usageFrequency = _isUnused
          ? '미사용'
          : '주 $_usageDaysPerWeek일, 하루 $_usageHoursPerDay시간';

      // 각 부품별 가격
      final List<int> prices = _priceControllers
          .map((controller) => int.parse(controller.text))
          .toList();

      // Provider를 통해 제출
      await ref
          .read(submitMultipleSellRequestsControllerProvider.notifier)
          .submitMultipleRequests(
        baseParts: widget.selectedBaseParts,
        prices: prices,
        userId: currentUser.uid,
        images: _images,
        ageInfoType: _selectedAgeInfoType,
        ageInfoYear: year,
        ageInfoMonth: month,
        isSecondHand: _isSecondHand,
        hasWarranty: _hasWarranty,
        warrantyMonthsLeft: _hasWarranty
            ? int.tryParse(_warrantyMonthsController.text)
            : null,
        usageFrequency: usageFrequency,
        purpose: purpose,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('판매 요청이 성공적으로 제출되었습니다.')),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final submitState = ref.watch(submitMultipleSellRequestsControllerProvider);
    final isLoading = submitState.status == SubmitStatus.submitting ||
        submitState.status == SubmitStatus.uploading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('판매 정보 입력'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildSelectedPartsSection(),
            const SizedBox(height: 24),
            _buildPriceInputSection(),
            const Divider(height: 40),
            _buildAgeInfoSection(),
            const SizedBox(height: 24),
            _buildOwnershipSection(),
            const SizedBox(height: 24),
            _buildWarrantySection(),
            const SizedBox(height: 24),
            _buildUsageSection(),
            const SizedBox(height: 24),
            _buildPurposeSection(),
            const SizedBox(height: 24),
            _buildImagePicker(),
            const SizedBox(height: 32),
            _buildSubmitButton(isLoading),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// 선택된 부품 목록
  Widget _buildSelectedPartsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.memory, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            Text(
              '판매할 부품 목록 (${widget.selectedBaseParts.length}개)',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          color: Colors.blue.shade50,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.blue.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: widget.selectedBaseParts.map((part) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${part.category} - ${part.modelName}',
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  /// 각 부품별 가격 입력
  Widget _buildPriceInputSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('각 부품별 희망 가격 💰',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          '각 부품의 희망 판매 가격을 개별적으로 입력해주세요.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(widget.selectedBaseParts.length, (index) {
          final part = widget.selectedBaseParts[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: TextFormField(
              controller: _priceControllers[index],
              decoration: InputDecoration(
                labelText: part.modelName,
                hintText: '희망 판매 가격 입력',
                border: const OutlineInputBorder(),
                suffixText: '원',
                prefixIcon: const Icon(Icons.attach_money),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '가격을 입력해주세요.';
                }
                if (int.tryParse(value) == null || int.parse(value) <= 0) {
                  return '유효한 가격을 입력해주세요.';
                }
                return null;
              },
            ),
          );
        }),
      ],
    );
  }
  /// 연식 정보 섹션
  Widget _buildAgeInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('부품 연식 정보 📅', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        RadioListTile<AgeInfoType>(
          title: const Text('구매한 날짜를 알고 있음'),
          value: AgeInfoType.originalPurchaseDate,
          groupValue: _selectedAgeInfoType,
          onChanged: (value) => setState(() => _selectedAgeInfoType = value!),
        ),
        RadioListTile<AgeInfoType>(
          title: const Text('제조 날짜만 알고 있음'),
          value: AgeInfoType.manufacturDate,
          groupValue: _selectedAgeInfoType,
          onChanged: (value) => setState(() => _selectedAgeInfoType = value!),
        ),
        RadioListTile<AgeInfoType>(
          title: const Text('정보 없음'),
          value: AgeInfoType.unknown,
          groupValue: _selectedAgeInfoType,
          onChanged: (value) => setState(() => _selectedAgeInfoType = value!),
        ),
        if (_selectedAgeInfoType != AgeInfoType.unknown) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _yearController,
                  decoration: const InputDecoration(
                    labelText: '년도',
                    hintText: '예: 2023',
                    border: OutlineInputBorder(),
                    suffixText: '년',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  validator: (value) {
                    if (_selectedAgeInfoType != AgeInfoType.unknown &&
                        (value == null || value.isEmpty)) {
                      return '년도 입력';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _monthController,
                  decoration: const InputDecoration(
                    labelText: '월',
                    hintText: '예: 6',
                    border: OutlineInputBorder(),
                    suffixText: '월',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(2),
                  ],
                  validator: (value) {
                    if (_selectedAgeInfoType != AgeInfoType.unknown &&
                        (value == null || value.isEmpty)) {
                      return '월 입력';
                    }
                    final month = int.tryParse(value ?? '');
                    if (month != null && (month < 1 || month > 12)) {
                      return '1-12 입력';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// 소유 이력 섹션
  Widget _buildOwnershipSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('소유 이력 📦', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        RadioListTile<bool>(
          title: const Text('신품 직접 구매'),
          value: false,
          groupValue: _isSecondHand,
          onChanged: (value) => setState(() => _isSecondHand = value!),
        ),
        RadioListTile<bool>(
          title: const Text('중고 구매'),
          value: true,
          groupValue: _isSecondHand,
          onChanged: (value) => setState(() => _isSecondHand = value!),
        ),
      ],
    );
  }

  /// AS 정보 섹션
  Widget _buildWarrantySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('AS 정보 🔧', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('AS 기간이 남아 있음'),
          value: _hasWarranty,
          onChanged: (value) => setState(() => _hasWarranty = value),
        ),
        if (_hasWarranty) ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: _warrantyMonthsController,
            decoration: const InputDecoration(
              labelText: '남은 AS 기간',
              hintText: '개월 수 입력',
              border: OutlineInputBorder(),
              suffixText: '개월',
              prefixIcon: Icon(Icons.timer),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (value) {
              if (_hasWarranty && (value == null || value.isEmpty)) {
                return 'AS 기간을 입력해주세요.';
              }
              return null;
            },
          ),
        ],
      ],
    );
  }

  /// 사용 빈도 섹션
  Widget _buildUsageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('사용 빈도 ⏰', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        CheckboxListTile(
          title: const Text('미사용 (새 제품)'),
          value: _isUnused,
          onChanged: (value) => setState(() => _isUnused = value!),
        ),
        if (!_isUnused) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  decoration: const InputDecoration(
                    labelText: '주 사용 일수',
                    border: OutlineInputBorder(),
                    suffixText: '일',
                  ),
                  value: _usageDaysPerWeek,
                  items: List.generate(
                    8,
                        (index) => DropdownMenuItem(
                      value: index,
                      child: Text('$index일'),
                    ),
                  ),
                  onChanged: (value) =>
                      setState(() => _usageDaysPerWeek = value),
                  validator: (value) {
                    if (!_isUnused && value == null) {
                      return '선택 필요';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<int>(
                  decoration: const InputDecoration(
                    labelText: '하루 사용 시간',
                    border: OutlineInputBorder(),
                    suffixText: '시간',
                  ),
                  value: _usageHoursPerDay,
                  items: List.generate(
                    25,
                        (index) => DropdownMenuItem(
                      value: index,
                      child: Text('$index시간'),
                    ),
                  ),
                  onChanged: (value) =>
                      setState(() => _usageHoursPerDay = value),
                  validator: (value) {
                    if (!_isUnused && value == null) {
                      return '선택 필요';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// 사용 용도 섹션
  Widget _buildPurposeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('주 사용 용도 🎯', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: _purposes.map((purpose) {
            return ChoiceChip(
              label: Text(purpose),
              selected: _selectedPurpose == purpose,
              onSelected: (selected) {
                setState(() {
                  _selectedPurpose = selected ? purpose : null;
                });
              },
            );
          }).toList(),
        ),
        if (_selectedPurpose == '기타') ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: _otherPurposeController,
            decoration: const InputDecoration(
              labelText: '기타 용도 직접 입력',
              hintText: '예: 영상 편집, 3D 작업 등',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (_selectedPurpose == '기타' &&
                  (value == null || value.isEmpty)) {
                return '기타 용도를 입력해주세요.';
              }
              return null;
            },
          ),
        ],
      ],
    );
  }

  /// 이미지 선택 섹션
  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('부품 사진 📷', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          '최대 5장까지 업로드 가능합니다.',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              // 이미지 추가 버튼
              GestureDetector(
                onTap: _pickImages,
                child: Container(
                  width: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate,
                          size: 40, color: Colors.grey.shade600),
                      const SizedBox(height: 8),
                      Text(
                        '사진 추가',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // 선택된 이미지 표시
              ..._images.map((image) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: kIsWeb
                            ? Image.network(
                          image.path,
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        )
                            : Image.file(
                          File(image.path),
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _images.remove(image);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  /// 제출 버튼
  Widget _buildSubmitButton(bool isLoading) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 56),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onPressed: isLoading ? null : _submitRequests,
      child: isLoading
          ? const SizedBox(
        height: 24,
        width: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      )
          : const Text('판매 요청 제출'),
    );
  }
}
