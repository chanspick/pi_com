// lib/main.dart

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
  try {
    await dotenv.load(fileName: ".env");
    debugPrint('✅ .env file loaded');
  } catch (e) {
    debugPrint('⚠️ .env file not found: $e');
  }

  // ===== 카카오 SDK 초기화 =====
  KakaoSdk.init(
    nativeAppKey: '8e75eecf0338c9b84861f8000b664336',
    javaScriptAppKey: 'aabc80253972e0504d05951a66373200',
  );
  debugPrint('✅ Kakao SDK initialized');

  // ===== Firebase 초기화 =====
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint('✅ Firebase initialized');

  // ===== App Check 초기화 =====
  // 개발 환경에서는 App Check 비활성화
  if (kReleaseMode) {
    if (kIsWeb) {
      await FirebaseAppCheck.instance.activate(
        providerWeb: ReCaptchaV3Provider('recaptcha-v3-site-key'),
      );
      debugPrint('✅ Firebase App Check activated (Web)');
    } else {
      await FirebaseAppCheck.instance.activate();
      debugPrint('✅ Firebase App Check activated (Android)');
    }
  } else {
    debugPrint('⚠️ Firebase App Check disabled (Debug mode)');
  }

  // ===== Firestore 설정 =====
  // 🔥 개발 중 캐시 완전 비활성화 - 항상 서버에서 최신 데이터 가져오기
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: false,  // 로컬 캐시 완전 비활성화
    cacheSizeBytes: 1048576,    // 최소 캐시 (1MB)
  );

  // 🔥 기존 캐시 완전 삭제
  try {
    await FirebaseFirestore.instance.clearPersistence();
    debugPrint('✅ Firestore cache cleared');
  } catch (e) {
    debugPrint('⚠️ Failed to clear cache (expected if app just started): $e');
  }

  // ✅ ProviderScope 추가
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}
