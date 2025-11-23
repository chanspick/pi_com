# PiCom 개발 로드맵 및 필수 구현 사항

> 작성일: 2025-11-13
> 버전: 1.0.0
> 작성자: Claude Code

---

## 목차

1. [웹사이트 랜딩페이지 구축](#1-웹사이트-랜딩페이지-구축)
2. [추천 시스템 고도화 및 ML 이식](#2-추천-시스템-고도화-및-ml-이식)
3. [Admin 페이지 자동화](#3-admin-페이지-자동화)
4. [엑셀 기반 판매 요청 자동 생성](#4-엑셀-기반-판매-요청-자동-생성)

---

## 1. 웹사이트 랜딩페이지 구축

### 📋 현재 상태
- **기존**: Flutter Web으로 빌드되지만 모바일 앱 UI 그대로 표시
- **문제점**:
  - 웹 브라우저에 최적화되지 않은 레이아웃
  - 데스크톱 화면 크기에서 비효율적인 공간 사용
  - SEO 최적화 부족
  - 웹 사용자 경험 미흡

### 🎯 목표
애플리케이션의 모든 핵심 기능을 웹에 맞게 재디자인하여 반응형 랜딩페이지 구축

### 🔧 구현 단계

#### Phase 1: 웹 전용 레이아웃 설계 (2주)

**Step 1.1: 화면 크기별 레이아웃 정의**
```
- Mobile (< 768px): 현재 앱 디자인 유지
- Tablet (768px - 1024px): 2단 레이아웃
- Desktop (> 1024px): 3단 레이아웃 + 사이드바
```

**Step 1.2: 웹 전용 위젯 생성**
```dart
lib/features/web_public/
├── presentation/
│   ├── widgets/
│   │   ├── web_navbar.dart          ✅ 이미 존재
│   │   ├── web_hero_section.dart    🆕 히어로 섹션
│   │   ├── web_features_grid.dart   🆕 기능 소개 그리드
│   │   ├── web_testimonials.dart    🆕 사용자 후기
│   │   ├── web_pricing_section.dart 🆕 가격 정책
│   │   └── web_footer.dart          🆕 풍부한 푸터
│   └── screens/
│       ├── landing_page.dart        ✅ 이미 존재
│       ├── features_page.dart       🆕 기능 상세
│       └── how_it_works_page.dart   🆕 이용 방법
```

**Step 1.3: 반응형 디자인 유틸리티**
```dart
// lib/core/utils/responsive_helper.dart
class ResponsiveHelper {
  static bool isMobile(BuildContext context) =>
    MediaQuery.of(context).size.width < 768;

  static bool isTablet(BuildContext context) =>
    MediaQuery.of(context).size.width >= 768 &&
    MediaQuery.of(context).size.width < 1024;

  static bool isDesktop(BuildContext context) =>
    MediaQuery.of(context).size.width >= 1024;

  static double getGridCrossAxisCount(BuildContext context) {
    if (isDesktop(context)) return 4;
    if (isTablet(context)) return 2;
    return 1;
  }
}
```

#### Phase 2: 핵심 기능 페이지 웹 전용 구현 (3주)

**Step 2.1: 부품 거래 페이지 (1주)**
```
[ ] 부품 스토어 웹 레이아웃 (PartShopScreen 웹 버전)
  - 좌측: 필터 사이드바 (카테고리, 가격대, 컨디션)
  - 중앙: 그리드 레이아웃 (4열 카드)
  - 우측: 최근 본 상품, 인기 상품

[ ] 부품 상세 페이지 웹 최적화
  - 좌측: 큰 이미지 갤러리 (썸네일 하단 배치)
  - 우측: 상세 정보 + 구매 옵션
  - 하단: 연관 상품 추천

파일: lib/features/listing/presentation/screens/web/
  - part_shop_web_screen.dart
  - listing_detail_web_screen.dart
```

**Step 2.2: 견적 추천 페이지 (1주)**
```
[ ] 견적 입력 폼 웹 최적화
  - 진행 단계 표시 (Step 1: 용도 → Step 2: 예산 → Step 3: 선호도)
  - 각 단계를 한 화면에 배치 (스크롤 없이)
  - 실시간 예상 견적 미리보기 (우측)

[ ] 추천 결과 페이지
  - 좌측: 추천 구성 (부품 목록)
  - 중앙: 성능 벤치마크 그래프
  - 우측: 가격 비교 + 구매 옵션

파일: lib/features/recommendation/presentation/screens/web/
  - my_estimate_web_screen.dart
  - pc_assembly_web_screen.dart
```

**Step 2.3: 가격 시세 페이지 (0.5주)**
```
[ ] 시세 차트 웹 최적화
  - 전체 너비 차트 (1200px)
  - 인터랙티브 툴팁
  - 기간별 필터 (1개월, 3개월, 6개월, 1년)

파일: lib/features/parts_price/presentation/screens/web/
  - price_history_web_screen.dart
```

**Step 2.4: 판매 요청 페이지 (0.5주)**
```
[ ] 판매 요청 폼 웹 최적화
  - 2단 레이아웃 (정보 입력 | 미리보기)
  - 드래그 앤 드롭 이미지 업로드
  - 실시간 예상 가격 표시

파일: lib/features/sell_request/presentation/screens/web/
  - sell_request_web_screen.dart
```

#### Phase 3: SEO 및 성능 최적화 (1주)

**Step 3.1: 메타 태그 및 SEO**
```html
<!-- web/index.html 업데이트 -->
<head>
  <meta name="description" content="중고 컴퓨터 부품 거래 플랫폼 - 시세 확인부터 견적 추천까지">
  <meta name="keywords" content="중고부품, PC견적, 컴퓨터부품, 시세, 거래">

  <!-- Open Graph -->
  <meta property="og:title" content="PiCom - 중고 PC 부품 거래 플랫폼">
  <meta property="og:description" content="...">
  <meta property="og:image" content="https://picom.team/og-image.png">

  <!-- Google Search Console 인증 -->
  <meta name="google-site-verification" content="...">
</head>
```

**Step 3.2: Google Analytics 연동**
```dart
// lib/core/analytics/web_analytics.dart
import 'package:universal_html/html.dart' as html;

class WebAnalytics {
  static void trackPageView(String pageName) {
    if (kIsWeb) {
      html.window.history.pushState(null, '', '/$pageName');
      // GA4 이벤트 전송
    }
  }
}
```

**Step 3.3: 성능 최적화**
```
[ ] 이미지 레이지 로딩
[ ] 코드 스플리팅 (라우트별)
[ ] 캐싱 전략 수립
[ ] Lighthouse 점수 90점 이상 목표
```

#### Phase 4: 배포 및 도메인 설정 (3일)

**Step 4.1: Firebase Hosting 배포**
```bash
# firebase.json 설정
{
  "hosting": {
    "public": "build/web",
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ],
    "headers": [
      {
        "source": "**/*.@(jpg|jpeg|gif|png|svg|webp)",
        "headers": [{
          "key": "Cache-Control",
          "value": "max-age=31536000"
        }]
      }
    ]
  }
}
```

**Step 4.2: 커스텀 도메인 연결**
```
1. 도메인 구매 (picom.team 또는 picom.kr)
2. Firebase Hosting에 도메인 연결
3. SSL 인증서 자동 발급 확인
4. www 리다이렉트 설정
```

### 📊 성공 지표
- [ ] 웹 페이지 로딩 속도 < 3초
- [ ] Lighthouse 성능 점수 > 90
- [ ] 모바일/태블릿/데스크톱 모든 기기에서 정상 작동
- [ ] Google 검색 결과 노출 (2주 내)

---

## 2. 추천 시스템 고도화 및 ML 이식

### 📋 현재 상태
- **기존**: 규칙 기반 추천 시스템 (하드코딩된 조건)
- **위치**: `lib/features/recommendation/`
- **문제점**:
  - 단순 if-else 로직으로 제한적인 추천
  - 사용자 선호도 학습 불가
  - 최신 부품 정보 반영 어려움
  - 성능/가격 최적화 부족

### 🎯 목표
머신러닝 기반 지능형 추천 시스템으로 전환하여 사용자별 최적화된 견적 제공

### 🔧 구현 단계

#### Phase 1: 데이터 수집 및 전처리 (2주)

**Step 1.1: 학습 데이터셋 구축**
```python
# scripts/ml/data_collection.py

필요 데이터:
1. 부품 정보
   - CPU: 코어 수, 클럭, TDP, 벤치마크 점수
   - GPU: VRAM, 코어 클럭, 벤치마크 점수
   - RAM: 용량, 속도, 레이턴시
   - 메인보드: 칩셋, 소켓, 확장 슬롯
   - 저장장치: 용량, 읽기/쓰기 속도

2. 거래 데이터
   - 판매가격 (실제 거래가)
   - 컨디션 스코어
   - 거래 완료 여부
   - 판매 소요 시간

3. 사용자 행동 데이터
   - 검색 키워드
   - 클릭한 부품
   - 찜한 부품
   - 구매한 부품
   - 견적 요청 이력

4. 벤치마크 데이터
   - PassMark CPU 점수
   - 3DMark GPU 점수
   - 게임별 FPS 데이터
```

**Step 1.2: Firestore에서 데이터 추출**
```javascript
// scripts/ml/export_training_data.js
const admin = require('firebase-admin');
const fs = require('fs');

async function exportTrainingData() {
  // 1. base_parts 데이터 추출
  const baseParts = await db.collection('base_parts').get();

  // 2. listings 데이터 추출 (거래 완료된 것만)
  const listings = await db.collection('listings')
    .where('status', '==', 'sold')
    .get();

  // 3. orders 데이터 추출
  const orders = await db.collection('orders').get();

  // 4. CSV/JSON 형태로 저장
  fs.writeFileSync('training_data.json', JSON.stringify({
    baseParts: [...],
    listings: [...],
    orders: [...]
  }));
}
```

**Step 1.3: 데이터 정제 및 특성 공학**
```python
# scripts/ml/preprocess_data.py
import pandas as pd
import numpy as np

def preprocess_cpu_data(df):
    """CPU 데이터 정제"""
    # 1. 결측치 처리
    df['tdp'].fillna(df['tdp'].median(), inplace=True)

    # 2. 범주형 변수 인코딩
    df['brand_encoded'] = pd.get_dummies(df['brand'])

    # 3. 숫자형 변수 정규화
    from sklearn.preprocessing import MinMaxScaler
    scaler = MinMaxScaler()
    df[['cores', 'threads', 'base_clock']] = scaler.fit_transform(
        df[['cores', 'threads', 'base_clock']]
    )

    # 4. 새로운 특성 생성
    df['performance_per_watt'] = df['benchmark_score'] / df['tdp']
    df['price_performance_ratio'] = df['price'] / df['benchmark_score']

    return df

def create_compatibility_matrix():
    """부품 호환성 매트릭스 생성"""
    # CPU 소켓 - 메인보드 소켓 호환성
    # RAM 타입 - 메인보드 RAM 타입 호환성
    # GPU 전력 - PSU 용량 호환성
    pass
```

#### Phase 2: ML 모델 개발 (3주)

**Step 2.1: 추천 모델 아키텍처 설계**
```python
# scripts/ml/models/recommendation_model.py

"""
하이브리드 추천 시스템:
1. 협업 필터링 (Collaborative Filtering)
   - 비슷한 구매 패턴을 가진 사용자 찾기
   - Matrix Factorization (SVD)

2. 콘텐츠 기반 필터링 (Content-Based Filtering)
   - 부품 사양 유사도 계산
   - TF-IDF + Cosine Similarity

3. 성능 예측 모델
   - XGBoost Regression
   - 입력: 부품 구성
   - 출력: 예상 벤치마크 점수

4. 가격 예측 모델
   - LSTM (시계열)
   - 입력: 과거 가격 데이터
   - 출력: 향후 가격 추세
"""

import tensorflow as tf
from sklearn.ensemble import GradientBoostingRegressor

class PCRecommendationModel:
    def __init__(self):
        self.performance_model = self._build_performance_model()
        self.price_model = self._build_price_model()
        self.compatibility_checker = CompatibilityChecker()

    def _build_performance_model(self):
        """성능 예측 모델 (XGBoost)"""
        model = GradientBoostingRegressor(
            n_estimators=100,
            learning_rate=0.1,
            max_depth=5
        )
        return model

    def _build_price_model(self):
        """가격 예측 모델 (LSTM)"""
        model = tf.keras.Sequential([
            tf.keras.layers.LSTM(50, return_sequences=True),
            tf.keras.layers.Dropout(0.2),
            tf.keras.layers.LSTM(50, return_sequences=False),
            tf.keras.layers.Dropout(0.2),
            tf.keras.layers.Dense(25),
            tf.keras.layers.Dense(1)
        ])
        model.compile(optimizer='adam', loss='mse')
        return model

    def recommend_build(self, user_preferences, budget):
        """
        사용자 선호도와 예산 기반 최적 견적 추천

        Args:
            user_preferences: {
                'purpose': '게임용',
                'games': ['오버워치', 'LOL'],
                'target_fps': 144,
                'resolution': '1080p'
            }
            budget: 1000000

        Returns:
            {
                'cpu': {...},
                'gpu': {...},
                'ram': {...},
                'motherboard': {...},
                'storage': {...},
                'psu': {...},
                'case': {...},
                'total_price': 980000,
                'expected_performance': {
                    'overwatch_fps': 165,
                    'lol_fps': 240
                },
                'confidence_score': 0.89
            }
        """
        # 1. 예산 배분 최적화 (강화학습)
        budget_allocation = self._optimize_budget_allocation(
            budget, user_preferences
        )

        # 2. 각 카테고리별 부품 후보 생성
        candidates = self._generate_candidates(budget_allocation)

        # 3. 호환성 검증
        compatible_builds = self._filter_compatible_builds(candidates)

        # 4. 성능 예측 및 순위 매기기
        ranked_builds = self._rank_builds(
            compatible_builds,
            user_preferences
        )

        return ranked_builds[0]  # 최상위 추천
```

**Step 2.2: 모델 학습**
```python
# scripts/ml/train_model.py

def train_recommendation_model():
    # 1. 데이터 로드
    data = pd.read_json('training_data.json')

    # 2. 학습/검증/테스트 분할 (7:2:1)
    train, val, test = split_data(data)

    # 3. 모델 학습
    model = PCRecommendationModel()

    # 성능 예측 모델 학습
    model.performance_model.fit(
        train[feature_cols],
        train['benchmark_score']
    )

    # 가격 예측 모델 학습
    model.price_model.fit(
        train_sequences,
        train_prices,
        epochs=50,
        validation_data=(val_sequences, val_prices)
    )

    # 4. 모델 평가
    test_performance = model.evaluate(test)
    print(f"Test RMSE: {test_performance['rmse']}")
    print(f"Test R²: {test_performance['r2']}")

    # 5. 모델 저장
    model.save('models/recommendation_v1.pkl')
```

**Step 2.3: 모델 서빙 아키텍처**
```
옵션 1: Firebase Functions (Python Runtime)
├── functions/
│   ├── ml_inference/
│   │   ├── main.py
│   │   ├── model.pkl
│   │   └── requirements.txt
│   └── package.json

옵션 2: Google Cloud Run (컨테이너)
├── ml_service/
│   ├── Dockerfile
│   ├── app.py (FastAPI)
│   ├── model.pkl
│   └── requirements.txt

옵션 3: TensorFlow Lite (클라이언트 사이드)
└── assets/
    └── models/
        └── recommendation_model.tflite
```

**추천: 옵션 2 (Cloud Run) - 확장성과 성능**
```python
# ml_service/app.py
from fastapi import FastAPI
import pickle

app = FastAPI()
model = pickle.load(open('model.pkl', 'rb'))

@app.post("/api/v1/recommend")
async def recommend_build(request: BuildRequest):
    """견적 추천 API"""
    result = model.recommend_build(
        user_preferences=request.preferences,
        budget=request.budget
    )
    return result

@app.post("/api/v1/predict-price")
async def predict_price(request: PriceRequest):
    """가격 예측 API"""
    prediction = model.price_model.predict(request.features)
    return {"predicted_price": int(prediction[0])}
```

#### Phase 3: Flutter 앱 통합 (1주)

**Step 3.1: ML Service Provider 생성**
```dart
// lib/core/services/ml_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class MLService {
  static const String baseUrl = 'https://ml-api-xxxxx.run.app';

  /// 견적 추천 요청
  Future<RecommendedBuild> getRecommendation({
    required Map<String, dynamic> preferences,
    required int budget,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/recommend'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'preferences': preferences,
        'budget': budget,
      }),
    );

    if (response.statusCode == 200) {
      return RecommendedBuild.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to get recommendation');
    }
  }

  /// 가격 예측 요청
  Future<int> predictPrice({
    required String basePartId,
    required double conditionScore,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/predict-price'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'base_part_id': basePartId,
        'condition_score': conditionScore,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['predicted_price'];
    } else {
      throw Exception('Failed to predict price');
    }
  }
}
```

**Step 3.2: 추천 화면 업데이트**
```dart
// lib/features/recommendation/presentation/screens/my_estimate_screen.dart

class MyEstimateScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Column([
        // 사용자 입력 폼
        _buildPreferenceForm(),

        // ML 추천 요청 버튼
        ElevatedButton(
          onPressed: () async {
            final mlService = ref.read(mlServiceProvider);

            // 로딩 표시
            ref.read(loadingProvider.notifier).state = true;

            try {
              final recommendation = await mlService.getRecommendation(
                preferences: _collectPreferences(),
                budget: _selectedBudget,
              );

              // 추천 결과 표시
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RecommendationResultScreen(
                    build: recommendation,
                  ),
                ),
              );
            } catch (e) {
              // 에러 처리
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('추천을 가져오는데 실패했습니다: $e')),
              );
            } finally {
              ref.read(loadingProvider.notifier).state = false;
            }
          },
          child: Text('AI 견적 추천 받기'),
        ),
      ]),
    );
  }
}
```

#### Phase 4: A/B 테스팅 및 모델 개선 (지속적)

**Step 4.1: 추천 품질 측정**
```dart
// lib/core/analytics/recommendation_analytics.dart

class RecommendationAnalytics {
  /// 추천 클릭률 (CTR) 추적
  static void trackRecommendationClick(String recommendationId) {
    FirebaseAnalytics.instance.logEvent(
      name: 'recommendation_click',
      parameters: {'recommendation_id': recommendationId},
    );
  }

  /// 추천 구매 전환율 추적
  static void trackRecommendationPurchase(
    String recommendationId,
    double totalPrice,
  ) {
    FirebaseAnalytics.instance.logEvent(
      name: 'recommendation_purchase',
      parameters: {
        'recommendation_id': recommendationId,
        'total_price': totalPrice,
      },
    );
  }
}
```

**Step 4.2: 모델 재학습 파이프라인**
```python
# scripts/ml/retrain_pipeline.py

"""
매월 1일 자동 재학습
- 지난 달 거래 데이터 추가
- 모델 재학습
- 성능 검증 (이전 모델과 비교)
- 성능 개선시 배포
"""

def retrain_monthly():
    # 1. 신규 데이터 수집
    new_data = fetch_new_transactions(last_30_days=True)

    # 2. 기존 데이터와 병합
    all_data = merge_with_existing_data(new_data)

    # 3. 재학습
    new_model = train_model(all_data)

    # 4. 성능 비교
    old_performance = evaluate_model('models/current_model.pkl')
    new_performance = evaluate_model(new_model)

    if new_performance['r2'] > old_performance['r2']:
        # 5. 배포
        deploy_model(new_model, version='v1.{}'.format(get_next_version()))
        print("New model deployed!")
    else:
        print("New model performance not improved. Keeping old model.")
```

### 📊 성공 지표
- [ ] 추천 정확도 (R² > 0.85)
- [ ] 사용자 만족도 (별점 4.5+)
- [ ] 추천 구매 전환율 > 15%
- [ ] API 응답 시간 < 2초

---

## 3. Admin 페이지 자동화

### 📋 현재 상태
- **기존**: 수동으로 컨디션 스코어 입력 및 승인/반려 처리
- **위치**: `lib/features/admin/`
- **문제점**:
  - 판매 요청 승인 시 일일이 컨디션 스코어 입력
  - 구매자 배송지와 물건 수동 매칭
  - 반복 작업으로 인한 시간 소모
  - 사람의 실수 가능성

### 🎯 목표
AI 기반 컨디션 스코어 자동 산정 및 배송 자동화 시스템 구축

### 🔧 구현 단계

#### Phase 1: 컨디션 스코어 자동 산정 (2주)

**Step 1.1: 이미지 분석 ML 모델**
```python
# scripts/ml/condition_scoring/image_analyzer.py

"""
이미지 기반 컨디션 평가 모델

입력: 부품 사진 (최대 5장)
출력: {
  'condition_score': 8.5,  # 0-10점
  'defects': [
    {'type': 'scratch', 'severity': 'minor', 'location': [x, y, w, h]},
    {'type': 'dust', 'severity': 'moderate', 'location': [x, y, w, h]}
  ],
  'confidence': 0.92
}

모델: ResNet50 (Transfer Learning)
"""

import tensorflow as tf
from tensorflow.keras.applications import ResNet50
from tensorflow.keras import layers

class ConditionScorer:
    def __init__(self):
        self.model = self._build_model()

    def _build_model(self):
        base_model = ResNet50(
            weights='imagenet',
            include_top=False,
            input_shape=(224, 224, 3)
        )

        # Fine-tuning
        base_model.trainable = False

        model = tf.keras.Sequential([
            base_model,
            layers.GlobalAveragePooling2D(),
            layers.Dense(256, activation='relu'),
            layers.Dropout(0.5),
            layers.Dense(128, activation='relu'),
            layers.Dense(1, activation='sigmoid')  # 0-1 점수
        ])

        return model

    def score_images(self, image_urls):
        """여러 이미지 분석 후 평균 점수 산정"""
        scores = []

        for url in image_urls:
            img = self._load_and_preprocess(url)
            score = self.model.predict(img)[0][0]
            scores.append(score)

        # 가중 평균 (첫 번째 이미지 가중치 높음)
        weights = [0.4, 0.3, 0.2, 0.05, 0.05]
        weighted_score = sum(s * w for s, w in zip(scores, weights))

        return weighted_score * 10  # 0-10 스케일
```

**Step 1.2: 메타데이터 기반 점수 조정**
```python
# scripts/ml/condition_scoring/metadata_adjuster.py

def adjust_score_by_metadata(base_score, metadata):
    """
    메타데이터를 고려한 점수 조정

    조정 요인:
    - 연식: 최신 부품 +0.5점, 3년 이상 -0.5점
    - 사용 빈도: 미사용 +1점, 하루 8시간 이상 사용 -1점
    - AS 여부: AS 가능 +0.5점
    - 중고 여부: 신품 직접 구매 +0.3점
    """
    adjusted = base_score

    # 연식 반영
    if metadata.get('age_info_type') == 'unknown':
        adjusted -= 0.3
    elif metadata.get('age_info_year'):
        years_old = 2025 - metadata['age_info_year']
        if years_old < 1:
            adjusted += 0.5
        elif years_old > 3:
            adjusted -= 0.5 * (years_old - 3)

    # 사용 빈도 반영
    usage = metadata.get('usage_frequency', '')
    if '미사용' in usage:
        adjusted += 1.0
    elif '8시간' in usage or '7일' in usage:
        adjusted -= 1.0

    # AS 반영
    if metadata.get('has_warranty'):
        adjusted += 0.5

    # 소유 이력 반영
    if not metadata.get('is_second_hand'):
        adjusted += 0.3

    # 0-10 범위 제한
    return max(0, min(10, adjusted))
```

**Step 1.3: Firebase Functions 통합**
```typescript
// functions/src/autoScoring.ts

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import axios from 'axios';

export const autoScoreSellRequest = functions.firestore
  .document('sell_requests/{requestId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();

    // 1. ML 서비스 호출
    const response = await axios.post(
      'https://ml-api-xxxxx.run.app/api/v1/score-condition',
      {
        image_urls: data.imageUrls,
        metadata: {
          age_info_type: data.ageInfoType,
          age_info_year: data.ageInfoYear,
          usage_frequency: data.usageFrequency,
          has_warranty: data.hasWarranty,
          is_second_hand: data.isSecondHand,
        }
      }
    );

    const { condition_score, confidence } = response.data;

    // 2. 자동 승인 기준
    let autoApprove = false;
    let adminNotes = '';

    if (confidence > 0.85 && condition_score >= 7.0) {
      // 컨디션 좋고 확신도 높으면 자동 승인
      autoApprove = true;
      adminNotes = `AI 자동 승인 (컨디션 점수: ${condition_score.toFixed(1)}, 확신도: ${(confidence * 100).toFixed(1)}%)`;
    } else if (confidence > 0.85 && condition_score < 4.0) {
      // 컨디션 안좋고 확신도 높으면 자동 반려
      adminNotes = `AI 자동 반려 (컨디션 점수: ${condition_score.toFixed(1)}, 확신도: ${(confidence * 100).toFixed(1)}%). 더 나은 상태의 부품을 등록해주세요.`;
      await snap.ref.update({
        status: 'rejected',
        conditionScore: condition_score,
        adminNotes: adminNotes,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      return;
    } else {
      // 애매한 경우 관리자 검토 필요
      adminNotes = `AI 검토 필요 (컨디션 점수: ${condition_score.toFixed(1)}, 확신도: ${(confidence * 100).toFixed(1)}%). 관리자 확인이 필요합니다.`;
    }

    // 3. Firestore 업데이트
    if (autoApprove) {
      await snap.ref.update({
        status: 'approved',
        conditionScore: condition_score,
        adminNotes: adminNotes,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // 4. 승인 알림 전송
      await admin.firestore().collection('notifications').add({
        userId: data.sellerId,
        type: 'statusChanged',
        title: '판매 요청이 승인되었습니다 🎉',
        message: adminNotes,
        relatedSellRequestId: context.params.requestId,
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    } else {
      await snap.ref.update({
        conditionScore: condition_score,
        aiSuggestion: adminNotes,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
  });
```

#### Phase 2: 배송지-물건 자동 매칭 시스템 (1주)

**Step 2.1: 배송 최적화 알고리즘**
```typescript
// functions/src/shippingOptimizer.ts

interface ShippingRequest {
  orderId: string;
  buyerId: string;
  shippingAddress: string;
  items: {
    listingId: string;
    sellerId: string;
    warehouseLocation?: string;  // 보관 PC 위치
  }[];
}

/**
 * 배송 경로 최적화
 * - 같은 판매자의 여러 상품 → 한 번에 발송
 * - 보관 PC에 있는 상품 → 우선 출고
 */
export class ShippingOptimizer {
  async optimizeShipping(order: ShippingRequest) {
    const shipments: Shipment[] = [];

    // 1. 판매자별 그룹화
    const groupedBySeller = this.groupBySeller(order.items);

    for (const [sellerId, items] of Object.entries(groupedBySeller)) {
      // 2. 보관 PC 상품 우선 처리
      const warehouseItems = items.filter(i => i.warehouseLocation);
      const directItems = items.filter(i => !i.warehouseLocation);

      if (warehouseItems.length > 0) {
        // 보관 PC → 구매자 직접 배송
        shipments.push({
          from: 'warehouse',
          to: order.shippingAddress,
          items: warehouseItems,
          estimatedDelivery: this.calculateDelivery('warehouse', order.shippingAddress),
        });
      }

      if (directItems.length > 0) {
        // 판매자 → 구매자 직접 배송
        const sellerAddress = await this.getSellerAddress(sellerId);
        shipments.push({
          from: sellerAddress,
          to: order.shippingAddress,
          items: directItems,
          estimatedDelivery: this.calculateDelivery(sellerAddress, order.shippingAddress),
        });
      }
    }

    // 3. 배송 정보 Firestore 저장
    await this.saveShipments(order.orderId, shipments);

    // 4. 판매자에게 배송 요청 알림
    await this.notifySellers(shipments);

    return shipments;
  }

  calculateDelivery(from: string, to: string): Date {
    // 거리 기반 예상 배송일 계산
    // 서울 내: 1일, 수도권: 2일, 전국: 3일
    const distance = this.getDistance(from, to);
    const days = distance < 50 ? 1 : distance < 200 ? 2 : 3;

    const delivery = new Date();
    delivery.setDate(delivery.getDate() + days);
    return delivery;
  }
}
```

**Step 2.2: Admin 대시보드 자동화 위젯**
```dart
// lib/features/admin/presentation/widgets/auto_approval_card.dart

class AutoApprovalCard extends StatelessWidget {
  final SellRequest request;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column([
        // AI 제안 점수 표시
        Row([
          Text('AI 컨디션 점수: ${request.conditionScore?.toStringAsFixed(1) ?? 'N/A'}'),
          if (request.conditionScore != null)
            _buildScoreIndicator(request.conditionScore!),
        ]),

        // AI 제안
        if (request.aiSuggestion != null)
          Container(
            padding: EdgeInsets.all(12),
            color: Colors.blue.shade50,
            child: Row([
              Icon(Icons.lightbulb_outline, color: Colors.blue),
              SizedBox(width: 8),
              Expanded(child: Text(request.aiSuggestion!)),
            ]),
          ),

        // 관리자 최종 결정 버튼
        Row([
          ElevatedButton(
            onPressed: () => _approve(context, request),
            child: Text('승인'),
          ),
          OutlinedButton(
            onPressed: () => _reject(context, request),
            child: Text('반려'),
          ),
          // 점수 수동 조정
          TextButton(
            onPressed: () => _showScoreAdjustDialog(context, request),
            child: Text('점수 조정'),
          ),
        ]),
      ]),
    );
  }

  Widget _buildScoreIndicator(double score) {
    Color color;
    if (score >= 8) color = Colors.green;
    else if (score >= 6) color = Colors.orange;
    else color = Colors.red;

    return CircleAvatar(
      backgroundColor: color,
      radius: 12,
      child: Text(
        score.toStringAsFixed(1),
        style: TextStyle(fontSize: 10, color: Colors.white),
      ),
    );
  }
}
```

#### Phase 3: 대시보드 통계 및 모니터링 (0.5주)

**Step 3.1: 자동화 성과 추적**
```dart
// lib/features/admin/presentation/screens/automation_stats_page.dart

class AutomationStatsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('자동화 통계')),
      body: ListView([
        // 자동 승인률
        _StatCard(
          title: '자동 승인률',
          value: '67%',
          trend: '+12%',
          icon: Icons.check_circle,
          color: Colors.green,
        ),

        // 평균 처리 시간
        _StatCard(
          title: '평균 처리 시간',
          value: '2.3분',
          previousValue: '15분',
          icon: Icons.timer,
          color: Colors.blue,
        ),

        // AI 정확도
        _StatCard(
          title: 'AI 점수 정확도',
          value: '91%',
          subtitle: '관리자 수정률 9%',
          icon: Icons.psychology,
          color: Colors.purple,
        ),

        // 배송 자동화율
        _StatCard(
          title: '배송 자동 매칭률',
          value: '84%',
          icon: Icons.local_shipping,
          color: Colors.orange,
        ),
      ]),
    );
  }
}
```

### 📊 성공 지표
- [ ] 자동 승인률 > 60%
- [ ] AI 점수 정확도 > 85% (관리자 수정 기준)
- [ ] 평균 처리 시간 < 5분 (기존 15분)
- [ ] 배송 자동 매칭률 > 80%

---

## 4. 엑셀 기반 판매 요청 자동 생성

### 📋 현재 상태
- **기존**: 판매 요청을 하나씩 수동으로 앱에서 입력
- **문제점**:
  - 대량 부품 등록 시 시간 소모
  - 반복 입력으로 인한 실수 가능성
  - 엑셀로 관리하던 재고를 일일이 옮겨야 함

### 🎯 목표
엑셀 파일 업로드로 대량 판매 요청 자동 생성 시스템 구축

### 🔧 구현 단계

#### Phase 1: 엑셀 템플릿 정의 (2일)

**Step 1.1: 표준 엑셀 템플릿 생성**
```excel
# template/sell_request_template.xlsx

시트1: 부품 정보
| 카테고리 | 제조사 | 모델명 | 희망가격 | 연식(년) | 연식(월) | 연식정보 | 중고여부 | AS기간 | 사용빈도 | 사용용도 | 이미지URL1 | 이미지URL2 | ...
|---------|--------|--------|----------|----------|----------|----------|----------|--------|----------|----------|-----------|-----------|-----|
| CPU     | Intel  | i7-13700K | 350000 | 2023 | 6 | 구매일 | N | 12 | 주3일 하루4시간 | 게임용 | http://... | http://... |
| GPU     | NVIDIA | RTX 4070 | 550000 | 2024 | 1 | 구매일 | N | 24 | 주5일 하루6시간 | 게임용 | http://... | |

필수 컬럼:
- 카테고리 (CPU, GPU, RAM, ...)
- 제조사
- 모델명
- 희망가격

선택 컬럼:
- 연식정보 (구매일, 제조일, 정보없음)
- 중고여부 (Y/N)
- AS기간 (개월 수)
- 사용빈도
- 사용용도
```

**Step 1.2: 검증 규칙 정의**
```typescript
// functions/src/excelValidator.ts

interface ValidationRule {
  field: string;
  required: boolean;
  type: 'string' | 'number' | 'date' | 'url';
  validators?: ((value: any) => boolean)[];
  errorMessage?: string;
}

const VALIDATION_RULES: ValidationRule[] = [
  {
    field: '카테고리',
    required: true,
    type: 'string',
    validators: [
      (v) => ['CPU', 'GPU', 'RAM', '메인보드', '저장장치', 'PSU', '케이스'].includes(v)
    ],
    errorMessage: '유효한 카테고리를 입력해주세요 (CPU, GPU, RAM, ...)'
  },
  {
    field: '희망가격',
    required: true,
    type: 'number',
    validators: [
      (v) => v > 0,
      (v) => v < 10000000  // 1000만원 미만
    ],
    errorMessage: '희망가격은 0원 초과 1000만원 미만이어야 합니다'
  },
  // ... 기타 필드
];

export function validateRow(row: any, rowNumber: number): ValidationError[] {
  const errors: ValidationError[] = [];

  for (const rule of VALIDATION_RULES) {
    const value = row[rule.field];

    // 필수 체크
    if (rule.required && !value) {
      errors.push({
        row: rowNumber,
        field: rule.field,
        message: `${rule.field}는 필수 입력 항목입니다`,
      });
      continue;
    }

    // 타입 체크
    if (value && typeof value !== rule.type) {
      errors.push({
        row: rowNumber,
        field: rule.field,
        message: `${rule.field}는 ${rule.type} 타입이어야 합니다`,
      });
      continue;
    }

    // 커스텀 검증
    if (rule.validators) {
      for (const validator of rule.validators) {
        if (!validator(value)) {
          errors.push({
            row: rowNumber,
            field: rule.field,
            message: rule.errorMessage || `${rule.field} 값이 유효하지 않습니다`,
          });
          break;
        }
      }
    }
  }

  return errors;
}
```

#### Phase 2: 업로드 UI 구현 (3일)

**Step 2.1: 파일 선택 화면**
```dart
// lib/features/admin/presentation/screens/bulk_upload_screen.dart

import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';

class BulkUploadScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<BulkUploadScreen> createState() => _BulkUploadScreenState();
}

class _BulkUploadScreenState extends ConsumerState<BulkUploadScreen> {
  List<Map<String, dynamic>>? _parsedData;
  List<ValidationError> _validationErrors = [];
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('대량 판매 요청 등록'),
        actions: [
          IconButton(
            icon: Icon(Icons.download),
            tooltip: '템플릿 다운로드',
            onPressed: _downloadTemplate,
          ),
        ],
      ),
      body: Column([
        // 안내 메시지
        Container(
          padding: EdgeInsets.all(16),
          color: Colors.blue.shade50,
          child: Row([
            Icon(Icons.info_outline, color: Colors.blue),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                '엑셀 템플릿을 다운로드하여 부품 정보를 입력한 후 업로드하세요.',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ]),
        ),

        // 파일 업로드 영역
        if (_parsedData == null)
          _buildUploadArea()
        else
          _buildPreviewArea(),

        // 검증 오류 표시
        if (_validationErrors.isNotEmpty)
          _buildErrorList(),

        // 제출 버튼
        if (_parsedData != null && _validationErrors.isEmpty)
          Padding(
            padding: EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _submitBulkRequest,
              child: _isProcessing
                  ? CircularProgressIndicator()
                  : Text('${_parsedData!.length}개 판매 요청 생성'),
            ),
          ),
      ]),
    );
  }

  Widget _buildUploadArea() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.upload_file, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text('엑셀 파일을 선택하세요', style: TextStyle(fontSize: 18)),
            SizedBox(height: 24),
            ElevatedButton.icon(
              icon: Icon(Icons.file_upload),
              label: Text('파일 선택'),
              onPressed: _pickFile,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );

    if (result != null) {
      setState(() => _isProcessing = true);

      try {
        // 엑셀 파일 파싱
        final bytes = result.files.single.bytes!;
        final excel = Excel.decodeBytes(bytes);

        // 첫 번째 시트 읽기
        final sheet = excel.tables.keys.first;
        final rows = excel.tables[sheet]!.rows;

        // 헤더 행 (첫 번째 행)
        final headers = rows[0].map((cell) => cell?.value.toString() ?? '').toList();

        // 데이터 행 파싱
        final data = <Map<String, dynamic>>[];
        for (int i = 1; i < rows.length; i++) {
          final row = rows[i];
          final rowData = <String, dynamic>{};

          for (int j = 0; j < headers.length && j < row.length; j++) {
            rowData[headers[j]] = row[j]?.value;
          }

          data.add(rowData);
        }

        // 검증
        final errors = await _validateData(data);

        setState(() {
          _parsedData = data;
          _validationErrors = errors;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('파일 파싱 오류: $e')),
        );
      } finally {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<List<ValidationError>> _validateData(List<Map<String, dynamic>> data) async {
    // 서버에 검증 요청
    final response = await http.post(
      Uri.parse('https://us-central1-picom-team.cloudfunctions.net/validateBulkUpload'),
      body: jsonEncode({'data': data}),
    );

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      return (result['errors'] as List)
          .map((e) => ValidationError.fromJson(e))
          .toList();
    }

    return [];
  }

  Widget _buildPreviewArea() {
    return Expanded(
      child: Column([
        // 요약 정보
        Container(
          padding: EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStat('총 항목', '${_parsedData!.length}개'),
              _buildStat('검증 통과', '${_parsedData!.length - _validationErrors.length}개'),
              _buildStat('오류', '${_validationErrors.length}개'),
            ],
          ),
        ),

        // 데이터 테이블
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: DataTable(
                columns: [
                  DataColumn(label: Text('행')),
                  DataColumn(label: Text('카테고리')),
                  DataColumn(label: Text('제조사')),
                  DataColumn(label: Text('모델명')),
                  DataColumn(label: Text('희망가격')),
                  DataColumn(label: Text('상태')),
                ],
                rows: _parsedData!.asMap().entries.map((entry) {
                  final index = entry.key;
                  final row = entry.value;
                  final hasError = _validationErrors.any((e) => e.row == index + 2);

                  return DataRow(
                    color: MaterialStateProperty.resolveWith<Color?>(
                      (states) => hasError ? Colors.red.shade50 : null,
                    ),
                    cells: [
                      DataCell(Text('${index + 2}')),
                      DataCell(Text(row['카테고리']?.toString() ?? '')),
                      DataCell(Text(row['제조사']?.toString() ?? '')),
                      DataCell(Text(row['모델명']?.toString() ?? '')),
                      DataCell(Text(row['희망가격']?.toString() ?? '')),
                      DataCell(
                        hasError
                            ? Icon(Icons.error, color: Colors.red)
                            : Icon(Icons.check_circle, color: Colors.green),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Future<void> _submitBulkRequest() async {
    setState(() => _isProcessing = true);

    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) throw Exception('로그인이 필요합니다');

      // Cloud Functions 호출
      final response = await http.post(
        Uri.parse('https://us-central1-picom-team.cloudfunctions.net/createBulkSellRequests'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'seller_id': currentUser.uid,
          'data': _parsedData,
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${result['created_count']}개 판매 요청이 생성되었습니다!'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context);
      } else {
        throw Exception('생성 실패: ${response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }
}
```

#### Phase 3: 서버 측 처리 (2일)

**Step 3.1: Cloud Functions - 대량 생성**
```typescript
// functions/src/bulkSellRequests.ts

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

export const createBulkSellRequests = functions.https.onRequest(async (req, res) => {
  if (req.method !== 'POST') {
    res.status(405).send('Method Not Allowed');
    return;
  }

  const { seller_id, data } = req.body;

  if (!seller_id || !data || !Array.isArray(data)) {
    res.status(400).send('Invalid request body');
    return;
  }

  const batch = admin.firestore().batch();
  const createdIds: string[] = [];

  try {
    for (const row of data) {
      // 1. BasePart 검색 (제조사 + 모델명으로)
      const basePartQuery = await admin.firestore()
        .collection('base_parts')
        .where('brand', '==', row['제조사'])
        .where('modelName', '==', row['모델명'])
        .where('category', '==', row['카테고리'])
        .limit(1)
        .get();

      let basePartId: string;
      let partId: string;

      if (basePartQuery.empty) {
        // BasePart 없으면 생성
        const newBasePartRef = admin.firestore().collection('base_parts').doc();
        batch.set(newBasePartRef, {
          category: row['카테고리'],
          brand: row['제조사'],
          modelName: row['모델명'],
          listingCount: 0,
          lowestPrice: 0,
          averagePrice: 0,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        basePartId = newBasePartRef.id;

        // Part도 생성
        const newPartRef = admin.firestore().collection('parts').doc();
        batch.set(newPartRef, {
          basePartId: basePartId,
          brand: row['제조사'],
          modelName: row['모델명'],
          category: row['카테고리'],
          specifications: {},
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        partId = newPartRef.id;
      } else {
        basePartId = basePartQuery.docs[0].id;

        // 기존 Part 검색
        const partQuery = await admin.firestore()
          .collection('parts')
          .where('basePartId', '==', basePartId)
          .limit(1)
          .get();

        partId = partQuery.empty ? basePartId : partQuery.docs[0].id;
      }

      // 2. SellRequest 생성
      const sellRequestRef = admin.firestore().collection('sell_requests').doc();

      // 이미지 URL 수집 (이미지URL1, 이미지URL2, ...)
      const imageUrls: string[] = [];
      for (let i = 1; i <= 5; i++) {
        const url = row[`이미지URL${i}`];
        if (url) imageUrls.push(url);
      }

      // 연식 정보 파싱
      let ageInfoType = 'unknown';
      if (row['연식정보'] === '구매일') ageInfoType = 'originalPurchaseDate';
      else if (row['연식정보'] === '제조일') ageInfoType = 'manufacturDate';

      batch.set(sellRequestRef, {
        requestId: sellRequestRef.id,
        sellerId: seller_id,
        partId: partId,
        basePartId: basePartId,
        brand: row['제조사'],
        category: row['카테고리'],
        modelName: row['모델명'],
        requestedPrice: parseInt(row['희망가격']),
        ageInfoType: ageInfoType,
        ageInfoYear: row['연식(년)'] || null,
        ageInfoMonth: row['연식(월)'] || null,
        isSecondHand: row['중고여부'] === 'Y',
        hasWarranty: !!row['AS기간'],
        warrantyMonthsLeft: parseInt(row['AS기간']) || null,
        usageFrequency: row['사용빈도'] || '',
        purpose: row['사용용도'] || '',
        imageUrls: imageUrls,
        status: 'pending',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      createdIds.push(sellRequestRef.id);

      // Batch는 500개 제한
      if (createdIds.length % 400 === 0) {
        await batch.commit();
        // 새 batch 시작
      }
    }

    // 남은 batch commit
    await batch.commit();

    res.status(200).json({
      success: true,
      created_count: createdIds.length,
      request_ids: createdIds,
    });
  } catch (error) {
    console.error('Bulk creation error:', error);
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});
```

#### Phase 4: 진행 상황 추적 (1일)

**Step 4.1: 실시간 진행률 표시**
```dart
// lib/features/admin/presentation/screens/bulk_upload_progress_screen.dart

class BulkUploadProgressScreen extends ConsumerWidget {
  final List<String> requestIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressStream = FirebaseFirestore.instance
        .collection('bulk_upload_jobs')
        .doc(jobId)
        .snapshots();

    return StreamBuilder<DocumentSnapshot>(
      stream: progressStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return CircularProgressIndicator();

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final total = data['total'] as int;
        final completed = data['completed'] as int;
        final failed = data['failed'] as int;

        final progress = completed / total;

        return Scaffold(
          appBar: AppBar(title: Text('업로드 진행 중')),
          body: Center(
            child: Column([
              // 진행률 표시
              CircularProgressIndicator(value: progress),
              SizedBox(height: 24),
              Text(
                '${(progress * 100).toStringAsFixed(1)}%',
                style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text('$completed / $total 완료'),

              if (failed > 0)
                Text('$failed 실패', style: TextStyle(color: Colors.red)),

              // 완료되면 완료 화면으로
              if (completed == total)
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('완료'),
                ),
            ]),
          ),
        );
      },
    );
  }
}
```

### 📊 성공 지표
- [ ] 100개 부품 업로드 시간 < 3분
- [ ] 검증 정확도 > 95%
- [ ] 대량 등록 실패율 < 1%
- [ ] 템플릿 다운로드 및 가이드 제공

---

## 우선순위 및 일정

### Phase 1: 기반 구축 (2주)
1. ✅ 웹 전용 레이아웃 설계
2. ✅ ML 학습 데이터 수집

### Phase 2: 핵심 기능 구현 (6주)
1. 🔄 웹 랜딩페이지 주요 페이지 (3주)
2. 🔄 추천 시스템 ML 모델 개발 (3주)

### Phase 3: 자동화 구현 (3주)
1. 🔄 컨디션 스코어 자동 산정 (2주)
2. 🔄 엑셀 업로드 기능 (1주)

### Phase 4: 배포 및 최적화 (2주)
1. 🔄 웹 SEO 및 성능 최적화 (1주)
2. 🔄 ML 모델 배포 및 모니터링 (1주)

**총 예상 기간: 13주 (약 3개월)**

---

## 기술 스택 요약

### Frontend
- Flutter Web (반응형 디자인)
- Riverpod (상태 관리)
- go_router (라우팅)

### Backend
- Firebase Functions (TypeScript)
- Cloud Run (Python, ML 서빙)
- Firestore (데이터베이스)

### ML/AI
- TensorFlow / PyTorch
- scikit-learn
- XGBoost
- ResNet50 (이미지 분석)

### DevOps
- Firebase Hosting
- Google Cloud Run
- Cloud Build (CI/CD)

---

## 리스크 및 대응 방안

### 1. ML 모델 성능 부족
- **리스크**: 추천 정확도가 목표(85%) 미달
- **대응**: 규칙 기반 시스템과 하이브리드로 운영, 지속적 데이터 수집 및 재학습

### 2. 웹 성능 이슈
- **리스크**: Flutter Web 번들 크기가 너무 커서 로딩 느림
- **대응**: 코드 스플리팅, 이미지 최적화, CDN 활용

### 3. 자동화 오류
- **리스크**: AI 자동 승인 시 부적절한 부품 승인
- **대응**: 초기에는 보수적 기준 적용, 관리자 최종 검토 단계 유지

### 4. 대량 업로드 성능
- **리스크**: 수백 개 부품 동시 등록 시 타임아웃
- **대응**: 배치 처리 및 큐 시스템 도입, 진행 상황 실시간 추적

---

> **마지막 업데이트**: 2025-11-13
> **다음 검토 예정**: 2025-12-01
