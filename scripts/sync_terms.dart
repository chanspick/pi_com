import 'dart:io';

/// 루트 디렉토리의 약관 파일들을 web/과 assets/html/ 디렉토리에 동기화합니다.
///
/// 사용법: dart run scripts/sync_terms.dart
void main() {
  print('📄 약관 파일 동기화 시작...\n');

  final termsFiles = [
    'privacy_policy.html',
    'refund.html',
    'storage_service_terms.html',
    'termsofuse.html',
  ];

  final destinations = [
    'web',
    'assets/html',
  ];

  int syncedCount = 0;
  int errorCount = 0;

  for (final file in termsFiles) {
    final sourceFile = File(file);

    if (!sourceFile.existsSync()) {
      print('⚠️  소스 파일이 존재하지 않습니다: $file');
      errorCount++;
      continue;
    }

    for (final dest in destinations) {
      try {
        final destDir = Directory(dest);
        if (!destDir.existsSync()) {
          print('⚠️  대상 디렉토리가 존재하지 않습니다: $dest');
          continue;
        }

        final destFile = File('$dest/$file');
        sourceFile.copySync(destFile.path);
        print('✅ $file → $dest/$file');
        syncedCount++;
      } catch (e) {
        print('❌ 복사 실패 ($file → $dest): $e');
        errorCount++;
      }
    }
  }

  print('\n📊 동기화 완료:');
  print('   성공: $syncedCount개');
  print('   실패: $errorCount개');

  if (errorCount > 0) {
    exit(1);
  }
}
