// RAM 전용 삭제 스크립트
const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function deleteRamListings() {
  console.log('\n🗑️  RAM Listings 삭제 시작');
  console.log('==================================================\n');

  try {
    const ramListings = await db.collection('listings')
      .where('category', '==', 'ram')
      .get();

    console.log(`📊 총 ${ramListings.size}개의 RAM listings 발견\n`);

    if (ramListings.empty) {
      console.log('⚠️  삭제할 RAM listings가 없습니다.');
      process.exit(0);
    }

    // Batch 삭제
    let deletedCount = 0;
    const batchSize = 100;
    const batches = [];

    for (let i = 0; i < ramListings.docs.length; i += batchSize) {
      const batch = db.batch();
      const chunk = ramListings.docs.slice(i, i + batchSize);

      chunk.forEach(doc => {
        batch.delete(doc.ref);
        console.log(`  🗑️  삭제: ${doc.data().modelName} (${doc.id})`);
        deletedCount++;
      });

      batches.push(batch.commit());
    }

    await Promise.all(batches);

    console.log('\n==================================================');
    console.log(`✅ RAM Listings 삭제 완료: ${deletedCount}개`);
    console.log('==================================================\n');

  } catch (error) {
    console.error('❌ 오류 발생:', error.message);
    process.exit(1);
  }

  process.exit(0);
}

deleteRamListings().catch(console.error);
