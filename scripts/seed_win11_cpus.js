// Win11 지원 CPU BasePart 시드 데이터 생성 스크립트
// AMD Ryzen 3세대+ (3000~), Intel 9세대+ (9xxx~)
const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// Win11 지원 CPU 목록 (매물 없어도 검색/선택 가능하게)
const WIN11_CPUS = [
  // ============================================
  // AMD Ryzen 3000 시리즈 (Zen 2) - AM4
  // ============================================
  { brand: 'AMD', series: 'Ryzen 3', model: '3100', socket: 'AM4' },
  { brand: 'AMD', series: 'Ryzen 3', model: '3200G', socket: 'AM4' },
  { brand: 'AMD', series: 'Ryzen 3', model: '3300X', socket: 'AM4' },
  { brand: 'AMD', series: 'Ryzen 5', model: '3400G', socket: 'AM4' },
  { brand: 'AMD', series: 'Ryzen 5', model: '3500', socket: 'AM4' },
  { brand: 'AMD', series: 'Ryzen 5', model: '3500X', socket: 'AM4' },
  { brand: 'AMD', series: 'Ryzen 5', model: '3600', socket: 'AM4' },
  { brand: 'AMD', series: 'Ryzen 5', model: '3600X', socket: 'AM4' },
  { brand: 'AMD', series: 'Ryzen 5', model: '3600XT', socket: 'AM4' },
  { brand: 'AMD', series: 'Ryzen 7', model: '3700X', socket: 'AM4' },
  { brand: 'AMD', series: 'Ryzen 7', model: '3800X', socket: 'AM4' },
  { brand: 'AMD', series: 'Ryzen 7', model: '3800XT', socket: 'AM4' },
  { brand: 'AMD', series: 'Ryzen 9', model: '3900X', socket: 'AM4' },
  { brand: 'AMD', series: 'Ryzen 9', model: '3900XT', socket: 'AM4' },
  { brand: 'AMD', series: 'Ryzen 9', model: '3950X', socket: 'AM4' },

  // ============================================
  // AMD Ryzen 5000 시리즈 (Zen 3) - AM4
  // ============================================
  { brand: 'AMD', series: 'Ryzen 3', model: '5300G', socket: 'AM4' },
  { brand: 'AMD', series: 'Ryzen 5', model: '5500', socket: 'AM4' },
  { brand: 'AMD', series: 'Ryzen 5', model: '5600', socket: 'AM4' },
  { brand: 'AMD', series: 'Ryzen 5', model: '5600G', socket: 'AM4' },
  { brand: 'AMD', series: 'Ryzen 5', model: '5600X', socket: 'AM4' },
  { brand: 'AMD', series: 'Ryzen 5', model: '5600X3D', socket: 'AM4' },
  { brand: 'AMD', series: 'Ryzen 7', model: '5700', socket: 'AM4' },
  { brand: 'AMD', series: 'Ryzen 7', model: '5700G', socket: 'AM4' },
  { brand: 'AMD', series: 'Ryzen 7', model: '5700X', socket: 'AM4' },
  { brand: 'AMD', series: 'Ryzen 7', model: '5700X3D', socket: 'AM4' },
  { brand: 'AMD', series: 'Ryzen 7', model: '5800X', socket: 'AM4' },
  { brand: 'AMD', series: 'Ryzen 7', model: '5800X3D', socket: 'AM4' },
  { brand: 'AMD', series: 'Ryzen 9', model: '5900X', socket: 'AM4' },
  { brand: 'AMD', series: 'Ryzen 9', model: '5950X', socket: 'AM4' },

  // ============================================
  // AMD Ryzen 7000 시리즈 (Zen 4) - AM5
  // ============================================
  { brand: 'AMD', series: 'Ryzen 5', model: '7500F', socket: 'AM5' },
  { brand: 'AMD', series: 'Ryzen 5', model: '7600', socket: 'AM5' },
  { brand: 'AMD', series: 'Ryzen 5', model: '7600X', socket: 'AM5' },
  { brand: 'AMD', series: 'Ryzen 7', model: '7700', socket: 'AM5' },
  { brand: 'AMD', series: 'Ryzen 7', model: '7700X', socket: 'AM5' },
  { brand: 'AMD', series: 'Ryzen 7', model: '7800X3D', socket: 'AM5' },
  { brand: 'AMD', series: 'Ryzen 9', model: '7900', socket: 'AM5' },
  { brand: 'AMD', series: 'Ryzen 9', model: '7900X', socket: 'AM5' },
  { brand: 'AMD', series: 'Ryzen 9', model: '7900X3D', socket: 'AM5' },
  { brand: 'AMD', series: 'Ryzen 9', model: '7950X', socket: 'AM5' },
  { brand: 'AMD', series: 'Ryzen 9', model: '7950X3D', socket: 'AM5' },

  // ============================================
  // AMD Ryzen 8000G 시리즈 (Zen 4 APU) - AM5
  // ============================================
  { brand: 'AMD', series: 'Ryzen 5', model: '8500G', socket: 'AM5' },
  { brand: 'AMD', series: 'Ryzen 5', model: '8600G', socket: 'AM5' },
  { brand: 'AMD', series: 'Ryzen 7', model: '8700G', socket: 'AM5' },

  // ============================================
  // AMD Ryzen 9000 시리즈 (Zen 5) - AM5
  // ============================================
  { brand: 'AMD', series: 'Ryzen 5', model: '9600X', socket: 'AM5' },
  { brand: 'AMD', series: 'Ryzen 7', model: '9700X', socket: 'AM5' },
  { brand: 'AMD', series: 'Ryzen 7', model: '9800X3D', socket: 'AM5' },
  { brand: 'AMD', series: 'Ryzen 9', model: '9900X', socket: 'AM5' },
  { brand: 'AMD', series: 'Ryzen 9', model: '9950X', socket: 'AM5' },
  { brand: 'AMD', series: 'Ryzen 9', model: '9950X3D', socket: 'AM5' },

  // ============================================
  // Intel 9세대 (Coffee Lake Refresh) - LGA1151
  // ============================================
  { brand: 'Intel', series: 'Core i3', model: '9100', socket: 'LGA1151' },
  { brand: 'Intel', series: 'Core i3', model: '9100F', socket: 'LGA1151' },
  { brand: 'Intel', series: 'Core i5', model: '9400', socket: 'LGA1151' },
  { brand: 'Intel', series: 'Core i5', model: '9400F', socket: 'LGA1151' },
  { brand: 'Intel', series: 'Core i5', model: '9500', socket: 'LGA1151' },
  { brand: 'Intel', series: 'Core i5', model: '9600', socket: 'LGA1151' },
  { brand: 'Intel', series: 'Core i5', model: '9600K', socket: 'LGA1151' },
  { brand: 'Intel', series: 'Core i5', model: '9600KF', socket: 'LGA1151' },
  { brand: 'Intel', series: 'Core i7', model: '9700', socket: 'LGA1151' },
  { brand: 'Intel', series: 'Core i7', model: '9700F', socket: 'LGA1151' },
  { brand: 'Intel', series: 'Core i7', model: '9700K', socket: 'LGA1151' },
  { brand: 'Intel', series: 'Core i7', model: '9700KF', socket: 'LGA1151' },
  { brand: 'Intel', series: 'Core i9', model: '9900', socket: 'LGA1151' },
  { brand: 'Intel', series: 'Core i9', model: '9900K', socket: 'LGA1151' },
  { brand: 'Intel', series: 'Core i9', model: '9900KF', socket: 'LGA1151' },
  { brand: 'Intel', series: 'Core i9', model: '9900KS', socket: 'LGA1151' },

  // ============================================
  // Intel 10세대 (Comet Lake) - LGA1200
  // ============================================
  { brand: 'Intel', series: 'Core i3', model: '10100', socket: 'LGA1200' },
  { brand: 'Intel', series: 'Core i3', model: '10100F', socket: 'LGA1200' },
  { brand: 'Intel', series: 'Core i3', model: '10105', socket: 'LGA1200' },
  { brand: 'Intel', series: 'Core i3', model: '10105F', socket: 'LGA1200' },
  { brand: 'Intel', series: 'Core i5', model: '10400', socket: 'LGA1200' },
  { brand: 'Intel', series: 'Core i5', model: '10400F', socket: 'LGA1200' },
  { brand: 'Intel', series: 'Core i5', model: '10500', socket: 'LGA1200' },
  { brand: 'Intel', series: 'Core i5', model: '10600', socket: 'LGA1200' },
  { brand: 'Intel', series: 'Core i5', model: '10600K', socket: 'LGA1200' },
  { brand: 'Intel', series: 'Core i5', model: '10600KF', socket: 'LGA1200' },
  { brand: 'Intel', series: 'Core i7', model: '10700', socket: 'LGA1200' },
  { brand: 'Intel', series: 'Core i7', model: '10700F', socket: 'LGA1200' },
  { brand: 'Intel', series: 'Core i7', model: '10700K', socket: 'LGA1200' },
  { brand: 'Intel', series: 'Core i7', model: '10700KF', socket: 'LGA1200' },
  { brand: 'Intel', series: 'Core i9', model: '10850K', socket: 'LGA1200' },
  { brand: 'Intel', series: 'Core i9', model: '10900', socket: 'LGA1200' },
  { brand: 'Intel', series: 'Core i9', model: '10900F', socket: 'LGA1200' },
  { brand: 'Intel', series: 'Core i9', model: '10900K', socket: 'LGA1200' },
  { brand: 'Intel', series: 'Core i9', model: '10900KF', socket: 'LGA1200' },

  // ============================================
  // Intel 11세대 (Rocket Lake) - LGA1200
  // ============================================
  { brand: 'Intel', series: 'Core i5', model: '11400', socket: 'LGA1200' },
  { brand: 'Intel', series: 'Core i5', model: '11400F', socket: 'LGA1200' },
  { brand: 'Intel', series: 'Core i5', model: '11500', socket: 'LGA1200' },
  { brand: 'Intel', series: 'Core i5', model: '11600', socket: 'LGA1200' },
  { brand: 'Intel', series: 'Core i5', model: '11600K', socket: 'LGA1200' },
  { brand: 'Intel', series: 'Core i5', model: '11600KF', socket: 'LGA1200' },
  { brand: 'Intel', series: 'Core i7', model: '11700', socket: 'LGA1200' },
  { brand: 'Intel', series: 'Core i7', model: '11700F', socket: 'LGA1200' },
  { brand: 'Intel', series: 'Core i7', model: '11700K', socket: 'LGA1200' },
  { brand: 'Intel', series: 'Core i7', model: '11700KF', socket: 'LGA1200' },
  { brand: 'Intel', series: 'Core i9', model: '11900', socket: 'LGA1200' },
  { brand: 'Intel', series: 'Core i9', model: '11900F', socket: 'LGA1200' },
  { brand: 'Intel', series: 'Core i9', model: '11900K', socket: 'LGA1200' },
  { brand: 'Intel', series: 'Core i9', model: '11900KF', socket: 'LGA1200' },

  // ============================================
  // Intel 12세대 (Alder Lake) - LGA1700
  // ============================================
  { brand: 'Intel', series: 'Core i3', model: '12100', socket: 'LGA1700' },
  { brand: 'Intel', series: 'Core i3', model: '12100F', socket: 'LGA1700' },
  { brand: 'Intel', series: 'Core i5', model: '12400', socket: 'LGA1700' },
  { brand: 'Intel', series: 'Core i5', model: '12400F', socket: 'LGA1700' },
  { brand: 'Intel', series: 'Core i5', model: '12500', socket: 'LGA1700' },
  { brand: 'Intel', series: 'Core i5', model: '12600', socket: 'LGA1700' },
  { brand: 'Intel', series: 'Core i5', model: '12600K', socket: 'LGA1700' },
  { brand: 'Intel', series: 'Core i5', model: '12600KF', socket: 'LGA1700' },
  { brand: 'Intel', series: 'Core i7', model: '12700', socket: 'LGA1700' },
  { brand: 'Intel', series: 'Core i7', model: '12700F', socket: 'LGA1700' },
  { brand: 'Intel', series: 'Core i7', model: '12700K', socket: 'LGA1700' },
  { brand: 'Intel', series: 'Core i7', model: '12700KF', socket: 'LGA1700' },
  { brand: 'Intel', series: 'Core i9', model: '12900', socket: 'LGA1700' },
  { brand: 'Intel', series: 'Core i9', model: '12900F', socket: 'LGA1700' },
  { brand: 'Intel', series: 'Core i9', model: '12900K', socket: 'LGA1700' },
  { brand: 'Intel', series: 'Core i9', model: '12900KF', socket: 'LGA1700' },
  { brand: 'Intel', series: 'Core i9', model: '12900KS', socket: 'LGA1700' },

  // ============================================
  // Intel 13세대 (Raptor Lake) - LGA1700
  // ============================================
  { brand: 'Intel', series: 'Core i3', model: '13100', socket: 'LGA1700' },
  { brand: 'Intel', series: 'Core i3', model: '13100F', socket: 'LGA1700' },
  { brand: 'Intel', series: 'Core i5', model: '13400', socket: 'LGA1700' },
  { brand: 'Intel', series: 'Core i5', model: '13400F', socket: 'LGA1700' },
  { brand: 'Intel', series: 'Core i5', model: '13500', socket: 'LGA1700' },
  { brand: 'Intel', series: 'Core i5', model: '13600K', socket: 'LGA1700' },
  { brand: 'Intel', series: 'Core i5', model: '13600KF', socket: 'LGA1700' },
  { brand: 'Intel', series: 'Core i7', model: '13700', socket: 'LGA1700' },
  { brand: 'Intel', series: 'Core i7', model: '13700F', socket: 'LGA1700' },
  { brand: 'Intel', series: 'Core i7', model: '13700K', socket: 'LGA1700' },
  { brand: 'Intel', series: 'Core i7', model: '13700KF', socket: 'LGA1700' },
  { brand: 'Intel', series: 'Core i9', model: '13900', socket: 'LGA1700' },
  { brand: 'Intel', series: 'Core i9', model: '13900F', socket: 'LGA1700' },
  { brand: 'Intel', series: 'Core i9', model: '13900K', socket: 'LGA1700' },
  { brand: 'Intel', series: 'Core i9', model: '13900KF', socket: 'LGA1700' },
  { brand: 'Intel', series: 'Core i9', model: '13900KS', socket: 'LGA1700' },

  // ============================================
  // Intel 14세대 (Raptor Lake Refresh) - LGA1700
  // ============================================
  { brand: 'Intel', series: 'Core i5', model: '14400', socket: 'LGA1700' },
  { brand: 'Intel', series: 'Core i5', model: '14400F', socket: 'LGA1700' },
  { brand: 'Intel', series: 'Core i5', model: '14500', socket: 'LGA1700' },
  { brand: 'Intel', series: 'Core i5', model: '14600K', socket: 'LGA1700' },
  { brand: 'Intel', series: 'Core i5', model: '14600KF', socket: 'LGA1700' },
  { brand: 'Intel', series: 'Core i7', model: '14700', socket: 'LGA1700' },
  { brand: 'Intel', series: 'Core i7', model: '14700F', socket: 'LGA1700' },
  { brand: 'Intel', series: 'Core i7', model: '14700K', socket: 'LGA1700' },
  { brand: 'Intel', series: 'Core i7', model: '14700KF', socket: 'LGA1700' },
  { brand: 'Intel', series: 'Core i9', model: '14900', socket: 'LGA1700' },
  { brand: 'Intel', series: 'Core i9', model: '14900F', socket: 'LGA1700' },
  { brand: 'Intel', series: 'Core i9', model: '14900K', socket: 'LGA1700' },
  { brand: 'Intel', series: 'Core i9', model: '14900KF', socket: 'LGA1700' },
  { brand: 'Intel', series: 'Core i9', model: '14900KS', socket: 'LGA1700' },
];

// BasePart 문서 생성
function createBasePartDoc(cpu) {
  const modelName = `${cpu.brand} ${cpu.series} ${cpu.model}`;
  const basePartId = `${cpu.brand}_${cpu.series.replace(/ /g, '_')}_${cpu.model}`;

  return {
    basePartId,
    modelName,
    category: 'cpu',
    socket: cpu.socket,
    brand: cpu.brand,
    // 시드 데이터이므로 가격/매물 정보 없음
    lowestPrice: 0,
    averagePrice: 0,
    listingCount: 0,
    // 메타 정보
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    isSeeded: true,  // 시드 데이터 표시
    win11Compatible: true,
  };
}

async function seedWin11CPUs() {
  console.log('\n🖥️  Win11 지원 CPU BasePart 시드 데이터 생성');
  console.log('==================================================\n');

  // 기존 BasePart 확인
  const existingSnapshot = await db.collection('base_parts')
    .where('category', '==', 'cpu')
    .get();

  const existingIds = new Set(existingSnapshot.docs.map(doc => doc.id));
  console.log(`📊 기존 CPU BasePart: ${existingIds.size}개\n`);

  let createdCount = 0;
  let skippedCount = 0;

  for (const cpu of WIN11_CPUS) {
    const doc = createBasePartDoc(cpu);

    if (existingIds.has(doc.basePartId)) {
      skippedCount++;
      continue;
    }

    try {
      await db.collection('base_parts').doc(doc.basePartId).set(doc);
      createdCount++;
      console.log(`  ✅ ${doc.modelName} (${doc.socket})`);
    } catch (error) {
      console.error(`  ❌ ${doc.modelName}: ${error.message}`);
    }
  }

  console.log(`\n==================================================`);
  console.log(`✅ 생성 완료: ${createdCount}개`);
  console.log(`⏭️  스킵 (이미 존재): ${skippedCount}개`);
  console.log(`==================================================\n`);

  process.exit(0);
}

seedWin11CPUs().catch(console.error);
