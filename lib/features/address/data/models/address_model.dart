// lib/features/address/data/models/address_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/address_entity.dart';

class AddressModel {
  final String addressId;
  final String recipientName;
  final String recipientPhone;
  final String zonecode;
  final String roadAddress;
  final String jibunAddress;
  final String buildingName;
  final String detailAddress;
  final bool isDefault;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  AddressModel({
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

  factory AddressModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AddressModel(
      addressId: doc.id,
      recipientName: data['recipientName'] ?? '',
      recipientPhone: data['recipientPhone'] ?? '',
      zonecode: data['zonecode'] ?? '',
      roadAddress: data['roadAddress'] ?? '',
      jibunAddress: data['jibunAddress'] ?? '',
      buildingName: data['buildingName'] ?? '',
      detailAddress: data['detailAddress'] ?? '',
      isDefault: data['isDefault'] ?? false,
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'recipientName': recipientName,
      'recipientPhone': recipientPhone,
      'zonecode': zonecode,
      'roadAddress': roadAddress,
      'jibunAddress': jibunAddress,
      'buildingName': buildingName,
      'detailAddress': detailAddress,
      'isDefault': isDefault,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  AddressEntity toEntity() {
    return AddressEntity(
      addressId: addressId,
      recipientName: recipientName,
      recipientPhone: recipientPhone,
      zonecode: zonecode,
      roadAddress: roadAddress,
      jibunAddress: jibunAddress,
      buildingName: buildingName,
      detailAddress: detailAddress,
      isDefault: isDefault,
      createdAt: createdAt.toDate(),
      updatedAt: updatedAt.toDate(),
    );
  }

  factory AddressModel.fromEntity(AddressEntity entity) {
    return AddressModel(
      addressId: entity.addressId,
      recipientName: entity.recipientName,
      recipientPhone: entity.recipientPhone,
      zonecode: entity.zonecode,
      roadAddress: entity.roadAddress,
      jibunAddress: entity.jibunAddress,
      buildingName: entity.buildingName,
      detailAddress: entity.detailAddress,
      isDefault: entity.isDefault,
      createdAt: Timestamp.fromDate(entity.createdAt),
      updatedAt: Timestamp.fromDate(entity.updatedAt),
    );
  }
}
