// RAM 전용 업로드 스크립트
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

function generateBasePartId(data) {
  const brand = sanitize(data['제조사']);
  const type = sanitize(data['메모리 규격']);
  const capacity = sanitize(data['용량 (GB)']);
  const speed = sanitize(data['클럭 (MHz)']);

  return [brand, type, capacity, speed].filter(p => p).join('_');
}

function generateModelName(data) {
  const brand = data['제조사'] || '';
  const type = data['메모리 규격'] || '';
  const capacity = data['용량 (GB)'] || '';
  const speed = data['클럭 (MHz)'] || '';

  return [brand, type, capacity, speed].filter(p => p).join(' ');
}

function calculateConditionScore(data) {
  // RAM은 신제품 가격이 있는 경우
  const price = parsePrice(data['판매가(개당)']);
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

function getImageUrls(data) {
  const imageUrls = [];
  const baseUrl = 'https://firebasestorage.googleapis.com/v0/b/picom-team.firebasestorage.app/o/';

  for (let i = 1; i <= 5; i++) {
    const imageFilename = data[`사진${i}`];
    if (imageFilename && imageFilename.trim()) {
      const encodedFilename = encodeURIComponent(`listings/${imageFilename}`);
      imageUrls.push(`${baseUrl}${encodedFilename}?alt=media`);
    }
  }

  return imageUrls;
}

function createRamListing(rowData) {
  const basePartId = generateBasePartId(rowData);
  const modelName = generateModelName(rowData);
  const brand = rowData['제조사'] || '';

  // RAM은 '판매가(개당)' 사용
  const price = parsePrice(rowData['판매가(개당)']);
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
    status: 'available', // RAM은 판매중만 있음
    createdAt: admin.firestore.Timestamp.fromDate(createdAt),
    category: 'ram',
    likesCount: parseNumber(rowData['좋아요 수']),
    chatCount: parseNumber(rowData['채팅 수']),
    viewCount: parseNumber(rowData['조회수']),
    isSealed: rowData['미개봉 여부'] === 'O',
    ownershipTransfers: rowData['소유권 이전횟수'] || '모름',
    warrantyPeriod: rowData['AS기간'] || '모름',
    usageFrequency: rowData['사용빈도'] || '모름',
    purchaseDate: rowData['구매일'] || '모름',
  };

  // RAM 특수 필드: 판매 개수 (참고용, 실제 가격은 개당 가격)
  if (rowData['판매 개수']) {
    listing.quantity = parseNumber(rowData['판매 개수']);
  }

  return listing;
}

// ============================================
// 메인 업로드 로직
// ============================================

async function uploadRam() {
  console.log('\n🚀 RAM 전용 업로드 시작');
  console.log('==================================================\n');

  const filePath = path.join(__dirname, '../datas/RAM.xlsx');
  const workbook = xlsx.readFile(filePath);

  // RAM은 '판매중' 시트만 처리
  const sheetName = '판매중';

  if (!workbook.SheetNames.includes(sheetName)) {
    console.error('❌ "판매중" 시트를 찾을 수 없습니다.');
    process.exit(1);
  }

  console.log(`📋 시트 처리: ${sheetName}`);
  const sheet = workbook.Sheets[sheetName];
  const rows = xlsx.utils.sheet_to_json(sheet);

  console.log(`  총 ${rows.length}개 행 발견\n`);

  // 유효한 데이터만 필터링
  const validRows = rows.filter(row => {
    return row['제조사'] &&
           row['메모리 규격'] &&
           row['용량 (GB)'] &&
           row['판매가(개당)'];
  });

  console.log(`  유효한 데이터: ${validRows.length}개\n`);

  if (validRows.length === 0) {
    console.log('⚠️  업로드할 유효한 데이터가 없습니다.');
    process.exit(0);
  }

  // Firestore 배치 업로드
  let uploadCount = 0;
  const batchSize = 100;

  for (let i = 0; i < validRows.length; i += batchSize) {
    const batch = db.batch();
    const chunk = validRows.slice(i, i + batchSize);

    chunk.forEach(row => {
      const listing = createRamListing(row);
      const docRef = db.collection('listings').doc(listing.listingId);
      batch.set(docRef, listing);

      console.log(`  ✅ 추가: ${listing.modelName} (₩${listing.price.toLocaleString()})`);
      uploadCount++;
    });

    await batch.commit();
    console.log(`\n  📦 배치 ${Math.floor(i / batchSize) + 1} 업로드 완료\n`);
  }

  console.log('==================================================');
  console.log(`✅ RAM 업로드 완료: ${uploadCount}개`);
  console.log('==================================================\n');

  console.log('📌 다음 단계:');
  console.log('  1. BasePart 생성을 위해 30초 대기...');

  // BasePart 생성 대기
  await new Promise(resolve => setTimeout(resolve, 5000));

  console.log('  2. BasePart 수동 생성 실행...\n');

  // BasePart 수동 생성
  await createRamBaseParts();

  process.exit(0);
}

async function createRamBaseParts() {
  console.log('🔄 RAM BasePart 생성 시작\n');

  const ramListings = await db.collection('listings')
    .where('category', '==', 'ram')
    .get();

  const basePartIds = new Set();
  ramListings.docs.forEach(doc => {
    const basePartId = doc.data().basePartId;
    if (basePartId) {
      basePartIds.add(basePartId);
    }
  });

  console.log(`📊 ${basePartIds.size}개의 unique RAM basePartId 발견\n`);

  for (const basePartId of basePartIds) {
    const snapshot = await db.collection('listings')
      .where('basePartId', '==', basePartId)
      .where('status', '==', 'available')
      .get();

    if (snapshot.empty) continue;

    const prices = [];
    let brand = '';
    let modelName = '';

    snapshot.docs.forEach(doc => {
      const data = doc.data();
      prices.push(data.price);
      if (!brand) brand = data.brand;
      if (!modelName) modelName = data.modelName;
    });

    const lowestPrice = Math.min(...prices);
    const averagePrice = Math.round(prices.reduce((a, b) => a + b, 0) / prices.length);
    const listingCount = prices.length;

    await db.collection('base_parts').doc(basePartId).set({
      basePartId,
      brand,
      modelName,
      category: 'ram',
      lowestPrice,
      averagePrice,
      listingCount,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log(`  ✅ ${basePartId}: ${listingCount}개, ₩${lowestPrice.toLocaleString()}`);
  }

  console.log('\n✅ RAM BasePart 생성 완료!\n');
}

uploadRam().catch(console.error);
