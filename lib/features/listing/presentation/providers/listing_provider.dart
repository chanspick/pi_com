// lib/features/listing/presentation/providers/listing_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pi_com/features/listing/data/repositories/listing_repository_impl.dart';
import 'package:pi_com/features/listing/domain/entities/listing_entity.dart';
import 'package:pi_com/features/listing/domain/usecases/get_listings_usecase.dart';
import 'package:pi_com/features/listing/domain/usecases/get_listing_usecase.dart';
import '../../data/datasources/listing_remote_datasource.dart';
import '../../domain/repositories/listing_repository.dart';

// 🆕 무한 스크롤을 위한 상태 클래스
class PaginatedListingsState {
  final List<ListingEntity> listings;
  final bool isLoading;
  final bool hasMore;
  final dynamic lastDocument;
  final String? error;

  PaginatedListingsState({
    this.listings = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.lastDocument,
    this.error,
  });

  PaginatedListingsState copyWith({
    List<ListingEntity>? listings,
    bool? isLoading,
    bool? hasMore,
    dynamic lastDocument,
    String? error,
  }) {
    return PaginatedListingsState(
      listings: listings ?? this.listings,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      lastDocument: lastDocument ?? this.lastDocument,
      error: error ?? this.error,
    );
  }
}

// 🆕 무한 스크롤 컨트롤러 (StateNotifier)
class PaginatedListingsNotifier extends StateNotifier<PaginatedListingsState> {
  final ListingRepository repository;
  final ListingQueryParams params;

  PaginatedListingsNotifier({
    required this.repository,
    required this.params,
  }) : super(PaginatedListingsState()) {
    // 초기 로드
    loadInitial();
  }

  /// 초기 로드 (실시간 데이터)
  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await repository.getListingsPaginated(
        category: params.category,
        sortBy: params.sortBy,
        searchQuery: params.searchQuery,
        includeAllStatuses: params.includeAllStatuses,
        limit: 20,
        useCache: false, // 중고 거래 플랫폼 특성상 항상 최신 데이터
      );

      state = PaginatedListingsState(
        listings: result.listings,
        isLoading: false,
        hasMore: result.hasMore,
        lastDocument: result.lastDocument,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// 다음 페이지 로드
  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);

    try {
      final result = await repository.getListingsPaginated(
        category: params.category,
        sortBy: params.sortBy,
        searchQuery: params.searchQuery,
        includeAllStatuses: params.includeAllStatuses,
        limit: 20,
        lastDocument: state.lastDocument,
        useCache: false, // 중고 거래 플랫폼 특성상 항상 최신 데이터
      );

      state = PaginatedListingsState(
        listings: [...state.listings, ...result.listings],
        isLoading: false,
        hasMore: result.hasMore,
        lastDocument: result.lastDocument,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// 새로고침 (Pull-to-refresh, 서버 강제)
  Future<void> refresh() async {
    state = PaginatedListingsState(isLoading: true); // 완전 초기화

    try {
      final result = await repository.getListingsPaginated(
        category: params.category,
        sortBy: params.sortBy,
        searchQuery: params.searchQuery,
        includeAllStatuses: params.includeAllStatuses,
        limit: 20,
        useCache: false, // 새로고침은 서버 강제
      );

      state = PaginatedListingsState(
        listings: result.listings,
        isLoading: false,
        hasMore: result.hasMore,
        lastDocument: result.lastDocument,
      );
    } catch (e) {
      state = PaginatedListingsState(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}

class ListingQueryParams {
  final String? category;
  final String? sortBy;
  final String? searchQuery;  // 검색어 추가
  final bool includeAllStatuses;  // Admin용: 모든 상태 포함

  ListingQueryParams({
    this.category,
    this.sortBy,
    this.searchQuery,
    this.includeAllStatuses = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ListingQueryParams &&
          runtimeType == other.runtimeType &&
          category == other.category &&
          sortBy == other.sortBy &&
          searchQuery == other.searchQuery &&
          includeAllStatuses == other.includeAllStatuses;

  @override
  int get hashCode => category.hashCode ^ sortBy.hashCode ^ searchQuery.hashCode ^ includeAllStatuses.hashCode;
}

final selectedCategoryProvider = StateProvider<String>((ref) => 'All');

final selectedSortProvider = StateProvider<String>((ref) => '최신순');

final searchQueryProvider = StateProvider<String?>((ref) => null);

final selectedBasePartIdProvider = StateProvider<String?>((ref) => null);

final selectedBasePartIdsProvider = StateProvider<List<String>>((ref) => []);

final basePartSearchQueryProvider = StateProvider<String?>((ref) => null);

final listingRemoteDataSourceProvider = Provider<ListingRemoteDataSource>((ref) {
  return ListingRemoteDataSourceImpl(firestore: FirebaseFirestore.instance);
});

final listingRepositoryProvider = Provider<ListingRepository>((ref) {
  return ListingRepositoryImpl(remoteDataSource: ref.watch(listingRemoteDataSourceProvider));
});

final getListingsProvider = Provider<GetListingsUseCase>((ref) {
  return GetListingsUseCase(ref.watch(listingRepositoryProvider));
});

final getListingProvider = Provider<GetListingUseCase>((ref) {
  return GetListingUseCase(repository: ref.watch(listingRepositoryProvider));
});

// ✅ .first 제거 - getListings()가 이제 Future를 반환하므로 바로 사용
final listingsFutureProvider = FutureProvider.autoDispose.family<List<ListingEntity>, ListingQueryParams>((ref, params) {
  return ref.watch(getListingsProvider).call(
    category: params.category,
    sortBy: params.sortBy,
    searchQuery: params.searchQuery,
    includeAllStatuses: params.includeAllStatuses,
  );
});

// ✅ 단일 listing은 Stream으로 유지 (실시간 업데이트 필요할 수 있음)
final listingProvider = StreamProvider.autoDispose.family<ListingEntity, String>((ref, id) {
  return ref.watch(getListingProvider).call(id);
});

// basePartId로 필터링된 listings
final listingsByBasePartIdProvider = FutureProvider.autoDispose.family<List<ListingEntity>, String>((ref, basePartId) async {
  final repository = ref.watch(listingRepositoryProvider);
  return repository.getListingsByBasePartId(basePartId);
});

// 여러 basePartId의 listings 합치기
final listingsByMultipleBasePartIdsProvider = FutureProvider.autoDispose.family<List<ListingEntity>, List<String>>((ref, basePartIds) async {
  if (basePartIds.isEmpty) {
    return [];
  }

  final repository = ref.watch(listingRepositoryProvider);
  final allListings = <ListingEntity>[];

  for (final basePartId in basePartIds) {
    final listings = await repository.getListingsByBasePartId(basePartId);
    allListings.addAll(listings);
  }

  // 최신순으로 정렬
  allListings.sort((a, b) => b.createdAt.compareTo(a.createdAt));

  return allListings;
});

// 🆕 페이지네이션을 지원하는 listings provider
final paginatedListingsProvider = StateNotifierProvider.autoDispose.family<PaginatedListingsNotifier, PaginatedListingsState, ListingQueryParams>((ref, params) {
  return PaginatedListingsNotifier(
    repository: ref.watch(listingRepositoryProvider),
    params: params,
  );
});
