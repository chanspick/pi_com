// new_datas 폴더의 이미지들을 Firebase Storage로 업로드
const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Firebase Admin 초기화
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  storageBucket: 'picom-team.firebasestorage.app'
});

const bucket = admin.storage().bucket();

// ============================================
// 설정
// ============================================
const NEW_DATAS_DIR = path.join(__dirname, '../new_datas');
const STORAGE_PATH_PREFIX = 'listings/';

// 카테고리별 폴더 구조
const CATEGORIES = ['cpu', 'gpu', 'mainboard', 'ram', 'ssd'];

// ============================================
// 유틸리티 함수
// ============================================

function isImageFile(filename) {
  const imageExtensions = ['.png', '.jpg', '.jpeg', '.webp', '.gif'];
  const ext = path.extname(filename).toLowerCase();
  return imageExtensions.includes(ext);
}

function getAllImageFiles(basePath) {
  const allImages = [];

  for (const category of CATEGORIES) {
    const imagesDir = path.join(basePath, category, 'images');

    if (!fs.existsSync(imagesDir)) {
      console.log(`⚠️  ${category}/images 폴더 없음`);
      continue;
    }

    const files = fs.readdirSync(imagesDir);
    const imageFiles = files.filter(isImageFile);

    for (const file of imageFiles) {
      allImages.push({
        category,
        filename: file,
        fullPath: path.join(imagesDir, file)
      });
    }

    console.log(`📁 ${category}: ${imageFiles.length}개 이미지`);
  }

  return allImages;
}

function getContentType(filename) {
  const ext = path.extname(filename).toLowerCase();
  const contentTypes = {
    '.png': 'image/png',
    '.jpg': 'image/jpeg',
    '.jpeg': 'image/jpeg',
    '.webp': 'image/webp',
    '.gif': 'image/gif',
  };
  return contentTypes[ext] || 'application/octet-stream';
}

async function uploadImage(imageInfo) {
  const { filename, fullPath } = imageInfo;
  const destination = `${STORAGE_PATH_PREFIX}${filename}`;

  try {
    // 이미 존재하는지 확인
    const file = bucket.file(destination);
    const [exists] = await file.exists();

    if (exists) {
      return { success: true, filename, skipped: true };
    }

    // Firebase Storage에 업로드
    await bucket.upload(fullPath, {
      destination,
      metadata: {
        contentType: getContentType(filename),
        cacheControl: 'public, max-age=31536000',
      },
    });

    // 공개 설정
    await file.makePublic();

    return { success: true, filename, skipped: false };
  } catch (error) {
    return { success: false, filename, error: error.message };
  }
}

// ============================================
// 메인 로직
// ============================================

async function main() {
  console.log('\n🚀 new_datas 이미지 업로드 시작');
  console.log('==================================================\n');
  console.log(`📁 소스: ${NEW_DATAS_DIR}`);
  console.log(`☁️  대상: ${STORAGE_PATH_PREFIX}\n`);

  // 폴더 확인
  if (!fs.existsSync(NEW_DATAS_DIR)) {
    console.error(`❌ new_datas 폴더를 찾을 수 없습니다: ${NEW_DATAS_DIR}`);
    process.exit(1);
  }

  // 모든 이미지 수집
  console.log('📂 이미지 파일 스캔 중...\n');
  const allImages = getAllImageFiles(NEW_DATAS_DIR);

  if (allImages.length === 0) {
    console.log('\n⚠️  업로드할 이미지가 없습니다.');
    process.exit(0);
  }

  console.log(`\n✅ 총 ${allImages.length}개 이미지 발견\n`);
  console.log('==================================================');
  console.log('업로드 시작...\n');

  const results = {
    success: 0,
    skipped: 0,
    failed: 0,
    errors: []
  };

  for (let i = 0; i < allImages.length; i++) {
    const imageInfo = allImages[i];
    const result = await uploadImage(imageInfo);

    const percent = ((i + 1) / allImages.length * 100).toFixed(1);

    if (result.success) {
      if (result.skipped) {
        results.skipped++;
        if (results.skipped <= 3) {
          console.log(`[${i + 1}/${allImages.length}] (${percent}%) ⏭️  ${result.filename} (이미 존재)`);
        }
      } else {
        results.success++;
        console.log(`[${i + 1}/${allImages.length}] (${percent}%) ✅ ${result.filename}`);
      }
    } else {
      results.failed++;
      console.log(`[${i + 1}/${allImages.length}] (${percent}%) ❌ ${result.filename}`);
      console.error(`   ⚠️  ${result.error}`);
      results.errors.push({ filename: result.filename, error: result.error });
    }

    // 10개마다 잠시 대기 (속도 제한 방지)
    if ((i + 1) % 10 === 0) {
      await new Promise(resolve => setTimeout(resolve, 300));
    }
  }

  // 결과 요약
  console.log('\n==================================================');
  console.log('📊 업로드 완료');
  console.log('==================================================');
  console.log(`✅ 성공: ${results.success}개`);
  console.log(`⏭️  스킵 (이미 존재): ${results.skipped}개`);
  console.log(`❌ 실패: ${results.failed}개`);

  if (results.errors.length > 0) {
    console.log('\n⚠️  실패한 파일:');
    results.errors.forEach((err, idx) => {
      console.log(`  ${idx + 1}. ${err.filename}: ${err.error}`);
    });
  }

  console.log('\n✨ 이미지 업로드 작업 완료\n');

  process.exit(results.failed > 0 ? 1 : 0);
}

main().catch((error) => {
  console.error('💥 치명적 오류:', error);
  process.exit(1);
});
