// 모든 Listings 삭제 스크립트
const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function deleteAllListings() {
  console.log('\n🗑️  모든 Listings 삭제 시작');
  console.log('==================================================\n');

  try {
    const allListings = await db.collection('listings').get();

    console.log(`📊 총 ${allListings.size}개의 listings 발견\n`);

    if (allListings.empty) {
      console.log('⚠️  삭제할 listings가 없습니다.');
      process.exit(0);
    }

    // Batch 삭제
    let deletedCount = 0;
    const batchSize = 100;

    for (let i = 0; i < allListings.docs.length; i += batchSize) {
      const batch = db.batch();
      const chunk = allListings.docs.slice(i, i + batchSize);

      chunk.forEach(doc => {
        batch.delete(doc.ref);
        const data = doc.data();
        console.log(`  🗑️  삭제: [${data.category}] ${data.modelName}`);
        deletedCount++;
      });

      await batch.commit();
      console.log(`\n  📦 배치 ${Math.floor(i / batchSize) + 1} 완료 (${deletedCount}/${allListings.size})\n`);
    }

    console.log('==================================================');
    console.log(`✅ 모든 Listings 삭제 완료: ${deletedCount}개`);
    console.log('==================================================\n');

  } catch (error) {
    console.error('❌ 오류 발생:', error.message);
    process.exit(1);
  }

  process.exit(0);
}

deleteAllListings().catch(console.error);
