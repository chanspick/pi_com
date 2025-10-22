// lib/features/admin/presentation/screens/listing_list_page.dart
import 'package:flutter/material.dart';

class ListingListPage extends StatelessWidget {
  const ListingListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('매물 관리')),
      body: const Center(child: Text('매물 목록 (개발 예정)')),
    );
  }
}
