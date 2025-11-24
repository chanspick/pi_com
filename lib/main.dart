// lib/main.dart

import 'dart:async';  // ✅ TimeoutException을 위해 추가
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';  // ✅ 추가
import 'package:flutter_dotenv/flutter_dotenv.dart';  // ✅ 추가
import 'package:kakao_flutter_sdk_common/kakao_flutter_sdk_common.dart';  // ✅ 카카오 SDK

import 'firebase_options.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ===== 환경 변수 로드 =====
  // 웹에서는 .env 파일이 번들되지 않으므로 스킵
  if (!kIsWeb) {
    try {
      await dotenv.load(fileName: ".env").timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('⚠️ .env file loading timed out');
        },
      );
      debugPrint('✅ .env file loaded');
    } catch (e) {
      debugPrint('⚠️ .env file not found: $e');
    }
  } else {
    debugPrint('ℹ️ .env loading skipped on web');
  }

  // ===== 카카오 SDK 초기화 =====
  try {
    KakaoSdk.init(
      nativeAppKey: '8e75eecf0338c9b84861f8000b664336',
      javaScriptAppKey: 'aabc80253972e0504d05951a66373200',
    );
    debugPrint('✅ Kakao SDK initialized');
  } catch (e) {
    debugPrint('⚠️ Kakao SDK initialization failed: $e');
  }

  // ===== Firebase 초기화 =====
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        throw TimeoutException('Firebase initialization timed out');
      },
    );
    debugPrint('✅ Firebase initialized');
  } catch (e) {
    debugPrint('❌ Firebase initialization failed: $e');
    // Firebase 실패는 치명적이므로 에러 표시하고 계속 진행
  }

  // ===== App Check 초기화 =====
  // 개발 환경에서는 App Check 비활성화
  if (kReleaseMode) {
    try {
      if (kIsWeb) {
        // 웹에서는 reCAPTCHA 키가 유효한 경우에만 활성화
        // 개발 중에는 비활성화
        debugPrint('⚠️ App Check skipped on web (configure reCAPTCHA key in production)');
      } else {
        await FirebaseAppCheck.instance.activate().timeout(
          const Duration(seconds: 5),
        );
        debugPrint('✅ Firebase App Check activated (Android)');
      }
    } catch (e) {
      debugPrint('⚠️ Firebase App Check activation failed: $e');
    }
  } else {
    debugPrint('⚠️ Firebase App Check disabled (Debug mode)');
  }

  // ===== Firestore 설정 =====
  try {
    // 웹에서는 persistenceEnabled가 항상 true이므로 설정 스킵
    if (!kIsWeb) {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: false,  // 로컬 캐시 완전 비활성화
        cacheSizeBytes: 1048576,    // 최소 캐시 (1MB)
      );
      debugPrint('✅ Firestore settings applied');
    } else {
      debugPrint('ℹ️ Firestore persistence settings skipped on web');
    }

    // 🔥 기존 캐시 삭제 - 웹에서는 작동하지 않으므로 스킵
    if (!kIsWeb) {
      try {
        await FirebaseFirestore.instance.clearPersistence().timeout(
          const Duration(seconds: 3),
        );
        debugPrint('✅ Firestore cache cleared');
      } catch (e) {
        debugPrint('⚠️ Failed to clear cache: $e');
      }
    } else {
      debugPrint('ℹ️ Firestore cache clearing skipped on web');
    }
  } catch (e) {
    debugPrint('⚠️ Firestore configuration failed: $e');
  }

  // ✅ ProviderScope 추가
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}
