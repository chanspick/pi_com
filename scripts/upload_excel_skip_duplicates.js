// 중복 스킵하고 신규 데이터만 업로드하는 스크립트
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
  return 'available';
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
      const series = sanitize(data['시리즈']);
      return [manufacturer, chipset, series].filter(p => p).join('_');
    }
    case 'ram': {
      const brand = sanitize(data['브랜드']);
      const type = sanitize(data['타입']);
      const capacity = sanitize(data['용량']);
      const speed = sanitize(data['속도']);
      return [brand, type, capacity, speed].filter(p => p).join('_');
    }
    case 'ssd': {
      const brand = sanitize(data['브랜드']);
      const type = sanitize(data['타입']);
      const capacity = sanitize(data['용량']);
      return [brand, type, capacity].filter(p => p).join('_');
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
  if (data['conditionScore'] != null && data['conditionScore'] !== '') {
    const existingScore = parseFloat(data['conditionScore']);
    if (!isNaN(existingScore)) {
      return existingScore;
    }
  }

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

function createListingDocument(category, sheetName, rowData) {
  const status = getStatusFromSheetName(sheetName);
  const basePartId = generateBasePartId(category, rowData);
  const modelName = generateModelName(category, rowData);
  const brand = extractBrand(category, rowData);
  const price = parsePrice(rowData['판매가']);
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

  return {
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

async function main() {
  console.log('\n🚀 중복 스킵 Excel 업로드 시작');
  console.log('='.repeat(60));

  if (SELLER_ID === 'YOUR_SELLER_ID_HERE') {
    console.error('\n❌ 오류: SELLER_ID를 설정해주세요!\n');
    process.exit(1);
  }

  // 기존 Firestore 데이터 로드
  console.log('\n📊 기존 Firestore 데이터 로드 중...');
  const existingSnapshot = await db.collection('listings').get();
  console.log(`  ✅ ${existingSnapshot.size}개 listings 로드 완료\n`);

  const files = [
    { path: path.join(__dirname, '../datas/CPU.xlsx'), category: 'cpu' },
    { path: path.join(__dirname, '../datas/GPU.xlsx'), category: 'gpu' },
    { path: path.join(__dirname, '../datas/Mainboard.xlsx'), category: 'mainboard' },
    // { path: path.join(__dirname, '../datas/RAM.xlsx'), category: 'ram' },
    // { path: path.join(__dirname, '../datas/SSD.xlsx'), category: 'ssd' },
  ];

  const grandTotal = {
    processed: 0,
    skipped: 0,
    uploaded: 0,
  };

  for (const file of files) {
    try {
      // 해당 카테고리의 기존 문서만 필터링
      const categoryDocs = existingSnapshot.docs.filter(doc =>
        doc.data().category === file.category
      );

      console.log(`📂 ${file.category} 카테고리: 기존 ${categoryDocs.length}개`);

      const result = await processExcelFile(file.path, file.category, categoryDocs);

      grandTotal.processed += result.processed;
      grandTotal.skipped += result.skipped;
      grandTotal.uploaded += result.uploaded;
    } catch (error) {
      console.error(`\n❌ ${file.path} 처리 실패:`, error);
    }
  }

  console.log('\n' + '='.repeat(60));
  console.log('📊 전체 업로드 요약');
  console.log('='.repeat(60));
  console.log(`처리한 행: ${grandTotal.processed}개`);
  console.log(`중복 스킵: ${grandTotal.skipped}개`);
  console.log(`신규 업로드: ${grandTotal.uploaded}개`);
  console.log('='.repeat(60));

  if (grandTotal.uploaded === 0) {
    console.log('\n💡 신규 데이터가 없습니다.');
    console.log('   Excel 파일에 새로운 행을 추가한 후 다시 실행하세요.');
  } else {
    console.log('\n📌 다음 단계:');
    console.log('  1. Firestore Console에서 listings 컬렉션 확인');
    console.log('  2. Cloud Functions가 baseParts 및 priceHistory 업데이트');
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
