// 순차적 업로드 스크립트 (Price Chart용)
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

// 판매자 ID
const SELLER_ID = 'G7BfeVct9kTL3SjdLJjD7qGJh313';

// 중복 감지 임계값
const DUPLICATE_THRESHOLD = {
  PRICE_DIFF: 0.05,  // 가격 5% 이내
  SCORE_DIFF: 5,     // 점수 5점 이내
};

// ============================================
// 유틸리티 함수들 (upload_excel_to_firestore.js와 동일)
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
      const brand = sanitize(data['브랜드']);
      const series = sanitize(data['시리즈']);
      const modelNumber = sanitize(data['모델 번호']);
      const suffix = sanitize(data['접미사']);
      const memory = sanitize(data['메모리 용량']);
      return [brand, series, modelNumber, suffix, memory].filter(p => p).join('_');
    }
    case 'mainboard': {
      const manufacturer = sanitize(data['제조사']);
      const chipset = sanitize(data['칩셋']);
      return [manufacturer, chipset].filter(p => p).join('_');
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
      const capacity = sanitize(data['용량']);
      return [brand, capacity].filter(p => p).join('_');
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
      const brand = data['브랜드'] || '';
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
      const capacity = data['용량 (GB)'] || '';
      const speed = data['클럭 (MHz)'] || '';
      return [brand, type, capacity, speed].filter(p => p).join(' ');
    }
    case 'ssd': {
      const brand = data['제조사'] || '';
      const series = data['시리즈/모델명'] || '';
      const capacity = data['용량'] || '';
      return [brand, series, capacity].filter(p => p).join(' ');
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
      return data['제조사'] || '';
    case 'ram':
    case 'ssd':
      return data['제조사'] || '';
    default:
      return '';
  }
}

function getImageUrls(data) {
  const imageUrls = [];
  const baseUrl = 'https://firebasestorage.googleapis.com/v0/b/picom-team.firebasestorage.app/o/';

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
// 카테고리별 기본 점수 (사용빈도 제거 & 가격 비중 강화)
// ============================================
const CATEGORY_BASE_SCORES = {
  'cpu': 70,       // CPU는 고장이 잘 안나서 기본 점수 유지
  'gpu': 68,       // GPU는 채굴 리스크를 가격으로 판단하기 위해 기본 점수 소폭 하향
  'mainboard': 75,
  'ssd': 65,       // 수명 소모품이라 보수적
  'ram': 70,
  'unknown': 65
};

function calculateConditionScore(category, row, imageUrls) {
  // 1. 카테고리 기본 점수
  let score = CATEGORY_BASE_SCORES[category.toLowerCase()] || 65.0;

  // 2. 신품/중고 절대 기준 (팩트 체크)
  const isSealed = row['미개봉 여부'] === 'O' || row['미개봉 여부'] === true;
  if (isSealed) {
    score += 10; // 미개봉 가산점
  }

  // 3. 이미지 투명성 (신뢰도)
  if (imageUrls.length >= 3) {
    score += 3; // 사진이 많을수록 상태 자신감 표현
  } else if (imageUrls.length <= 1) {
    score -= 2; // 정보 부족 페널티
  }

  // 4. AS 잔존 여부 (팩트 체크)
  const warranty = (row['AS기간'] || '').toString().trim();
  if (warranty && warranty !== '모름' && warranty !== '만료') {
    score += 5; // AS 남았으면 가산점
  }

  // 5. 가격 기반 상태 추정 (가장 중요한 변수)
  const price = parsePrice(category === 'ram' ? row['판매가(개당)'] : row['판매가']);
  const refPrice = parsePrice(row['신제품 판매가']);

  if (price > 0 && refPrice > 0) {
    const ratio = price / refPrice;

    if (ratio < 0.35) {
      // 35% 미만: "부품용"이나 "하자품"일 확률 매우 높음
      score -= 15;
    } else if (ratio < 0.5) {
      // 50% 미만: 급매 혹은 사용감 많음
      score -= 5;
    } else if (ratio >= 0.5 && ratio <= 0.8) {
      // 50~80%: 가장 일반적인 양품 구간
      score += 2;
    } else if (ratio > 0.8) {
      // 80% 초과: "S급" 혹은 "단순 개봉" 주장 매물
      if (ratio > 1.0 && !isSealed) {
        score -= 10; // 신품가보다 비싼데 미개봉 아님 (사기 의심)
      } else {
        score += 5; // 상태 자신감 인정
      }
    }
  }

  // 6. 점수 범위 제한 (Max 95)
  return Math.min(95, Math.max(0, Math.round(score)));
}

function createListingDocument(category, sheetName, rowData) {
  const status = getStatusFromSheetName(sheetName);
  const basePartId = generateBasePartId(category, rowData);
  const modelName = generateModelName(category, rowData);
  const brand = extractBrand(category, rowData);

  // RAM은 '판매가(개당)' 사용
  const price = parsePrice(category === 'ram' ? rowData['판매가(개당)'] : rowData['판매가']);
  const referencePrice = parsePrice(rowData['신제품 판매가']);
  const imageUrls = getImageUrls(rowData);
  const conditionScore = calculateConditionScore(category, rowData, imageUrls);

  let createdAt = new Date();
  const excelDate = rowData['판매글 게시일자'];
  if (excelDate && typeof excelDate === 'number') {
    createdAt = new Date((excelDate - 25569) * 86400 * 1000);
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
    ownershipTransfers: rowData['소유권 이전횟수'] || '모름',
    warrantyPeriod: rowData['AS기간'] || '모름',
    usageFrequency: rowData['사용빈도'] || '모름',
    purchaseDate: rowData['구매일'] || '모름',
  };

  // CPU: 소켓 추가
  if (category === 'cpu' && rowData['소켓']) {
    listing.socket = rowData['소켓'];
  }

  // GPU: TDP 추가
  if (category === 'gpu' && rowData['TDP(W)']) {
    listing.tdp = parseNumber(rowData['TDP(W)']);
  }

  // Mainboard: 시리즈, 세부특징 추가
  if (category === 'mainboard') {
    if (rowData['시리즈']) listing.series = rowData['시리즈'];
    if (rowData['모델명']) listing.modelDetail = rowData['모델명'];
    if (rowData['세부특징1']) listing.feature1 = rowData['세부특징1'];
    if (rowData['세부특징2']) listing.feature2 = rowData['세부특징2'];
  }

  // SSD: 폼팩터, 시리즈/모델명 추가
  if (category === 'ssd') {
    if (rowData['폼팩터']) listing.formFactor = rowData['폼팩터'];
    if (rowData['시리즈/모델명']) listing.seriesModel = rowData['시리즈/모델명'];
  }

  // RAM: 판매 개수 추가
  if (category === 'ram' && rowData['판매 개수']) {
    listing.quantity = parseNumber(rowData['판매 개수']);
  }

  return listing;
}

// ============================================
// 중복 감지 로직
// ============================================

function isDuplicate(firestoreDoc, excelListing) {
  const fsData = firestoreDoc.data();

  // 1. basePartId 비교
  const sameBasePartId = fsData.basePartId === excelListing.basePartId ||
                         fsData.partId === excelListing.basePartId;

  // 2. modelName 비교
  const sameModelName = fsData.modelName === excelListing.modelName;

  // 3. 가격 비교 (±5% 허용)
  const priceDiff = Math.abs(excelListing.price - fsData.price) / Math.max(excelListing.price, fsData.price, 1);
  const similarPrice = priceDiff < DUPLICATE_THRESHOLD.PRICE_DIFF;

  // 4. conditionScore 비교 (±5 허용)
  const scoreDiff = Math.abs(excelListing.conditionScore - (fsData.conditionScore || 70));
  const similarScore = scoreDiff < DUPLICATE_THRESHOLD.SCORE_DIFF;

  // 높은 확신도 중복: basePartId + modelName + 가격 유사
  if (sameBasePartId && sameModelName && similarPrice) {
    return { isDuplicate: true, confidence: 'high' };
  }

  // 중간 확신도 중복: basePartId + 가격 + 점수 유사
  if (sameBasePartId && similarPrice && similarScore) {
    return { isDuplicate: true, confidence: 'medium' };
  }

  return { isDuplicate: false };
}

// ============================================
// 메인 업로드 로직
// ============================================

async function processExcelFile(filePath, category, existingDocs) {
  console.log(`\n📊 처리 시작: ${filePath} (category: ${category})`);
  console.log('='.repeat(60));

  const workbook = xlsx.readFile(filePath);
  const targetSheets = ['거래완료', '예약중', '판매중'];

  let totalProcessed = 0;
  let totalSkipped = 0;
  let totalUploaded = 0;

  for (const sheetName of targetSheets) {
    if (!workbook.SheetNames.includes(sheetName)) {
      console.log(`⚠️  시트 "${sheetName}"를 찾을 수 없습니다.`);
      continue;
    }

    console.log(`\n📋 시트 처리: ${sheetName}`);
    const sheet = workbook.Sheets[sheetName];
    const rows = xlsx.utils.sheet_to_json(sheet, { defval: '' });

    console.log(`  총 ${rows.length}개 행 발견`);

    const batchSize = 500;
    let batch = db.batch();
    let batchCount = 0;

    for (const row of rows) {
      totalProcessed++;

      const price = parsePrice(row['판매가']);
      if (price === 0) {
        continue;
      }

      try {
        const listing = createListingDocument(category, sheetName, row);

        // 중복 체크
        let isDupe = false;
        for (const existingDoc of existingDocs) {
          const result = isDuplicate(existingDoc, listing);
          if (result.isDuplicate) {
            isDupe = true;
            totalSkipped++;
            if (totalSkipped <= 3) {
              console.log(`  ⏭️  중복 스킵: ${listing.modelName} (${result.confidence})`);
            } else if (totalSkipped === 4) {
              console.log(`  ⏭️  ... (이후 중복 스킵 메시지 생략)`);
            }
            break;
          }
        }

        if (!isDupe) {
          // 신규 데이터 업로드
          const docRef = db.collection('listings').doc(listing.listingId);
          batch.set(docRef, listing);
          batchCount++;
          totalUploaded++;

          if (totalUploaded <= 5) {
            console.log(`  ✅ 신규 추가: ${listing.modelName} (${listing.price.toLocaleString()}원)`);
          } else if (totalUploaded === 6) {
            console.log(`  ✅ ... (이후 추가 메시지 생략)`);
          }

          // 배치 커밋
          if (batchCount >= batchSize) {
            await batch.commit();
            batch = db.batch();
            batchCount = 0;
          }
        }
      } catch (error) {
        console.error(`  ❌ 행 처리 실패:`, error.message);
      }
    }

    // 남은 배치 커밋
    if (batchCount > 0) {
      await batch.commit();
    }
  }

  console.log(`\n✅ ${path.basename(filePath)} 처리 완료:`);
  console.log(`   - 처리: ${totalProcessed}개`);
  console.log(`   - 중복 스킵: ${totalSkipped}개`);
  console.log(`   - 신규 업로드: ${totalUploaded}개`);

  return { processed: totalProcessed, skipped: totalSkipped, uploaded: totalUploaded };
}

async function collectAllListings() {
  console.log('\n📊 모든 Excel 파일에서 데이터 수집 중...');
  console.log('==================================================\n');

  const allListings = [];

  const files = [
    { path: path.join(__dirname, '../datas/CPU.xlsx'), category: 'cpu', sheets: ['거래완료', '예약중', '판매중'] },
    { path: path.join(__dirname, '../datas/GPU.xlsx'), category: 'gpu', sheets: ['거래완료', '예약중', '판매중'] },
    { path: path.join(__dirname, '../datas/Mainboard.xlsx'), category: 'mainboard', sheets: ['거래완료', '예약중', '판매중'] },
    { path: path.join(__dirname, '../datas/SSD.xlsx'), category: 'ssd', sheets: ['거래완료', '예약중', '판매중'] },
    { path: path.join(__dirname, '../datas/RAM.xlsx'), category: 'ram', sheets: ['판매중'] }, // RAM은 판매중만
  ];

  for (const { path: filePath, category, sheets } of files) {
    console.log(`📁 ${category.toUpperCase()} 파일 읽는 중...`);
    const workbook = xlsx.readFile(filePath);

    for (const sheetName of sheets) {
      if (!workbook.SheetNames.includes(sheetName)) {
        continue;
      }

      const sheet = workbook.Sheets[sheetName];
      const rows = xlsx.utils.sheet_to_json(sheet, { defval: '' });

      const validRows = rows.filter(row => {
        // RAM은 '판매가(개당)' 사용
        const price = parsePrice(category === 'ram' ? row['판매가(개당)'] : row['판매가']);
        return price > 0;
      });

      console.log(`  [${sheetName}] ${validRows.length}개 유효 데이터`);

      for (const row of validRows) {
        try {
          const listing = createListingDocument(category, sheetName, row);
          allListings.push(listing);
        } catch (error) {
          // 조용히 스킵
        }
      }
    }
  }

  console.log(`\n✅ 총 ${allListings.length}개 listing 수집 완료\n`);

  // createdAt 기준으로 정렬 (오래된 것부터)
  allListings.sort((a, b) => a.createdAt.toMillis() - b.createdAt.toMillis());

  return allListings;
}

async function uploadSequentially(listings) {
  console.log('\n🚀 순차적 업로드 시작');
  console.log('==================================================\n');
  console.log(`총 ${listings.length}개 listing을 순차적으로 업로드합니다.\n`);

  const delay = 50; // 50ms 간격
  let uploadCount = 0;

  for (const listing of listings) {
    try {
      const docRef = db.collection('listings').doc(listing.listingId);
      await docRef.set(listing);

      uploadCount++;

      if (uploadCount % 50 === 0) {
        console.log(`  ✅ ${uploadCount}/${listings.length} 업로드 완료...`);
      }

      // 작은 딜레이 추가
      await new Promise(resolve => setTimeout(resolve, delay));

    } catch (error) {
      console.error(`  ❌ 오류: ${listing.modelName} - ${error.message}`);
    }
  }

  console.log(`\n==================================================`);
  console.log(`✅ 순차적 업로드 완료: ${uploadCount}개`);
  console.log(`==================================================\n`);
}

async function main() {
  console.log('\n🚀 순차적 Excel 업로드 시작 (Price Chart용)');
  console.log('==================================================\n');

  if (SELLER_ID === 'YOUR_SELLER_ID_HERE') {
    console.error('\n❌ 오류: SELLER_ID를 설정해주세요!\n');
    process.exit(1);
  }

  try {
    // 1. 모든 데이터 수집
    const allListings = await collectAllListings();

    // 2. 순차적 업로드
    await uploadSequentially(allListings);

    console.log('\n📌 다음 단계:');
    console.log('  1. Cloud Functions가 BasePart를 자동 생성합니다.');
    console.log('  2. 약 1-2분 정도 기다리면 Price Chart 데이터가 준비됩니다.\n');

  } catch (error) {
    console.error('❌ 오류 발생:', error);
  }
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
