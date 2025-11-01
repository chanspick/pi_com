// lib/main.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';  // ✅ 추가

import 'firebase_options.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ===== Firebase 초기화 =====
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint('✅ Firebase initialized');

  // ===== App Check 초기화 =====
  if (kIsWeb) {
    await FirebaseAppCheck.instance.activate(
      providerWeb: ReCaptchaV3Provider('recaptcha-v3-site-key'),
    );
    debugPrint('✅ Firebase App Check activated (Web)');
  } else {
    await FirebaseAppCheck.instance.activate();
    debugPrint('✅ Firebase App Check activated (Android)');
  }

  // ===== Firestore 설정 =====
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // ✅ ProviderScope 추가
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}
