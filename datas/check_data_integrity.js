const ExcelJS = require('exceljs');
const path = require('path');

/**
 * 엑셀 파일의 데이터 무결성을 확인하는 스크립트
 */

async function checkExcelFile(filename) {
  console.log(`\n${'='.repeat(60)}`);
  console.log(`📄 ${filename} 확인 중...`);
  console.log('='.repeat(60));

  const workbook = new ExcelJS.Workbook();
  await workbook.xlsx.readFile(path.join(__dirname, filename));

  let totalDataRows = 0;

  workbook.eachSheet((worksheet, sheetId) => {
    // ValidationLists 시트는 스킵
    if (worksheet.name === '_ValidationLists' || worksheet.name.includes('Sheet')) {
      return;
    }

    console.log(`\n📋 시트: ${worksheet.name}`);

    // 헤더 확인
    const headerRow = worksheet.getRow(1);
    const headers = [];
    headerRow.eachCell((cell, colNumber) => {
      headers.push({ col: colNumber, name: cell.value });
    });

    console.log(`   총 컬럼 수: ${headers.length}`);
    console.log(`   마지막 5개 컬럼: ${headers.slice(-5).map(h => h.name).join(' | ')}`);

    // 데이터 행 수 확인
    const rowCount = worksheet.actualRowCount;
    const dataRowCount = rowCount - 1; // 헤더 제외
    totalDataRows += dataRowCount;

    console.log(`   총 행 수: ${rowCount} (헤더 포함)`);
    console.log(`   데이터 행 수: ${dataRowCount}`);

    // 샘플 데이터 확인 (2-4행)
    if (dataRowCount > 0) {
      console.log(`\n   📊 샘플 데이터 (처음 3행):`);

      for (let rowNum = 2; rowNum <= Math.min(4, rowCount); rowNum++) {
        const row = worksheet.getRow(rowNum);
        const rowData = [];

        // 처음 5개 컬럼만 출력
        for (let colNum = 1; colNum <= Math.min(5, headers.length); colNum++) {
          const cell = row.getCell(colNum);
          const value = cell.value;
          let displayValue = '';

          if (value === null || value === undefined) {
            displayValue = '(비어있음)';
          } else if (typeof value === 'object' && value.text) {
            displayValue = value.text;
          } else if (typeof value === 'object' && value.formula) {
            displayValue = `=${value.formula}`;
          } else {
            displayValue = String(value).substring(0, 20);
          }

          rowData.push(displayValue);
        }

        console.log(`   행 ${rowNum}: ${rowData.join(' | ')}`);
      }

      // 새로 추가된 컬럼 확인 (마지막 컬럼)
      const lastColNum = headers.length;
      const lastColName = headers[lastColNum - 1].name;

      console.log(`\n   🆕 새 컬럼 "${lastColName}" 데이터 확인 (처음 3행):`);
      for (let rowNum = 2; rowNum <= Math.min(4, rowCount); rowNum++) {
        const row = worksheet.getRow(rowNum);
        const cell = row.getCell(lastColNum);
        const value = cell.value;

        let displayValue = '';
        if (value === null || value === undefined || value === '') {
          displayValue = '(비어있음) ⚠️';
        } else {
          displayValue = String(value);
        }

        console.log(`   행 ${rowNum}: ${displayValue}`);
      }
    } else {
      console.log(`   ⚠️  데이터 없음`);
    }
  });

  console.log(`\n📊 ${filename} 요약:`);
  console.log(`   전체 데이터 행 수: ${totalDataRows}`);
}

async function main() {
  console.log('🔍 엑셀 파일 데이터 무결성 확인 시작...\n');

  const files = [
    'CPU.xlsx',
    'GPU.xlsx',
    'Mainboard.xlsx',
    'RAM.xlsx',
    'SSD.xlsx'
  ];

  for (const file of files) {
    try {
      await checkExcelFile(file);
    } catch (error) {
      console.error(`\n❌ ${file} 확인 중 오류:`, error.message);
    }
  }

  console.log('\n' + '='.repeat(60));
  console.log('✅ 확인 완료!');
  console.log('='.repeat(60));
}

main();
