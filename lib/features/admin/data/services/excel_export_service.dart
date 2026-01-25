/// Excel Export Service - 엑셀 파일 생성 및 내보내기
///
/// 기능:
/// - 주문 데이터 엑셀 내보내기
/// - 매출 리포트 엑셀 생성
/// - 정산 내역 엑셀 생성

import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';

// Conditional import for web download
import 'excel_web_helper_stub.dart'
    if (dart.library.html) 'excel_web_helper.dart';

class ExcelExportService {
  static final _dateFormat = DateFormat('yyyy-MM-dd HH:mm');
  static final _currencyFormat = NumberFormat('#,###');

  /// 주문 데이터를 엑셀로 내보내기
  static Future<void> exportOrders(
    List<Map<String, dynamic>> orders, {
    String? fileName,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel['주문목록'];

    // 헤더 스타일
    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#4472C4'),
      fontColorHex: ExcelColor.white,
      horizontalAlign: HorizontalAlign.Center,
    );

    // 헤더 행
    final headers = [
      '주문번호',
      '주문일시',
      '구매자',
      '판매자',
      '상품명',
      '수량',
      '상품금액',
      '배송비',
      '총 결제액',
      '주문상태',
      '배송상태',
      '결제일시',
      '배송시작일',
      '배송완료일',
      '송장번호',
    ];

    for (var i = 0; i < headers.length; i++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = headerStyle;
    }

    // 데이터 행
    for (var rowIndex = 0; rowIndex < orders.length; rowIndex++) {
      final order = orders[rowIndex];
      final items = order['items'] as List? ?? [];
      final itemNames = items.map((e) => e['partName'] ?? '').join(', ');
      final totalQuantity = items.fold<int>(0, (sum, e) => sum + ((e['quantity'] as num?)?.toInt() ?? 0));

      final rowData = [
        order['orderId'] ?? '',
        _formatTimestamp(order['createdAt']),
        order['buyerName'] ?? '',
        order['sellerName'] ?? '',
        itemNames,
        totalQuantity.toString(),
        _formatCurrency(order['totalPrice']),
        _formatCurrency(order['shippingFee']),
        _formatCurrency((order['totalPrice'] ?? 0) + (order['shippingFee'] ?? 0)),
        _getStatusLabel(order['status']),
        _getShippingStatusLabel(order['shippingStatus']),
        _formatTimestamp(order['paidAt']),
        _formatTimestamp(order['shippedAt']),
        _formatTimestamp(order['deliveredAt']),
        order['trackingNumber'] ?? '',
      ];

      for (var colIndex = 0; colIndex < rowData.length; colIndex++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: colIndex, rowIndex: rowIndex + 1));
        cell.value = TextCellValue(rowData[colIndex].toString());
      }
    }

    // 열 너비 자동 조정
    for (var i = 0; i < headers.length; i++) {
      sheet.setColumnWidth(i, 15);
    }
    sheet.setColumnWidth(0, 25); // 주문번호
    sheet.setColumnWidth(4, 40); // 상품명

    // 기본 시트 삭제
    excel.delete('Sheet1');

    // 파일 저장 및 공유
    final defaultFileName = '주문내역_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';
    await _saveAndShare(excel, fileName ?? defaultFileName);
  }

  /// 매출 리포트를 엑셀로 내보내기
  static Future<void> exportRevenueReport(
    Map<String, dynamic> reportData, {
    String? fileName,
  }) async {
    final excel = Excel.createExcel();

    // 1. 요약 시트
    final summarySheet = excel['매출요약'];
    _addSummarySheet(summarySheet, reportData);

    // 2. 일별 매출 시트
    if (reportData['dailyRevenue'] != null) {
      final dailySheet = excel['일별매출'];
      _addDailyRevenueSheet(dailySheet, reportData['dailyRevenue'] as List);
    }

    // 3. 상품별 매출 시트
    if (reportData['productRevenue'] != null) {
      final productSheet = excel['상품별매출'];
      _addProductRevenueSheet(productSheet, reportData['productRevenue'] as List);
    }

    // 기본 시트 삭제
    excel.delete('Sheet1');

    final defaultFileName = '매출리포트_${DateFormat('yyyyMMdd').format(DateTime.now())}.xlsx';
    await _saveAndShare(excel, fileName ?? defaultFileName);
  }

  /// 정산 리포트를 엑셀로 내보내기
  static Future<void> exportSettlementReport(
    List<Map<String, dynamic>> settlements, {
    String? fileName,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel['정산내역'];

    // 헤더 스타일
    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#2E7D32'),
      fontColorHex: ExcelColor.white,
      horizontalAlign: HorizontalAlign.Center,
    );

    // 헤더 행
    final headers = [
      '정산번호',
      '정산일자',
      '판매자',
      '주문건수',
      '총 매출액',
      '수수료',
      '정산금액',
      '정산상태',
      '입금일자',
    ];

    for (var i = 0; i < headers.length; i++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = headerStyle;
    }

    // 데이터 행
    for (var rowIndex = 0; rowIndex < settlements.length; rowIndex++) {
      final settlement = settlements[rowIndex];

      final rowData = [
        settlement['settlementId'] ?? '',
        _formatTimestamp(settlement['settlementDate']),
        settlement['sellerName'] ?? '',
        settlement['orderCount']?.toString() ?? '0',
        _formatCurrency(settlement['totalRevenue']),
        _formatCurrency(settlement['commission']),
        _formatCurrency(settlement['settlementAmount']),
        _getSettlementStatusLabel(settlement['status']),
        _formatTimestamp(settlement['depositedAt']),
      ];

      for (var colIndex = 0; colIndex < rowData.length; colIndex++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: colIndex, rowIndex: rowIndex + 1));
        cell.value = TextCellValue(rowData[colIndex].toString());
      }
    }

    // 열 너비 조정
    for (var i = 0; i < headers.length; i++) {
      sheet.setColumnWidth(i, 15);
    }

    // 기본 시트 삭제
    excel.delete('Sheet1');

    final defaultFileName = '정산내역_${DateFormat('yyyyMMdd').format(DateTime.now())}.xlsx';
    await _saveAndShare(excel, fileName ?? defaultFileName);
  }

  // ======== Private Helper Methods ========

  static void _addSummarySheet(Sheet sheet, Map<String, dynamic> data) {
    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#4472C4'),
      fontColorHex: ExcelColor.white,
    );

    final summaryData = [
      ['항목', '값'],
      ['기간', data['period'] ?? '-'],
      ['총 매출', _formatCurrency(data['totalRevenue'])],
      ['총 주문 수', data['totalOrders']?.toString() ?? '0'],
      ['평균 주문액', _formatCurrency(data['averageOrderValue'])],
      ['환불 금액', _formatCurrency(data['totalRefunds'])],
      ['순 매출', _formatCurrency(data['netRevenue'])],
    ];

    for (var rowIndex = 0; rowIndex < summaryData.length; rowIndex++) {
      for (var colIndex = 0; colIndex < summaryData[rowIndex].length; colIndex++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: colIndex, rowIndex: rowIndex));
        cell.value = TextCellValue(summaryData[rowIndex][colIndex].toString());
        if (rowIndex == 0) {
          cell.cellStyle = headerStyle;
        }
      }
    }

    sheet.setColumnWidth(0, 20);
    sheet.setColumnWidth(1, 25);
  }

  static void _addDailyRevenueSheet(Sheet sheet, List dailyData) {
    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#4472C4'),
      fontColorHex: ExcelColor.white,
    );

    final headers = ['날짜', '주문 수', '매출액', '환불액', '순매출'];

    for (var i = 0; i < headers.length; i++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = headerStyle;
    }

    for (var rowIndex = 0; rowIndex < dailyData.length; rowIndex++) {
      final day = dailyData[rowIndex] as Map<String, dynamic>;
      final rowData = [
        day['date'] ?? '',
        day['orderCount']?.toString() ?? '0',
        _formatCurrency(day['revenue']),
        _formatCurrency(day['refunds']),
        _formatCurrency(day['netRevenue']),
      ];

      for (var colIndex = 0; colIndex < rowData.length; colIndex++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: colIndex, rowIndex: rowIndex + 1));
        cell.value = TextCellValue(rowData[colIndex].toString());
      }
    }
  }

  static void _addProductRevenueSheet(Sheet sheet, List productData) {
    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#4472C4'),
      fontColorHex: ExcelColor.white,
    );

    final headers = ['상품명', '판매 수량', '매출액', '비율(%)'];

    for (var i = 0; i < headers.length; i++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = headerStyle;
    }

    for (var rowIndex = 0; rowIndex < productData.length; rowIndex++) {
      final product = productData[rowIndex] as Map<String, dynamic>;
      final rowData = [
        product['productName'] ?? '',
        product['quantity']?.toString() ?? '0',
        _formatCurrency(product['revenue']),
        '${product['percentage']?.toStringAsFixed(1) ?? '0'}%',
      ];

      for (var colIndex = 0; colIndex < rowData.length; colIndex++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: colIndex, rowIndex: rowIndex + 1));
        cell.value = TextCellValue(rowData[colIndex].toString());
      }
    }

    sheet.setColumnWidth(0, 40);
  }

  static Future<void> _saveAndShare(Excel excel, String fileName) async {
    final bytes = excel.encode();
    if (bytes == null) return;

    if (kIsWeb) {
      // 웹에서는 다운로드
      downloadExcelWeb(Uint8List.fromList(bytes), fileName);
    } else {
      // 모바일/데스크탑에서는 파일 저장 후 공유
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(filePath)],
        subject: fileName,
      );
    }
  }

  static String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '-';
    try {
      if (timestamp is DateTime) {
        return _dateFormat.format(timestamp);
      }
      // Firestore Timestamp
      final date = timestamp.toDate();
      return _dateFormat.format(date);
    } catch (e) {
      return '-';
    }
  }

  static String _formatCurrency(dynamic value) {
    if (value == null) return '0';
    final numValue = value is num ? value : 0;
    return '${_currencyFormat.format(numValue)}원';
  }

  static String _getStatusLabel(String? status) {
    switch (status) {
      case 'pending':
        return '대기중';
      case 'processing':
        return '처리중';
      case 'shipped':
        return '배송중';
      case 'delivered':
        return '배송완료';
      case 'confirmed':
        return '구매확정';
      case 'cancelled':
        return '취소됨';
      case 'refundRequested':
        return '환불신청';
      case 'refundCompleted':
        return '환불완료';
      default:
        return status ?? '-';
    }
  }

  static String _getShippingStatusLabel(String? status) {
    switch (status) {
      case 'pending_shipment':
        return '발송대기';
      case 'shipped':
        return '발송완료';
      case 'in_transit':
        return '배송중';
      case 'delivered':
        return '배송완료';
      default:
        return status ?? '-';
    }
  }

  static String _getSettlementStatusLabel(String? status) {
    switch (status) {
      case 'pending':
        return '정산대기';
      case 'processing':
        return '처리중';
      case 'completed':
        return '정산완료';
      case 'failed':
        return '정산실패';
      default:
        return status ?? '-';
    }
  }
}
