const ExcelJS = require('exceljs');
const path = require('path');

/**
 * 기존 엑셀 파일에 새 컬럼을 추가하는 스크립트
 * 샘플 데이터는 그대로 유지하고, 새 컬럼만 헤더에 추가됩니다.
 */

async function addColumnToCPU() {
  console.log('📝 CPU.xlsx 처리 중...');
  const workbook = new ExcelJS.Workbook();
  await workbook.xlsx.readFile(path.join(__dirname, 'CPU.xlsx'));

  // 모든 시트에 대해 처리
  workbook.eachSheet((worksheet) => {
    const headerRow = worksheet.getRow(1);
    const lastCol = headerRow.actualCellCount;

    // 마지막 컬럼 다음에 "소켓" 추가
    const newCol = lastCol + 1;
    worksheet.getCell(1, newCol).value = '소켓';

    // 헤더 스타일 적용
    worksheet.getCell(1, newCol).font = { bold: true, color: { argb: 'FFFFFFFF' } };
    worksheet.getCell(1, newCol).fill = {
      type: 'pattern',
      pattern: 'solid',
      fgColor: { argb: 'FF808080' }
    };
    worksheet.getCell(1, newCol).alignment = { horizontal: 'center', vertical: 'middle' };

    // 열 너비 설정
    worksheet.getColumn(newCol).width = 18;

    console.log(`  ✅ ${worksheet.name} 시트: "소켓" 컬럼 추가 (${newCol}번 컬럼)`);
  });

  await workbook.xlsx.writeFile(path.join(__dirname, 'CPU.xlsx'));
  console.log('✅ CPU.xlsx 완료!\n');
}

async function addColumnToGPU() {
  console.log('📝 GPU.xlsx 처리 중...');
  const workbook = new ExcelJS.Workbook();
  await workbook.xlsx.readFile(path.join(__dirname, 'GPU.xlsx'));

  workbook.eachSheet((worksheet) => {
    const headerRow = worksheet.getRow(1);
    const lastCol = headerRow.actualCellCount;

    // 마지막 컬럼 다음에 "TDP (W)" 추가
    const newCol = lastCol + 1;
    worksheet.getCell(1, newCol).value = 'TDP (W)';

    // 헤더 스타일 적용
    worksheet.getCell(1, newCol).font = { bold: true, color: { argb: 'FFFFFFFF' } };
    worksheet.getCell(1, newCol).fill = {
      type: 'pattern',
      pattern: 'solid',
      fgColor: { argb: 'FF808080' }
    };
    worksheet.getCell(1, newCol).alignment = { horizontal: 'center', vertical: 'middle' };

    // 열 너비 설정
    worksheet.getColumn(newCol).width = 12;

    console.log(`  ✅ ${worksheet.name} 시트: "TDP (W)" 컬럼 추가 (${newCol}번 컬럼)`);
  });

  await workbook.xlsx.writeFile(path.join(__dirname, 'GPU.xlsx'));
  console.log('✅ GPU.xlsx 완료!\n');
}

async function addColumnsToMainboard() {
  console.log('📝 Mainboard.xlsx 처리 중...');
  const workbook = new ExcelJS.Workbook();
  await workbook.xlsx.readFile(path.join(__dirname, 'Mainboard.xlsx'));

  workbook.eachSheet((worksheet) => {
    const headerRow = worksheet.getRow(1);
    const lastCol = headerRow.actualCellCount;

    // 3개 컬럼 추가: "소켓", "메모리 타입", "폼팩터"
    const newCols = [
      { name: '소켓', width: 18 },
      { name: '메모리 타입', width: 15 },
      { name: '폼팩터', width: 15 }
    ];

    newCols.forEach((col, idx) => {
      const colNum = lastCol + 1 + idx;
      worksheet.getCell(1, colNum).value = col.name;

      // 헤더 스타일 적용
      worksheet.getCell(1, colNum).font = { bold: true, color: { argb: 'FFFFFFFF' } };
      worksheet.getCell(1, colNum).fill = {
        type: 'pattern',
        pattern: 'solid',
        fgColor: { argb: 'FF808080' }
      };
      worksheet.getCell(1, colNum).alignment = { horizontal: 'center', vertical: 'middle' };

      // 열 너비 설정
      worksheet.getColumn(colNum).width = col.width;

      console.log(`  ✅ ${worksheet.name} 시트: "${col.name}" 컬럼 추가 (${colNum}번 컬럼)`);
    });
  });

  await workbook.xlsx.writeFile(path.join(__dirname, 'Mainboard.xlsx'));
  console.log('✅ Mainboard.xlsx 완료!\n');
}

async function checkRAM() {
  console.log('📝 RAM.xlsx 확인 중...');
  const workbook = new ExcelJS.Workbook();
  await workbook.xlsx.readFile(path.join(__dirname, 'RAM.xlsx'));

  let hasMemoryType = false;

  workbook.eachSheet((worksheet) => {
    const headerRow = worksheet.getRow(1);
    const headers = [];

    headerRow.eachCell((cell) => {
      headers.push(cell.value);
    });

    // "메모리 규격" 또는 유사한 컬럼 찾기
    const memoryColumns = headers.filter(h =>
      h && (h.includes('메모리') || h.includes('규격') || h.includes('DDR'))
    );

    if (memoryColumns.length > 0) {
      console.log(`  ✅ ${worksheet.name} 시트: 메모리 관련 컬럼 발견 - ${memoryColumns.join(', ')}`);
      hasMemoryType = true;
    } else {
      console.log(`  ⚠️  ${worksheet.name} 시트: 메모리 관련 컬럼 없음`);
    }
  });

  if (hasMemoryType) {
    console.log('✅ RAM.xlsx: 메모리 규격 컬럼 이미 존재 - 수정 불필요\n');
  } else {
    console.log('⚠️  RAM.xlsx: 메모리 규격 컬럼이 없습니다. 수동으로 확인이 필요합니다.\n');
  }
}

async function addColumnToSSD() {
  console.log('📝 SSD.xlsx 처리 중...');
  const workbook = new ExcelJS.Workbook();
  await workbook.xlsx.readFile(path.join(__dirname, 'SSD.xlsx'));

  workbook.eachSheet((worksheet) => {
    const headerRow = worksheet.getRow(1);
    const lastCol = headerRow.actualCellCount;

    // 마지막 컬럼 다음에 "인터페이스" 추가
    const newCol = lastCol + 1;
    worksheet.getCell(1, newCol).value = '인터페이스';

    // 헤더 스타일 적용
    worksheet.getCell(1, newCol).font = { bold: true, color: { argb: 'FFFFFFFF' } };
    worksheet.getCell(1, newCol).fill = {
      type: 'pattern',
      pattern: 'solid',
      fgColor: { argb: 'FF808080' }
    };
    worksheet.getCell(1, newCol).alignment = { horizontal: 'center', vertical: 'middle' };

    // 열 너비 설정
    worksheet.getColumn(newCol).width = 20;

    console.log(`  ✅ ${worksheet.name} 시트: "인터페이스" 컬럼 추가 (${newCol}번 컬럼)`);
  });

  await workbook.xlsx.writeFile(path.join(__dirname, 'SSD.xlsx'));
  console.log('✅ SSD.xlsx 완료!\n');
}

async function main() {
  console.log('🚀 기존 엑셀 파일에 새 컬럼 추가 시작...\n');
  console.log('⚠️  주의: 원본 파일이 수정됩니다. 백업본은 *_backup.xlsx 파일을 확인하세요.\n');

  try {
    await addColumnToCPU();
    await addColumnToGPU();
    await addColumnsToMainboard();
    await checkRAM();
    await addColumnToSSD();

    console.log('\n🎉 모든 작업 완료!');
    console.log('\n✅ 추가된 컬럼:');
    console.log('   - CPU.xlsx: 소켓');
    console.log('   - GPU.xlsx: TDP (W)');
    console.log('   - Mainboard.xlsx: 소켓, 메모리 타입, 폼팩터');
    console.log('   - RAM.xlsx: (확인만 수행)');
    console.log('   - SSD.xlsx: 인터페이스');
    console.log('\n📌 다음 단계:');
    console.log('   1. 엑셀 파일을 열어서 새 컬럼 확인');
    console.log('   2. 샘플 데이터가 잘 유지되었는지 확인');
    console.log('   3. 새 컬럼에 필요한 데이터 입력 (선택사항)');
    console.log('   4. Phase 10 (업로드 스크립트) 진행');
  } catch (error) {
    console.error('\n❌ 오류 발생:', error.message);
    console.error(error.stack);
    process.exit(1);
  }
}

main();
