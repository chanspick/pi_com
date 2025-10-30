// lib/features/listing/presentation/widgets/listing_header.dart
import 'package:flutter/material.dart';
import '../../domain/entities/listing_entity.dart';

class ListingHeader extends StatelessWidget {
  final ListingEntity listing;

  const ListingHeader({super.key, required this.listing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            listing.brand,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(listing.modelName, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 4),
          Text(
            '컨디션: ${listing.conditionScore}',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
