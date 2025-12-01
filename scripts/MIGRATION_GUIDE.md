# 🔄 데이터 마이그레이션 가이드

## 개요
- **목적**: 기존 데이터를 Price Chart용으로 보존하면서 새 데이터(링크 포함)로 교체
- **원칙**: 그래프 급변동 방지를 위해 순차적으로 처리

---

## 📋 실행 순서

### 1단계: 의존성 설치 (최초 1회)
```bash
cd scripts
npm install
```

### 2단계: 기존 데이터 마킹 (available → markedForSold)
```bash
# 50개씩 순차적으로 마킹 (여러 번 실행 가능)
node mark_for_sold.js
```
- 한 번에 50개씩 처리 (그래프 급변동 방지)
- 모든 available이 마킹될 때까지 반복 실행
- `markedForSold: true` 플래그 추가

### 3단계: 새 이미지 업로드
```bash
node upload_new_images.js
```
- `new_datas/*/images/` 폴더의 모든 이미지 업로드
- 이미 존재하는 이미지는 스킵

### 4단계: 새 데이터 업로드
```bash
node upload_new_datas.js
```
- `new_datas/` 폴더의 엑셀 데이터 업로드
- 날짜순 정렬하여 순차 업로드 (Price Chart 최적화)
- Cloud Functions가 자동으로 BasePart 생성

### 5단계: 마킹된 데이터를 sold로 전환
```bash
# 새 데이터 업로드 후 1-2분 대기 (BasePart 생성 대기)
node convert_marked_to_sold.js
```
- `markedForSold: true` → `status: 'sold'`
- 100ms 간격으로 순차 처리

---

## 📁 파일 구조

```
new_datas/
├── cpu/
│   ├── CPU.xlsx
│   └── images/
├── gpu/
│   ├── GPU.xlsx
│   └── images/
├── mainboard/
│   ├── 메보.xlsx
│   └── images/
├── ram/
│   ├── RAM.xlsx
│   └── images/
└── ssd/
    ├── SSD.xlsx
    └── images/
```

---

## 📊 엑셀 컬럼 구조

### CPU
| 컬럼 | 설명 |
|------|------|
| 판매글 게시일자 | 등록일 (YYYY-MM-DD) |
| 브랜드 | Intel / AMD |
| 시리즈 | Ryzen / Core 등 |
| 모델 번호 | 9, 7800X3D 등 |
| 접미사 | X, G, F 등 |
| 판매가 | 가격 (원) |
| 신제품 판매가 | 참고가 |
| 소켓 | AM4, LGA1700 등 |
| 사진1~5 | 이미지 파일명 |
| 링크 | 원본 URL |

### GPU
| 컬럼 | 설명 |
|------|------|
| 브랜드/제조사 | ASUS, MSI 등 |
| 시리즈 | GeForce, Radeon |
| 모델 번호 | RTX3060, RX7600 등 |
| 접미사 | Ti, XT 등 |
| 세부 모델명 | Gaming, STRIX 등 |
| 메모리 용량 | 8GB, 12GB 등 |
| 사진1 | 이미지 파일명 |

### RAM
| 컬럼 | 설명 |
|------|------|
| 제조사 | 삼성전자, SK하이닉스 등 |
| 메모리 규격 | DDR4, DDR5 |
| 용량 (GB) | 16, 32 등 |
| 클럭 (MHz) | 3200, 5600 등 |
| 판매 개수 | 개수 |
| 판매가(개당) | 개당 가격 |

### Mainboard
| 컬럼 | 설명 |
|------|------|
| 제조사 | MSI, ASUS 등 |
| 시리즈 | PRO, ROG 등 |
| 칩셋 | H610, B650 등 |
| 모델명 | 세부 모델 |
| 세부특징1, 2 | 추가 특징 |

### SSD
| 컬럼 | 설명 |
|------|------|
| 제조사 | Samsung, Transcend 등 |
| 시리즈/모델명 | 830S, 980 PRO 등 |
| 폼팩터 | M.2, SATA 등 |
| 용량 | 512GB, 1TB 등 |

---

## ⚠️ 주의사항

1. **순서 준수**: 반드시 위 순서대로 실행
2. **대기 시간**: 4단계 후 1-2분 대기 (Cloud Functions 처리)
3. **반복 실행**: 2단계는 여러 번 실행 가능 (50개씩)
4. **serviceAccountKey.json**: Firebase 서비스 계정 키 필요

---

## 🔧 스크립트 설명

| 스크립트 | 용도 |
|----------|------|
| `mark_for_sold.js` | 기존 available → markedForSold 마킹 |
| `upload_new_images.js` | new_datas 이미지 업로드 |
| `upload_new_datas.js` | new_datas 엑셀 데이터 업로드 |
| `convert_marked_to_sold.js` | 마킹된 데이터 → sold 전환 |

---

## 📈 그래프 신뢰도 유지 전략

1. 기존 데이터는 삭제하지 않고 `sold` 상태로 유지
2. Price Chart는 sold 데이터도 포함하여 표시
3. 순차적 처리로 급격한 가격 변동 방지
4. 새 데이터가 점진적으로 그래프에 반영됨
