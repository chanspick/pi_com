// markedForSold 플래그가 있는 listings를 sold로 전환
const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function convertMarkedToSold() {
  console.log('\n🔄 마킹된 listings를 sold로 전환 중...');
  console.log('==================================================\n');

  // markedForSold가 true인 모든 listings 가져오기
  const markedListings = await db.collection('listings')
    .where('markedForSold', '==', true)
    .get();

  console.log(`총 ${markedListings.size}개의 마킹된 listings 발견\n`);

  if (markedListings.empty) {
    console.log('⚠️  마킹된 listings가 없습니다.\n');
    process.exit(0);
  }

  const delay = 100; // 100ms 간격
  let convertedCount = 0;

  for (const doc of markedListings.docs) {
    try {
      // sold로 변경하고 마킹 플래그 제거
      await doc.ref.update({
        status: 'sold',
        markedForSold: admin.firestore.FieldValue.delete(),
        markedAt: admin.firestore.FieldValue.delete(),
        convertedToSoldAt: admin.firestore.FieldValue.serverTimestamp()
      });

      convertedCount++;

      if (convertedCount % 50 === 0) {
        console.log(`  🔄 ${convertedCount}/${markedListings.size} 전환 완료...`);
      }

      // 순차 처리를 위한 딜레이
      await new Promise(resolve => setTimeout(resolve, delay));

    } catch (error) {
      console.error(`  ❌ 오류: ${doc.id} - ${error.message}`);
    }
  }

  console.log(`\n==================================================`);
  console.log(`✅ 전환 완료: ${convertedCount}개`);
  console.log(`==================================================\n`);
  console.log('📝 변경사항:');
  console.log('  - status: available → sold로 변경');
  console.log('  - markedForSold, markedAt 플래그 제거');
  console.log('  - convertedToSoldAt: 전환 시간 기록\n');

  process.exit(0);
}

convertMarkedToSold().catch(console.error);
