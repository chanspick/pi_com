# 알림 내비게이션 및 정보 입력 설계

## 개요
알림을 탭했을 때 적절한 화면으로 이동하여 사용자가 필요한 정보를 입력하거나 액션을 수행할 수 있도록 설계

---

## 1. 정보 입력이 필요한 알림 타입 분류

### A. 즉시 액션 가능 (기존 화면 활용)

| 알림 타입 | 이동 화면 | 필요한 액션 | 우선순위 |
|---------|---------|-----------|---------|
| `purchaseConfirmReminder` | PurchaseDetailScreen | 구매확정 버튼 | ⭐⭐⭐ |
| `autoConfirmed` | PurchaseDetailScreen | 정보 확인만 | ⭐ |
| `storageWarning` | PcStorageScreen | 출고 신청 버튼 | ⭐⭐⭐ |
| `storageUrgent` | PcStorageScreen | 출고 신청 버튼 | ⭐⭐⭐ |
| `storageFinalWarning` | PcStorageScreen | 출고 신청 버튼 | ⭐⭐⭐ |
| `dragonball_expiring` | PcStorageScreen | 일괄 배송 신청 | ⭐⭐ |
| `paymentCompleted` | PurchaseDetailScreen | 정보 확인 | ⭐ |
| `listingSold` | SalesHistoryScreen | 정보 확인 | ⭐ |
| `statusChanged` | SellRequestDetailScreen | 정보 확인 | ⭐ |

### B. 새 화면 필요 (정보 입력 폼)

| 알림 타입 | 필요한 화면 | 입력 정보 | 우선순위 |
|---------|----------|---------|---------|
| `refundApproved` | RefundReturnShippingScreen | 택배사, 송장번호 | ⭐⭐⭐ |
| `returnAddressReminder` | RefundReturnShippingScreen | 택배사, 송장번호 | ⭐⭐⭐ |
| `returnAddressDeadline` | RefundReturnShippingScreen | 택배사, 송장번호 | ⭐⭐⭐ |
| `refundInspectionFail` | RefundDetailScreen | 재발송 주소 선택 or 환불 포기 | ⭐⭐ |
| `inspectionFailed` | SellRequestDetailScreen | 반품 주소 선택 or 포기 | ⭐⭐ |

### C. 정보 확인만 (상세 화면)

| 알림 타입 | 이동 화면 | 확인 정보 | 우선순위 |
|---------|---------|---------|---------|
| `refundRequested` | RefundListScreen (새 화면) | 환불 요청 목록 | ⭐⭐ |
| `refundRejected` | RefundDetailScreen | 거부 사유 | ⭐⭐ |
| `refundInspecting` | RefundDetailScreen | 검수 진행 상황 | ⭐ |
| `refundInspectionPass` | RefundDetailScreen | 검수 합격 정보 | ⭐ |
| `refundCompleted` | RefundDetailScreen | 환불 완료 금액 | ⭐⭐ |
| `settlementPending` | SalesHistoryScreen | 정산 대기 정보 | ⭐ |
| `settlementCompleted` | SalesHistoryScreen | 정산 완료 금액 | ⭐⭐ |
| `consignmentConverted` | PcStorageScreen | 위탁 전환 정보 | ⭐⭐ |
| `consignmentSold` | PcStorageScreen | 위탁 판매 수익 | ⭐⭐ |

---

## 2. 알림 핸들러 구조 설계

### NotificationHandler 클래스
```dart
class NotificationHandler {
  final BuildContext context;

  NotificationHandler(this.context);

  /// 알림 탭 처리
  Future<void> handleNotificationTap(NotificationModel notification) async {
    // 1. 알림을 읽음 처리
    await _markAsRead(notification.notificationId);

    // 2. 타입별 라우팅
    switch (notification.type) {
      // A. 구매/주문 관련
      case NotificationType.purchaseConfirmReminder:
      case NotificationType.autoConfirmed:
      case NotificationType.paymentCompleted:
        _navigateToPurchaseDetail(notification.relatedOrderId);
        break;

      // B. 환불 관련 - 정보 입력 필요
      case NotificationType.refundApproved:
      case NotificationType.returnAddressReminder:
      case NotificationType.returnAddressDeadline:
        _navigateToReturnShipping(notification.relatedRefundId);
        break;

      // C. 환불 관련 - 정보 확인
      case NotificationType.refundRequested:
      case NotificationType.refundRejected:
      case NotificationType.refundInspecting:
      case NotificationType.refundInspectionPass:
      case NotificationType.refundInspectionFail:
      case NotificationType.refundCompleted:
        _navigateToRefundDetail(notification.relatedRefundId);
        break;

      // D. 보관 서비스 관련
      case NotificationType.storageWarning:
      case NotificationType.storageUrgent:
      case NotificationType.storageFinalWarning:
      case NotificationType.consignmentConverted:
      case NotificationType.consignmentSold:
        _navigateToPcStorage();
        break;

      // E. 판매 관련
      case NotificationType.listingSold:
      case NotificationType.settlementPending:
      case NotificationType.settlementCompleted:
        _navigateToSalesHistory();
        break;

      // F. 판매 신청 관련
      case NotificationType.statusChanged:
      case NotificationType.inspectionStarted:
      case NotificationType.inspectionPassed:
      case NotificationType.inspectionFailed:
        _navigateToSellRequestDetail(notification.relatedSellRequestId);
        break;

      default:
        // 기본: 알림 목록으로
        break;
    }
  }
}
```

---

## 3. 새로 생성할 화면 설계

### 3.1 RefundReturnShippingScreen (환불 반품 송장 입력)

**경로**: `lib/features/refund/presentation/screens/refund_return_shipping_screen.dart`

**UI 구성**:
```
┌─────────────────────────────┐
│ ← 반품 송장 정보 입력         │
├─────────────────────────────┤
│                             │
│ [환불 정보 카드]              │
│ • 주문번호: ORD-123         │
│ • 상품명: RTX 4090          │
│ • 환불 예정액: 1,500,000원   │
│                             │
│ [반품 안내]                  │
│ ⚠️ 3일 내 반품 물품 발송 필수 │
│ • 반품 주소: 서울시...       │
│ • 포장 상태 유지 필수         │
│                             │
│ [송장 정보 입력]             │
│ 택배사 선택  [▼]            │
│ ┌─────────────────────┐    │
│ │ CJ대한통운           │    │
│ │ 한진택배             │    │
│ │ 롯데택배             │    │
│ │ 우체국택배           │    │
│ └─────────────────────┘    │
│                             │
│ 송장번호                     │
│ [123456789012345]           │
│                             │
│ [송장 사진 첨부] (선택)       │
│ 📷 📷                       │
│                             │
│                             │
│ [ 반품 신청 완료 ]           │
│                             │
└─────────────────────────────┘
```

**입력 필드**:
- 택배사 (Dropdown): CJ대한통운, 한진택배, 롯데택배, 우체국택배, 로젠택배
- 송장번호 (TextField): 숫자만 입력, 10-15자
- 송장 사진 (이미지 업로드, 선택사항)

**Validation**:
- 택배사 필수 선택
- 송장번호 10자 이상 필수 입력
- 송장번호 숫자만 허용

**액션**:
```dart
onSubmit() async {
  // 1. Validation
  if (!_formKey.currentState!.validate()) return;

  // 2. 송장 이미지 업로드 (있는 경우)
  List<String> photoUrls = [];
  if (_selectedImages.isNotEmpty) {
    photoUrls = await _uploadImages();
  }

  // 3. Firestore 업데이트
  await refundRepository.markItemShipped(
    refundId: widget.refundId,
    trackingNumber: _trackingNumberController.text,
    courierCompany: _selectedCourier,
  );

  // 4. 성공 메시지 + 화면 닫기
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('반품 신청이 완료되었습니다')),
  );
  Navigator.pop(context);
}
```

---

### 3.2 RefundDetailScreen (환불 상세 화면)

**경로**: `lib/features/refund/presentation/screens/refund_detail_screen.dart`

**UI 구성**:
```
┌─────────────────────────────┐
│ ← 환불 상세                  │
├─────────────────────────────┤
│                             │
│ [환불 진행 상태]             │
│ ●─────●─────○─────○         │
│ 신청   승인   검수   완료     │
│                             │
│ [주문 정보]                  │
│ • 주문번호: ORD-123         │
│ • 상품명: RTX 4090          │
│ • 주문금액: 1,500,000원      │
│                             │
│ [환불 정보]                  │
│ • 환불 사유: 상품 불량       │
│ • 신청일: 2025-01-15        │
│ • 환불 예정액: 1,470,000원   │
│   - 배송비 차감: 30,000원    │
│                             │
│ [반품 송장 정보]             │
│ • 택배사: CJ대한통운         │
│ • 송장번호: 123456789012    │
│ • 발송일: 2025-01-16        │
│                             │
│ [검수 결과] (검수 완료 시)    │
│ • 검수 상태: 합격/불합격      │
│ • 검수 사유: ...            │
│ • 검수 사진: [📷 📷 📷]     │
│                             │
│ ──────────────────────      │
│ 타임라인                     │
│ • 2025-01-18 환불 완료      │
│ • 2025-01-17 검수 합격      │
│ • 2025-01-16 반품 물품 수령  │
│ • 2025-01-16 반품 발송      │
│ • 2025-01-15 환불 승인      │
│ • 2025-01-15 환불 신청      │
│                             │
└─────────────────────────────┘
```

**검수 불합격 시 액션**:
```dart
// 검수 불합격 시 하단에 액션 버튼 표시
if (refund.status == RefundStatus.inspectionFail) {
  return Column(
    children: [
      Text('검수 불합격 사유: ${refund.failReason}'),
      SizedBox(height: 16),

      // 옵션 1: 재발송 주소 입력
      ElevatedButton(
        onPressed: () => _showReturnAddressDialog(),
        child: Text('재발송 주소 입력'),
      ),

      // 옵션 2: 환불 포기
      TextButton(
        onPressed: () => _cancelRefund(),
        child: Text('환불 포기', style: TextStyle(color: Colors.red)),
      ),
    ],
  );
}
```

---

### 3.3 RefundListScreen (환불 요청 목록 - 판매자용)

**경로**: `lib/features/refund/presentation/screens/refund_list_screen.dart`

**UI 구성**:
```
┌─────────────────────────────┐
│ ← 환불 요청 관리              │
├─────────────────────────────┤
│ [탭]  대기중(3)  처리중  완료│
├─────────────────────────────┤
│                             │
│ ┌─────────────────────────┐ │
│ │ RTX 4090              🔴│ │
│ │ 환불 사유: 상품 불량      │ │
│ │ 주문금액: 1,500,000원    │ │
│ │ 신청일: 2025-01-15      │ │
│ │ [ 승인 ]  [ 거부 ]      │ │
│ └─────────────────────────┘ │
│                             │
│ ┌─────────────────────────┐ │
│ │ i5-13600K             🔴│ │
│ │ 환불 사유: 단순 변심      │ │
│ │ 주문금액: 350,000원      │ │
│ │ 신청일: 2025-01-14      │ │
│ │ [ 승인 ]  [ 거부 ]      │ │
│ └─────────────────────────┘ │
│                             │
└─────────────────────────────┘
```

---

## 4. 라우트 추가

### routes.dart에 추가
```dart
class Routes {
  // 환불 관련
  static const String refundList = '/refund-list';
  static const String refundDetail = '/refund-detail';
  static const String refundReturnShipping = '/refund-return-shipping';
}
```

### app_router.dart에 추가
```dart
case Routes.refundDetail:
  final refundId = settings.arguments as String?;
  if (refundId == null) {
    return _errorRoute('환불 ID가 필요합니다.');
  }
  return MaterialPageRoute(
    builder: (_) => RefundDetailScreen(refundId: refundId),
    settings: settings,
  );

case Routes.refundReturnShipping:
  final refundId = settings.arguments as String?;
  if (refundId == null) {
    return _errorRoute('환불 ID가 필요합니다.');
  }
  return MaterialPageRoute(
    builder: (_) => RefundReturnShippingScreen(refundId: refundId),
    settings: settings,
  );

case Routes.refundList:
  return MaterialPageRoute(
    builder: (_) => const RefundListScreen(),
    settings: settings,
  );
```

---

## 5. NotificationModel 확장

### relatedRefundId, relatedOrderId 필드 추가
```dart
class NotificationModel {
  // 기존 필드...
  final String? relatedSellRequestId;
  final String? relatedListingId;

  // 새로 추가
  final String? relatedRefundId;      // 환불 ID
  final String? relatedOrderId;       // 주문 ID
  final String? relatedDragonBallId;  // 보관 ID

  // ...
}
```

---

## 6. 구현 우선순위

### Phase 1: 필수 (⭐⭐⭐)
1. ✅ NotificationHandler 생성
2. ✅ NotificationModel에 필드 추가 (relatedRefundId, relatedOrderId 등)
3. ✅ RefundReturnShippingScreen 구현
4. ✅ 라우트 추가 및 app_router 업데이트
5. ✅ PurchaseDetailScreen에 구매확정 버튼 추가

### Phase 2: 중요 (⭐⭐)
6. ✅ RefundDetailScreen 구현
7. ✅ RefundListScreen 구현
8. ✅ 검수 불합격 시 액션 버튼 추가

### Phase 3: 추가 개선 (⭐)
9. ✅ 알림 아이콘 및 스타일 개선
10. ✅ 딥링크 지원 (FCM 페이로드에 라우팅 정보 포함)

---

## 7. 택배사 Enum

```dart
enum CourierCompany {
  cj('CJ대한통운', 'cj'),
  hanjin('한진택배', 'hanjin'),
  lotte('롯데택배', 'lotte'),
  post('우체국택배', 'post'),
  logen('로젠택배', 'logen');

  final String displayName;
  final String code;

  const CourierCompany(this.displayName, this.code);
}
```

---

## 8. 예상 사용자 시나리오

### 시나리오 1: 환불 승인 후 송장 입력
1. 구매자가 환불 신청
2. 판매자가 환불 승인
3. 구매자에게 `refundApproved` 알림 발송
4. 구매자가 알림 탭 → **RefundReturnShippingScreen** 이동
5. 택배사 선택, 송장번호 입력
6. "반품 신청 완료" 버튼 클릭
7. Firestore에 송장 정보 저장 → status: `itemShipped`
8. 판매자에게 "반품 물품 발송됨" 알림

### 시나리오 2: 구매확정 요청
1. 주문이 배송 완료 5일 경과
2. Cloud Functions 스케줄러가 `purchaseConfirmReminder` 알림 발송
3. 구매자가 알림 탭 → **PurchaseDetailScreen** 이동
4. "구매 확정" 버튼 표시
5. 버튼 클릭 → Order status: `confirmed`
6. 판매자에게 "정산 대기 중" 알림

### 시나리오 3: 보관 50일 경고
1. 보관 기간 50일 도달
2. Cloud Functions 스케줄러가 `storageWarning` 알림 발송
3. 사용자가 알림 탭 → **PcStorageScreen** 이동
4. 해당 DragonBall 하이라이트 표시
5. "출고 신청" 또는 "위탁 전환 수락" 버튼 표시

---

## 구현 시작 준비 완료
다음 단계: NotificationHandler 구현 → RefundReturnShippingScreen 구현
