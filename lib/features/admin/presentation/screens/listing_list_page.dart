// lib/features/admin/presentation/screens/listing_list_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pi_com/features/listing/domain/entities/listing_entity.dart';
import 'package:pi_com/features/listing/presentation/providers/listing_provider.dart';

class ListingListPage extends ConsumerWidget {
  const ListingListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingsAsync = ref.watch(listingsFutureProvider(ListingQueryParams()));

    return Scaffold(
      appBar: AppBar(title: const Text('매물 관리')),
      body: Column(
        children: [
          // TODO: Add search and filter UI
          Expanded(
            child: listingsAsync.when(
              data: (listings) {
                if (listings.isEmpty) {
                  return const Center(child: Text('매물이 없습니다.'));
                }
                return ListView.builder(
                  itemCount: listings.length,
                  itemBuilder: (context, index) {
                    final listing = listings[index];
                    return ListTile(
                      title: Text(listing.modelName),
                      subtitle: Text('${listing.brand} / ${listing.price}원'),
                      trailing: Text(listing.status.name),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('에러 발생: $err')),
            ),
          ),
        ],
      ),
    );
  }
}
