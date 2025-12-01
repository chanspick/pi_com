// new_datas 폴더의 엑셀 데이터를 Firestore에 업로드
// 실제 링크 데이터 포함, Price Chart 최적화
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
// 설정
// ============================================
const SELLER_ID = 'G7BfeVct9kTL3SjdLJjD7qGJh313';
const NEW_DATAS_DIR = path.join(__dirname, '../new_datas');
const DELAY_MS = 50; // 순차 업로드 딜레이

// 카테고리별 파일 매핑
const FILE_MAP = {
  cpu: { path: 'cpu/CPU.xlsx', sheets: ['판매중', '거래완료', '예약중'] },
  gpu: { path: 'gpu/GPU.xlsx', sheets: ['판매중', '거래완료', '예약중'] },
  mainboard: { path: 'mainboard/메보.xlsx', sheets: ['판매중', '거래완료', '예약중'] },
  ram: { path: 'ram/RAM.xlsx', sheets: ['판매중', '거래완료', '예약중'] },
  ssd: { path: 'ssd/SSD.xlsx', sheets: ['판매중', '거래완료', '예약중'] },
};

// 카테고리별 기본 점수
const CATEGORY_BASE_SCORES = {
  'cpu': 70,
  'gpu': 68,
  'mainboard': 75,
  'ssd': 65,
  'ram': 70,
};

// ============================================
// 유틸리티 함수
// ============================================

function getStatusFromSheetName(sheetName) {
  const statusMap = {
    '판매중': 'available',
    '거래완료': 'sold',
    '예약중': 'reserved'
  };
  return statusMap[sheetName] || 'available';
}

function parsePrice(priceValue) {
  if (!priceValue) return 0;
  const priceStr = String(priceValue).replace(/[^\d]/g, '');
  const price = parseInt(priceStr, 10);
  return isNaN(price) ? 0 : price;
}

function sanitize(str) {
  if (!str) return '';
  return String(str).trim().replace(/\s+/g, '_').replace(/[^\w가-힣-]/g, '');
}

// ============================================
// 카테고리별 ID/이름 생성 (새 컬럼 구조 반영)
// ============================================

function generateBasePartId(category, data) {
  switch (category) {
    case 'cpu': {
      const brand = sanitize(data['브랜드']);
      const series = sanitize(data['시리즈']);
      const modelNumber = sanitize(data['모델 번호']);
      const suffix = sanitize(data['접미사']);
      return [brand, series, modelNumber, suffix].filter(p => p).join('_');
    }
    case 'gpu': {
      const brand = sanitize(data['브랜드'] || data['제조사']);
      const series = sanitize(data['시리즈']);
      const modelNumber = sanitize(data['모델 번호']);
      const suffix = sanitize(data['접미사']);
      const memory = sanitize(data['메모리 용량']);
      return [brand, series, modelNumber, suffix, memory].filter(p => p).join('_');
    }
    case 'mainboard': {
      const manufacturer = sanitize(data['제조사']);
      const series = sanitize(data['시리즈']);
      const chipset = sanitize(data['칩셋']);
      const model = sanitize(data['모델명']);
      return [manufacturer, series, chipset, model].filter(p => p).join('_');
    }
    case 'ram': {
      const brand = sanitize(data['제조사']);
      const type = sanitize(data['메모리 규격']);
      const capacity = sanitize(data['용량 (GB)']);
      const speed = sanitize(data['클럭 (MHz)']);
      return [brand, type, capacity, speed].filter(p => p).join('_');
    }
    case 'ssd': {
      const brand = sanitize(data['제조사']);
      const series = sanitize(data['시리즈/모델명']);
      const capacity = sanitize(data['용량']);
      return [brand, series, capacity].filter(p => p).join('_');
    }
    default:
      return 'unknown';
  }
}

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
      const brand = data['브랜드'] || data['제조사'] || '';
      const series = data['시리즈'] || '';
      const modelNumber = data['모델 번호'] || '';
      const suffix = data['접미사'] || '';
      const detailModel = data['세부 모델명'] || '';
      const memory = data['메모리 용량'] || '';
      return [brand, series, modelNumber, suffix, detailModel, memory].filter(p => p).join(' ');
    }
    case 'mainboard': {
      const manufacturer = data['제조사'] || '';
      const series = data['시리즈'] || '';
      const chipset = data['칩셋'] || '';
      const modelName = data['모델명'] || '';
      const detail1 = data['세부특징1'] || '';
      const detail2 = data['세부특징2'] || '';
      return [manufacturer, series, chipset, modelName, detail1, detail2].filter(p => p).join(' ');
    }
    case 'ram': {
      const brand = data['제조사'] || '';
      const type = data['메모리 규격'] || '';
      const series = data['시리즈/모델명'] || '';
      const capacity = data['용량 (GB)'] ? `${data['용량 (GB)']}GB` : '';
      const speed = data['클럭 (MHz)'] ? `${data['클럭 (MHz)']}MHz` : '';
      return [brand, type, series, capacity, speed].filter(p => p).join(' ');
    }
    case 'ssd': {
      const brand = data['제조사'] || '';
      const series = data['시리즈/모델명'] || '';
      const formFactor = data['폼팩터'] || '';
      const capacity = data['용량'] || '';
      return [brand, series, formFactor, capacity].filter(p => p).join(' ');
    }
    default:
      return 'Unknown Model';
  }
}

function extractBrand(category, data) {
  switch (category) {
    case 'cpu':
      return data['브랜드'] || '';
    case 'gpu':
      return data['제조사'] || data['브랜드'] || '';
    case 'mainboard':
    case 'ram':
    case 'ssd':
      return data['제조사'] || '';
    default:
      return '';
  }
}

// ============================================
// 이미지 URL 생성 (새 컬럼 구조: 사진1~사진5)
// ============================================

function getImageUrls(data) {
  const imageUrls = [];
  const baseUrl = 'https://firebasestorage.googleapis.com/v0/b/picom-team.firebasestorage.app/o/';

  // 사진1 ~ 사진5 체크
  for (let i = 1; i <= 5; i++) {
    const imageFilename = data[`사진${i}`];
    if (imageFilename && imageFilename.trim()) {
      const encodedFilename = encodeURIComponent(`listings/${imageFilename}`);
      const imageUrl = `${baseUrl}${encodedFilename}?alt=media`;
      imageUrls.push(imageUrl);
    }
  }

  return imageUrls;
}

// ============================================
// 컨디션 점수 계산
// ============================================

function calculateConditionScore(category, row, imageUrls) {
  let score = CATEGORY_BASE_SCORES[category.toLowerCase()] || 65.0;

  // 미개봉 여부
  const isSealed = row['미개봉 여부'] === 'O' || row['미개봉 여부'] === true;
  if (isSealed) {
    score += 10;
  }

  // 이미지 개수
  const imageCount = parseInt(row['사진 개수']) || imageUrls.length;
  if (imageCount >= 3) {
    score += 3;
  } else if (imageCount <= 1) {
    score -= 2;
  }

  // AS 기간
  const warranty = (row['AS기간'] || '').toString().trim();
  if (warranty && warranty !== '모름' && warranty !== '만료') {
    score += 5;
  }

  // 가격 기반 상태 추정
  const price = parsePrice(category === 'ram' ? row['판매가(개당)'] : row['판매가']);
  const refPrice = parsePrice(row['신제품 판매가']);

  if (price > 0 && refPrice > 0) {
    const ratio = price / refPrice;

    if (ratio < 0.35) {
      score -= 15;
    } else if (ratio < 0.5) {
      score -= 5;
    } else if (ratio >= 0.5 && ratio <= 0.8) {
      score += 2;
    } else if (ratio > 0.8) {
      if (ratio > 1.0 && !isSealed) {
        score -= 10;
      } else {
        score += 5;
      }
    }
  }

  return Math.min(95, Math.max(0, Math.round(score)));
}

// ============================================
// Listing 문서 생성
// ============================================

function createListingDocument(category, sheetName, rowData) {
  const status = getStatusFromSheetName(sheetName);
  const basePartId = generateBasePartId(category, rowData);
  const modelName = generateModelName(category, rowData);
  const brand = extractBrand(category, rowData);
  const imageUrls = getImageUrls(rowData);

  // RAM은 '판매가(개당)' 사용
  const price = parsePrice(category === 'ram' ? rowData['판매가(개당)'] : rowData['판매가']);
  const referencePrice = parsePrice(rowData['신제품 판매가']);
  const conditionScore = calculateConditionScore(category, rowData, imageUrls);

  // 날짜 파싱
  let createdAt = new Date();
  const excelDate = rowData['판매글 게시일자'];
  if (excelDate) {
    if (typeof excelDate === 'number') {
      createdAt = new Date((excelDate - 25569) * 86400 * 1000);
    } else if (typeof excelDate === 'string') {
      const parsed = new Date(excelDate);
      if (!isNaN(parsed.getTime())) {
        createdAt = parsed;
      }
    }
  }

  const listingId = uuidv4();

  const parseNumber = (val) => {
    const num = parseInt(val, 10);
    return isNaN(num) ? 0 : num;
  };

  const listing = {
    listingId,
    partId: basePartId,
    basePartId,
    sellerId: SELLER_ID,
    brand,
    modelName,
    price,
    referencePrice,
    conditionScore,
    imageUrls,
    status,
    createdAt: admin.firestore.Timestamp.fromDate(createdAt),
    category,
    likesCount: parseNumber(rowData['좋아요 수']),
    chatCount: parseNumber(rowData['채팅 수']),
    viewCount: parseNumber(rowData['조회수']),
    isSealed: rowData['미개봉 여부'] === 'O',
    warrantyPeriod: rowData['AS기간'] || '모름',
  };

  // 카테고리별 추가 필드
  if (category === 'cpu' && rowData['소켓']) {
    listing.socket = rowData['소켓'];
  }

  if (category === 'gpu' && rowData['TDP(W)']) {
    listing.tdp = parseNumber(rowData['TDP(W)']);
  }

  if (category === 'mainboard') {
    if (rowData['시리즈']) listing.series = rowData['시리즈'];
    if (rowData['모델명']) listing.modelDetail = rowData['모델명'];
    if (rowData['칩셋']) listing.chipset = rowData['칩셋'];
    if (rowData['세부특징1']) listing.feature1 = rowData['세부특징1'];
    if (rowData['세부특징2']) listing.feature2 = rowData['세부특징2'];
  }

  if (category === 'ssd') {
    if (rowData['폼팩터']) listing.formFactor = rowData['폼팩터'];
    if (rowData['시리즈/모델명']) listing.seriesModel = rowData['시리즈/모델명'];
  }

  if (category === 'ram' && rowData['판매 개수']) {
    listing.quantity = parseNumber(rowData['판매 개수']);
  }

  // 원본 링크 저장 (당근 또는 링크 컬럼)
  const sourceLink = rowData['링크'] || rowData['당근'];
  if (sourceLink) {
    listing.sourceUrl = sourceLink;
  }

  return listing;
}

// ============================================
// 데이터 수집
// ============================================

async function collectAllListings() {
  console.log('\n📊 new_datas에서 데이터 수집 중...');
  console.log('==================================================\n');

  const allListings = [];

  for (const [category, config] of Object.entries(FILE_MAP)) {
    const filePath = path.join(NEW_DATAS_DIR, config.path);

    try {
      const workbook = xlsx.readFile(filePath);
      console.log(`📁 ${category.toUpperCase()} (${path.basename(config.path)})`);
      console.log(`   시트: ${workbook.SheetNames.join(', ')}`);

      for (const sheetName of config.sheets) {
        if (!workbook.SheetNames.includes(sheetName)) {
          continue;
        }

        const sheet = workbook.Sheets[sheetName];
        const rows = xlsx.utils.sheet_to_json(sheet, { defval: '' });

        const validRows = rows.filter(row => {
          const price = parsePrice(category === 'ram' ? row['판매가(개당)'] : row['판매가']);
          return price > 0;
        });

        console.log(`   [${sheetName}] ${validRows.length}개 유효 데이터`);

        for (const row of validRows) {
          try {
            const listing = createListingDocument(category, sheetName, row);
            allListings.push(listing);
          } catch (error) {
            // 조용히 스킵
          }
        }
      }

      console.log('');

    } catch (error) {
      console.error(`   ❌ 파일 읽기 실패: ${error.message}`);
    }
  }

  console.log(`✅ 총 ${allListings.length}개 listing 수집 완료\n`);

  // createdAt 기준 정렬 (오래된 것부터 - Price Chart 최적화)
  allListings.sort((a, b) => a.createdAt.toMillis() - b.createdAt.toMillis());

  return allListings;
}

// ============================================
// 순차적 업로드
// ============================================

async function uploadSequentially(listings) {
  console.log('\n🚀 순차적 업로드 시작');
  console.log('==================================================\n');
  console.log(`총 ${listings.length}개 listing을 순차적으로 업로드합니다.\n`);

  let uploadCount = 0;
  let errorCount = 0;

  for (const listing of listings) {
    try {
      const docRef = db.collection('listings').doc(listing.listingId);
      await docRef.set(listing);

      uploadCount++;

      if (uploadCount % 50 === 0) {
        console.log(`  ✅ ${uploadCount}/${listings.length} 업로드 완료...`);
      }

      await new Promise(resolve => setTimeout(resolve, DELAY_MS));

    } catch (error) {
      errorCount++;
      console.error(`  ❌ 오류: ${listing.modelName} - ${error.message}`);
    }
  }

  console.log(`\n==================================================`);
  console.log(`✅ 업로드 완료: ${uploadCount}개`);
  if (errorCount > 0) {
    console.log(`❌ 오류: ${errorCount}개`);
  }
  console.log(`==================================================\n`);

  return { uploadCount, errorCount };
}

// ============================================
// 메인 실행
// ============================================

async function main() {
  console.log('\n🚀 new_datas 업로드 시작');
  console.log('==================================================\n');

  try {
    // 1. 데이터 수집
    const allListings = await collectAllListings();

    if (allListings.length === 0) {
      console.log('⚠️  업로드할 데이터가 없습니다.');
      process.exit(0);
    }

    // 2. 순차적 업로드
    const result = await uploadSequentially(allListings);

    console.log('📌 다음 단계:');
    console.log('  1. Cloud Functions가 BasePart를 자동 생성합니다.');
    console.log('  2. 약 1-2분 후 Price Chart 데이터가 준비됩니다.\n');

    process.exit(result.errorCount > 0 ? 1 : 0);

  } catch (error) {
    console.error('❌ 오류 발생:', error);
    process.exit(1);
  }
}

main();
