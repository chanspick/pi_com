
// lib/features/listing/presentation/providers/use_case_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/usecases/create_cart_item_usecase.dart';
import '../../domain/usecases/validate_purchase_usecase.dart';

final createCartItemUseCaseProvider = Provider<CreateCartItemUseCase>((ref) {
  return CreateCartItemUseCase();
});

final validatePurchaseUseCaseProvider = Provider<ValidatePurchaseUseCase>((ref) {
  return ValidatePurchaseUseCase();
});
