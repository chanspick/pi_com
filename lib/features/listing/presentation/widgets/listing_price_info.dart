// lib/features/listing/presentation/widgets/listing_price_info.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/listing_entity.dart';

class ListingPriceInfo extends StatelessWidget {
  final ListingEntity listing;

  const ListingPriceInfo({super.key, required this.listing});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###');

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '판매 가격',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(
            '${formatter.format(listing.price)}원',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}
