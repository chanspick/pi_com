// 이미지 파일을 Firebase Storage로 업로드하는 스크립트
const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Firebase Admin 초기화
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  storageBucket: 'picom-team.firebasestorage.app'  // Firebase Storage 버킷
});

const bucket = admin.storage().bucket();

// ============================================
// 설정
// ============================================
const IMAGES_DIR = path.join(__dirname, '../datas/images');
const STORAGE_PATH_PREFIX = 'listings/';  // Firebase Storage 경로 prefix

// ============================================
// 유틸리티 함수
// ============================================

/**
 * 이미지 파일 여부 확인
 */
function isImageFile(filename) {
  const imageExtensions = ['.png', '.jpg', '.jpeg', '.webp', '.gif'];
  const ext = path.extname(filename).toLowerCase();
  return imageExtensions.includes(ext);
}

/**
 * 재귀적으로 모든 이미지 파일 찾기
 */
function getAllImageFiles(dirPath, arrayOfFiles = []) {
  const files = fs.readdirSync(dirPath);

  files.forEach((file) => {
    const fullPath = path.join(dirPath, file);

    if (fs.statSync(fullPath).isDirectory()) {
      // 하위 디렉토리 재귀 탐색
      arrayOfFiles = getAllImageFiles(fullPath, arrayOfFiles);
    } else if (isImageFile(file)) {
      // 이미지 파일 추가
      arrayOfFiles.push(fullPath);
    }
  });

  return arrayOfFiles;
}

/**
 * 단일 이미지 업로드
 */
async function uploadImage(localPath) {
  const filename = path.basename(localPath);
  const destination = `${STORAGE_PATH_PREFIX}${filename}`;

  try {
    // Firebase Storage에 업로드
    await bucket.upload(localPath, {
      destination,
      metadata: {
        contentType: getContentType(filename),
        cacheControl: 'public, max-age=31536000', // 1년 캐싱
      },
    });

    // 공개 URL 생성
    const file = bucket.file(destination);
    await file.makePublic();

    const publicUrl = `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/${encodeURIComponent(destination)}?alt=media`;

    return { success: true, filename, publicUrl };
  } catch (error) {
    return { success: false, filename, error: error.message };
  }
}

/**
 * Content-Type 결정
 */
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

/**
 * 진행 상황 표시
 */
function printProgress(current, total, result) {
  const percent = ((current / total) * 100).toFixed(1);
  const status = result.success ? '✅' : '❌';
  console.log(`[${current}/${total}] (${percent}%) ${status} ${result.filename}`);

  if (!result.success) {
    console.error(`   ⚠️  에러: ${result.error}`);
  }
}

// ============================================
// 메인 업로드 로직
// ============================================

/**
 * 모든 이미지 업로드
 */
async function uploadAllImages() {
  console.log('\n🚀 이미지 업로드 시작');
  console.log('='.repeat(60));
  console.log(`📁 소스 디렉토리: ${IMAGES_DIR}`);
  console.log(`☁️  Storage 경로: ${STORAGE_PATH_PREFIX}`);
  console.log('='.repeat(60));

  // 이미지 폴더 존재 확인
  if (!fs.existsSync(IMAGES_DIR)) {
    console.error(`\n❌ 오류: 이미지 폴더를 찾을 수 없습니다: ${IMAGES_DIR}`);
    process.exit(1);
  }

  // 모든 이미지 파일 찾기
  console.log('\n📂 이미지 파일 스캔 중...');
  const imageFiles = getAllImageFiles(IMAGES_DIR);

  if (imageFiles.length === 0) {
    console.log('\n⚠️  업로드할 이미지 파일이 없습니다.');
    process.exit(0);
  }

  console.log(`✅ 총 ${imageFiles.length}개 이미지 파일 발견\n`);

  // 업로드 시작
  const results = {
    success: 0,
    failed: 0,
    errors: [],
  };

  for (let i = 0; i < imageFiles.length; i++) {
    const filePath = imageFiles[i];
    const result = await uploadImage(filePath);

    printProgress(i + 1, imageFiles.length, result);

    if (result.success) {
      results.success++;
    } else {
      results.failed++;
      results.errors.push({ filename: result.filename, error: result.error });
    }

    // 속도 제한 방지 (10개마다 잠시 대기)
    if ((i + 1) % 10 === 0) {
      await new Promise(resolve => setTimeout(resolve, 500));
    }
  }

  // 결과 요약
  console.log('\n' + '='.repeat(60));
  console.log('📊 업로드 완료');
  console.log('='.repeat(60));
  console.log(`✅ 성공: ${results.success}개`);
  console.log(`❌ 실패: ${results.failed}개`);

  if (results.errors.length > 0) {
    console.log('\n⚠️  실패한 파일 목록:');
    results.errors.forEach((err, idx) => {
      console.log(`  ${idx + 1}. ${err.filename}`);
      console.log(`     → ${err.error}`);
    });
  }

  console.log('\n✨ 이미지 업로드 작업 완료\n');

  return results;
}

/**
 * 메인 실행 함수
 */
async function main() {
  try {
    const results = await uploadAllImages();

    if (results.failed > 0) {
      console.log('\n⚠️  일부 파일 업로드 실패. 로그를 확인하세요.');
      process.exit(1);
    } else {
      console.log('\n🎉 모든 이미지가 성공적으로 업로드되었습니다!');
      process.exit(0);
    }
  } catch (error) {
    console.error('\n💥 치명적 오류 발생:', error);
    process.exit(1);
  }
}

// 실행
main();
