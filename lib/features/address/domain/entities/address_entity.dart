// lib/features/address/domain/entities/address_entity.dart

class AddressEntity {
  final String addressId;
  final String recipientName;
  final String recipientPhone;
  final String zonecode;
  final String roadAddress;
  final String jibunAddress;
  final String buildingName;
  final String detailAddress;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  AddressEntity({
    required this.addressId,
    required this.recipientName,
    required this.recipientPhone,
    required this.zonecode,
    required this.roadAddress,
    required this.jibunAddress,
    required this.buildingName,
    required this.detailAddress,
    required this.isDefault,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 전체 주소 문자열 (한 줄)
  String get fullAddressOneLine {
    final building = buildingName.isNotEmpty ? ' $buildingName' : '';
    return '($zonecode) $roadAddress$building, $detailAddress';
  }

  /// 전체 주소 문자열 (여러 줄)
  String get fullAddressMultiLine {
    final building = buildingName.isNotEmpty ? ' $buildingName' : '';
    return '($zonecode)\n$roadAddress$building\n$detailAddress';
  }

  /// 기본 주소 (우편번호 + 도로명)
  String get basicAddress {
    final building = buildingName.isNotEmpty ? ' $buildingName' : '';
    return '($zonecode) $roadAddress$building';
  }

  AddressEntity copyWith({
    String? addressId,
    String? recipientName,
    String? recipientPhone,
    String? zonecode,
    String? roadAddress,
    String? jibunAddress,
    String? buildingName,
    String? detailAddress,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AddressEntity(
      addressId: addressId ?? this.addressId,
      recipientName: recipientName ?? this.recipientName,
      recipientPhone: recipientPhone ?? this.recipientPhone,
      zonecode: zonecode ?? this.zonecode,
      roadAddress: roadAddress ?? this.roadAddress,
      jibunAddress: jibunAddress ?? this.jibunAddress,
      buildingName: buildingName ?? this.buildingName,
      detailAddress: detailAddress ?? this.detailAddress,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
