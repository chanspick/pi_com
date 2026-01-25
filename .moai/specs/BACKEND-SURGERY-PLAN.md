# PiCom 백엔드 수술서 (Backend Surgery Plan)

> **작성일**: 2026-01-22
> **대상**: Firebase + Cloud Functions 백엔드
> **목표**: 프로덕션 안정성 확보, 성능 최적화, 확장성 개선

---

## 📋 Executive Summary

### 현재 백엔드 아키텍처

```
┌─────────────────────────────────────────────────────────────┐
│                    Flutter Client (Mobile/Web)               │
└────────────────────────────┬────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────┐
│              Firebase Cloud Functions (Seoul)                │
│  ┌───────────┐  ┌───────────┐  ┌───────────────────────┐   │
│  │   Auth    │  │  Payment  │  │     Schedulers        │   │
│  │  Kakao    │  │ Kakao/Toss│  │ Price/Expiry/Refund   │   │
│  └───────────┘  └───────────┘  └───────────────────────┘   │
└────────────────────────────┬────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────┐
│                     Firebase Services                        │
│  ┌───────────┐  ┌───────────┐  ┌───────────────────────┐   │
│  │ Firestore │  │  Storage  │  │   Authentication      │   │
│  │  16 cols  │  │  Images   │  │  Kakao/Google/Email   │   │
│  └───────────┘  └───────────┘  └───────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────┐
│                    External APIs                             │
│  ┌───────────┐  ┌───────────┐  ┌───────────────────────┐   │
│  │ Kakao Pay │  │Toss Pay v2│  │   Daum Postcode       │   │
│  └───────────┘  └───────────┘  └───────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### 핵심 수치

| 항목 | 현재 | 목표 |
|------|------|------|
| Cloud Functions | 17개 | 20개 (감사/모니터링 추가) |
| Firestore 컬렉션 | 16개 | 14개 (중복 정리) |
| 평균 응답 시간 | 측정 필요 | < 500ms |
| 에러율 | 측정 필요 | < 0.1% |

---

## 🔴 Phase 1: Critical 수정 (즉시)

### 1.1 Admin UID 하드코딩 수정

**현재 문제**:
```typescript
// functions/src/refund/approval_deadline_scheduler.ts:306
// functions/src/refund/process_refund.ts:306
const ADMIN_UIDS = ["ADMIN_UID_1", "ADMIN_UID_2"]; // 플레이스홀더!
```

**수정 방법**:
```typescript
// functions/src/config/admin.ts (신규 생성)
export function getAdminUids(): string[] {
  const adminIds = process.env.ADMIN_USER_IDS || functions.config().admin?.user_ids;
  if (!adminIds) {
    console.error('ADMIN_USER_IDS not configured');
    return [];
  }
  return adminIds.split(',').map(id => id.trim());
}

// 사용처에서
import { getAdminUids } from '../config/admin';
const ADMIN_UIDS = getAdminUids();
```

**환경변수 설정**:
```bash
# Firebase Functions 환경변수 설정
firebase functions:config:set admin.user_ids="UID1,UID2,UID3"

# 또는 .env 파일 (Cloud Functions Gen 2)
ADMIN_USER_IDS=UID1,UID2,UID3
```

**영향받는 파일**:
- [ ] `functions/src/refund/approval_deadline_scheduler.ts`
- [ ] `functions/src/refund/process_refund.ts`
- [ ] `functions/src/schedulers/settlement_notification_scheduler.ts` (확인 필요)

---

### 1.2 Firestore 인덱스 생성

**필요한 복합 인덱스** (`firestore.indexes.json`):

```json
{
  "indexes": [
    {
      "collectionGroup": "listings",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "category", "order": "ASCENDING" },
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "listings",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "basePartId", "order": "ASCENDING" },
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "price", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "orders",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "orders",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "sellerId", "order": "ASCENDING" },
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "priceAlerts",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "isActive", "order": "ASCENDING" },
        { "fieldPath": "triggeredAt", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "refundRequests",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "requestedAt", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "dragonBalls",
      "queryScope": "COLLECTION_GROUP",
      "fields": [
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "expiresAt", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "notifications",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "isRead", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    }
  ]
}
```

**배포 명령**:
```bash
firebase deploy --only firestore:indexes
```

---

### 1.3 결제 트랜잭션 보장

**현재 문제**: 결제 승인 후 주문 생성 실패 시 사용자 금전 손실

**해결 방안**: Firestore 트랜잭션 + 상태 머신

```typescript
// functions/src/payment/payment_transaction.ts (신규)

import { getFirestore, FieldValue } from 'firebase-admin/firestore';

interface PaymentTransaction {
  orderId: string;
  paymentKey: string;
  status: 'pending' | 'payment_approved' | 'order_created' | 'completed' | 'failed' | 'rollback';
  amount: number;
  createdAt: FieldValue;
  updatedAt: FieldValue;
  errorMessage?: string;
}

export async function processPaymentWithTransaction(
  orderId: string,
  paymentKey: string,
  amount: number,
  orderData: any
): Promise<{ success: boolean; error?: string }> {
  const db = getFirestore();
  const transactionRef = db.collection('payment_transactions').doc(orderId);

  try {
    // 1. 트랜잭션 시작 기록
    await transactionRef.set({
      orderId,
      paymentKey,
      status: 'pending',
      amount,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });

    // 2. 주문 먼저 생성 (pending 상태)
    const orderRef = db.collection('orders').doc(orderId);
    await orderRef.set({
      ...orderData,
      status: 'pending',
      createdAt: FieldValue.serverTimestamp(),
    });

    await transactionRef.update({
      status: 'order_created',
      updatedAt: FieldValue.serverTimestamp(),
    });

    // 3. 결제 승인 (외부 API 호출)
    const paymentResult = await approvePayment(paymentKey, orderId, amount);

    if (!paymentResult.success) {
      throw new Error(paymentResult.error || 'Payment approval failed');
    }

    await transactionRef.update({
      status: 'payment_approved',
      updatedAt: FieldValue.serverTimestamp(),
    });

    // 4. 주문 상태 업데이트
    await orderRef.update({
      status: 'paid',
      paidAt: FieldValue.serverTimestamp(),
    });

    // 5. 완료
    await transactionRef.update({
      status: 'completed',
      updatedAt: FieldValue.serverTimestamp(),
    });

    return { success: true };

  } catch (error: any) {
    // 롤백 처리
    await transactionRef.update({
      status: 'failed',
      errorMessage: error.message,
      updatedAt: FieldValue.serverTimestamp(),
    });

    // 결제가 승인된 상태라면 취소 시도
    const txData = (await transactionRef.get()).data() as PaymentTransaction;
    if (txData?.status === 'payment_approved') {
      try {
        await cancelPayment(paymentKey, amount, '주문 생성 실패로 인한 자동 취소');
        await transactionRef.update({
          status: 'rollback',
          updatedAt: FieldValue.serverTimestamp(),
        });
      } catch (cancelError) {
        console.error('Payment rollback failed:', cancelError);
        // 수동 처리 필요 - 알림 발송
        await notifyAdminForManualRollback(orderId, paymentKey, amount);
      }
    }

    return { success: false, error: error.message };
  }
}
```

---

## 🟠 Phase 2: 성능 최적화 (1주)

### 2.1 스케줄러 쿼리 최적화

**현재 문제**: 스케줄러에서 전체 문서 조회 (limit 없음)

**수정 전**:
```typescript
// 현재: 모든 활성 알림 조회
const alertsSnapshot = await db.collection('priceAlerts')
  .where('isActive', '==', true)
  .get();
```

**수정 후**:
```typescript
// 개선: 배치 처리 + limit
const BATCH_SIZE = 100;
let lastDoc: DocumentSnapshot | null = null;

do {
  let query = db.collection('priceAlerts')
    .where('isActive', '==', true)
    .limit(BATCH_SIZE);

  if (lastDoc) {
    query = query.startAfter(lastDoc);
  }

  const batch = await query.get();

  if (batch.empty) break;

  // 배치 처리
  await Promise.all(batch.docs.map(processPriceAlert));

  lastDoc = batch.docs[batch.docs.length - 1];
} while (true);
```

**적용 대상 스케줄러**:
- [ ] `checkPriceAlerts` - `priceAlerts` 쿼리
- [ ] `checkDragonBallExpiry` - `dragonBalls` collectionGroup 쿼리
- [ ] `checkSettlementNotifications` - `orders` 쿼리
- [ ] `checkReturnAddressDeadline` - `refundRequests` 쿼리
- [ ] `notifyRefundApprovalDeadline` - `refundRequests` 쿼리

---

### 2.2 dragonBalls 쿼리 최적화

**현재 문제**: `collectionGroup` 쿼리가 모든 사용자의 dragonBalls를 스캔

**현재**:
```typescript
// 비효율적: 전체 사용자 스캔
const expiring = await db.collectionGroup('dragonBalls')
  .where('status', '==', 'active')
  .where('expiresAt', '<=', sevenDaysLater)
  .get();
```

**개선 방안 1: 루트 컬렉션으로 이동** (권장)
```typescript
// 신규 컬렉션 구조
// dragonBalls/{ballId} (루트 레벨)
//   - userId: string (소유자)
//   - status: string
//   - expiresAt: timestamp

// 마이그레이션 스크립트 필요
```

**개선 방안 2: 캐시 컬렉션 사용**
```typescript
// dragonBall_expiry_cache 컬렉션
// 만료 예정 항목만 캐시
{
  ballId: string,
  userId: string,
  expiresAt: timestamp
}
```

---

### 2.3 Rate Limiting 추가

**적용 대상**: 결제 엔드포인트

```typescript
// functions/src/middleware/rate-limiter.ts (신규)

import rateLimit from 'express-rate-limit';

export const paymentRateLimiter = rateLimit({
  windowMs: 60 * 1000, // 1분
  max: 5, // 분당 최대 5회
  message: {
    error: 'Too many payment requests, please try again later.',
    retryAfter: 60
  },
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator: (req) => {
    // Firebase Auth UID 기반 제한
    return req.headers.authorization?.replace('Bearer ', '') || req.ip || 'unknown';
  }
});

// 적용
app.use('/payment', paymentRateLimiter);
app.use('/toss-payment', paymentRateLimiter);
```

---

### 2.4 캐싱 전략

**1. base_parts 캐싱** (1시간 TTL)
```typescript
// functions/src/cache/parts-cache.ts (신규)

import { getFirestore } from 'firebase-admin/firestore';

interface CacheEntry<T> {
  data: T;
  expiresAt: number;
}

class PartsCache {
  private cache = new Map<string, CacheEntry<any>>();
  private TTL = 60 * 60 * 1000; // 1시간

  async getBasePart(basePartId: string): Promise<any> {
    const cached = this.cache.get(basePartId);
    if (cached && cached.expiresAt > Date.now()) {
      return cached.data;
    }

    const doc = await getFirestore()
      .collection('base_parts')
      .doc(basePartId)
      .get();

    const data = doc.data();
    this.cache.set(basePartId, {
      data,
      expiresAt: Date.now() + this.TTL
    });

    return data;
  }

  invalidate(basePartId: string) {
    this.cache.delete(basePartId);
  }
}

export const partsCache = new PartsCache();
```

---

## 🟡 Phase 3: 데이터 정합성 (1주)

### 3.1 컬렉션 이름 통일

**현재 중복**:
- `sell_requests` vs `sellRequests` (둘 다 사용)

**결정**: `sell_requests` (snake_case) 유지

**마이그레이션**:
```typescript
// functions/src/migration/consolidate_sell_requests.ts

export async function consolidateSellRequests() {
  const db = getFirestore();
  const oldCollection = db.collection('sellRequests');
  const newCollection = db.collection('sell_requests');

  const oldDocs = await oldCollection.get();

  const batch = db.batch();
  for (const doc of oldDocs.docs) {
    // 새 컬렉션에 복사
    batch.set(newCollection.doc(doc.id), doc.data());
    // 이전 문서 삭제
    batch.delete(doc.ref);
  }

  await batch.commit();
  console.log(`Migrated ${oldDocs.size} documents`);
}
```

**클라이언트 코드 수정**:
```dart
// 모든 'sellRequests' 참조를 'sell_requests'로 변경
// lib/features/sell_request/data/datasources/
```

---

### 3.2 비정규화 적용

**listings 컬렉션에 base_parts 정보 포함**:

```typescript
// listings 문서 구조 개선
{
  listingId: string,
  basePartId: string,
  // 비정규화된 필드 (base_parts에서 복사)
  basePartInfo: {
    modelName: string,
    brand: string,
    category: string,
    lowestPrice: number,    // 현재 최저가
    averagePrice: number,   // 현재 평균가
    listingCount: number    // 현재 매물 수
  },
  // 기존 필드들...
}
```

**동기화 트리거**:
```typescript
// base_parts 업데이트 시 관련 listings 동기화
export const onBasePartUpdated = functions.firestore
  .document('base_parts/{basePartId}')
  .onUpdate(async (change, context) => {
    const { basePartId } = context.params;
    const newData = change.after.data();

    // 해당 base_part를 참조하는 모든 listings 업데이트
    const listings = await getFirestore()
      .collection('listings')
      .where('basePartId', '==', basePartId)
      .get();

    const batch = getFirestore().batch();
    for (const doc of listings.docs) {
      batch.update(doc.ref, {
        'basePartInfo.lowestPrice': newData.lowestPrice,
        'basePartInfo.averagePrice': newData.averagePrice,
        'basePartInfo.listingCount': newData.listingCount,
      });
    }

    await batch.commit();
  });
```

---

### 3.3 감사 로그 추가

**auditLogs 컬렉션 생성**:

```typescript
// functions/src/audit/audit-logger.ts (신규)

interface AuditLog {
  action: string;
  actorId: string;
  actorEmail?: string;
  targetType: 'order' | 'refund' | 'listing' | 'user' | 'payment';
  targetId: string;
  previousState?: any;
  newState?: any;
  metadata?: Record<string, any>;
  timestamp: FieldValue;
  ipAddress?: string;
}

export async function logAudit(log: Omit<AuditLog, 'timestamp'>): Promise<void> {
  await getFirestore().collection('auditLogs').add({
    ...log,
    timestamp: FieldValue.serverTimestamp(),
  });
}

// 사용 예시
await logAudit({
  action: 'REFUND_COMPLETED',
  actorId: 'system',
  targetType: 'refund',
  targetId: refundId,
  previousState: { status: 'inspectionPass' },
  newState: { status: 'refundCompleted' },
  metadata: { refundAmount: 50000 }
});
```

---

## 🟢 Phase 4: 확장성 개선 (2주)

### 4.1 검색 기능 고도화

**현재 문제**: 클라이언트 측 필터링, 전체 데이터 로드

**해결 방안**: Algolia 또는 Meilisearch 도입

```typescript
// functions/src/search/algolia-sync.ts

import algoliasearch from 'algoliasearch';

const client = algoliasearch(
  process.env.ALGOLIA_APP_ID!,
  process.env.ALGOLIA_ADMIN_KEY!
);
const index = client.initIndex('listings');

// Firestore 트리거로 동기화
export const onListingWritten = functions.firestore
  .document('listings/{listingId}')
  .onWrite(async (change, context) => {
    const { listingId } = context.params;

    if (!change.after.exists) {
      // 삭제됨
      await index.deleteObject(listingId);
      return;
    }

    const data = change.after.data()!;

    // Algolia에 인덱싱
    await index.saveObject({
      objectID: listingId,
      modelName: data.modelName,
      brand: data.brand,
      category: data.category,
      price: data.price,
      status: data.status,
      condition: data.condition,
      createdAt: data.createdAt?.toMillis(),
      // 검색용 추가 필드
      _tags: [data.category, data.brand, data.condition],
    });
  });
```

---

### 4.2 알림 시스템 개선

**FCM 푸시 알림 추가**:

```typescript
// functions/src/notifications/push-notification.ts

import { getMessaging } from 'firebase-admin/messaging';

export async function sendPushNotification(
  userId: string,
  title: string,
  body: string,
  data?: Record<string, string>
): Promise<void> {
  // 사용자의 FCM 토큰 조회
  const userDoc = await getFirestore()
    .collection('users')
    .doc(userId)
    .get();

  const fcmToken = userDoc.data()?.fcmToken;
  if (!fcmToken) return;

  await getMessaging().send({
    token: fcmToken,
    notification: { title, body },
    data,
    android: {
      priority: 'high',
      notification: {
        channelId: 'picom_notifications',
        clickAction: 'FLUTTER_NOTIFICATION_CLICK',
      },
    },
    apns: {
      payload: {
        aps: {
          badge: 1,
          sound: 'default',
        },
      },
    },
  });
}
```

---

### 4.3 모니터링 및 알림

**Cloud Functions 에러 모니터링**:

```typescript
// functions/src/monitoring/error-handler.ts

export function handleFunctionError(
  functionName: string,
  error: Error,
  context?: any
): void {
  console.error(`[${functionName}] Error:`, error);

  // Slack 알림 (선택)
  // await sendSlackAlert(functionName, error);

  // Firestore에 에러 로그 저장
  getFirestore().collection('errorLogs').add({
    functionName,
    errorMessage: error.message,
    errorStack: error.stack,
    context: JSON.stringify(context),
    timestamp: FieldValue.serverTimestamp(),
  });
}
```

---

## 📊 컬렉션 스키마 정리

### 최종 컬렉션 구조

```
Firestore Database
├── users/{userId}                    # 사용자 정보
│   ├── cart/{cartItemId}            # 장바구니
│   ├── favorites/{favoriteId}       # 찜 목록
│   ├── addresses/{addressId}        # 배송지
│   └── priceAlerts/{alertId}        # 가격 알림
│
├── listings/{listingId}              # 매물
├── base_parts/{basePartId}           # 부품 기준 정보
├── orders/{orderId}                  # 주문
├── payments/{tid}                    # Kakao Pay 결제
├── toss_payments/{paymentKey}        # Toss 결제
├── payment_transactions/{orderId}    # 결제 트랜잭션 (신규)
├── refundRequests/{refundId}         # 환불 요청
├── dragonBalls/{ballId}              # 드래곤볼 보관 (루트로 이동 권장)
├── batchShipments/{shipmentId}       # 일괄 배송
├── sell_requests/{requestId}         # 판매 요청
├── notifications/{notificationId}    # 알림
├── priceHistory/{snapshotId}         # 가격 히스토리
├── auditLogs/{logId}                 # 감사 로그 (신규)
└── errorLogs/{logId}                 # 에러 로그 (신규)
```

---

## ✅ 체크리스트

### Phase 1: Critical (즉시)
- [ ] Admin UID 환경변수로 이동
- [ ] Firestore 인덱스 배포
- [ ] 결제 트랜잭션 로직 구현

### Phase 2: 성능 (1주)
- [ ] 스케줄러 배치 처리 적용
- [ ] dragonBalls 쿼리 최적화
- [ ] Rate limiting 추가
- [ ] base_parts 캐싱 구현

### Phase 3: 데이터 정합성 (1주)
- [ ] 컬렉션 이름 통일 (sellRequests → sell_requests)
- [ ] listings 비정규화 적용
- [ ] 감사 로그 추가

### Phase 4: 확장성 (2주)
- [ ] Algolia/Meilisearch 검색 연동
- [ ] FCM 푸시 알림 추가
- [ ] 에러 모니터링 시스템

---

## 🔗 프론트엔드 연동 포인트

### Flutter 앱 수정 필요 항목

| 백엔드 변경 | 프론트엔드 영향 | 파일 |
|------------|---------------|------|
| sell_requests 통일 | 컬렉션 참조 변경 | `sell_request_repository_impl.dart` |
| listings 비정규화 | 모델 필드 추가 | `listing_model.dart` |
| 결제 트랜잭션 | 에러 핸들링 개선 | `checkout_screen.dart` |
| 감사 로그 | 없음 (서버 측) | - |
| FCM 푸시 | 토큰 등록 로직 | `notification_provider.dart` |

---

## 📅 실행 일정

```
Week 1: Phase 1 (Critical)
├── Day 1-2: Admin UID 수정 + 인덱스 배포
└── Day 3-5: 결제 트랜잭션 구현

Week 2: Phase 2 (성능)
├── Day 1-3: 스케줄러 + 쿼리 최적화
└── Day 4-5: Rate limiting + 캐싱

Week 3: Phase 3 (데이터)
├── Day 1-2: 컬렉션 정리
└── Day 3-5: 비정규화 + 감사 로그

Week 4-5: Phase 4 (확장성)
├── Week 4: 검색 고도화
└── Week 5: 푸시 알림 + 모니터링
```

---

*이 문서는 Alfred (MoAI-ADK)에 의해 생성되었습니다.*
*최종 수정: 2026-01-22*
