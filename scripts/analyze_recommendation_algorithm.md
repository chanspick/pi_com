# 🔍 Recommendation Algorithm 상세 분석

## 1️⃣ 현재 알고리즘 흐름 분석

### 입력 (Input)
```dart
RecommendationCriteriaEntity {
  usage: "G" | "C" | "O",     // 게임/창작/사무
  minBudget: 100만원,
  maxBudget: 200만원,
  ssdCapacity: 512GB,
  // 용도별 추가 정보
  gameIds, resolution, targetFps, graphicsQuality, // 게임용
  software, projectScale, renderFrequency,         // 창작용
  workType, programCount, monitorCount, dataSize,  // 사무용
}
```

---

## 2️⃣ 추천 프로세스 (recommendBuilds)

### Step 1: 예산 3단계 분할
```dart
minBudget: 100만원, maxBudget: 200만원
→ 저가형: 100~133만원
→ 중급형: 133~167만원
→ 고급형: 167~200만원
```

**문제점:**
- 범위가 겹침 (133만원, 167만원이 2개 범위에 포함)

---

### Step 2: 각 예산 범위별로 최적 조합 탐색 (_findBestBuildForBudget)

#### 2-1. 상위 부품 선택 (_getTopParts)
```dart
// CPU 상위 5개 선택
final cpus = _getTopParts(availableParts['cpu'] ?? [], criteria, 5);
// GPU 상위 5개 선택
final gpus = _getTopParts(availableParts['gpu'] ?? [], criteria, 5);
```

**_getTopParts 로직:**
```dart
List<BasePart> _getTopParts(parts, criteria, count) {
  // 1. 모든 부품에 대해 scorePartForCriteria 계산
  final scored = parts.map((part) {
    final score = scorePartForCriteria(part: part, criteria: criteria);
    return {'part': part, 'score': score};
  });

  // 2. 점수 높은 순으로 정렬
  scored.sort((a, b) => b['score'].compareTo(a['score']));

  // 3. 상위 count개 반환
  return scored.take(count);
}
```

**여기서 가격 사용 여부 체크:**
- ❌ **가격을 전혀 고려하지 않음**
- ✅ **순수 점수(usage 기반)만 사용**
- 예: 게임용이면 GPU 점수가 높음, TDP 높으면 점수 높음

**결론: 이 단계는 순수 성능/용도 기반 (가격 무시)**

---

#### 2-2. 조합 탐색 및 예산 필터링
```dart
for (final cpu in cpus) {           // 5개
  for (final gpu in gpus) {         // 5개
    for (final mb in compatibleMainboards) {
      for (final ram in compatibleRams) {
        // 현재까지 가격 계산
        final currentPrice = cpu.lowestPrice + gpu.lowestPrice +
                            mb.lowestPrice + ram.lowestPrice + ssd.lowestPrice;

        // ✅ 예산 초과 시 스킵
        if (currentPrice > maxBudget) continue;

        // 남은 예산으로 PSU/쿨러/케이스 선택
        final remainingBudget = maxBudget - currentPrice;
        final psu = _selectPsu(psus, requiredWattage, remainingBudget ~/ 3);

        final totalPrice = currentPrice + psu.lowestPrice + ...;

        // ✅ 예산 범위 체크
        if (totalPrice < minBudget || totalPrice > maxBudget) continue;

        // ... 점수 계산 후 최고 점수 빌드 저장
      }
    }
  }
}
```

**가격 사용 방식:**
- ✅ **Hard Constraint (필터링)**: 예산 초과 조합은 아예 제외
- ✅ **남은 예산 분배**: PSU/쿨러/케이스에 남은 예산의 1/3씩 배정

**결론: 가격은 필터링 조건으로만 사용 (점수에는 반영 안 됨)**

---

#### 2-3. 점수 계산
```dart
final overallScore = compatibilityScore * 0.4 +    // 호환성 40%
                     performanceScore * 0.3 +      // 성능 30%
                     valueScore * 0.3;             // 가성비 30%
```

##### A. compatibilityScore (40%)
```dart
// 호환성 체크 통과하면 무조건 1.0
final compatibilityScore = 1.0;
```

##### B. performanceScore (30%)
```dart
double calculatePerformanceScore(build, criteria) {
  double score = 0.0;

  // CPU 점수
  score += scorePartForCriteria(part: build.cpu, criteria: criteria);

  // GPU 점수
  score += scorePartForCriteria(part: build.gpu, criteria: criteria);

  // RAM 점수
  score += scorePartForCriteria(part: build.ram, criteria: criteria);

  // SSD 점수
  score += scorePartForCriteria(part: build.ssd, criteria: criteria);

  return score / 4;  // 평균
}
```

**scorePartForCriteria 상세:**

**CPU:**
```dart
double _scoreCpu(cpu, criteria) {
  double score = 0.5;

  // 용도별 가중치
  if (criteria.usage == 'G') score = 0.6;      // 게임
  else if (criteria.usage == 'C') score = 0.9; // 창작
  else score = 0.7;                            // 사무

  // ❌ TDP를 성능으로 착각
  if (cpu.tdp != null) {
    final performance = cpu.tdp! / max(cpu.lowestPrice / 10000, 1);
    score *= (1.0 + performance / 10.0).clamp(0.8, 1.2);
  }

  return score;
}
```

**문제:**
- ❌ **가격을 TDP와 나눔**: `cpu.tdp / (cpu.lowestPrice / 10000)`
- ❌ **TDP를 성능으로 착각**: TDP는 소비전력이지 성능이 아님
- ❌ **cores, threads, clock을 전혀 안 봄**

**GPU:**
```dart
double _scoreGpu(gpu, criteria) {
  double score = 0.5;

  // 용도별 가중치
  if (criteria.usage == 'G') {
    score = 1.0;  // 게임: 매우 중요
    if (criteria.graphicsQuality == '최고') score *= 1.2;
  } else if (criteria.usage == 'C') {
    score = 0.9;  // 창작: 매우 중요
    if (criteria.resolution == '4K') score *= 1.3;
  } else {
    score = 0.3;  // 사무: 중요도 낮음
  }

  // ❌ TDP를 성능으로 착각
  if (gpu.tdp != null) {
    final performance = gpu.tdp! / max(gpu.lowestPrice / 10000, 1);
    score *= (1.0 + performance / 10.0).clamp(0.8, 1.2);
  }

  return score;
}
```

**문제:**
- ❌ **가격을 TDP와 나눔**: `gpu.tdp / (gpu.lowestPrice / 10000)`
- ❌ **VRAM 크기를 전혀 안 봄**
- ❌ **칩셋 (RTX 3060 vs 3090) 구분 안 함**

##### C. valueScore (30%)
```dart
double calculateValueScore(build, criteria) {
  // 예산 중간값
  final budgetMid = (criteria.minBudget + criteria.maxBudget) / 2;

  // 가격 차이
  final priceDiff = (build.totalPrice - budgetMid).abs();

  // ✅ 예산 점수: 예산 중간값에 가까울수록 높음
  final budgetScore = 1.0 - (priceDiff / budgetMid).clamp(0.0, 1.0);

  // 성능 점수
  final performanceScore = calculatePerformanceScore(build, criteria);

  // 가성비 = 성능 70% + 예산 30%
  return (performanceScore * 0.7 + budgetScore * 0.3).clamp(0.0, 1.0);
}
```

**가격 반영 방식:**
- ✅ **예산 중간값에 가까울수록 점수 높음**
- 예: 100~200만원 → 150만원에 가까울수록 점수 높음

**문제:**
- ⚠️ **저렴할수록 좋은 게 아니라, 중간 가격이 좋음**
- ⚠️ **120만원 vs 180만원이 같은 점수** (둘 다 150만원에서 30만원 차이)

---

## 3️⃣ 최종 정리: 가격 vs 점수

### 가격 사용 위치

1. **Step 1: 상위 부품 선택 (_getTopParts)**
   - ❌ **가격 사용 안 함**
   - ✅ **순수 용도 기반 점수만 사용**
   - CPU/GPU는 TDP 기반 (잘못된 지표)

2. **Step 2: 조합 탐색**
   - ✅ **Hard Constraint (필터링)**
   - 예산 초과 조합은 아예 제외
   - 남은 예산을 PSU/쿨러/케이스에 분배

3. **Step 3-A: performanceScore**
   - ⚠️ **가격을 TDP와 나눔** (잘못된 사용)
   - `performance = tdp / (price / 10000)`
   - 의도: 가격 대비 성능
   - 문제: TDP는 성능이 아님

4. **Step 3-B: valueScore**
   - ✅ **예산 중간값 근접도**
   - 150만원 예산이면 150만원에 가까울수록 점수 높음
   - 문제: 저렴한 게 아니라 중간 가격이 좋음

---

## 4️⃣ 알고리즘 문제점 요약

### 가격 관련
1. ❌ **performanceScore에서 가격을 잘못 사용**
   - `tdp / price`는 의미 없음 (TDP는 성능이 아님)

2. ⚠️ **valueScore가 중간 가격 선호**
   - 저렴할수록 좋은 게 아니라 중간값 선호
   - 100~200만원 예산에서 120만원 < 150만원 > 180만원

3. ❌ **_getTopParts에서 가격 고려 안 함**
   - 100만원짜리 CPU와 200만원짜리 CPU가 같은 점수면 둘 다 후보에 포함
   - 저가형 빌드 만들 때 비싼 CPU 먼저 선택될 수 있음

### 성능 관련
4. ❌ **TDP를 성능으로 착각**
   - cores, threads, clock을 안 봄

5. ❌ **parts 컬렉션 안 씀**
   - 상세 스펙 무시

---

## 5️⃣ 개선 방향 제안

### Option A: 가격 중심 알고리즘
**핵심:** 예산 내에서 최대 성능

```
1. 예산에서 CPU/GPU에 60~70% 배정
2. CPU/GPU를 예산 내 최고 성능으로 선택
3. 남은 예산으로 나머지 부품 선택
```

**장점:**
- 직관적
- 예산 관리 명확

**단점:**
- 밸런스 안 좋을 수 있음
- CPU만 좋고 GPU는 나쁜 조합 가능

---

### Option B: 점수 중심 + 가격 필터링 (현재 방식 개선)
**핵심:** 부품별 점수 기반, 가격은 제약 조건

```
1. 각 부품에 점수 부여 (성능, 용도 적합도)
2. 예산 범위 내 조합만 탐색
3. 점수 높은 조합 선택
```

**개선점:**
- TDP 대신 cores×threads×clock 사용
- parts 컬렉션에서 상세 스펙 가져오기
- valueScore를 "저렴할수록 좋음"으로 변경

**장점:**
- 밸런스 좋음
- 용도 맞춤형

**단점:**
- 복잡함
- 점수 계산 로직 정교해야 함

---

### Option C: Tier 기반 알고리즘
**핵심:** 부품을 Tier로 분류, Tier 맞춰서 조합

```
CPU/GPU Tier:
- Entry: i3, Ryzen 3, GTX 1650
- Mid: i5, Ryzen 5, RTX 3060
- High: i7, Ryzen 7, RTX 3070
- Ultra: i9, Ryzen 9, RTX 3090

예산별 Tier 매칭:
- 100만원 이하: Entry
- 100~150만원: Mid
- 150~200만원: High
- 200만원 이상: Ultra
```

**장점:**
- 밸런스 보장 (같은 Tier끼리 매칭)
- 구현 간단
- 성능 예측 쉬움

**단점:**
- Tier 분류 필요 (수동 작업)
- 유연성 떨어짐

---

## 6️⃣ 추천

**제 생각:**
- **Option B (점수 중심 + 개선)** 추천
- 현재 구조를 유지하면서 수정
- parts 컬렉션 연동만 하면 됨

**핵심 수정:**
1. parts에서 cores, threads, clock 가져오기
2. 성능 점수 = cores × threads × clock / 기준값
3. valueScore = 저렴할수록 좋음
4. 호환성 체크 정교화

---

**어떤 방향으로 갈까요?**
