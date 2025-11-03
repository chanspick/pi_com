// lib/features/my_page/presentation/providers/favorites_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/repositories/favorites_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/models/listing_model.dart';

/// Favorites Repository Provider
final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  return FavoritesRepository();
});

/// 찜 목록 ID Stream Provider
final favoritesIdsProvider = StreamProvider.autoDispose<List<String>>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) {
    return Stream.value([]);
  }

  final repository = ref.watch(favoritesRepositoryProvider);
  return repository.getFavoritesStream(currentUser.uid);
});

/// 특정 listing이 찜인지 확인하는 Provider
final isFavoriteProvider = FutureProvider.autoDispose.family<bool, String>((ref, listingId) async {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) {
    return false;
  }

  final repository = ref.watch(favoritesRepositoryProvider);
  return repository.isFavorite(currentUser.uid, listingId);
});

/// 찜 목록 전체 Listing Provider
final favoritesListingsProvider = FutureProvider.autoDispose<List<Listing>>((ref) async {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) {
    return [];
  }

  // 찜 목록 ID 조회
  final repository = ref.watch(favoritesRepositoryProvider);
  final favoritesIds = await repository.getFavorites(currentUser.uid);

  if (favoritesIds.isEmpty) {
    return [];
  }

  // Firestore 제한: in 쿼리는 최대 10개까지
  // 10개씩 끊어서 조회
  final List<Listing> allListings = [];

  for (int i = 0; i < favoritesIds.length; i += 10) {
    final batch = favoritesIds.skip(i).take(10).toList();

    final snapshot = await FirebaseFirestore.instance
        .collection('listings')
        .where(FieldPath.documentId, whereIn: batch)
        .get();

    final listings = snapshot.docs
        .map((doc) => Listing.fromFirestore(doc))
        .toList();

    allListings.addAll(listings);
  }

  return allListings;
});

/// 찜 추가/제거 액션
class FavoritesActions {
  final FavoritesRepository _repository;
  final String _userId;

  FavoritesActions(this._repository, this._userId);

  Future<void> toggleFavorite(String listingId) async {
    final isFav = await _repository.isFavorite(_userId, listingId);
    if (isFav) {
      await _repository.removeFavorite(_userId, listingId);
    } else {
      await _repository.addFavorite(_userId, listingId);
    }
  }

  Future<void> addFavorite(String listingId) async {
    await _repository.addFavorite(_userId, listingId);
  }

  Future<void> removeFavorite(String listingId) async {
    await _repository.removeFavorite(_userId, listingId);
  }
}

final favoritesActionsProvider = Provider.autoDispose<FavoritesActions?>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) return null;

  final repository = ref.watch(favoritesRepositoryProvider);
  return FavoritesActions(repository, currentUser.uid);
});
