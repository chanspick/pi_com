// lib/features/sell_request/presentation/screens/part_search_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../../../core/models/base_part_model.dart';

/// 부품 검색 화면 (Cloud Functions searchParts 사용)
class PartSearchScreen extends StatefulWidget {
  const PartSearchScreen({super.key});

  @override
  State<PartSearchScreen> createState() => _PartSearchScreenState();
}

class _PartSearchScreenState extends State<PartSearchScreen> {
  final _searchController = TextEditingController();
  final _functions = FirebaseFunctions.instanceFor(region: 'asia-northeast3');

  String _selectedCategory = 'cpu';
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  String? _errorMessage;

  final List<Map<String, String>> _categories = [
    {'value': 'cpu', 'label': 'CPU'},
    {'value': 'gpu', 'label': 'GPU'},
    {'value': 'mainboard', 'label': '메인보드'},
    {'value': 'ram', 'label': 'RAM'},
    {'value': 'ssd', 'label': 'SSD'},
    {'value': 'psu', 'label': '파워'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Cloud Functions searchParts 호출
  Future<void> _searchParts(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _errorMessage = '검색어를 입력하세요';
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _errorMessage = null;
    });

    try {
      final callable = _functions.httpsCallable('searchParts');
      final result = await callable.call({
        'category': _selectedCategory,
        'query': query.toLowerCase().trim(),
      });

      final data = result.data as List<dynamic>;
      setState(() {
        _searchResults = data.cast<Map<String, dynamic>>();
        _isSearching = false;
      });

      if (_searchResults.isEmpty) {
        setState(() {
          _errorMessage = '검색 결과가 없습니다';
        });
      }
    } catch (e) {
      setState(() {
        _isSearching = false;
        _errorMessage = '검색 중 오류 발생: $e';
      });
    }
  }

  /// 부품 선택 시 BasePart로 변환하여 반환
  void _selectPart(Map<String, dynamic> partData) {
    final referencePrice = (partData['referencePrice'] as num?)?.toInt() ?? 0;

    final basePart = BasePart(
      basePartId: partData['basePartId'] ?? partData['partId'] ?? '',
      modelName: partData['modelName'] ?? partData['model'] ?? partData['name'] ?? '',
      category: _selectedCategory.toUpperCase(),
      lowestPrice: referencePrice,
      averagePrice: referencePrice.toDouble(),
      listingCount: 0,
    );

    Navigator.pop(context, basePart);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('부품 검색'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 카테고리 선택
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: '카테고리',
                border: OutlineInputBorder(),
              ),
              items: _categories.map((category) {
                return DropdownMenuItem<String>(
                  value: category['value'],
                  child: Text(category['label']!),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                  _searchResults = [];
                  _errorMessage = null;
                });
              },
            ),
            const SizedBox(height: 16),

            // 검색 바
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '부품 모델명, 제조사 등을 입력하세요',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchResults = [];
                      _errorMessage = null;
                    });
                  },
                ),
              ),
              onSubmitted: _searchParts,
            ),
            const SizedBox(height: 8),

            // 검색 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSearching
                    ? null
                    : () => _searchParts(_searchController.text),
                child: _isSearching
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text('검색 중...'),
                        ],
                      )
                    : const Text('검색'),
              ),
            ),
            const SizedBox(height: 16),

            // 결과 표시
            if (_errorMessage != null)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (_searchResults.isEmpty && !_isSearching)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '검색어를 입력하고\n검색 버튼을 눌러주세요',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final part = _searchResults[index];
                    final modelName = part['modelName'] ?? part['model'] ?? part['name'] ?? '알 수 없음';
                    final brand = part['brand'] ?? '';
                    final price = (part['referencePrice'] as num?)?.toInt();

                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(brand.isNotEmpty ? brand[0].toUpperCase() : '?'),
                        ),
                        title: Text(modelName),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (brand.isNotEmpty) Text('제조사: $brand'),
                            if (price != null)
                              Text(
                                '참고가: ${price.toString().replaceAllMapped(
                                  RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                  (Match m) => '${m[1]},',
                                )}원',
                              ),
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => _selectPart(part),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
