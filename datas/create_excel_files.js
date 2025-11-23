const ExcelJS = require('exceljs');
const path = require('path');

// 공통 헤더
const COMMON_HEADERS = [
  '판매가', '다나와 검색', '신제품 판매가', '좋아요 수', '채팅 수', '조회수',
  '미개봉 여부', '소유권 이전횟수', 'AS기간', '사용빈도', '구매일',
  '사진 개수', '파일명(복사용)', '사진1', '사진2', '사진3', '사진4', '사진5'
];

const SHEET_NAMES = ['거래완료', '예약중', '판매중'];

// CPU 엑셀 생성
async function createCPUExcel() {
  const workbook = new ExcelJS.Workbook();

  // ⭐ 소켓 컬럼 추가
  const headers = ['판매글 게시일자', '날짜 선택', '브랜드', '시리즈', '모델 번호', '접미사', ...COMMON_HEADERS, '소켓'];

  SHEET_NAMES.forEach(sheetName => {
    const worksheet = workbook.addWorksheet(sheetName);
    worksheet.addRow(headers);

    // 헤더 스타일 설정
    const headerRow = worksheet.getRow(1);
    headerRow.font = { bold: true, color: { argb: 'FFFFFFFF' } };
    headerRow.fill = {
      type: 'pattern',
      pattern: 'solid',
      fgColor: { argb: 'FF808080' }
    };
    headerRow.alignment = { horizontal: 'center', vertical: 'middle' };

    // 열 너비 설정
    worksheet.columns = headers.map((header, idx) => {
      const widths = {
        '판매글 게시일자': 20,
        '날짜 선택': 15,
        '브랜드': 20,
        '시리즈': 15,
        '모델 번호': 15,
        '접미사': 15,
        '판매가': 15,
        '다나와 검색': 18,
        '신제품 판매가': 15,
        '좋아요 수': 12,
        '채팅 수': 12,
        '조회수': 12,
        '미개봉 여부': 12,
        '소유권 이전횟수': 15,
        'AS기간': 15,
        '사용빈도': 20,
        '구매일': 20,
        '사진 개수': 12,
        '파일명(복사용)': 60,
        '사진1': 65,
        '사진2': 65,
        '사진3': 65,
        '사진4': 65,
        '사진5': 65,
        '소켓': 18
      };
      return { width: widths[header] || header.length + 5 };
    });
  });

  await workbook.xlsx.writeFile(path.join(__dirname, 'CPU.xlsx'));
  console.log('✅ CPU.xlsx 생성 완료! (소켓 컬럼 포함)');
}

// GPU 엑셀 생성
async function createGPUExcel() {
  const workbook = new ExcelJS.Workbook();

  // ⭐ TDP (W) 컬럼 추가
  const headers = ['판매글 게시일자', '날짜 선택', '브랜드', '제조사', '시리즈', '모델 번호', '접미사', '세부 모델명', '메모리 용량', ...COMMON_HEADERS, 'TDP (W)'];

  SHEET_NAMES.forEach(sheetName => {
    const worksheet = workbook.addWorksheet(sheetName);
    worksheet.addRow(headers);

    // 헤더 스타일 설정
    const headerRow = worksheet.getRow(1);
    headerRow.font = { bold: true, color: { argb: 'FFFFFFFF' } };
    headerRow.fill = {
      type: 'pattern',
      pattern: 'solid',
      fgColor: { argb: 'FF808080' }
    };
    headerRow.alignment = { horizontal: 'center', vertical: 'middle' };

    // 열 너비 설정
    worksheet.columns = headers.map((header, idx) => {
      const widths = {
        '판매글 게시일자': 20,
        '날짜 선택': 15,
        '브랜드': 20,
        '제조사': 25,
        '시리즈': 22,
        '모델 번호': 15,
        '접미사': 15,
        '세부 모델명': 25,
        '메모리 용량': 15,
        '판매가': 15,
        '다나와 검색': 18,
        '신제품 판매가': 15,
        '좋아요 수': 12,
        '채팅 수': 12,
        '조회수': 12,
        '미개봉 여부': 12,
        '소유권 이전횟수': 15,
        'AS기간': 15,
        '사용빈도': 20,
        '구매일': 20,
        '사진 개수': 12,
        '파일명(복사용)': 60,
        '사진1': 65,
        '사진2': 65,
        '사진3': 65,
        '사진4': 65,
        '사진5': 65,
        'TDP (W)': 12
      };
      return { width: widths[header] || header.length + 5 };
    });
  });

  await workbook.xlsx.writeFile(path.join(__dirname, 'GPU.xlsx'));
  console.log('✅ GPU.xlsx 생성 완료! (TDP 컬럼 포함)');
}

// Mainboard 엑셀 생성
async function createMainboardExcel() {
  const workbook = new ExcelJS.Workbook();

  // ⭐ 소켓, 메모리 타입, 폼팩터 컬럼 추가
  const headers = ['판매글 게시일자', '날짜 선택', '제조사', '시리즈', '칩셋', '모델명', '세부특징1', '세부특징2', ...COMMON_HEADERS, '소켓', '메모리 타입', '폼팩터'];

  SHEET_NAMES.forEach(sheetName => {
    const worksheet = workbook.addWorksheet(sheetName);
    worksheet.addRow(headers);

    // 헤더 스타일 설정
    const headerRow = worksheet.getRow(1);
    headerRow.font = { bold: true, color: { argb: 'FFFFFFFF' } };
    headerRow.fill = {
      type: 'pattern',
      pattern: 'solid',
      fgColor: { argb: 'FF808080' }
    };
    headerRow.alignment = { horizontal: 'center', vertical: 'middle' };

    // 열 너비 설정
    worksheet.columns = headers.map((header, idx) => {
      const widths = {
        '판매글 게시일자': 20,
        '날짜 선택': 15,
        '제조사': 25,
        '시리즈': 22,
        '칩셋': 15,
        '모델명': 22,
        '세부특징1': 20,
        '세부특징2': 20,
        '판매가': 15,
        '다나와 검색': 18,
        '신제품 판매가': 15,
        '좋아요 수': 12,
        '채팅 수': 12,
        '조회수': 12,
        '미개봉 여부': 12,
        '소유권 이전횟수': 15,
        'AS기간': 15,
        '사용빈도': 20,
        '구매일': 20,
        '사진 개수': 12,
        '파일명(복사용)': 60,
        '사진1': 65,
        '사진2': 65,
        '사진3': 65,
        '사진4': 65,
        '사진5': 65,
        '소켓': 18,
        '메모리 타입': 15,
        '폼팩터': 15
      };
      return { width: widths[header] || header.length + 5 };
    });
  });

  await workbook.xlsx.writeFile(path.join(__dirname, 'Mainboard.xlsx'));
  console.log('✅ Mainboard.xlsx 생성 완료! (소켓, 메모리 타입, 폼팩터 컬럼 포함)');
}

// RAM 엑셀 생성
async function createRAMExcel() {
  const workbook = new ExcelJS.Workbook();

  // RAM 전용 헤더 (판매 개수, 판매가(개당) 포함)
  const headers = [
    '판매글 게시일자', '날짜 선택', '제조사', '메모리 규격', '시리즈/모델명', '클럭 (MHz)', '용량 (GB)',
    '판매 개수', '판매가(개당)', '다나와 검색', '신제품 판매가', '좋아요 수', '채팅 수', '조회수',
    '미개봉 여부', '소유권 이전횟수', 'AS기간', '사용빈도', '구매일',
    '사진 개수', '파일명(복사용)', '사진1', '사진2', '사진3', '사진4', '사진5'
  ];

  SHEET_NAMES.forEach(sheetName => {
    const worksheet = workbook.addWorksheet(sheetName);
    worksheet.addRow(headers);

    // 헤더 스타일 설정
    const headerRow = worksheet.getRow(1);
    headerRow.font = { bold: true, color: { argb: 'FFFFFFFF' } };
    headerRow.fill = {
      type: 'pattern',
      pattern: 'solid',
      fgColor: { argb: 'FF808080' }
    };
    headerRow.alignment = { horizontal: 'center', vertical: 'middle' };

    // 열 너비 설정
    worksheet.columns = headers.map((header, idx) => {
      const widths = {
        '판매글 게시일자': 20,
        '날짜 선택': 15,
        '제조사': 25,
        '메모리 규격': 15,
        '시리즈/모델명': 22,
        '클럭 (MHz)': 15,
        '용량 (GB)': 15,
        '판매 개수': 12,
        '판매가(개당)': 15,
        '다나와 검색': 18,
        '신제품 판매가': 15,
        '좋아요 수': 12,
        '채팅 수': 12,
        '조회수': 12,
        '미개봉 여부': 12,
        '소유권 이전횟수': 15,
        'AS기간': 15,
        '사용빈도': 20,
        '구매일': 20,
        '사진 개수': 12,
        '파일명(복사용)': 60,
        '사진1': 65,
        '사진2': 65,
        '사진3': 65,
        '사진4': 65,
        '사진5': 65
      };
      return { width: widths[header] || header.length + 5 };
    });
  });

  await workbook.xlsx.writeFile(path.join(__dirname, 'RAM.xlsx'));
  console.log('✅ RAM.xlsx 생성 완료! (메모리 규격 컬럼 포함)');
}

// SSD 엑셀 생성
async function createSSDExcel() {
  const workbook = new ExcelJS.Workbook();

  // ⭐ 인터페이스 컬럼 추가
  const headers = [
    '판매글 게시일자', '날짜 선택', '제조사', '시리즈/모델명', '폼팩터', '용량',
    ...COMMON_HEADERS, '인터페이스'
  ];

  SHEET_NAMES.forEach(sheetName => {
    const worksheet = workbook.addWorksheet(sheetName);
    worksheet.addRow(headers);

    // 헤더 스타일 설정
    const headerRow = worksheet.getRow(1);
    headerRow.font = { bold: true, color: { argb: 'FFFFFFFF' } };
    headerRow.fill = {
      type: 'pattern',
      pattern: 'solid',
      fgColor: { argb: 'FF808080' }
    };
    headerRow.alignment = { horizontal: 'center', vertical: 'middle' };

    // 열 너비 설정
    worksheet.columns = headers.map((header, idx) => {
      const widths = {
        '판매글 게시일자': 20,
        '날짜 선택': 15,
        '제조사': 25,
        '시리즈/모델명': 22,
        '폼팩터': 20,
        '용량': 15,
        '판매가': 15,
        '다나와 검색': 18,
        '신제품 판매가': 15,
        '좋아요 수': 12,
        '채팅 수': 12,
        '조회수': 12,
        '미개봉 여부': 12,
        '소유권 이전횟수': 15,
        'AS기간': 15,
        '사용빈도': 20,
        '구매일': 20,
        '사진 개수': 12,
        '파일명(복사용)': 60,
        '사진1': 65,
        '사진2': 65,
        '사진3': 65,
        '사진4': 65,
        '사진5': 65,
        '인터페이스': 20
      };
      return { width: widths[header] || header.length + 5 };
    });
  });

  await workbook.xlsx.writeFile(path.join(__dirname, 'SSD.xlsx'));
  console.log('✅ SSD.xlsx 생성 완료! (인터페이스 컬럼 포함)');
}

// 메인 실행
async function main() {
  console.log('🚀 엑셀 파일 생성 시작...\n');

  try {
    await createCPUExcel();
    await createGPUExcel();
    await createMainboardExcel();
    await createRAMExcel();
    await createSSDExcel();

    console.log('\n🎉 모든 엑셀 파일 생성 완료!');
    console.log('📍 생성 위치: datas 폴더');
    console.log('\n✅ 추가된 컬럼:');
    console.log('   - CPU.xlsx: 소켓 (25개 컬럼)');
    console.log('   - GPU.xlsx: TDP (W) (28개 컬럼)');
    console.log('   - Mainboard.xlsx: 소켓, 메모리 타입, 폼팩터 (29개 컬럼)');
    console.log('   - RAM.xlsx: 메모리 규격 (26개 컬럼)');
    console.log('   - SSD.xlsx: 인터페이스 (25개 컬럼)');
  } catch (error) {
    console.error('❌ 오류 발생:', error.message);
    process.exit(1);
  }
}

main();
