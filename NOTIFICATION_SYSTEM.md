# 📬 파이컴퓨터 알림 시스템 가이드

## 📊 알림 타입 (NotificationType)

| 타입 | 설명 | 아이콘 | 색상 | 사용 상황 |
|------|------|--------|------|----------|
| `statusChanged` | 판매 요청 상태 변경 | ✅ check_circle | 녹색 | Admin 승인/반려 |
| `paymentCompleted` | 결제 완료 | 💳 payment | 파란색 | 구매자 결제 완료 |
| `listingSold` | 매물 판매 완료 | 💰 sell | 보라색 | 판매자에게 판매 알림 |
| `purchaseConfirmed` | 구매 확정 | ✔️ verified | 청록색 | 구매 확정 시 판매자에게 |
| `shipping` | 배송 시작 | 🚚 local_shipping | 인디고 | 배송 시작 알림 |
| `priceAlert` | 목표 가격 도달 | 📉 trending_down | 빨간색 | 시세 알림 |
| `marketing` | 광고/마케팅 | 📢 campaign | 주황색 | Admin 광고 전송 |
| `system` | 시스템 공지 | ℹ️ info | 주황색 | 시스템 공지사항 |

---

## 🔧 알림 사용 방법

### **1. NotificationHelper 사용**

```dart
import 'package:pi_com/core/utils/notification_helper.dart';

final helper = NotificationHelper();
```

---

### **2. 판매 관련 알림**

#### **판매 요청 승인**
```dart
await helper.notifySellRequestApproved(
  sellerId: 'user123',
  sellRequestId: 'req456',
  partName: 'Intel Core i7-13700K',
  finalPrice: 450000,
);
```

**결과**:
```
제목: 판매 요청이 승인되었습니다 🎉
내용: Intel Core i7-13700K 부품의 판매 요청이 승인되었습니다.
     최종 판매 가격: 450,000원
```

#### **판매 요청 반려**
```dart
await helper.notifySellRequestRejected(
  sellerId: 'user123',
  sellRequestId: 'req456',
  partName: 'Intel Core i7-13700K',
  reason: '사진이 불분명합니다. 부품 사진을 다시 찍어주세요.',
);
```

#### **매물 판매 완료 (판매자에게)**
```dart
await helper.notifyListingSold(
  sellerId: 'user123',
  listingId: 'listing789',
  partName: 'Intel Core i7-13700K',
  soldPrice: 450000,
);
```

**결과**:
```
제목: 축하합니다! 매물이 판매되었습니다 🎊
내용: Intel Core i7-13700K이(가) 450,000원에 판매되었습니다.
     구매자가 결제를 완료하면 배송을 시작해주세요.
```

---

### **3. 구매 관련 알림**

#### **결제 완료 (구매자에게)**
```dart
await helper.notifyPaymentCompleted(
  buyerId: 'buyer123',
  listingId: 'listing789',
  partName: 'Intel Core i7-13700K',
  totalAmount: 452500, // 배송비 포함
);
```

#### **배송 시작 (구매자에게)**
```dart
await helper.notifyShippingStarted(
  buyerId: 'buyer123',
  listingId: 'listing789',
  partName: 'Intel Core i7-13700K',
  trackingNumber: '123456789012', // 선택
);
```

**결과**:
```
제목: 배송이 시작되었습니다 📦
내용: Intel Core i7-13700K 배송이 시작되었습니다.
     송장번호: 123456789012
     상품을 받으신 후 구매 확정을 해주세요.
```

#### **구매 확정 (판매자에게)**
```dart
await helper.notifyPurchaseConfirmed(
  sellerId: 'seller123',
  listingId: 'listing789',
  partName: 'Intel Core i7-13700K',
  finalAmount: 427500, // 수수료 제외
);
```

**결과**:
```
제목: 구매가 확정되었습니다 💰
내용: Intel Core i7-13700K 구매가 확정되었습니다!
     정산 금액: 427,500원
     수수료를 제외한 금액이 지급됩니다.
```

---

### **4. 시세 알림**

#### **목표 가격 도달**
```dart
await helper.notifyPriceAlert(
  userId: 'user123',
  partName: 'RTX 4070 Ti',
  targetPrice: 800000,
  currentPrice: 795000,
  listingId: 'listing999', // 선택
);
```

**결과**:
```
제목: 목표 가격에 도달했습니다! 🎯
내용: RTX 4070 Ti의 가격이 목표 가격에 도달했습니다.
     목표 가격: 800,000원
     현재 가격: 795,000원
```

---

### **5. 시스템/마케팅 알림**

#### **시스템 공지**
```dart
await helper.notifySystem(
  userId: 'user123',
  title: '긴급 점검 안내',
  message: '내일 오전 2시~4시 서버 점검이 있습니다.',
);
```

#### **마케팅 알림 (개별)**
```dart
await helper.notifyMarketing(
  userId: 'user123',
  title: '신규 매물 입고! 🎉',
  message: 'RTX 4090 최저가 매물이 새로 등록되었습니다.',
);
```

#### **마케팅 알림 (전체 사용자)**
```dart
final sentCount = await helper.notifyAllUsers(
  title: '블랙프라이데이 특가!',
  message: '모든 부품 최대 30% 할인!',
);

print('$sentCount명에게 알림 전송 완료');
```

---

## 🎨 알림 UI

### **알림 아이콘 & 색상**

```dart
// notification_item.dart 에서 자동 처리
switch (notification.type) {
  case NotificationType.statusChanged:
    아이콘: Icons.check_circle (✅)
    색상: Colors.green

  case NotificationType.paymentCompleted:
    아이콘: Icons.payment (💳)
    색상: Colors.blue

  case NotificationType.listingSold:
    아이콘: Icons.sell (💰)
    색상: Colors.purple

  case NotificationType.purchaseConfirmed:
    아이콘: Icons.verified (✔️)
    색상: Colors.teal

  case NotificationType.shipping:
    아이콘: Icons.local_shipping (🚚)
    색상: Colors.indigo

  case NotificationType.priceAlert:
    아이콘: Icons.trending_down (📉)
    색상: Colors.red

  case NotificationType.marketing:
    아이콘: Icons.campaign (📢)
    색상: Colors.deepOrange

  case NotificationType.system:
    아이콘: Icons.info (ℹ️)
    색상: Colors.orange
}
```

---

## 📂 파일 구조

```
lib/
├── core/
│   ├── models/
│   │   └── notification_model.dart       # NotificationType enum 정의
│   └── utils/
│       └── notification_helper.dart      # 알림 헬퍼 클래스
├── features/
│   ├── admin/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── admin_notification_datasource.dart
│   │   │   └── repositories/
│   │   │       └── admin_sell_request_repository_impl.dart  # NotificationHelper 사용
│   │   └── presentation/
│   │       └── screens/
│   │           └── admin_dashboard.dart  # 광고 알림 전송
│   └── notification/
│       └── presentations/
│           ├── widgets/
│           │   └── notification_item.dart  # 알림 UI (아이콘/색상)
│           └── providers/
│               └── notification_provider.dart
```

---

## 🔄 거래 프로세스 알림 흐름

### **일반 거래 시나리오**

```
1. 판매자: 판매 요청 제출
   ↓
2. Admin: 승인
   ↓ notifySellRequestApproved()
   📬 판매자: "판매 요청이 승인되었습니다"
   ↓
3. 구매자: 결제 완료
   ↓ notifyPaymentCompleted() + notifyListingSold()
   📬 구매자: "결제가 완료되었습니다"
   📬 판매자: "매물이 판매되었습니다"
   ↓
4. 판매자: 배송 시작
   ↓ notifyShippingStarted()
   📬 구매자: "배송이 시작되었습니다"
   ↓
5. 구매자: 물건 수령 → 구매 확정
   ↓ notifyPurchaseConfirmed()
   📬 판매자: "구매가 확정되었습니다"
```

### **반려 시나리오**

```
1. 판매자: 판매 요청 제출
   ↓
2. Admin: 반려
   ↓ notifySellRequestRejected()
   📬 판매자: "판매 요청이 반려되었습니다 (사유 포함)"
```

---

## 🚀 실전 사용 예시

### **결제 완료 처리 (Cart/Checkout 구현 시)**

```dart
// checkout_screen.dart
Future<void> _processPayment() async {
  final helper = NotificationHelper();

  try {
    // 1. PG 결제 처리
    final paymentResult = await _paymentService.processPayment(...);

    if (paymentResult.success) {
      // 2. Transaction 생성
      final transactionId = await _createTransaction(...);

      // 3. Listing 상태 변경 (available → sold)
      await _updateListingStatus(listingId, ListingStatus.sold);

      // 4. 알림 전송
      // 구매자에게
      await helper.notifyPaymentCompleted(
        buyerId: currentUser.uid,
        listingId: listingId,
        partName: listing.modelName,
        totalAmount: totalAmount,
      );

      // 판매자에게
      await helper.notifyListingSold(
        sellerId: listing.sellerId,
        listingId: listingId,
        partName: listing.modelName,
        soldPrice: listing.price,
      );
    }
  } catch (e) {
    // 에러 처리
  }
}
```

### **배송 시작 (Admin 또는 판매자 페이지)**

```dart
Future<void> _startShipping(String transactionId) async {
  final helper = NotificationHelper();

  // 1. Transaction 업데이트
  await _updateTransactionStatus(transactionId, 'shipped');

  // 2. 송장번호 입력받기
  final trackingNumber = await _showTrackingNumberDialog();

  // 3. 알림 전송
  await helper.notifyShippingStarted(
    buyerId: transaction.buyerId,
    listingId: transaction.listingId,
    partName: transaction.partName,
    trackingNumber: trackingNumber,
  );
}
```

### **구매 확정 (자동/수동)**

```dart
// Cloud Functions (자동 확정 - 3일 후)
export const autoConfirmPurchase = functions
  .pubsub.schedule('every 1 hours')
  .onRun(async () => {
    const threeDaysAgo = admin.firestore.Timestamp.fromDate(
      new Date(Date.now() - 3 * 24 * 60 * 60 * 1000)
    );

    const transactions = await admin.firestore()
      .collection('transactions')
      .where('status', '==', 'shipped')
      .where('shippedAt', '<=', threeDaysAgo)
      .get();

    for (const doc of transactions.docs) {
      const transaction = doc.data();

      // Transaction 상태 변경
      await doc.ref.update({ status: 'confirmed' });

      // 알림 전송 (Dart NotificationHelper 호출)
      await _callNotificationHelper(transaction);
    }
  });

// 또는 수동 확정 (Flutter 앱)
Future<void> _confirmPurchase(String transactionId) async {
  final helper = NotificationHelper();

  // 1. Transaction 업데이트
  await _updateTransactionStatus(transactionId, 'confirmed');

  // 2. 정산 금액 계산 (수수료 제외)
  final platformFee = transaction.finalPrice * 0.05; // 5%
  final sellerAmount = transaction.finalPrice - platformFee;

  // 3. 알림 전송
  await helper.notifyPurchaseConfirmed(
    sellerId: transaction.sellerId,
    listingId: transaction.listingId,
    partName: transaction.partName,
    finalAmount: sellerAmount.toInt(),
  );
}
```

---

## 🎯 Admin 광고 알림 전송

### **Admin Dashboard에서 전송**

```
1. Admin 로그인
   ↓
2. Dashboard → "광고 알림 전송" 클릭
   ↓
3. 제목/내용 입력
   예: 제목: "블랙프라이데이 특가!"
       내용: "모든 부품 최대 30% 할인!"
   ↓
4. 전송 확인
   ↓
5. 전체 사용자에게 알림 전송 완료
```

**코드 (admin_dashboard.dart에 이미 구현됨)**:
```dart
_sendMarketingNotification() async {
  // 제목/내용 다이얼로그
  // → 전체 사용자 조회
  // → 일괄 알림 전송
}
```

---

## ⚠️ 주의사항

### **1. 중복 알림 방지**

```dart
// 같은 이벤트에 대해 중복 알림 방지
final existingNotification = await _firestore
  .collection('notifications')
  .where('userId', isEqualTo: userId)
  .where('relatedListingId', isEqualTo: listingId)
  .where('type', isEqualTo: 'listingSold')
  .get();

if (existingNotification.docs.isEmpty) {
  await helper.notifyListingSold(...);
}
```

### **2. 알림 설정 (향후 구현)**

```dart
// 사용자가 알림 끄기 가능
final userSettings = await _getUserSettings(userId);

if (userSettings.marketingNotificationsEnabled) {
  await helper.notifyMarketing(...);
}
```

### **3. FCM 푸시 알림 (향후 추가)**

현재는 인앱 알림만 지원합니다. FCM 연동 시:

```dart
// notification_helper.dart 에 추가
Future<void> _sendPushNotification({
  required String userId,
  required String title,
  required String message,
}) async {
  // FCM 토큰 조회
  final token = await _getUserFcmToken(userId);

  // FCM 전송
  await FirebaseMessaging.instance.sendMessage(
    to: token,
    notification: Notification(title: title, body: message),
  );
}
```

---

## 📊 데이터베이스 구조

### **notifications 컬렉션**

```
notifications/{notificationId}
├── userId: string              # 알림 받을 사용자
├── type: string                # 알림 타입 (statusChanged, paymentCompleted 등)
├── title: string               # 알림 제목
├── message: string             # 알림 내용
├── isRead: boolean             # 읽음 여부
├── createdAt: timestamp        # 생성 시간
├── readAt: timestamp?          # 읽은 시간 (선택)
├── relatedSellRequestId: string? # 관련 판매 요청 ID
└── relatedListingId: string?   # 관련 리스팅 ID
```

---

## ✅ 체크리스트

### **판매 관련**
- [x] 판매 요청 승인 알림
- [x] 판매 요청 반려 알림
- [x] 매물 판매 완료 알림
- [x] 구매 확정 알림

### **구매 관련**
- [ ] 결제 완료 알림 (구현 준비 완료)
- [ ] 배송 시작 알림 (구현 준비 완료)
- [ ] 구매 확정 알림 (구현 준비 완료)

### **기타**
- [ ] 시세 알림 (구현 준비 완료)
- [x] 광고 알림
- [x] 시스템 공지

### **향후 추가**
- [ ] FCM 푸시 알림
- [ ] 알림 설정 (on/off)
- [ ] 알림 필터링
- [ ] 이메일 알림

---

## 🔗 관련 파일

- [notification_model.dart](lib/core/models/notification_model.dart) - 알림 모델 & 타입
- [notification_helper.dart](lib/core/utils/notification_helper.dart) - 알림 헬퍼
- [notification_item.dart](lib/features/notification/presentations/widgets/notification_item.dart) - 알림 UI
- [admin_dashboard.dart](lib/features/admin/presentation/screens/admin_dashboard.dart) - 광고 전송

---

**마지막 업데이트**: 2025-11-03
