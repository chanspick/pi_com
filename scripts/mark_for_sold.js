// 기존 available listings를 markedForSold로 마킹 (순차적으로 sold 전환 준비)
// 그래프 급변동 방지를 위해 순차적으로 처리
const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// 설정: 한 번에 마킹할 개수 (그래프 급변동 방지)
const BATCH_SIZE = 50; // 한 번 실행 시 50개씩 마킹
const DELAY_MS = 200;  // 각 문서 간 200ms 딜레이

async function markForSold() {
  console.log('\n🏷️  기존 available listings를 markedForSold로 마킹');
  console.log('==================================================\n');

  // available 상태인 listings 가져오기 (markedForSold가 아직 없는 것들만)
  const availableListings = await db.collection('listings')
    .where('status', '==', 'available')
    .limit(BATCH_SIZE)
    .get();

  // 이미 마킹된 것들 제외
  const toMark = availableListings.docs.filter(doc => {
    const data = doc.data();
    return !data.markedForSold;
  });

  console.log(`📊 available listings 중 마킹 대상: ${toMark.length}개`);

  if (toMark.length === 0) {
    console.log('\n⚠️  마킹할 listings가 없습니다.');
    console.log('   - 모든 available listings가 이미 마킹되었거나');
    console.log('   - available 상태인 listings가 없습니다.\n');

    // 현재 상태 확인
    const totalAvailable = await db.collection('listings')
      .where('status', '==', 'available')
      .count()
      .get();
    const totalMarked = await db.collection('listings')
      .where('markedForSold', '==', true)
      .count()
      .get();

    console.log(`📈 현재 상태:`);
    console.log(`   - available: ${totalAvailable.data().count}개`);
    console.log(`   - markedForSold: ${totalMarked.data().count}개\n`);

    process.exit(0);
  }

  let markedCount = 0;

  for (const doc of toMark) {
    try {
      const data = doc.data();

      await doc.ref.update({
        markedForSold: true,
        markedAt: admin.firestore.FieldValue.serverTimestamp()
      });

      markedCount++;
      console.log(`  🏷️  [${markedCount}/${toMark.length}] ${data.modelName || doc.id}`);

      // 딜레이 추가
      await new Promise(resolve => setTimeout(resolve, DELAY_MS));

    } catch (error) {
      console.error(`  ❌ 오류: ${doc.id} - ${error.message}`);
    }
  }

  // 최종 상태 확인
  const remainingAvailable = await db.collection('listings')
    .where('status', '==', 'available')
    .count()
    .get();
  const totalMarkedNow = await db.collection('listings')
    .where('markedForSold', '==', true)
    .count()
    .get();

  console.log(`\n==================================================`);
  console.log(`✅ 마킹 완료: ${markedCount}개`);
  console.log(`==================================================\n`);
  console.log(`📈 현재 상태:`);
  console.log(`   - 남은 available: ${remainingAvailable.data().count}개`);
  console.log(`   - markedForSold 총계: ${totalMarkedNow.data().count}개\n`);

  if (remainingAvailable.data().count > 0) {
    console.log(`💡 아직 마킹되지 않은 available listings가 있습니다.`);
    console.log(`   이 스크립트를 다시 실행하세요.\n`);
  } else {
    console.log(`💡 모든 available listings가 마킹되었습니다.`);
    console.log(`   다음 단계: node convert_marked_to_sold.js\n`);
  }

  process.exit(0);
}

markForSold().catch(console.error);
