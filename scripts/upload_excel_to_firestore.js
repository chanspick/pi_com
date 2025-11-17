// Excel 데이터를 Firestore Listings로 업로드하는 스크립트
const admin = require('firebase-admin');
const xlsx = require('xlsx');
const path = require('path');
const { v4: uuidv4 } = require('uuid');

// Firebase Admin 초기화
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// ============================================
// 설정: 판매자 ID
// ============================================
const SELLER_ID = 'G7BfeVct9kTL3SjdLJjD7qGJh313';
const SELLER_NAME = '조찬형';

// ============================================
// 유틸리티 함수
// ============================================

/**
 * Sheet 이름을 ListingStatus로 변환
 * 모든 시트의 데이터를 'available' 상태로 설정하여
 * BasePart 통계와 가격 차트에 포함되도록 함
 */
function getStatusFromSheetName(sheetName) {
  // 모든 데이터를 available로 설정
  return 'available';
}

/**
 * basePartId 생성 로직
 * - CPU: brand_series_modelNumber_suffix (예: AMD_Ryzen_5_3600_XT)
 * - GPU: brand_series_modelNumber_suffix_memory (예: NVIDIA_GeForce_RTX_3060_Ti_8GB)
 * - Mainboard: manufacturer_chipset_series (예: ASUS_B550_TUF_Gaming)
 */
function generateBasePartId(category, data) {
  const sanitize = (str) => {
    if (!str) return '';
    return String(str).trim().replace(/\s+/g, '_').replace(/[^\w가-힣-]/g, '');
  };

  switch (category) {
    case 'cpu': {
      const brand = sanitize(data['브랜드']);
      const series = sanitize(data['시리즈']);
      const modelNumber = sanitize(data['모델 번호']);
      const suffix = sanitize(data['접미사']);

      const parts = [brand, series, modelNumber, suffix].filter(p => p);
      return parts.join('_');
    }

    case 'gpu': {
      const brand = sanitize(data['브랜드']);
      const series = sanitize(data['시리즈']);
      const modelNumber = sanitize(data['모델 번호']);
      const suffix = sanitize(data['접미사']);
      const memory = sanitize(data['메모리 용량']);

      const parts = [brand, series, modelNumber, suffix, memory].filter(p => p);
      return parts.join('_');
    }

    case 'mainboard': {
      const manufacturer = sanitize(data['제조사']);
      const chipset = sanitize(data['칩셋']);
      const series = sanitize(data['시리즈']);

      const parts = [manufacturer, chipset, series].filter(p => p);
      return parts.join('_');
    }

    case 'ram': {
      const brand = sanitize(data['브랜드']);
      const type = sanitize(data['타입']);  // DDR4, DDR5
      const capacity = sanitize(data['용량']);
      const speed = sanitize(data['속도']);

      const parts = [brand, type, capacity, speed].filter(p => p);
      return parts.join('_');
    }

    case 'ssd': {
      const brand = sanitize(data['브랜드']);
      const type = sanitize(data['타입']);  // NVMe, SATA
      const capacity = sanitize(data['용량']);

      const parts = [brand, type, capacity].filter(p => p);
      return parts.join('_');
    }

    default:
      return 'unknown';
  }
}

/**
 * modelName 생성 로직
 */
function generateModelName(category, data) {
  switch (category) {
    case 'cpu': {
      const brand = data['브랜드'] || '';
      const series = data['시리즈'] || '';
      const modelNumber = data['모델 번호'] || '';
      const suffix = data['접미사'] || '';

      return [brand, series, modelNumber, suffix].filter(p => p).join(' ');
    }

    case 'gpu': {
      const brand = data['브랜드'] || '';
      const series = data['시리즈'] || '';
      const modelNumber = data['모델 번호'] || '';
      const suffix = data['접미사'] || '';
      const detailModel = data['세부 모델명'] || '';
      const memory = data['메모리 용량'] || '';

      const parts = [brand, series, modelNumber, suffix, detailModel, memory].filter(p => p);
      return parts.join(' ');
    }

    case 'mainboard': {
      const manufacturer = data['제조사'] || '';
      const series = data['시리즈'] || '';
      const chipset = data['칩셋'] || '';
      const modelName = data['모델명'] || '';
      const detail1 = data['세부특징1'] || '';
      const detail2 = data['세부특징2'] || '';

      const parts = [manufacturer, series, chipset, modelName, detail1, detail2].filter(p => p);
      return parts.join(' ');
    }

    case 'ram': {
      const brand = data['브랜드'] || '';
      const type = data['타입'] || '';
      const capacity = data['용량'] || '';
      const speed = data['속도'] || '';
      const modelName = data['모델명'] || '';

      return [brand, type, capacity, speed, modelName].filter(p => p).join(' ');
    }

    case 'ssd': {
      const brand = data['브랜드'] || '';
      const type = data['타입'] || '';
      const capacity = data['용량'] || '';
      const modelName = data['모델명'] || '';

      return [brand, type, capacity, modelName].filter(p => p).join(' ');
    }

    default:
      return 'Unknown Model';
  }
}

/**
 * brand 추출 로직
 */
function extractBrand(category, data) {
  switch (category) {
    case 'cpu':
      return data['브랜드'] || '';
    case 'gpu':
      return data['제조사'] || data['브랜드'] || '';
    case 'mainboard':
      return data['제조사'] || '';
    case 'ram':
    case 'ssd':
      return data['브랜드'] || data['제조사'] || '';
    default:
      return '';
  }
}

/**
 * 이미지 URL 생성 (Firebase Storage 경로 기반)
 * NOTE: 이미지는 사전에 Firebase Storage에 업로드되어 있어야 함
 */
function getImageUrls(data) {
  const imageUrls = [];
  const baseUrl = 'https://firebasestorage.googleapis.com/v0/b/picom-team.firebasestorage.app/o/';

  for (let i = 1; i <= 5; i++) {
    const imageFilename = data[`사진${i}`];
    if (imageFilename && imageFilename.trim()) {
      // 이미지 파일명을 URL 인코딩하여 Firebase Storage 경로 생성
      const encodedFilename = encodeURIComponent(`listings/${imageFilename}`);
      const imageUrl = `${baseUrl}${encodedFilename}?alt=media`;
      imageUrls.push(imageUrl);
    }
  }

  return imageUrls;
}

/**
 * 판매가 파싱 (숫자가 아닌 값 처리)
 */
function parsePrice(priceValue) {
  if (!priceValue) return 0;

  // 숫자가 아닌 문자 제거 (쉼표, 원 등)
  const priceStr = String(priceValue).replace(/[^\d]/g, '');
  const price = parseInt(priceStr, 10);

  return isNaN(price) ? 0 : price;
}

/**
 * conditionScore 계산 v5 알고리즘
 *
 * 핵심 철학:
 * - 가격 비율이 1차 지표: 저렴 = 상태 안 좋을 가능성
 * - 관심도는 2차 검증: 저렴한데 관심 많으면 상태 좋은 것 확인
 * - 95점은 미개봉만 가능
 * - 일반 중고 최대 90점
 *
 * 범위: 55~95점
 */
function calculateConditionScore(data) {
  // Excel에 이미 conditionScore가 있으면 그걸 사용
  if (data['conditionScore'] != null && data['conditionScore'] !== '') {
    const existingScore = parseFloat(data['conditionScore']);
    if (!isNaN(existingScore)) {
      return existingScore;
    }
  }

  // 없으면 v5 알고리즘으로 계산
  const price = parsePrice(data['판매가']);
  const referencePrice = parsePrice(data['신제품 판매가']);
  const likes = parseInt(data['좋아요 수'], 10) || 0;
  const chats = parseInt(data['채팅 수'], 10) || 0;
  const views = parseInt(data['조회수'], 10) || 0;
  const isSealed = data['미개봉 여부'] === 'O';

  // 미개봉은 바로 95점
  if (isSealed) {
    return 95;
  }

  // 신제품 가격 없으면 기본값
  if (!referencePrice || referencePrice === 0) {
    return 70;
  }

  const priceRatio = price / referencePrice;

  // 1. 가격 비율로 기본 점수 설정
  let baseScore;
  if (priceRatio < 0.4) {
    baseScore = 55 + (priceRatio / 0.4) * 5; // 0-40% → 55-60점
  } else if (priceRatio < 0.5) {
    baseScore = 60 + ((priceRatio - 0.4) / 0.1) * 5; // 40-50% → 60-65점
  } else if (priceRatio < 0.6) {
    baseScore = 65 + ((priceRatio - 0.5) / 0.1) * 5; // 50-60% → 65-70점
  } else if (priceRatio < 0.7) {
    baseScore = 70 + ((priceRatio - 0.6) / 0.1) * 3; // 60-70% → 70-73점
  } else if (priceRatio < 0.8) {
    baseScore = 73 + ((priceRatio - 0.7) / 0.1) * 3; // 70-80% → 73-76점
  } else if (priceRatio < 0.9) {
    baseScore = 76 + ((priceRatio - 0.8) / 0.1) * 4; // 80-90% → 76-80점
  } else {
    baseScore = 80 + Math.min((priceRatio - 0.9) / 0.1 * 3, 3); // 90%+ → 80-83점
  }

  // 2. 관심도 점수 (0~12점 범위)
  const interestRaw = chats * 3 + likes * 1.5 + views * 0.01;

  let interestAdjustment;
  if (interestRaw < 5) {
    interestAdjustment = -5 + (interestRaw / 5) * 5; // 0-5 → -5~0점
  } else if (interestRaw < 15) {
    interestAdjustment = (interestRaw - 5) / 10 * 4; // 5-15 → 0-4점
  } else if (interestRaw < 30) {
    interestAdjustment = 4 + (interestRaw - 15) / 15 * 4; // 15-30 → 4-8점
  } else if (interestRaw < 50) {
    interestAdjustment = 8 + (interestRaw - 30) / 20 * 3; // 30-50 → 8-11점
  } else {
    interestAdjustment = 11 + Math.min((interestRaw - 50) / 50 * 1, 1); // 50+ → 11-12점
  }

  // 3. 최종 점수 계산
  let score = baseScore + interestAdjustment;

  // 4. 범위 제한 (일반 중고는 최대 90점)
  score = Math.max(55, Math.min(90, score));

  return Math.round(score * 10) / 10;
}

/**
 * Listing 문서 생성
 */
function createListingDocument(category, sheetName, rowData) {
  const status = getStatusFromSheetName(sheetName);
  const basePartId = generateBasePartId(category, rowData);
  const modelName = generateModelName(category, rowData);
  const brand = extractBrand(category, rowData);
  const price = parsePrice(rowData['판매가']);
  const referencePrice = parsePrice(rowData['신제품 판매가']);
  const conditionScore = calculateConditionScore(rowData);
  const imageUrls = getImageUrls(rowData);

  // 날짜 처리 (Excel 날짜 → JavaScript Date)
  let createdAt = new Date();
  const excelDate = rowData['판매글 게시일자'];
  if (excelDate && typeof excelDate === 'number') {
    // Excel 날짜는 1900년 1월 1일부터의 일수
    createdAt = new Date((excelDate - 25569) * 86400 * 1000);
  }

  // Listing ID 생성 (UUID 사용하여 고유성 보장)
  const listingId = uuidv4();

  // 숫자 파싱 헬퍼
  const parseNumber = (val) => {
    const num = parseInt(val, 10);
    return isNaN(num) ? 0 : num;
  };

  return {
    listingId,
    partId: basePartId,  // basePartId와 동일
    basePartId,  // ✅ 추가
    sellerId: SELLER_ID,
    brand,
    modelName,
    price,
    referencePrice,  // ✅ 신제품 판매가 추가
    conditionScore,
    imageUrls,
    status,
    createdAt: admin.firestore.Timestamp.fromDate(createdAt),
    category,

    // ✅ 통계 필드 추가
    likesCount: parseNumber(rowData['좋아요 수']),
    chatCount: parseNumber(rowData['채팅 수']),
    viewCount: parseNumber(rowData['조회수']),

    // ✅ 상태 정보 추가
    isSealed: rowData['미개봉 여부'] === 'O',
    ownershipTransfers: rowData['소유권 이전횟수'] || '모름',
    warrantyPeriod: rowData['AS기간'] || '모름',
    usageFrequency: rowData['사용빈도'] || '모름',
    purchaseDate: rowData['구매일'] || '모름',
  };
}

// ============================================
// 메인 업로드 로직
// ============================================

/**
 * Excel 파일 처리 및 Firestore 업로드
 */
async function processExcelFile(filePath, category) {
  console.log(`\n📊 처리 시작: ${filePath} (category: ${category})`);
  console.log('='.repeat(60));

  const workbook = xlsx.readFile(filePath);
  const targetSheets = ['거래완료', '예약중', '판매중'];

  let totalCount = 0;

  for (const sheetName of targetSheets) {
    if (!workbook.SheetNames.includes(sheetName)) {
      console.log(`⚠️  시트 "${sheetName}"를 찾을 수 없습니다. 건너뜁니다.`);
      continue;
    }

    console.log(`\n📋 시트 처리: ${sheetName}`);

    const sheet = workbook.Sheets[sheetName];
    const rows = xlsx.utils.sheet_to_json(sheet, { defval: '' });

    console.log(`  총 ${rows.length}개 행 발견`);

    // Firestore 배치 작업 (최대 500개씩)
    const batchSize = 500;
    let uploadedCount = 0;

    for (let i = 0; i < rows.length; i += batchSize) {
      const batch = db.batch();
      const batchRows = rows.slice(i, i + batchSize);

      for (const row of batchRows) {
        // 필수 필드 검증 (판매가가 없으면 건너뜀)
        const price = parsePrice(row['판매가']);
        if (price === 0) {
          continue;
        }

        try {
          const listing = createListingDocument(category, sheetName, row);
          const docRef = db.collection('listings').doc(listing.listingId);
          batch.set(docRef, listing);
          uploadedCount++;
        } catch (error) {
          console.error(`  ❌ 행 처리 실패:`, row, error.message);
        }
      }

      // 배치 커밋
      if (uploadedCount > 0) {
        await batch.commit();
        console.log(`  ✅ ${uploadedCount}개 업로드 완료 (진행률: ${Math.min(i + batchSize, rows.length)}/${rows.length})`);
      }
    }

    totalCount += uploadedCount;
  }

  console.log(`\n✅ ${path.basename(filePath)} 처리 완료: 총 ${totalCount}개 업로드`);
  return totalCount;
}

/**
 * 메인 실행 함수
 */
async function main() {
  console.log('\n🚀 Excel → Firestore 업로드 시작');
  console.log('='.repeat(60));

  // 판매자 ID 확인
  if (SELLER_ID === 'YOUR_SELLER_ID_HERE') {
    console.error('\n❌ 오류: SELLER_ID를 설정해주세요!');
    console.error('   스크립트 상단의 SELLER_ID 변수를 수정하세요.\n');
    process.exit(1);
  }

  const files = [
    { path: path.join(__dirname, '../datas/CPU.xlsx'), category: 'cpu' },
    { path: path.join(__dirname, '../datas/GPU.xlsx'), category: 'gpu' },
    { path: path.join(__dirname, '../datas/Mainboard.xlsx'), category: 'mainboard' },
    { path: path.join(__dirname, '../datas/RAM.xlsx'), category: 'ram' },
    { path: path.join(__dirname, '../datas/SSD.xlsx'), category: 'ssd' },
  ];

  let grandTotal = 0;

  for (const file of files) {
    try {
      const count = await processExcelFile(file.path, file.category);
      grandTotal += count;
    } catch (error) {
      console.error(`\n❌ ${file.path} 처리 실패:`, error);
    }
  }

  console.log('\n' + '='.repeat(60));
  console.log(`✅ 전체 업로드 완료: 총 ${grandTotal}개 Listing 생성`);
  console.log('='.repeat(60));

  console.log('\n📌 다음 단계:');
  console.log('  1. Firestore Console에서 listings 컬렉션 확인');
  console.log('  2. Cloud Functions가 자동으로 baseParts 생성 및 priceHistory 업데이트');
  console.log('  3. 이미지 파일을 Firebase Storage의 listings/ 폴더에 업로드');
}

// 실행
main()
  .then(() => {
    console.log('\n✨ 스크립트 실행 완료\n');
    process.exit(0);
  })
  .catch((error) => {
    console.error('\n💥 치명적 오류 발생:', error);
    process.exit(1);
  });
