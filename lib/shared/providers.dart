// lib/shared/providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../features/auth/data/datasources/google_auth_datasource.dart';
import '../features/auth/data/datasources/firestore_user_datasource.dart';
import '../features/notification/data/datasources/notification_datasource.dart';

/// ========================================
/// Firebase 인스턴스 Providers
/// ========================================

/// FirebaseAuth 인스턴스
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

/// FirebaseFirestore 인스턴스
final firebaseFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

/// ========================================
/// Auth DataSource Providers
/// ========================================

/// Google Auth DataSource
final googleAuthDataSourceProvider = Provider<GoogleAuthDataSource>((ref) {
  return GoogleAuthDataSource();
});

/// Firestore User DataSource
final firestoreUserDataSourceProvider = Provider<FirestoreUserDataSource>((ref) {
  return FirestoreUserDataSource();
});

/// Notification DataSource
final notificationDataSourceProvider = Provider<NotificationDataSource>((ref) {
  return NotificationDataSourceImpl(
    firestore: ref.watch(firebaseFirestoreProvider),
  );
});