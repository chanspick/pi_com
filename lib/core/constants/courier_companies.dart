// lib/core/constants/courier_companies.dart

/// 택배사 목록
enum CourierCompany {
  cj('CJ대한통운', 'cj'),
  hanjin('한진택배', 'hanjin'),
  lotte('롯데택배', 'lotte'),
  post('우체국택배', 'post'),
  logen('로젠택배', 'logen'),
  coupang('쿠팡로켓배송', 'coupang');

  final String displayName;
  final String code;

  const CourierCompany(this.displayName, this.code);

  /// String code로 CourierCompany 찾기
  static CourierCompany fromCode(String code) {
    return CourierCompany.values.firstWhere(
      (e) => e.code == code,
      orElse: () => CourierCompany.cj, // 기본값
    );
  }

  /// displayName으로 CourierCompany 찾기
  static CourierCompany fromDisplayName(String displayName) {
    return CourierCompany.values.firstWhere(
      (e) => e.displayName == displayName,
      orElse: () => CourierCompany.cj,
    );
  }
}
