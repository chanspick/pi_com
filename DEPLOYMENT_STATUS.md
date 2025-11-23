# 🚀 PiCom 배포 현황 (2025-11-12)

**현재 버전**: 1.0.3 (Build 4)
**마지막 업데이트**: 2025-11-12
**배포 상태**: 🟡 프로덕션 배포 준비 중 (긴급 수정 필요)

---

## 📋 현재 상태 요약

### ✅ 완료된 작업
1. **프로젝트 구조 정리**
   - 19개 Feature 모두 작동 중
   - Outdated 문서 13개 삭제
   - `APP_STRUCTURE.md` 생성 (전체 앱 구조 문서화)

2. **보안 설정**
   - Firestore Security Rules 프로덕션 전환 완료
   - ProGuard 코드 난독화 활성화
   - Release Keystore 설정 완료

3. **버전 관리**
   - pubspec.yaml: 1.0.3+4 ✅
   - build.gradle.kts: versionCode 4, versionName "1.0.3" ✅
   - VERSION_HISTORY.md 문서화 완료 ✅

4. **Firebase 설정**
   - Firestore 인덱스 설정 완료
   - Firebase Functions 카카오페이 연동 완료
   - Firebase Storage 구조 정리 완료

---

## 🚨 배포 전 긴급 수정 필요 (4개)

### 1. 결제-주문 트랜잭션 보장 ⭐⭐⭐⭐⭐
**파일**: `lib/features/checkout/presentation/screens/checkout_screen.dart:443`

**문제**: 결제 승인 후 주문 생성 실패 시 롤백 로직 없음

**해결 방법**:
```dart
try {
  final approvedPayment = await approvePaymentUseCase(...);

  try {
    await ref.read(purchaseUseCaseProvider).call(...);
  } catch (orderError) {
    // 주문 생성 실패 시 즉시 결제 취소
    await cancelPaymentUseCase(approvedPayment.tid);
    throw Exception('주문 생성 실패로 결제가 취소되었습니다.');
  }
} catch (e) {
  showErrorDialog('결제 처리 중 오류가 발생했습니다.');
}
```

---

### 2. 중복 결제 방지 ⭐⭐⭐⭐⭐
**파일**: `lib/features/checkout/presentation/screens/checkout_screen.dart:394`

**문제**: 타임스탬프 기반 orderId → 동시 요청 시 중복 가능

**해결 방법**:
```dart
import 'package:uuid/uuid.dart';

final orderId = 'ORDER_${const Uuid().v4()}';  // UUID 사용
```

---

### 3. 타임아웃 설정 ⭐⭐⭐⭐
**파일**: `lib/features/payment/data/datasources/payment_remote_datasource_impl.dart:46, 82, 125`

**문제**: Dio 요청에 타임아웃 없음 → 무한 대기 위험

**해결 방법**:
```dart
final response = await _dio.post(
  '$_baseUrl/payment/prepare',
  data: request.toJson(),
  options: Options(
    receiveTimeout: const Duration(seconds: 15),
    sendTimeout: const Duration(seconds: 15),
    connectTimeout: const Duration(seconds: 10),
  ),
);
```

---

### 4. Order 생성 에러 처리 ⭐⭐⭐⭐
**파일**: `lib/features/checkout/data/datasources/order_remote_datasource_impl.dart:19`

**문제**: try-catch 없음

**해결 방법**:
```dart
Future<void> createOrder(OrderModel order) async {
  try {
    await _firestore.collection('orders').doc(order.orderId).set(order.toFirestore());
  } on FirebaseException catch (e) {
    throw Exception('주문 생성 실패: ${e.message}');
  } catch (e) {
    throw Exception('주문 생성 중 오류 발생');
  }
}
```

---

## ⚠️ 개선 권장 (배포 후 가능)

1. **사용자 친화적 에러 메시지**
   - 기술적 에러 → 일반 사용자용 메시지 변환

2. **Firebase Crashlytics 도입**
   - 프로덕션 에러 추적

3. **print() 제거**
   - 프로덕션 코드에 46개 존재
   - debugPrint() 또는 로깅 라이브러리 사용

4. **드래곤볼 생성 실패 복구**
   - 결제 완료 후 드래곤볼 생성 실패 시 복구 로직

---

## 📦 배포 준비 체크리스트

### 긴급 수정 (출시 전 필수)
- [ ] 결제-주문 트랜잭션 보장 코드 추가
- [ ] UUID 기반 orderId로 변경
- [ ] Dio 타임아웃 설정 추가
- [ ] Order 생성 에러 처리 추가

### Firebase 배포
- [ ] Firestore Rules 배포
  ```bash
  firebase deploy --only firestore:rules
  ```
- [ ] Firebase Functions 배포
  ```bash
  firebase deploy --only functions
  ```
- [ ] 카카오페이 CID 확인 (테스트 → 프로덕션)
  ```bash
  firebase functions:config:get
  firebase functions:config:set kakaopay.cid="YOUR_REAL_CID"
  firebase functions:config:set kakaopay.admin_key="YOUR_ADMIN_KEY"
  ```

### 앱 메타데이터
- [ ] 앱 아이콘 설정
  - `assets/photos/app_icon.png` → Android 리소스 변환
- [ ] 스크린샷 준비 (8개 존재: assets/photos/app_screenshot (1-8).jpg)
- [ ] Google Play Console 앱 설명 작성

### Release Keystore
- [ ] Release Keystore 생성 (upload-keystore.jks)
- [ ] key.properties 파일 생성
  ```properties
  storePassword=여기에_키스토어_비밀번호_입력
  keyPassword=여기에_키_비밀번호_입력
  keyAlias=upload
  storeFile=app/upload-keystore.jks
  ```
- [ ] .gitignore에 추가 확인
  ```
  android/key.properties
  android/app/upload-keystore.jks
  ```

### 최종 빌드
- [ ] 긴급 수정 완료 후 재빌드
  ```bash
  flutter clean
  flutter pub get
  flutter build appbundle --release
  ```
- [ ] App Bundle 확인: `build/app/outputs/bundle/release/app-release.aab`
- [ ] Internal Testing 테스트
- [ ] 프로덕션 릴리즈

---

## 🎯 배포 전략

### 옵션 1: 안전한 배포 (권장) ✅
1. **긴급 수정 완료** (1-2일 소요)
2. **Internal Testing** (2-3일)
3. **Closed Testing** (선택, 1주)
4. **Open Testing** (선택, 1-2주)
5. **Production Release**

**장점**:
- 결제 오류 위험 최소화
- 사용자 불만 방지
- 안정적인 출시

---

### 옵션 2: 빠른 배포 (비권장) ⚠️
1. **현재 상태로 출시**
2. **24시간 집중 모니터링**
3. **문제 발생 시 즉시 핫픽스 v1.0.4 배포**

**리스크**:
- 결제 오류 발생 가능
- 고객 불만 및 환불 요청
- 앱 평점 하락 위험

---

## 📊 출시 후 모니터링

### 첫 주 집중 모니터링 항목
1. **결제 성공률** (Target: 95% 이상)
   - Firebase Console → Payments 컬렉션 확인
   - 결제 준비/승인/취소 비율 추적

2. **에러 발생률** (Target: 1% 이하)
   - Firebase Crashlytics (도입 권장)
   - 주요 에러 타입 분석

3. **사용자 피드백**
   - Google Play Console 리뷰 모니터링
   - 결제 관련 문의 최우선 처리

---

## 🔧 긴급 상황 대응

### 결제 오류 발생 시
1. **Firebase Console** → Payments 컬렉션 확인
2. **카카오페이 관리자 센터**에서 수동 취소
3. **사용자에게 환불 안내 및 처리**

### 앱 다운 시
1. Firestore Rules를 읽기 전용으로 긴급 변경
2. 원인 파악 후 핫픽스 배포

---

## 📞 배포 담당자

- **개발팀**: PiCom Team
- **Firebase 관리**: (담당자 지정 필요)
- **Google Play Console**: (담당자 지정 필요)
- **카카오페이 관리**: (담당자 지정 필요)

---

## 🔗 관련 문서

- **[APP_STRUCTURE.md](APP_STRUCTURE.md)** - 전체 앱 구조
- **[SECURITY_GUIDE.md](SECURITY_GUIDE.md)** - 보안 설정
- **[VERSION_HISTORY.md](VERSION_HISTORY.md)** - 버전 히스토리
- **[PLAYSTORE_GUIDE.md](PLAYSTORE_GUIDE.md)** - 배포 가이드 (상세)
- **[PRE_LAUNCH_CHECKLIST.md](PRE_LAUNCH_CHECKLIST.md)** - 출시 전 체크리스트

---

## 💡 결론 및 권고사항

### 현재 상태: 🟡 조건부 배포 가능

**권고사항**:
1. ✅ **긴급 수정 4개 완료 후 배포** (권장)
   - 예상 소요 시간: 1-2일
   - 안정적인 출시 보장

2. ⚠️ **현재 상태로 배포** (비권장)
   - 결제 오류 위험 높음
   - 24시간 집중 모니터링 필수
   - 즉시 핫픽스 준비 필요

**최종 결정**: 프로젝트 매니저 및 개발팀 협의 필요

---

**작성자**: Claude Code
**마지막 업데이트**: 2025-11-12
**다음 리뷰**: 긴급 수정 완료 후
