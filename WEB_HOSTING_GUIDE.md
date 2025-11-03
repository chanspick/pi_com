# 🌐 파이컴퓨터 웹 호스팅 가이드

## 📋 현재 호스팅 구조

**Firebase Project**: `picom-team`
**호스팅 방식**: Firebase Hosting (Flutter Web Framework Backend)
**리전**: asia-east1

---

## 🚀 웹 배포 방법 (Admin 변경사항 반영)

### **방법 1: 전체 배포 (추천)** ✅

```bash
# 1. Flutter Web 빌드
flutter build web --release

# 2. Firebase 전체 배포 (Hosting + Functions)
firebase deploy

# 또는 Hosting만 배포
firebase deploy --only hosting
```

### **방법 2: Functions만 배포**

```bash
# Cloud Functions만 업데이트
firebase deploy --only functions
```

### **방법 3: Firestore Rules만 배포**

```bash
# Firestore Rules만 업데이트
firebase deploy --only firestore:rules
```

---

## 📦 배포 단계별 설명

### **Step 1: Flutter Web 빌드**

```bash
flutter build web --release
```

**생성 결과**:
- `build/web/` 폴더에 빌드된 파일 생성
- `index.html`, `main.dart.js` 등

**옵션**:
```bash
# 웹 렌더러 지정 (canvaskit이 기본)
flutter build web --web-renderer canvaskit  # 고품질 렌더링
flutter build web --web-renderer html       # 더 빠른 로딩

# 디버그 심볼 제거 (파일 크기 축소)
flutter build web --release --no-tree-shake-icons
```

---

### **Step 2: Firebase Hosting 배포**

```bash
# Firebase 로그인 (최초 1회)
firebase login

# 프로젝트 확인
firebase projects:list

# 배포
firebase deploy --only hosting
```

**배포 결과**:
```
✔  Deploy complete!

Project Console: https://console.firebase.google.com/project/picom-team/overview
Hosting URL: https://picom-team.web.app
```

---

## 🔧 Admin 변경사항 반영 체크리스트

### **Dart 코드 변경 (예: admin_dashboard.dart 수정)**

```bash
# 1. 변경 사항 저장
# 2. 웹 빌드
flutter build web --release

# 3. 배포
firebase deploy --only hosting

# 4. 브라우저 캐시 클리어 후 확인
# Ctrl + Shift + R (강력 새로고침)
```

### **Cloud Functions 변경 (예: index.ts 수정)**

```bash
# 1. functions 폴더로 이동
cd functions

# 2. TypeScript 컴파일 (자동)
npm run build

# 3. Functions 배포
cd ..
firebase deploy --only functions

# 4. 배포 확인
firebase functions:log
```

### **Firestore Rules 변경**

```bash
# firestore.rules 수정 후
firebase deploy --only firestore:rules
```

---

## 🌐 배포 URL 확인

**프로덕션 URL**:
- https://picom-team.web.app
- https://picom-team.firebaseapp.com

**Admin 페이지**:
- https://picom-team.web.app/admin

**Firebase Console**:
- https://console.firebase.google.com/project/picom-team

---

## ⚠️ 주의사항

### **1. 캐시 문제**

배포 후 변경사항이 안 보이면:

```bash
# 브라우저 강력 새로고침
Windows: Ctrl + Shift + R
Mac: Cmd + Shift + R

# 또는 시크릿 모드로 확인
```

### **2. 빌드 전 확인**

```bash
# 에러 체크
flutter analyze

# 웹에서 로컬 테스트
flutter run -d chrome
```

### **3. 환경 변수**

Firebase 설정은 자동으로 포함됩니다:
- `firebase_options.dart` (자동 생성)
- `google-services.json` (Android)
- `GoogleService-Info.plist` (iOS)

---

## 🔄 전체 배포 프로세스 (자동화)

### **배포 스크립트 생성 (선택)**

**`deploy.sh` (Linux/Mac)**:
```bash
#!/bin/bash
echo "🚀 파이컴퓨터 웹 배포 시작..."

echo "1️⃣ Flutter Web 빌드..."
flutter build web --release --web-renderer canvaskit

echo "2️⃣ Firebase 배포..."
firebase deploy --only hosting,functions

echo "✅ 배포 완료!"
echo "🌐 https://picom-team.web.app"
```

**`deploy.bat` (Windows)**:
```bat
@echo off
echo 🚀 파이컴퓨터 웹 배포 시작...

echo 1️⃣ Flutter Web 빌드...
flutter build web --release --web-renderer canvaskit

echo 2️⃣ Firebase 배포...
firebase deploy --only hosting,functions

echo ✅ 배포 완료!
echo 🌐 https://picom-team.web.app
pause
```

**실행**:
```bash
# Linux/Mac
chmod +x deploy.sh
./deploy.sh

# Windows
deploy.bat
```

---

## 🐛 문제 해결

### **문제 1: "firebase: command not found"**

```bash
# Firebase CLI 설치
npm install -g firebase-tools

# 확인
firebase --version
```

### **문제 2: "Permission denied"**

```bash
# 재로그인
firebase logout
firebase login
```

### **문제 3: "Build failed"**

```bash
# 캐시 클리어
flutter clean
flutter pub get
flutter build web --release
```

### **문제 4: "Functions 배포 실패"**

```bash
# functions 폴더로 이동
cd functions

# 의존성 재설치
npm install

# TypeScript 컴파일 확인
npm run build

# 배포
cd ..
firebase deploy --only functions
```

---

## 📊 배포 후 확인

### **1. Hosting 확인**

```bash
firebase hosting:sites:list
```

### **2. Functions 확인**

```bash
# 함수 목록
firebase functions:list

# 함수 로그
firebase functions:log --limit 50
```

### **3. Firestore 확인**

```bash
# Rules 확인
firebase firestore:rules

# 데이터 확인 (Console)
# https://console.firebase.google.com/project/picom-team/firestore
```

---

## 🎯 빠른 배포 명령 모음

```bash
# 전체 배포
flutter clean && flutter pub get && flutter build web --release && firebase deploy

# Hosting만
flutter build web --release && firebase deploy --only hosting

# Functions만
firebase deploy --only functions

# Rules만
firebase deploy --only firestore:rules

# 특정 Function만
firebase deploy --only functions:searchParts
```

---

## 🔐 보안 체크리스트

배포 전 확인:
- [ ] `.env` 파일이 `.gitignore`에 포함되었는지
- [ ] API 키가 노출되지 않았는지
- [ ] Firestore Rules가 올바른지
- [ ] Storage Rules가 올바른지
- [ ] Admin 권한 체크가 작동하는지

---

## 📞 도움말

**Firebase 문서**: https://firebase.google.com/docs/hosting
**Flutter Web 문서**: https://docs.flutter.dev/platform-integration/web

**문제 발생 시**:
1. Firebase Console 확인
2. `firebase functions:log` 확인
3. 브라우저 Console 확인 (F12)
