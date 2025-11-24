// lib/features/web_public/presentation/screens/landing_page_v2.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/routes.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../shared/widgets/app_footer.dart';
import '../widgets/web_navbar_v2.dart';
import '../../../listing/presentation/providers/listing_provider.dart';
import '../../../listing/domain/entities/listing_entity.dart';

/// Professional e-commerce style landing page (commawang inspired)
class LandingPageV2 extends ConsumerWidget {
  const LandingPageV2({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: const WebNavBarV2(),
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero banner carousel
            const HeroBannerCarousel(),
            const SizedBox(height: 60),

            // Quick categories
            _buildQuickCategories(context),
            const SizedBox(height: 80),

            // Featured products
            _buildFeaturedSection(context, ref, '최신 부품', '최근 등록된 부품'),
            const SizedBox(height: 80),

            // Why choose us
            _buildWhyChooseUs(context),
            const SizedBox(height: 80),

            // Stats
            _buildStats(context),
            const SizedBox(height: 60),

            // Footer
            const AppFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickCategories(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final isTablet = ResponsiveHelper.isTablet(context);

    final titleSize = isMobile ? 24.0 : isTablet ? 28.0 : 32.0;
    final spacing = isMobile ? 24.0 : isTablet ? 32.0 : 40.0;

    final categories = [
      {'icon': Icons.memory, 'label': 'CPU', 'route': '${Routes.partShop}?category=cpu'},
      {'icon': Icons.videogame_asset, 'label': 'GPU', 'route': '${Routes.partShop}?category=gpu'},
      {'icon': Icons.developer_board, 'label': '메인보드', 'route': '${Routes.partShop}?category=mainboard'},
      {'icon': Icons.dns, 'label': 'RAM', 'route': '${Routes.partShop}?category=ram'},
      {'icon': Icons.storage, 'label': '저장장치', 'route': '${Routes.partShop}?category=ssd'},
    ];

    return ResponsiveHelper.centeredMaxWidthContainer(
      context: context,
      child: Padding(
        padding: ResponsiveHelper.getHorizontalPadding(context),
        child: Column(
          children: [
            Text(
              '카테고리별 부품 찾기',
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: spacing),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: ResponsiveHelper.getGridCrossAxisCount(
                  context,
                  twoColumnOnMobile: false,
                ).clamp(3, 6),
                childAspectRatio: 1.3,
                crossAxisSpacing: 24,
                mainAxisSpacing: 24,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                return _buildCategoryCard(
                  context,
                  icon: cat['icon'] as IconData,
                  label: cat['label'] as String,
                  onTap: () => context.go(cat['route'] as String),
                  isMobile: isMobile,
                  isTablet: isTablet,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isMobile = false,
    bool isTablet = false,
  }) {
    final iconSize = isMobile ? 36.0 : isTablet ? 42.0 : 48.0;
    final fontSize = isMobile ? 13.0 : isTablet ? 14.0 : 16.0;
    final spacing = isMobile ? 8.0 : 12.0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              offset: const Offset(0, 4),
              blurRadius: 12,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: iconSize,
              color: Theme.of(context).primaryColor,
            ),
            SizedBox(height: spacing),
            Text(
              label,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedSection(BuildContext context, WidgetRef ref, String title, String subtitle) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final isTablet = ResponsiveHelper.isTablet(context);

    final titleSize = isMobile ? 24.0 : isTablet ? 28.0 : 32.0;
    final subtitleSize = isMobile ? 13.0 : isTablet ? 14.0 : 16.0;
    final spacing = isMobile ? 20.0 : isTablet ? 24.0 : 32.0;

    return ResponsiveHelper.centeredMaxWidthContainer(
      context: context,
      child: Padding(
        padding: ResponsiveHelper.getHorizontalPadding(context),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: titleSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: isMobile ? 4 : 8),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: subtitleSize,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isMobile)
                  TextButton(
                    onPressed: () => context.go(Routes.partShop),
                    child: const Row(
                      children: [
                        Text('전체 보기'),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward, size: 18),
                      ],
                    ),
                  ),
              ],
            ),
            SizedBox(height: spacing),
            _buildProductGrid(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildProductGrid(BuildContext context, WidgetRef ref) {
    // Load real listings from Firestore
    final listingsAsync = ref.watch(
      listingsFutureProvider(ListingQueryParams(category: 'All', sortBy: '최신순')),
    );

    return listingsAsync.when(
      data: (listings) {
        // Show first 8 items
        final displayListings = listings.take(8).toList();

        if (displayListings.isEmpty) {
          return Container(
            height: 200,
            alignment: Alignment.center,
            child: Text(
              '등록된 상품이 없습니다',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: ResponsiveHelper.getGridCrossAxisCount(context),
            childAspectRatio: 0.75,
            crossAxisSpacing: 24,
            mainAxisSpacing: 24,
          ),
          itemCount: displayListings.length,
          itemBuilder: (context, index) {
            return _buildProductCard(context, displayListings[index]);
          },
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Container(
        height: 200,
        alignment: Alignment.center,
        child: Text(
          '상품을 불러올 수 없습니다',
          style: TextStyle(color: Colors.grey[600], fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, ListingEntity listing) {
    return InkWell(
      onTap: () => context.go('${Routes.listingDetail}/${listing.listingId}'),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              offset: const Offset(0, 2),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: listing.imageUrls.isNotEmpty
                  ? Semantics(
                      label: '${listing.brand} ${listing.modelName} 상품 이미지',
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                        child: Image.network(
                          listing.imageUrls.first,
                          width: double.infinity,
                          height: 180,
                          fit: BoxFit.cover,
                          cacheWidth: 400, // Optimize memory usage
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Icon(
                                Icons.broken_image,
                                size: 64,
                                color: Colors.grey[300],
                              ),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                        ),
                      ),
                    )
                  : Semantics(
                      label: '이미지 없음',
                      child: Center(
                        child: Icon(
                          Icons.image,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${listing.brand} ${listing.modelName}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₩${listing.price.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
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

  // ignore: unused_element
  Widget _buildSpecialOffers(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final isTablet = ResponsiveHelper.isTablet(context);

    final titleSize = isMobile ? 24.0 : isTablet ? 28.0 : 32.0;
    final subtitleSize = isMobile ? 14.0 : isTablet ? 16.0 : 18.0;
    final buttonFontSize = isMobile ? 14.0 : isTablet ? 16.0 : 18.0;
    final verticalPadding = isMobile ? 40.0 : isTablet ? 60.0 : 80.0;
    final spacing = isMobile ? 24.0 : 40.0;
    final buttonPadding = EdgeInsets.symmetric(
      horizontal: isMobile ? 32.0 : isTablet ? 48.0 : 64.0,
      vertical: isMobile ? 16.0 : isTablet ? 20.0 : 24.0,
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: verticalPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.shade50,
            Colors.red.shade50,
          ],
        ),
      ),
      child: ResponsiveHelper.centeredMaxWidthContainer(
        context: context,
        child: Padding(
          padding: ResponsiveHelper.getHorizontalPadding(context),
          child: Column(
            children: [
              Text(
                '특별 혜택',
                style: TextStyle(
                  fontSize: titleSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: isMobile ? 12 : 16),
              Text(
                '지금 가입하고 다양한 혜택을 받으세요',
                style: TextStyle(
                  fontSize: subtitleSize,
                  color: Colors.grey[700],
                ),
                textAlign: isMobile ? TextAlign.center : TextAlign.left,
              ),
              SizedBox(height: spacing),
              ElevatedButton(
                onPressed: () => context.go(Routes.auth),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  padding: buttonPadding,
                  textStyle: TextStyle(
                    fontSize: buttonFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: const Text('무료 회원가입'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWhyChooseUs(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final isTablet = ResponsiveHelper.isTablet(context);

    final titleSize = isMobile ? 24.0 : isTablet ? 28.0 : 32.0;

    final features = [
      {
        'icon': Icons.verified_user,
        'title': '안전한 거래',
        'description': '카카오페이 결제로\n안심하고 거래하세요',
      },
      {
        'icon': Icons.trending_up,
        'title': '실시간 시세',
        'description': '부품별 실시간 가격을\n투명하게 확인',
      },
      {
        'icon': Icons.inventory,
        'title': '무료 보관',
        'description': 'PC 보관함으로\n7일 무료 보관',
      },
      {
        'icon': Icons.support_agent,
        'title': '24/7 고객지원',
        'description': '언제든지 문의하세요\n빠른 응답 보장',
      },
    ];

    return ResponsiveHelper.centeredMaxWidthContainer(
      context: context,
      child: Padding(
        padding: ResponsiveHelper.getHorizontalPadding(context),
        child: Column(
          children: [
            Text(
              'PiCom을 선택하는 이유',
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 48),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: ResponsiveHelper.isDesktop(context) ? 4 : 2,
                childAspectRatio: 1,
                crossAxisSpacing: 32,
                mainAxisSpacing: 32,
              ),
              itemCount: features.length,
              itemBuilder: (context, index) {
                final feature = features[index];
                return _buildFeatureCard(
                  context,
                  icon: feature['icon'] as IconData,
                  title: feature['title'] as String,
                  description: feature['description'] as String,
                  isMobile: isMobile,
                  isTablet: isTablet,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    bool isMobile = false,
    bool isTablet = false,
  }) {
    final iconSize = isMobile ? 40.0 : isTablet ? 48.0 : 56.0;
    final titleSize = isMobile ? 15.0 : isTablet ? 16.0 : 18.0;
    final descSize = isMobile ? 12.0 : isTablet ? 13.0 : 14.0;
    final padding = isMobile ? 20.0 : isTablet ? 24.0 : 32.0;
    final spacing = isMobile ? 12.0 : isTablet ? 16.0 : 20.0;

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: iconSize,
            color: Theme.of(context).primaryColor,
          ),
          SizedBox(height: spacing),
          Text(
            title,
            style: TextStyle(
              fontSize: titleSize,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isMobile ? 8 : 12),
          Text(
            description,
            style: TextStyle(
              fontSize: descSize,
              color: Colors.grey[600],
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStats(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final isTablet = ResponsiveHelper.isTablet(context);

    final numberSize = isMobile ? 32.0 : isTablet ? 40.0 : 48.0;
    final labelSize = isMobile ? 12.0 : isTablet ? 14.0 : 16.0;
    final verticalPadding = isMobile ? 40.0 : isTablet ? 50.0 : 60.0;

    final stats = [
      {'number': '10,000+', 'label': '거래 완료'},
      {'number': '5,000+', 'label': '활성 사용자'},
      {'number': '98%', 'label': '만족도'},
      {'number': '24/7', 'label': '고객 지원'},
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: verticalPadding),
      color: Theme.of(context).primaryColor,
      child: ResponsiveHelper.centeredMaxWidthContainer(
        context: context,
        child: Padding(
          padding: ResponsiveHelper.getHorizontalPadding(context),
          child: isMobile
              ? Column(
                  children: stats.map((stat) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Column(
                        children: [
                          Text(
                            stat['number']!,
                            style: TextStyle(
                              fontSize: numberSize,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: isMobile ? 4 : 8),
                          Text(
                            stat['label']!,
                            style: TextStyle(
                              fontSize: labelSize,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: stats.map((stat) {
                    return Column(
                      children: [
                        Text(
                          stat['number']!,
                          style: TextStyle(
                            fontSize: numberSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: isMobile ? 4 : 8),
                        Text(
                          stat['label']!,
                          style: TextStyle(
                            fontSize: labelSize,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
        ),
      ),
    );
  }
}

/// Hero Banner Carousel Widget
class HeroBannerCarousel extends StatefulWidget {
  const HeroBannerCarousel({super.key});

  @override
  State<HeroBannerCarousel> createState() => _HeroBannerCarouselState();
}

class _HeroBannerCarouselState extends State<HeroBannerCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _autoSlideTimer;

  // 배너 이미지 목록 (Firebase Storage 또는 assets)
  final List<Map<String, String>> banners = [
    {
      'image': 'assets/images/banner_pc_warranty.png', // 이미지를 assets/images/ 폴더에 저장하세요
      'title': '나만의 PC, 이제 안전하게 시작하세요',
      'subtitle': '원하는 부품 먼저 결제! 안전 보관부터 일괄 배송까지 책임집니다.',
      'route': '/pc-storage',
    },
  ];

  @override
  void initState() {
    super.initState();
    // 배너가 1개이므로 자동 슬라이드 비활성화
    // 배너가 여러개일 때만 자동 슬라이드 활성화
    if (banners.length > 1) {
      _autoSlideTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (!mounted) return;

        final nextPage = (_currentPage + 1) % banners.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final isTablet = ResponsiveHelper.isTablet(context);
    final screenHeight = MediaQuery.of(context).size.height;

    // 반응형 높이
    final bannerHeight = isMobile
        ? 400.0
        : isTablet
            ? 450.0
            : (screenHeight * 0.7).clamp(500.0, 600.0);

    return SizedBox(
      height: bannerHeight,
      width: double.infinity,
      child: Stack(
        children: [
          // PageView for banner images
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: banners.length,
            itemBuilder: (context, index) {
              return _buildBannerItem(
                context,
                banners[index],
                isMobile,
                isTablet,
              );
            },
          ),

          // Navigation arrows (desktop only)
          if (!isMobile) ...[
            // Left arrow
            Positioned(
              left: 20,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton(
                  onPressed: () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 30),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
            // Right arrow
            Positioned(
              right: 20,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton(
                  onPressed: () {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  icon: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 30),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
          ],

          // Dots indicator
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                banners.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerItem(
    BuildContext context,
    Map<String, String> banner,
    bool isMobile,
    bool isTablet,
  ) {
    final titleSize = isMobile ? 32.0 : isTablet ? 42.0 : 56.0;
    final subtitleSize = isMobile ? 14.0 : isTablet ? 18.0 : 24.0;
    final buttonFontSize = isMobile ? 14.0 : isTablet ? 16.0 : 18.0;

    return InkWell(
      onTap: () => context.go(banner['route']!),
      child: Semantics(
        label: '${banner['title']} 배너 이미지',
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(banner['image']!),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.black.withValues(alpha: 0.7),
                  Colors.black.withValues(alpha: 0.3),
                ],
              ),
            ),
          child: ResponsiveHelper.centeredMaxWidthContainer(
            context: context,
            child: Padding(
              padding: ResponsiveHelper.getHorizontalPadding(context),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    banner['title']!,
                    style: TextStyle(
                      fontSize: titleSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: isMobile ? 12 : 20),
                  Text(
                    banner['subtitle']!,
                    style: TextStyle(
                      fontSize: subtitleSize,
                      color: Colors.white.withValues(alpha: 0.9),
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: isMobile ? 24 : 40),
                  ElevatedButton(
                    onPressed: () => context.go(banner['route']!),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 24.0 : isTablet ? 32.0 : 48.0,
                        vertical: isMobile ? 14.0 : isTablet ? 18.0 : 24.0,
                      ),
                      textStyle: TextStyle(
                        fontSize: buttonFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: const Text('지금 보기'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }
}
