// Firestore 컬렉션 삭제 스크립트
const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function deleteCollection(collectionName, batchSize = 100) {
  const collectionRef = db.collection(collectionName);
  const query = collectionRef.limit(batchSize);

  return new Promise((resolve, reject) => {
    deleteQueryBatch(db, query, resolve, reject, collectionName);
  });
}

async function deleteQueryBatch(db, query, resolve, reject, collectionName) {
  try {
    const snapshot = await query.get();

    if (snapshot.size === 0) {
      console.log(`✅ ${collectionName} 컬렉션 삭제 완료\n`);
      resolve();
      return;
    }

    const batch = db.batch();
    snapshot.docs.forEach((doc) => {
      batch.delete(doc.ref);
    });

    await batch.commit();
    console.log(`   🗑️  ${collectionName}: ${snapshot.size}개 문서 삭제됨`);

    // 다음 배치 삭제
    process.nextTick(() => {
      deleteQueryBatch(db, query, resolve, reject, collectionName);
    });
  } catch (error) {
    reject(error);
  }
}

async function main() {
  console.log('\n🗑️  Firestore 컬렉션 삭제 시작');
  console.log('==================================================\n');

  const collections = ['listings', 'base_parts', 'priceHistory'];

  for (const collectionName of collections) {
    console.log(`📂 ${collectionName} 삭제 중...`);
    try {
      await deleteCollection(collectionName);
    } catch (error) {
      console.error(`❌ ${collectionName} 삭제 실패:`, error.message);
    }
  }

  console.log('==================================================');
  console.log('✅ 모든 컬렉션 삭제 완료!\n');
  process.exit(0);
}

main().catch(console.error);
