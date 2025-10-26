// lib/features/admin/presentation/screens/db_update_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';

class DbUpdateScreen extends StatefulWidget {
  const DbUpdateScreen({super.key});

  @override
  State<DbUpdateScreen> createState() => _DbUpdateScreenState();
}

class _DbUpdateScreenState extends State<DbUpdateScreen> {
  bool _isRunning = false;
  int _totalUpdated = 0;
  int _currentBatch = 0;
  String? _lastPartId;
  final List<String> _logs = [];

  Future<void> _runBatchUpdate() async {
    if (_isRunning) return;

    setState(() {
      _isRunning = true;
      _totalUpdated = 0;
      _currentBatch = 0;
      _lastPartId = null;
      _logs.clear();
    });

    final functions = FirebaseFunctions.instanceFor(region: 'asia-northeast3');

    try {
      do {
        _currentBatch++;
        _addLog('[$_currentBatch] 배치 시작...');

        final callable = functions.httpsCallable('addSearchKeywordsToParts');
        final result = await callable.call({
          'batchSize': 500,
          'startAfter': _lastPartId,
        });

        final data = result.data as Map<String, dynamic>;
        final updatedCount = data['updatedCount'] as int;
        _totalUpdated += updatedCount;
        _lastPartId = data['lastPartId'] as String?;

        _addLog('[$_currentBatch] ${data['message']}');
        _addLog('총 업데이트: $_totalUpdated개');

        setState(() {});

        if (!(data['hasMore'] as bool)) {
          _addLog('✅ 모든 Part 업데이트 완료!');
          break;
        }

        // 잠시 대기 (Firestore 부하 방지)
        await Future.delayed(const Duration(seconds: 2));
      } while (true);
    } catch (e) {
      _addLog('❌ 오류: $e');
    } finally {
      setState(() {
        _isRunning = false;
      });
    }
  }

  void _addLog(String message) {
    setState(() {
      _logs.add('[${DateTime.now().toString().substring(11, 19)}] $message');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DB 업데이트 (searchKeywords 추가)'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 상태 표시
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      _isRunning ? '⏳ 실행 중...' : '✅ 대기 중',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('현재 배치: $_currentBatch'),
                    Text('총 업데이트: $_totalUpdated개'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 실행 버튼
            ElevatedButton(
              onPressed: _isRunning ? null : _runBatchUpdate,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
              child: Text(
                _isRunning ? '실행 중...' : 'searchKeywords 추가 시작',
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),

            // 로그
            const Text(
              '실행 로그:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(8),
                child: ListView.builder(
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    return Text(
                      _logs[index],
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
