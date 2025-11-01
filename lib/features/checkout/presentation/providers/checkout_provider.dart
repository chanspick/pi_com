
// lib/features/checkout/presentation/providers/checkout_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pi_com/features/cart/presentation/providers/cart_provider.dart';
import 'package:pi_com/features/checkout/domain/usecases/purchase_usecase.dart';
import 'package:pi_com/features/listing/presentation/providers/listing_provider.dart';
import 'package:pi_com/features/order/data/datasources/order_remote_datasource.dart';
import 'package:pi_com/features/order/data/datasources/order_remote_datasource_impl.dart';
import 'package:pi_com/features/order/data/repositories/order_repository_impl.dart';
import 'package:pi_com/features/order/domain/repositories/order_repository.dart';

final orderRemoteDataSourceProvider = Provider<OrderRemoteDataSource>((ref) {
  return OrderRemoteDataSourceImpl();
});

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  final remoteDataSource = ref.watch(orderRemoteDataSourceProvider);
  return OrderRepositoryImpl(remoteDataSource: remoteDataSource);
});

final purchaseUseCaseProvider = Provider<PurchaseUseCase>((ref) {
  final orderRepository = ref.watch(orderRepositoryProvider);
  final listingRepository = ref.watch(listingRepositoryProvider);
  final cartRepository = ref.watch(cartRepositoryProvider);
  return PurchaseUseCase(orderRepository, listingRepository, cartRepository);
});
