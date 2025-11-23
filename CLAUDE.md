# Claude Code Instructions for PiCom

**Last Updated**: 2025-11-23
**Current Version**: 1.0.7+8
**Project**: PiCom (파이컴퓨터) - Used PC Parts Trading Platform

## Task Master AI Instructions
**Import Task Master's development workflow commands and guidelines, treat as if import is in the main CLAUDE.md file.**
@./.taskmaster/CLAUDE.md

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Technology Stack](#technology-stack)
3. [Architecture](#architecture)
4. [Directory Structure](#directory-structure)
5. [Development Workflows](#development-workflows)
6. [Key Conventions](#key-conventions)
7. [Firebase Configuration](#firebase-configuration)
8. [Common Tasks](#common-tasks)
9. [Critical Issues](#critical-issues)
10. [Security Guidelines](#security-guidelines)
11. [Deployment](#deployment)
12. [Troubleshooting](#troubleshooting)

---

## Project Overview

### What is PiCom?

PiCom is a **full-stack multi-platform used PC parts trading platform** for the Korean market. It enables users to:
- Buy and sell used PC components (CPU, GPU, RAM, etc.)
- Get AI-powered PC build recommendations
- Track price history and set price alerts
- Store purchased parts for free (30-day "DragonBall" service)
- Make secure payments via KakaoPay

### Platform Strategy

- **Framework**: Flutter (cross-platform)
- **Deployment Targets**:
  - Mobile: Android (primary), iOS
  - Desktop: Windows, macOS, Linux
  - Web: Progressive Web App (PWA)
- **Routing**:
  - Web: GoRouter (declarative)
  - Mobile/Desktop: Navigator (imperative)
  - Platform detection in `/lib/app.dart:68`

### Key Features

1. **Marketplace** - Browse and purchase used PC parts
2. **DragonBall Storage** - Free 30-day part storage after purchase
3. **Price Tracking** - Historical price data and alerts
4. **PC Recommendations** - Curated build suggestions
5. **Sell Requests** - Submit parts for sale (admin approval)
6. **KakaoPay Integration** - Secure Korean payment system
7. **Admin Dashboard** - Full management portal

---

## Technology Stack

### Frontend (Flutter/Dart)

```yaml
Core:
  - Flutter SDK: ^3.8.1
  - Dart SDK: ^3.8.1

State Management:
  - flutter_riverpod: ^2.6.1 (Primary)

Firebase:
  - firebase_core: ^4.2.0
  - firebase_auth: ^6.1.1
  - cloud_firestore: ^6.0.3
  - firebase_storage: ^13.0.3
  - cloud_functions: ^6.0.3

Authentication:
  - google_sign_in: ^6.2.1
  - kakao_flutter_sdk_user: ^1.9.6

Navigation:
  - go_router: ^16.2.5 (Web only)

UI/UX:
  - google_fonts: ^6.2.1
  - material_symbols_icons: ^4.2785.1
  - cached_network_image: ^3.3.0
  - fl_chart: ^0.65.0

Utilities:
  - uuid: ^4.5.1
  - dio: ^5.4.0
  - shared_preferences: ^2.2.2
  - intl: ^0.19.0
```

### Backend

**Firebase Services**:
- Firestore (NoSQL database, asia-northeast3)
- Authentication (Google + Kakao)
- Storage (Images and files)
- Cloud Functions (Node.js 22, TypeScript)
- Hosting (Web deployment)

**Express.js Server** (`/backend_example`):
- Purpose: KakaoPay API proxy (Admin Key protection)
- Framework: Express.js ^5.1.0
- Port: 3000

**Node.js Scripts** (Root):
- `exceljs: ^4.4.0` - Excel data processing
- `firebase-admin: ^13.5.0` - Admin SDK
- `task-master-ai: ^0.31.2` - AI task automation

---

## Architecture

### Clean Architecture Pattern

Every feature follows Clean Architecture with three layers:

```
lib/features/{feature_name}/
├── data/                    # Data Layer
│   ├── datasources/         # Remote/Local data sources
│   ├── models/              # Data models (JSON serialization)
│   └── repositories/        # Repository implementations
├── domain/                  # Domain Layer
│   ├── entities/            # Business entities
│   ├── repositories/        # Repository interfaces
│   ├── services/            # Business services
│   └── usecases/            # Use cases (business logic)
└── presentation/            # Presentation Layer
    ├── providers/           # Riverpod state providers
    ├── screens/             # UI screens
    └── widgets/             # Reusable widgets
```

### Features (19 total)

1. **address** - Address management (Daum Postcode API)
2. **admin** - Admin dashboard and management
3. **auth** - Authentication (Google, Kakao)
4. **cart** - Shopping cart
5. **checkout** - Payment checkout (KakaoPay)
6. **dragon_ball** - PC parts storage service
7. **home** - Main landing screen
8. **listing** - Used parts marketplace
9. **my_page** - User profile and history
10. **notification** - Real-time notifications
11. **order** - Order management
12. **parts_price** - BasePart info and pricing
13. **payment** - Payment service integration
14. **price_alert** - Price drop alerts
15. **price_history** - Historical price data
16. **recommendation** - PC build recommendations
17. **refund** - Refund management
18. **sell_request** - Sell request submissions
19. **web_public** - Public web pages (landing, terms)

---

## Directory Structure

```
/home/user/pi_com/
├── lib/                          # Main Flutter application
│   ├── main.dart                 # Entry point (Firebase init)
│   ├── app.dart                  # Platform routing fork
│   ├── firebase_options.dart     # Auto-generated Firebase config
│   ├── core/                     # Shared core functionality
│   │   ├── constants/            # Route names, storage policy, etc.
│   │   ├── models/               # Shared data models
│   │   ├── providers/            # Global Riverpod providers
│   │   ├── repositories/         # Shared repositories
│   │   ├── router/               # app_router.dart (Navigator)
│   │   └── utils/                # Helper functions
│   ├── features/                 # 19 feature modules
│   └── shared/                   # Shared UI components
│       ├── providers.dart        # Global providers
│       └── widgets/              # Common widgets
│
├── android/                      # Android native code
├── ios/                          # iOS native code
├── web/                          # Web-specific files
├── windows/, macos/, linux/      # Desktop platforms
│
├── functions/                    # Firebase Cloud Functions
│   ├── src/
│   │   ├── index.ts              # Main exports + KakaoPay API
│   │   ├── schedulers/           # Cron jobs
│   │   └── refund/               # Refund logic
│   └── package.json              # Node 22 runtime
│
├── backend_example/              # Express.js payment proxy
│   ├── server.js
│   └── routes/payment.js
│
├── scripts/                      # Data management scripts
│   ├── upload_sequential.js      # Excel → Firestore
│   ├── upload_images_to_storage.js
│   └── *.js                      # 20+ utility scripts
│
├── datas/                        # Source data files
│   ├── *.xlsx                    # CPU, GPU, Mainboard data
│   └── *.py                      # Python data generators
│
├── assets/                       # Application assets
│   ├── data/estimate_full.json   # PC build estimates
│   ├── html/                     # Policy pages
│   └── images/                   # App images
│
├── docs/                         # Documentation
│   ├── EPIC3_IMPLEMENTATION_DETAILS.md
│   ├── WEB_HOSTING_GUIDE.md
│   └── *.md
│
├── .env.example                  # Environment variables template
├── firebase.json                 # Firebase configuration
├── firestore.rules               # Security rules (PRODUCTION)
├── firestore.indexes.json        # Database indexes
├── storage.rules                 # Storage security rules
├── pubspec.yaml                  # Flutter dependencies
├── package.json                  # Node.js dependencies
└── tsconfig.json                 # TypeScript config
```

---

## Development Workflows

### Initial Setup

1. **Install Dependencies**:
```bash
# Flutter dependencies
flutter pub get

# Firebase Functions dependencies
cd functions
npm install

# Backend server dependencies (if needed)
cd backend_example
npm install
```

2. **Environment Setup**:
```bash
# Copy environment template
cp .env.example .env

# Edit .env with your keys
# Note: Firebase keys in lib/firebase_options.dart are safe to commit
```

3. **Firebase Configuration**:
```bash
# Login to Firebase
firebase login

# Select project
firebase use picom-team

# Deploy Firestore indexes (first time)
firebase deploy --only firestore:indexes
```

### Running the App

**Mobile (Android/iOS)**:
```bash
# Debug mode
flutter run

# Release mode
flutter run --release

# Specific device
flutter run -d chrome      # Web
flutter run -d android     # Android
flutter run -d macos       # macOS
```

**Web**:
```bash
flutter run -d chrome
```

**Backend Server** (optional, for local KakaoPay testing):
```bash
cd backend_example
npm start
# Server runs on http://localhost:3000
```

### Code Generation

No code generation tools are currently used. Models use manual JSON serialization.

### Testing

```bash
# Run all tests
flutter test

# Note: Test coverage is currently minimal
```

---

## Key Conventions

### Naming Conventions

**Files**:
- Screens: `*_screen.dart` (e.g., `checkout_screen.dart`)
- Widgets: `*_widget.dart` or descriptive names
- Models: `*_model.dart`
- Providers: `*_provider.dart`
- UseCases: `*_usecase.dart`

**Classes**:
- Screens: `*Screen` (e.g., `CheckoutScreen`)
- Widgets: descriptive names (e.g., `ProductCard`)
- Models: `*Model` (e.g., `ListingModel`)
- Providers: `*Provider` or `*NotifierProvider`

**Variables**:
- camelCase for variables and functions
- UPPER_SNAKE_CASE for constants

### Code Style

**State Management**:
```dart
// Use Riverpod for all state
final myProvider = StateProvider<int>((ref) => 0);

// In widgets
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(myProvider);
    // ...
  }
}
```

**Navigation**:
```dart
// Mobile (Navigator)
Navigator.pushNamed(context, Routes.checkout);

// Web (GoRouter - handled in app.dart)
context.go('/checkout');
```

**Error Handling**:
```dart
// Always wrap Firestore/Network calls in try-catch
try {
  await firestore.collection('orders').doc(id).set(data);
} on FirebaseException catch (e) {
  debugPrint('Firebase error: ${e.message}');
  throw Exception('Failed to create order');
} catch (e) {
  debugPrint('Unexpected error: $e');
  rethrow;
}
```

**Logging**:
- Use `debugPrint()` for development logging
- **TODO**: Replace `print()` statements (46 instances) with proper logging
- Never log sensitive data (passwords, payment info, etc.)

### Platform Detection

```dart
import 'package:flutter/foundation.dart';

// Check platform
if (kIsWeb) {
  // Web-specific code
} else if (Platform.isAndroid) {
  // Android-specific code
}

// Responsive design
import 'package:pi_com/core/utils/responsive_helper.dart';

if (ResponsiveHelper.isMobile(context)) {
  // Mobile layout
} else {
  // Desktop layout
}
```

---

## Firebase Configuration

### Firestore Collections

#### 1. users
- **Purpose**: User profiles
- **Security**: User owns data, admin full access
- **Key Fields**: `uid`, `email`, `displayName`, `isAdmin`, `role`

#### 2. base_parts
- **Purpose**: Part specifications and pricing
- **Security**: Public read, admin write
- **Key Fields**: `basePartId`, `category`, `brand`, `modelName`, `lowestPrice`, `averagePrice`, `listingCount`
- **Indexes**:
  - `category + brand`
  - `modelName`

#### 3. listings
- **Purpose**: Marketplace listings
- **Security**: Public read, seller writes, admin full
- **Key Fields**: `listingId`, `basePartId`, `sellerId`, `price`, `condition`, `status`, `images[]`
- **Indexes**:
  - `status + createdAt` (DESC)
  - `status + basePartId + price`
  - `sellerId + status`

#### 4. orders
- **Purpose**: Purchase orders
- **Security**: User owns data, **no deletion** (audit log)
- **Key Fields**: `orderId`, `userId`, `items[]`, `totalAmount`, `status`, `createdAt`
- **Indexes**:
  - `userId + createdAt` (DESC)
  - `orderId` (unique)

#### 5. payments
- **Purpose**: Payment transactions
- **Security**: User owns data, **no deletion** (audit log)
- **Key Fields**: `tid`, `orderId`, `userId`, `amount`, `status`, `provider`, `createdAt`

#### 6. dragonBalls
- **Purpose**: Stored parts (30-day free storage)
- **Security**: User owns data, admin reads
- **Key Fields**: `userId`, `partName`, `expiresAt`, `status`, `purchaseDate`
- **Policy**: See `lib/core/constants/storage_policy.dart`

#### 7. sellRequests
- **Purpose**: Sell request submissions
- **Security**: User owns data, admin manages
- **Key Fields**: `userId`, `category`, `partName`, `price`, `images[]`, `status`

#### 8. notifications
- **Purpose**: User notifications
- **Security**: User owns data
- **Key Fields**: `userId`, `title`, `message`, `type`, `isRead`, `createdAt`

#### 9. priceHistory
- **Purpose**: Historical pricing data
- **Security**: Public read, system writes
- **Key Fields**: `basePartId`, `timestamp`, `lowestPrice`, `averagePrice`

#### 10-12. favorites, priceAlerts, refunds
- Self-explanatory purposes
- User-owned data

### Firebase Storage Structure

```
storage/
├── users/{userId}/profile.jpg
├── listings/{listingId}/image1.jpg
├── sellRequests/{requestId}/images/
└── base_parts/{basePartId}/thumbnail.jpg
```

### Firebase Functions

**Main API** (`/api`):
- `/auth/kakao` - Custom token generation
- `/payment/prepare` - KakaoPay payment initialization
- `/payment/approve` - Payment confirmation
- `/payment/cancel` - Payment cancellation

**Scheduled Functions**:
- `checkPriceAlerts` - Daily 10 AM price alert checker
- `checkDragonBallExpiry` - Daily 9 AM storage expiry notifications
- `checkStorageNotifications` - Storage period warnings
- `checkSettlementNotifications` - Settlement reminders
- `checkReturnAddressDeadline` - Return address deadline checks

**Triggers**:
- `onListingCreated/Updated/Deleted` - Auto-update BasePart stats
- `searchParts` - Search functionality
- `addSearchKeywordsToParts` - Keyword indexing

---

## Common Tasks

### Adding a New Feature

1. **Create Feature Directory**:
```bash
mkdir -p lib/features/my_feature/data/datasources
mkdir -p lib/features/my_feature/data/models
mkdir -p lib/features/my_feature/data/repositories
mkdir -p lib/features/my_feature/domain/entities
mkdir -p lib/features/my_feature/domain/repositories
mkdir -p lib/features/my_feature/domain/usecases
mkdir -p lib/features/my_feature/presentation/providers
mkdir -p lib/features/my_feature/presentation/screens
mkdir -p lib/features/my_feature/presentation/widgets
```

2. **Follow Clean Architecture**:
   - Start with entity (domain)
   - Create repository interface (domain)
   - Implement data sources and repositories (data)
   - Build use cases (domain)
   - Create providers and screens (presentation)

3. **Add Routes**:
```dart
// lib/core/constants/routes.dart
static const String myFeature = '/my-feature';

// lib/core/router/app_router.dart (mobile)
case Routes.myFeature:
  return MaterialPageRoute(builder: (_) => MyFeatureScreen());

// lib/app.dart (web, GoRouter routes)
GoRoute(
  path: '/my-feature',
  builder: (context, state) => MyFeatureScreen(),
),
```

### Updating Firestore Data

**Using Scripts**:
```bash
cd scripts

# Upload from Excel
node upload_sequential.js

# Upload images
node upload_images_to_storage.js

# Delete collections
node delete_collections.js
```

**Using Firebase Admin SDK**:
```javascript
const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// Update document
await db.collection('base_parts').doc(id).update({
  price: 50000
});
```

### Deploying to Firebase

**Firestore Rules**:
```bash
firebase deploy --only firestore:rules
```

**Cloud Functions**:
```bash
cd functions
npm run build
firebase deploy --only functions

# Or specific function
firebase deploy --only functions:checkPriceAlerts
```

**Hosting (Web)**:
```bash
flutter build web --release
firebase deploy --only hosting
```

**All at once**:
```bash
firebase deploy
```

### Building Release APK/AAB

**APK**:
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

**App Bundle** (for Play Store):
```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

**Note**: ProGuard is enabled for release builds (`android/app/proguard-rules.pro`)

---

## Critical Issues

### 🚨 URGENT: Fix Before Production Launch

The following 4 issues MUST be fixed before deploying to production:

#### 1. Payment-Order Transaction Safety ⭐⭐⭐⭐⭐

**File**: `lib/features/checkout/presentation/screens/checkout_screen.dart:443`

**Problem**: Payment approved but order creation fails → No rollback

**Solution**:
```dart
try {
  final approvedPayment = await approvePaymentUseCase(...);

  try {
    await ref.read(purchaseUseCaseProvider).call(...);
  } catch (orderError) {
    // Immediately cancel payment if order creation fails
    await cancelPaymentUseCase(approvedPayment.tid);
    throw Exception('Order creation failed, payment cancelled');
  }
} catch (e) {
  showErrorDialog('Payment processing failed');
}
```

#### 2. Duplicate Payment Prevention ⭐⭐⭐⭐⭐

**File**: `lib/features/checkout/presentation/screens/checkout_screen.dart:394`

**Problem**: Timestamp-based orderId vulnerable to race conditions

**Solution**:
```dart
import 'package:uuid/uuid.dart';

final orderId = 'ORDER_${const Uuid().v4()}';  // Use UUID
```

#### 3. Network Timeout Configuration ⭐⭐⭐⭐

**File**: `lib/features/payment/data/datasources/payment_remote_datasource_impl.dart:46, 82, 125`

**Problem**: Dio requests have no timeout → infinite wait risk

**Solution**:
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

#### 4. Order Creation Error Handling ⭐⭐⭐⭐

**File**: `lib/features/checkout/data/datasources/order_remote_datasource_impl.dart:19`

**Problem**: No try-catch for Firestore operations

**Solution**:
```dart
Future<void> createOrder(OrderModel order) async {
  try {
    await _firestore.collection('orders').doc(order.orderId).set(order.toFirestore());
  } on FirebaseException catch (e) {
    throw Exception('Order creation failed: ${e.message}');
  } catch (e) {
    throw Exception('Unexpected error during order creation');
  }
}
```

**Status**: See `DEPLOYMENT_STATUS.md` for detailed tracking

---

## Security Guidelines

### API Keys

**Firebase API Keys** (PUBLIC - Safe in code):
- Location: `lib/firebase_options.dart`
- These keys are CLIENT-SAFE
- Security is managed by Firestore Rules

**KakaoPay Admin Key** (PRIVATE - Never commit):
- Location: Firebase Functions environment config
- Set with: `firebase functions:config:set kakaopay.admin_key="..."`
- Never hardcode in source code

### Firestore Security Rules

**Current State**: PRODUCTION MODE (Strict)

**Key Principles**:
1. Users can only access their own data
2. Admins identified by `isAdmin: true` in `users` collection
3. Public data (parts, listings) is read-only
4. All writes require authentication
5. Orders and payments are **never deletable** (audit log)

**Deployment**:
```bash
firebase deploy --only firestore:rules
```

### User Data Protection

**Personal Data Collected**:
- Email, password (encrypted)
- Nickname, profile image (optional)
- Shipping address (order-time only)
- Purchase/sell history

**Data Deletion**:
- User can request account deletion
- Personal data deleted, but orders/payments retained for 5 years (legal requirement)

**Compliance**:
- Privacy policy: `web/privacy_policy.html`
- Terms of service: `web/termsofuse.html`
- See `SECURITY_GUIDE.md` for full details

---

## Deployment

### Current Version

**Version**: 1.0.7+8 (from `pubspec.yaml` and `android/app/build.gradle.kts`)

**Build Configuration**:
- Target SDK: 36 (Android 15)
- ProGuard: Enabled
- Firestore Rules: Production mode

### Pre-Launch Checklist

Before deploying to production:

- [ ] Fix 4 critical payment/order issues (see Critical Issues section)
- [ ] Verify KakaoPay CID is production (not test `TC0ONETIME`)
- [ ] Test complete purchase flow end-to-end
- [ ] Deploy Firestore Rules: `firebase deploy --only firestore:rules`
- [ ] Deploy Cloud Functions: `firebase deploy --only functions`
- [ ] Generate release keystore for signing
- [ ] Update `android/key.properties` with keystore info
- [ ] Build release AAB: `flutter build appbundle --release`
- [ ] Upload to Play Store Internal Testing
- [ ] Test on real devices
- [ ] Monitor first 24 hours intensively

**Full Checklist**: See `PRE_LAUNCH_CHECKLIST.md`

### Deployment Commands

**Build**:
```bash
# Clean build
flutter clean
flutter pub get

# Android App Bundle (Play Store)
flutter build appbundle --release

# Web
flutter build web --release
```

**Deploy**:
```bash
# Firebase (all services)
firebase deploy

# Or individually
firebase deploy --only hosting
firebase deploy --only functions
firebase deploy --only firestore:rules
```

**Version Bump**:
```yaml
# pubspec.yaml
version: 1.0.8+9  # Format: MAJOR.MINOR.PATCH+BUILD_NUMBER

# Also update android/app/build.gradle.kts
versionCode = 9
versionName = "1.0.8"
```

---

## Troubleshooting

### Common Issues

#### Firestore Permission Denied

**Symptom**: `FirebaseException: PERMISSION_DENIED`

**Causes**:
1. User not authenticated
2. Security rules blocking access
3. Trying to delete orders/payments

**Fix**:
```dart
// Ensure user is authenticated
final user = FirebaseAuth.instance.currentUser;
if (user == null) {
  throw Exception('User must be logged in');
}

// Check security rules in firestore.rules
```

#### KakaoPay Payment Fails

**Symptom**: Payment initialization fails or returns error

**Causes**:
1. Using test CID in production
2. Invalid Admin Key
3. Network timeout

**Fix**:
```bash
# Check Firebase Functions config
firebase functions:config:get

# Ensure production CID
firebase functions:config:set kakaopay.cid="YOUR_PRODUCTION_CID"

# Redeploy functions
firebase deploy --only functions
```

#### Web Build Fails

**Symptom**: `flutter build web` fails

**Common fixes**:
```bash
# Clear cache
flutter clean

# Update dependencies
flutter pub get

# Check for null safety issues
dart migrate --apply-changes

# Rebuild
flutter build web --release
```

#### Firebase Functions Timeout

**Symptom**: Cloud Functions timeout or run slowly

**Fixes**:
- Increase timeout in `firebase.json`:
```json
"functions": {
  "source": "functions",
  "runtime": "nodejs22",
  "timeout": "60s"  // Increase from default 10s
}
```
- Optimize Firestore queries (add indexes)
- Use batched writes for bulk operations

### Debugging Tips

**Enable Firestore Debug Logging**:
```dart
// lib/main.dart
if (kDebugMode) {
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: false,
  );
}
```

**View Firebase Functions Logs**:
```bash
firebase functions:log

# Real-time
firebase functions:log --only checkPriceAlerts
```

**Check Firestore Indexes**:
```bash
# View current indexes
firebase firestore:indexes

# Deploy indexes
firebase deploy --only firestore:indexes
```

**Test Security Rules Locally**:
```bash
firebase emulators:start --only firestore

# In another terminal
firebase emulators:exec "npm test"
```

---

## Additional Resources

### Documentation Files

- **APP_STRUCTURE.md** - Complete app architecture overview
- **DEPLOYMENT_STATUS.md** - Current deployment state and issues
- **SECURITY_GUIDE.md** - Security configurations and best practices
- **ROADMAP.md** - Development roadmap (13-week plan)
- **VERSION_HISTORY.md** - Version changelog
- **PLAYSTORE_GUIDE.md** - Play Store deployment guide
- **PRE_LAUNCH_CHECKLIST.md** - Pre-launch verification tasks
- **docs/** - Epic implementation details, hosting guides

### External Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Riverpod Documentation](https://riverpod.dev)
- [Firebase Documentation](https://firebase.google.com/docs)
- [KakaoPay Developer Guide](https://developers.kakaopay.com/)
- [Clean Architecture in Flutter](https://resocoder.com/flutter-clean-architecture-tdd/)

---

## Important Constraints

### DO NOT

- ❌ Commit API keys or secrets (except Firebase client keys)
- ❌ Delete orders or payments from Firestore (audit log)
- ❌ Skip the 4 critical fixes before production launch
- ❌ Use `print()` in production (use `debugPrint()`)
- ❌ Deploy without testing payment flow end-to-end
- ❌ Modify Firestore security rules without understanding implications
- ❌ Push directly to main branch without testing
- ❌ Create new files when existing ones can be edited
- ❌ Add features beyond what's explicitly requested (avoid over-engineering)

### DO

- ✅ Follow Clean Architecture for all new features
- ✅ Use Riverpod for state management
- ✅ Write try-catch blocks for all Firebase/network operations
- ✅ Test on multiple platforms (Android, iOS, Web)
- ✅ Update version numbers before release
- ✅ Deploy Firestore rules and indexes before app release
- ✅ Monitor Firebase console after deployment
- ✅ Keep dependencies up to date
- ✅ Document breaking changes in VERSION_HISTORY.md
- ✅ Prefer editing existing files over creating new ones

---

## Contact & Support

**Development Team**: PiCom Team
**Firebase Project**: `picom-team`
**Project Repository**: Private
**Issue Tracking**: GitHub Issues

For questions about this codebase or development guidelines, refer to the documentation files listed above or reach out to the development team.

---

**Last Reviewed**: 2025-11-23
**Next Review**: After critical fixes implementation
**Maintained By**: Claude Code Assistant
