// lib/core/constants/firebase_constants.dart

class FirebaseConstants {
  FirebaseConstants._();

  // ===== Collections =====
  static const String usersCollection = 'users';
  static const String notificationsCollection = 'notifications';
  static const String sellRequestsCollection = 'sellRequests';  // ✅ 한 번만!
  static const String listingsCollection = 'listings';
  static const String basePartsCollection = 'baseParts';
  static const String partsCollection = 'parts';

  // ===== Sub-collections =====
  static const String sellRequestImagesSubCollection = 'images';

  // ===== Fields =====
  static const String userIdField = 'userId';
  static const String statusField = 'status';
  static const String createdAtField = 'createdAt';
}
