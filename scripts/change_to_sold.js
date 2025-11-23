// available → sold로 변경하는 스크립트
const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function changeToSold() {
  console.log('\n🔄 available → sold로 순차 변경');
  console.log('==================================================\n');

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

  console.log(`\n✅ 완료: ${changedCount}개 sold로 변경\n`);
  process.exit(0);
}

changeToSold().catch(console.error);
