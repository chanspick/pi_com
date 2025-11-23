// lib/features/refund/presentation/providers/refund_provider.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/refund_remote_datasource.dart';
import '../../data/repositories/refund_repository_impl.dart';
import '../../domain/entities/refund_request_entity.dart';
import '../../domain/repositories/refund_repository.dart';

/// RefundRepository Provider
final refundRepositoryProvider = Provider<RefundRepository>((ref) {
  return RefundRepositoryImpl(
    remoteDataSource: RefundRemoteDataSource(
      firestore: FirebaseFirestore.instance,
    ),
  );
});

/// 현재 판매자의 환불 요청 목록 Provider
final sellerRefundsProvider = StreamProvider<List<RefundRequestEntity>>((ref) {
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) {
    return Stream.value([]);
  }

  final repository = ref.watch(refundRepositoryProvider);
  return repository.watchSellerRefundRequests(currentUser.uid);
});

/// 특정 환불 요청 상세 Provider
final refundDetailProvider =
    StreamProvider.autoDispose.family<RefundRequestEntity?, String>(
  (ref, refundId) {
    final repository = ref.watch(refundRepositoryProvider);
    return FirebaseFirestore.instance
        .collection('refunds')
        .doc(refundId)
        .snapshots()
        .asyncMap((doc) async {
      if (!doc.exists) return null;
      return repository.getRefundRequest(refundId);
    });
  },
);
