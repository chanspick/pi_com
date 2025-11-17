// lib/core/utils/responsive_helper.dart

import 'package:flutter/material.dart';

/// 반응형 디자인을 위한 헬퍼 클래스
///
/// 화면 크기에 따라 레이아웃을 조정하는 유틸리티 메서드 제공
class ResponsiveHelper {
  // 브레이크포인트 정의
  static const double mobileBreakpoint = 768;
  static const double tabletBreakpoint = 1024;
  static const double desktopBreakpoint = 1440;

  /// 모바일 여부 확인 (< 768px)
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  /// 태블릿 여부 확인 (768px - 1024px)
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  /// 데스크톱 여부 확인 (>= 1024px)
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletBreakpoint;
  }

  /// 대형 데스크톱 여부 확인 (>= 1440px)
  static bool isLargeDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopBreakpoint;
  }

  /// 그리드 열 개수 반환
  /// - 모바일: 1열 또는 2열
  /// - 태블릿: 3열
  /// - 데스크톱: 4열
  static int getGridCrossAxisCount(BuildContext context, {bool twoColumnOnMobile = true}) {
    if (isLargeDesktop(context)) return 5;
    if (isDesktop(context)) return 4;
    if (isTablet(context)) return 3;
    return twoColumnOnMobile ? 2 : 1;
  }

  /// 최대 컨텐츠 너비 반환 (데스크톱에서 너무 넓어지지 않도록)
  static double getMaxContentWidth(BuildContext context) {
    if (isLargeDesktop(context)) return 1400;
    if (isDesktop(context)) return 1200;
    if (isTablet(context)) return 900;
    return double.infinity; // 모바일은 전체 너비 사용
  }

  /// 화면 크기에 따른 패딩 반환
  static EdgeInsets getPagePadding(BuildContext context) {
    if (isDesktop(context)) {
      return const EdgeInsets.symmetric(horizontal: 80, vertical: 40);
    } else if (isTablet(context)) {
      return const EdgeInsets.symmetric(horizontal: 40, vertical: 24);
    }
    return const EdgeInsets.symmetric(horizontal: 16, vertical: 16);
  }

  /// 화면 크기에 따른 수평 패딩 반환
  static EdgeInsets getHorizontalPadding(BuildContext context) {
    if (isDesktop(context)) {
      return const EdgeInsets.symmetric(horizontal: 80);
    } else if (isTablet(context)) {
      return const EdgeInsets.symmetric(horizontal: 40);
    }
    return const EdgeInsets.symmetric(horizontal: 16);
  }

  /// 반응형 폰트 크기 반환
  static double getResponsiveFontSize(BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    if (isDesktop(context)) return desktop ?? tablet ?? mobile;
    if (isTablet(context)) return tablet ?? mobile;
    return mobile;
  }

  /// 반응형 위젯 빌더
  /// 화면 크기에 따라 다른 위젯 반환
  static Widget responsiveBuilder({
    required BuildContext context,
    required Widget mobile,
    Widget? tablet,
    Widget? desktop,
  }) {
    if (isDesktop(context)) return desktop ?? tablet ?? mobile;
    if (isTablet(context)) return tablet ?? mobile;
    return mobile;
  }

  /// 중앙 정렬된 최대 너비 컨테이너
  static Widget centeredMaxWidthContainer({
    required BuildContext context,
    required Widget child,
    Color? backgroundColor,
  }) {
    return Container(
      color: backgroundColor,
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: getMaxContentWidth(context),
        ),
        child: child,
      ),
    );
  }

  /// 2단 레이아웃 (데스크톱: 좌우 분할, 모바일: 세로 스택)
  static Widget twoColumnLayout({
    required BuildContext context,
    required Widget left,
    required Widget right,
    double leftFlex = 1,
    double rightFlex = 1,
    double spacing = 24,
  }) {
    if (isMobile(context)) {
      return Column(
        children: [
          left,
          SizedBox(height: spacing),
          right,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: leftFlex.toInt(),
          child: left,
        ),
        SizedBox(width: spacing),
        Expanded(
          flex: rightFlex.toInt(),
          child: right,
        ),
      ],
    );
  }

  /// 3단 레이아웃 (데스크톱 전용, 나머지는 세로 스택)
  static Widget threeColumnLayout({
    required BuildContext context,
    required Widget left,
    required Widget center,
    required Widget right,
    double spacing = 24,
  }) {
    if (!isDesktop(context)) {
      return Column(
        children: [
          left,
          SizedBox(height: spacing),
          center,
          SizedBox(height: spacing),
          right,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 1, child: left),
        SizedBox(width: spacing),
        Expanded(flex: 2, child: center),
        SizedBox(width: spacing),
        Expanded(flex: 1, child: right),
      ],
    );
  }

  /// 사이드바 레이아웃 (데스크톱: 좌측 사이드바 + 메인, 모바일: 세로 스택)
  static Widget sidebarLayout({
    required BuildContext context,
    required Widget sidebar,
    required Widget main,
    double sidebarWidth = 280,
    double spacing = 24,
  }) {
    if (isMobile(context)) {
      return Column(
        children: [
          sidebar,
          SizedBox(height: spacing),
          main,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: sidebarWidth,
          child: sidebar,
        ),
        SizedBox(width: spacing),
        Expanded(child: main),
      ],
    );
  }
}
