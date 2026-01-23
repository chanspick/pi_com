// lib/main.dart

import 'dart:async';  // TimeoutException을 위해 추가
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kakao_flutter_sdk_common/kakao_flutter_sdk_common.dart';
import 'package:pi_com/core/utils/app_logger.dart';

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
          AppLogger.w('.env file loading timed out', tag: 'Main');
        },
      );
      AppLogger.i('.env file loaded', tag: 'Main');
    } catch (e) {
      AppLogger.w('.env file not found: $e', tag: 'Main');
    }
  } else {
    AppLogger.i('.env loading skipped on web', tag: 'Main');
  }

  // ===== 카카오 SDK 초기화 =====
  try {
    KakaoSdk.init(
      nativeAppKey: dotenv.env['KAKAO_NATIVE_KEY'] ?? '',
      javaScriptAppKey: dotenv.env['KAKAO_JS_KEY'] ?? '',
    );
    AppLogger.i('Kakao SDK initialized', tag: 'Main');
  } catch (e) {
    AppLogger.w('Kakao SDK initialization failed: $e', tag: 'Main');
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
    AppLogger.i('Firebase initialized', tag: 'Main');
  } catch (e) {
    AppLogger.e('Firebase initialization failed: $e', tag: 'Main');
    // Firebase 실패는 치명적이므로 에러 표시하고 계속 진행
  }

  // ===== App Check 초기화 =====
  // 개발 환경에서는 App Check 비활성화
  if (kReleaseMode) {
    try {
      if (kIsWeb) {
        // 웹에서는 reCAPTCHA 키가 유효한 경우에만 활성화
        // 개발 중에는 비활성화
        AppLogger.w('App Check skipped on web (configure reCAPTCHA key in production)', tag: 'Main');
      } else {
        await FirebaseAppCheck.instance.activate().timeout(
          const Duration(seconds: 5),
        );
        AppLogger.i('Firebase App Check activated (Android)', tag: 'Main');
      }
    } catch (e) {
      AppLogger.w('Firebase App Check activation failed: $e', tag: 'Main');
    }
  } else {
    AppLogger.w('Firebase App Check disabled (Debug mode)', tag: 'Main');
  }

  // ===== Firestore 설정 =====
  try {
    // 웹에서는 persistenceEnabled가 항상 true이므로 설정 스킵
    if (!kIsWeb) {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: false,  // 로컬 캐시 완전 비활성화
        cacheSizeBytes: 1048576,    // 최소 캐시 (1MB)
      );
      AppLogger.i('Firestore settings applied', tag: 'Main');
    } else {
      AppLogger.i('Firestore persistence settings skipped on web', tag: 'Main');
    }

    // 기존 캐시 삭제 - 웹에서는 작동하지 않으므로 스킵
    if (!kIsWeb) {
      try {
        await FirebaseFirestore.instance.clearPersistence().timeout(
          const Duration(seconds: 3),
        );
        AppLogger.i('Firestore cache cleared', tag: 'Main');
      } catch (e) {
        AppLogger.w('Failed to clear cache: $e', tag: 'Main');
      }
    } else {
      AppLogger.i('Firestore cache clearing skipped on web', tag: 'Main');
    }
  } catch (e) {
    AppLogger.w('Firestore configuration failed: $e', tag: 'Main');
  }

  // ✅ ProviderScope 추가
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}
