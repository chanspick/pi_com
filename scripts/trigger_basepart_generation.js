// BasePart 생성 트리거 스크립트
const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function recalculateBasePartStats(basePartId) {
  try {
    const snapshot = await db.collection('listings')
      .where('basePartId', '==', basePartId)
      .where('status', '==', 'available')
      .get();

    if (snapshot.empty) {
      console.log(`⚠️  ${basePartId}: available listings 없음`);
      return;
    }

    const prices = [];
    let brand = '';
    let modelName = '';
    let category = '';

    snapshot.docs.forEach(doc => {
      const data = doc.data();
      prices.push(data.price);
      if (!brand) brand = data.brand;
      if (!modelName) modelName = data.modelName;
      if (!category) category = data.category;
    });

    const lowestPrice = Math.min(...prices);
    const averagePrice = Math.round(prices.reduce((a, b) => a + b, 0) / prices.length);
    const listingCount = prices.length;

    await db.collection('base_parts').doc(basePartId).set({
      basePartId,
      brand,
      modelName,
      category,
      lowestPrice,
      averagePrice,
      listingCount,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log(`✅ ${basePartId}: ${listingCount}개, ₩${lowestPrice.toLocaleString()}`);
  } catch (error) {
    console.error(`❌ ${basePartId}: ${error.message}`);
  }
}

async function main() {
  console.log('\n🔄 BasePart 재생성 시작');
  console.log('==================================================\n');

  // 모든 unique basePartId 가져오기
  const listingsSnapshot = await db.collection('listings').get();
  const basePartIds = new Set();

  listingsSnapshot.docs.forEach(doc => {
    const basePartId = doc.data().basePartId;
    if (basePartId) {
      basePartIds.add(basePartId);
    }
  });

  console.log(`📊 총 ${basePartIds.size}개의 unique basePartId 발견\n`);

  let processed = 0;
  for (const basePartId of basePartIds) {
    await recalculateBasePartStats(basePartId);
    processed++;
    if (processed % 50 === 0) {
      console.log(`\n진행: ${processed}/${basePartIds.size}\n`);
    }
  }

  console.log('\n==================================================');
  console.log(`✅ 완료! ${processed}개 BasePart 생성됨\n`);
  process.exit(0);
}

main().catch(console.error);
