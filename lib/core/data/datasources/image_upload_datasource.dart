// lib/core/data/datasources/image_upload_datasource.dart

import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class ImageUploadDataSource {
  final FirebaseStorage _storage;

  ImageUploadDataSource({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  /// 여러 이미지를 Firebase Storage에 병렬 업로드
  ///
  /// [images]: XFile 리스트 (image_picker로 선택한 이미지)
  /// [userId]: 사용자 ID (폴더 구조용)
  /// [uploadId]: 업로드 세션 ID (기본값: UUID 자동 생성)
  ///
  /// Returns: 업로드된 이미지 URL 리스트
  Future<List<String>> uploadImages({
    required List<XFile> images,
    required String userId,
    String? uploadId,
  }) async {
    if (images.isEmpty) return [];

    final String sessionId = uploadId ?? const Uuid().v4();

    // 병렬 업로드
    final uploadTasks = images.asMap().entries.map((entry) {
      final index = entry.key;
      final image = entry.value;
      return _uploadSingleImage(
        image: image,
        userId: userId,
        sessionId: sessionId,
        imageIndex: index,
      );
    }).toList();

    // 모든 업로드 완료 대기
    return await Future.wait(uploadTasks);
  }

  /// 단일 이미지 업로드
  Future<String> _uploadSingleImage({
    required XFile image,
    required String userId,
    required String sessionId,
    required int imageIndex,
  }) async {
    try {
      // Storage 경로: sell_requests/{userId}/{sessionId}/image_{index}.jpg
      final String path =
          'sell_requests/$userId/$sessionId/image_$imageIndex.jpg';
      final storageRef = _storage.ref().child(path);

      // 플랫폼별 업로드
      UploadTask uploadTask;

      if (kIsWeb) {
        // 웹: Uint8List 사용
        final bytes = await image.readAsBytes();
        uploadTask = storageRef.putData(
          bytes,
          SettableMetadata(contentType: 'image/jpeg'),
        );
      } else {
        // 모바일: File 사용
        final file = File(image.path);
        uploadTask = storageRef.putFile(
          file,
          SettableMetadata(contentType: 'image/jpeg'),
        );
      }

      // 업로드 완료 대기
      final snapshot = await uploadTask;

      // 다운로드 URL 반환
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('이미지 업로드 실패 (index: $imageIndex): $e');
    }
  }

  /// 업로드 진행률 Stream (선택사항)
  Stream<double> uploadImagesWithProgress({
    required List<XFile> images,
    required String userId,
    String? uploadId,
  }) async* {
    if (images.isEmpty) {
      yield 1.0;
      return;
    }

    final String sessionId = uploadId ?? const Uuid().v4();
    int completedCount = 0;
    final totalCount = images.length;

    for (var i = 0; i < images.length; i++) {
      await _uploadSingleImage(
        image: images[i],
        userId: userId,
        sessionId: sessionId,
        imageIndex: i,
      );
      completedCount++;
      yield completedCount / totalCount;
    }
  }

  /// Storage에서 이미지 삭제
  Future<void> deleteImages(List<String> imageUrls) async {
    final deleteTasks = imageUrls.map((url) async {
      try {
        final ref = _storage.refFromURL(url);
        await ref.delete();
      } catch (e) {
        print('이미지 삭제 실패: $url, 에러: $e');
      }
    }).toList();

    await Future.wait(deleteTasks);
  }
}
