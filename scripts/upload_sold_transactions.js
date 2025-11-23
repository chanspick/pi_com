// 거래완료 데이터를 'available' 상태로 업로드 후 'sold'로 변경하는 스크립트
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

// ============================================
// 유틸리티 함수들
// ============================================

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
      return data['제조사'] || '';
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

function calculateConditionScore(data) {
  const price = parsePrice(data['판매가']);
  const referencePrice = parsePrice(data['신제품 판매가']);
  const likes = parseInt(data['좋아요 수'], 10) || 0;
  const chats = parseInt(data['채팅 수'], 10) || 0;
  const views = parseInt(data['조회수'], 10) || 0;
  const isSealed = data['미개봉 여부'] === 'O';

  if (isSealed) return 95;
  if (!referencePrice || referencePrice === 0) return 70;

  const priceRatio = price / referencePrice;

  let baseScore;
  if (priceRatio < 0.4) {
    baseScore = 55 + (priceRatio / 0.4) * 5;
  } else if (priceRatio < 0.5) {
    baseScore = 60 + ((priceRatio - 0.4) / 0.1) * 5;
  } else if (priceRatio < 0.6) {
    baseScore = 65 + ((priceRatio - 0.5) / 0.1) * 5;
  } else if (priceRatio < 0.7) {
    baseScore = 70 + ((priceRatio - 0.6) / 0.1) * 3;
  } else if (priceRatio < 0.8) {
    baseScore = 73 + ((priceRatio - 0.7) / 0.1) * 3;
  } else if (priceRatio < 0.9) {
    baseScore = 76 + ((priceRatio - 0.8) / 0.1) * 4;
  } else {
    baseScore = 80 + Math.min((priceRatio - 0.9) / 0.1 * 3, 3);
  }

  const interestRaw = chats * 3 + likes * 1.5 + views * 0.01;

  let interestAdjustment;
  if (interestRaw < 5) {
    interestAdjustment = -5 + (interestRaw / 5) * 5;
  } else if (interestRaw < 15) {
    interestAdjustment = (interestRaw - 5) / 10 * 4;
  } else if (interestRaw < 30) {
    interestAdjustment = 4 + (interestRaw - 15) / 15 * 4;
  } else if (interestRaw < 50) {
    interestAdjustment = 8 + (interestRaw - 30) / 20 * 3;
  } else {
    interestAdjustment = 11 + Math.min((interestRaw - 50) / 50 * 1, 1);
  }

  let score = baseScore + interestAdjustment;
  score = Math.max(55, Math.min(90, score));

  return Math.round(score * 10) / 10;
}

function createListingDocument(category, rowData) {
  const basePartId = generateBasePartId(category, rowData);
  const modelName = generateModelName(category, rowData);
  const brand = extractBrand(category, rowData);

  const price = parsePrice(category === 'ram' ? rowData['판매가(개당)'] : rowData['판매가']);
  const referencePrice = parsePrice(rowData['신제품 판매가']);
  const conditionScore = calculateConditionScore(rowData);
  const imageUrls = getImageUrls(rowData);

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
    status: 'available', // 일단 available로 업로드
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

  if (category === 'cpu' && rowData['소켓']) {
    listing.socket = rowData['소켓'];
  }

  if (category === 'gpu' && rowData['TDP(W)']) {
    listing.tdp = parseNumber(rowData['TDP(W)']);
  }

  if (category === 'mainboard') {
    if (rowData['시리즈']) listing.series = rowData['시리즈'];
    if (rowData['모델명']) listing.modelDetail = rowData['모델명'];
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

  return listing;
}

// ============================================
// 메인 로직
// ============================================

async function collectSoldListings() {
  console.log('\n📊 거래완료 데이터 수집 중...');
  console.log('==================================================\n');

  const soldListings = [];

  const files = [
    { path: path.join(__dirname, '../datas/CPU.xlsx'), category: 'cpu' },
    { path: path.join(__dirname, '../datas/GPU.xlsx'), category: 'gpu' },
    { path: path.join(__dirname, '../datas/Mainboard.xlsx'), category: 'mainboard' },
    { path: path.join(__dirname, '../datas/SSD.xlsx'), category: 'ssd' },
    // RAM은 거래완료 시트가 없으므로 제외
  ];

  const sheetName = '거래완료';

  for (const { path: filePath, category } of files) {
    console.log(`📁 ${category.toUpperCase()} [거래완료] 읽는 중...`);
    const workbook = xlsx.readFile(filePath);

    if (!workbook.SheetNames.includes(sheetName)) {
      console.log(`  ⚠️  거래완료 시트 없음`);
      continue;
    }

    const sheet = workbook.Sheets[sheetName];
    const rows = xlsx.utils.sheet_to_json(sheet, { defval: '' });

    const validRows = rows.filter(row => {
      const price = parsePrice(row['판매가']);
      return price > 0;
    });

    console.log(`  ✅ ${validRows.length}개 유효 데이터`);

    for (const row of validRows) {
      try {
        const listing = createListingDocument(category, row);
        soldListings.push(listing);
      } catch (error) {
        // 조용히 스킵
      }
    }
  }

  console.log(`\n✅ 총 ${soldListings.length}개 거래완료 listing 수집 완료\n`);

  // createdAt 기준으로 정렬 (오래된 것부터)
  soldListings.sort((a, b) => a.createdAt.toMillis() - b.createdAt.toMillis());

  return soldListings;
}

async function uploadAsAvailable(listings) {
  console.log('\n🚀 STEP 1: 거래완료 데이터를 available로 순차 업로드');
  console.log('==================================================\n');
  console.log(`총 ${listings.length}개를 순차적으로 업로드합니다.\n`);

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

      await new Promise(resolve => setTimeout(resolve, delay));

    } catch (error) {
      console.error(`  ❌ 오류: ${listing.modelName} - ${error.message}`);
    }
  }

  console.log(`\n✅ STEP 1 완료: ${uploadCount}개 업로드\n`);
  return uploadCount;
}

async function changeToSoldSequentially() {
  console.log('\n🔄 STEP 2: available → sold로 순차 변경');
  console.log('==================================================\n');
  console.log('잠시 대기 후 변경을 시작합니다...\n');

  // Cloud Functions가 BasePart/PriceHistory를 생성할 시간 (30초)
  await new Promise(resolve => setTimeout(resolve, 30000));

  console.log('변경 시작...\n');

  const availableListings = await db.collection('listings')
    .where('status', '==', 'available')
    .get();

  console.log(`총 ${availableListings.size}개를 sold로 변경합니다.\n`);

  const delay = 100; // 100ms 간격
  let changedCount = 0;

  for (const doc of availableListings.docs) {
    try {
      await doc.ref.update({ status: 'sold' });
      changedCount++;

      if (changedCount % 50 === 0) {
        console.log(`  🔄 ${changedCount}/${availableListings.size} sold로 변경...`);
      }

      await new Promise(resolve => setTimeout(resolve, delay));

    } catch (error) {
      console.error(`  ❌ 오류: ${doc.id} - ${error.message}`);
    }
  }

  console.log(`\n✅ STEP 2 완료: ${changedCount}개 sold로 변경\n`);
}

async function main() {
  console.log('\n🚀 거래완료 데이터 처리 시작 (그래프 데이터 유지)');
  console.log('==================================================\n');

  try {
    // 1. 거래완료 데이터 수집
    const soldListings = await collectSoldListings();

    // 2. available로 업로드 (그래프 데이터 생성)
    await uploadAsAvailable(soldListings);

    // 3. sold로 변경 (그래프 데이터는 유지)
    await changeToSoldSequentially();

    console.log('==================================================');
    console.log('✅ 모든 작업 완료!');
    console.log('==================================================\n');
    console.log('📊 Price Chart에 거래완료 데이터가 반영되었습니다.\n');

  } catch (error) {
    console.error('❌ 오류 발생:', error);
  }

  process.exit(0);
}

main().catch(console.error);
