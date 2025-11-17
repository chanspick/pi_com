import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? photoURL;
  final String provider;         // 기본 provider (하위 호환성)
  final List<String> providers;  // 모든 연결된 providers
  final bool isAdmin;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoURL,
    required this.provider,
    List<String>? providers,
    this.isAdmin = false,
    required this.createdAt,
    this.lastLoginAt,
  }) : providers = providers ?? [provider];

  // ===== Firestore → UserModel =====
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final provider = data['provider'] as String? ?? 'unknown';
    final providersList = data['providers'] as List<dynamic>?;

    return UserModel(
      uid: doc.id,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String? ?? 'Unknown User',
      photoURL: data['photoURL'] as String?,
      provider: provider,
      providers: providersList?.map((e) => e.toString()).toList() ?? [provider],
      isAdmin: data['isAdmin'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLoginAt: (data['lastLoginAt'] as Timestamp?)?.toDate(),
    );
  }

  // ===== UserModel → Firestore =====
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'provider': provider,
      'providers': providers,
      'isAdmin': isAdmin,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': lastLoginAt != null
          ? Timestamp.fromDate(lastLoginAt!)
          : null,
    };
  }

  // ===== Firebase User → UserModel =====
  factory UserModel.fromFirebaseUser(
      User firebaseUser, {
        String? provider,
        bool? isAdmin,
      }) {
    return UserModel(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName ??
          (firebaseUser.isAnonymous ? 'Guest User' : 'Unknown User'),
      photoURL: firebaseUser.photoURL,
      provider: provider ?? 'unknown',
      isAdmin: isAdmin ?? false,
      createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
      lastLoginAt: DateTime.now(),
    );
  }

  // ===== 편의 메서드 =====
  bool get isAnonymous => providers.contains('anonymous');
  bool get isGoogleUser => providers.contains('google');
  bool get isKakaoUser => providers.contains('kakao');
  bool get hasMultipleProviders => providers.length > 1;

  // ===== copyWith =====
  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoURL,
    String? provider,
    List<String>? providers,
    bool? isAdmin,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      provider: provider ?? this.provider,
      providers: providers ?? this.providers,
      isAdmin: isAdmin ?? this.isAdmin,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, email: $email, displayName: $displayName, '
        'provider: $provider, isAdmin: $isAdmin)';
  }
}
