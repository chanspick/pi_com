// lib/features/listing/data/datasources/listing_remote_datasource.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/listing_model.dart';
import '../../domain/entities/listing_entity.dart';

abstract class ListingRemoteDataSource {
  Stream<ListingModel> getListing(String listingId);
  Stream<List<ListingModel>> getListings({String? category, String? sortBy});
  Future<void> updateListingStatus(String listingId, ListingStatus status);
}

class ListingRemoteDataSourceImpl implements ListingRemoteDataSource {
  final FirebaseFirestore _firestore;

  ListingRemoteDataSourceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<ListingModel> getListing(String listingId) {
    return _firestore
        .collection('listings')
        .doc(listingId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) {
        throw Exception('Listing not found');
      }
      return ListingModel.fromFirestore(doc);
    });
  }

  @override
  Stream<List<ListingModel>> getListings({String? category, String? sortBy}) {
    Query query = _firestore
        .collection('listings')
        .where('status', isEqualTo: 'active');

    if (category != null && category != 'All') {
      query = query.where('category', isEqualTo: category);
    }

    if (sortBy == '낮은 가격순') {
      query = query.orderBy('price', descending: false);
    } else if (sortBy == '높은 가격순') {
      query = query.orderBy('price', descending: true);
    } else {
      query = query.orderBy('createdAt', descending: true);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => ListingModel.fromFirestore(doc)).toList();
    });
  }

  @override
  Future<void> updateListingStatus(String listingId, ListingStatus status) async {
    await _firestore.collection('listings').doc(listingId).update({
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
