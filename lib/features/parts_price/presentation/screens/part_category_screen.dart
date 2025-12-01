// lib/features/parts_price/presentation/screens/part_category_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/part_provider.dart';
import '../widgets/base_part_card.dart';
import '../../../../core/constants/routes.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../web_public/presentation/widgets/web_navbar_v2.dart';

class PartsCategoryScreen extends ConsumerStatefulWidget {
  const PartsCategoryScreen({super.key});

  @override
  ConsumerState<PartsCategoryScreen> createState() => _PartsCategoryScreenState();
}

class _PartsCategoryScreenState extends ConsumerState<PartsCategoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _categories = ['cpu', 'gpu', 'ram', 'mainboard', 'ssd'];
  final Map<String, String> _categoryNames = {
    'cpu': 'CPU',
    'gpu': 'GPU',
    'ram': 'RAM',
    'mainboard': '메인보드',
    'ssd': 'SSD',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        ref.read(selectedPartCategoryProvider.notifier).state =
        _categories[_tabController.index];
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Scaffold(
        appBar: const WebNavBarV2(),
        body: ResponsiveHelper.centeredMaxWidthContainer(
          context: context,
          child: Column(
            children: [
              // Tab bar for web
              Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: Theme.of(context).primaryColor,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Theme.of(context).primaryColor,
                  tabs: _categories
                      .map((c) => Tab(text: _categoryNames[c] ?? c.toUpperCase()))
                      .toList(),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: _categories.map((category) {
                    return _buildPartGrid(category);
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Mobile layout
    return Scaffold(
      appBar: AppBar(
        title: const Text('부품 시세'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _categories
              .map((c) => Tab(text: _categoryNames[c] ?? c.toUpperCase()))
              .toList(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).pushNamed(Routes.basePartSearch);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.search, color: Colors.grey),
                    SizedBox(width: 8),
                    Text(
                      '부품 검색',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _categories.map((category) {
                return _buildPartGrid(category);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartGrid(String category) {
    final basePartsAsync = ref.watch(basePartsStreamProvider(category));

    return basePartsAsync.when(
      data: (baseParts) {
        if (baseParts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  '판매중인 부품이 없습니다.',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(basePartsStreamProvider);
          },
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: ResponsiveHelper.getGridCrossAxisCount(context),
              childAspectRatio: 0.75,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: baseParts.length,
            itemBuilder: (context, index) {
              return BasePartCard(basePart: baseParts[index]);
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              '오류가 발생했습니다',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800]),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                ref.invalidate(basePartsStreamProvider);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }
}
