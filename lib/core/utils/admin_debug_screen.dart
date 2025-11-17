// lib/core/utils/admin_debug_screen.dart
// 개발자 전용 디버그 화면 (데이터 Seeding 등)

import 'package:flutter/material.dart';
import 'package:pi_com/core/utils/firebase_data_seeder.dart';

class AdminDebugScreen extends StatefulWidget {
  const AdminDebugScreen({super.key});

  @override
  State<AdminDebugScreen> createState() => _AdminDebugScreenState();
}

class _AdminDebugScreenState extends State<AdminDebugScreen> {
  final FirebaseDataSeeder _seeder = FirebaseDataSeeder();
  bool _isLoading = false;
  String _statusMessage = '';
  final List<String> _logs = [];

  Future<void> _seedRamAndSsdData() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'RAM/SSD 데이터 추가 중...';
      _logs.clear();
    });

    try {
      // 로그를 캡처하기 위해 print를 override
      await _seeder.seedRamAndSsdData();

      setState(() {
        _statusMessage = '✅ 데이터 추가 완료!';
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ RAM/SSD 데이터가 성공적으로 추가되었습니다!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (error) {
      setState(() {
        _statusMessage = '❌ 오류 발생: $error';
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ 오류: $error'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🛠️ Admin Debug'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 경고 메시지
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade300),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '⚠️ 개발자 전용 화면입니다.\n기존 데이터를 덮어쓸 수 있습니다.',
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // RAM/SSD 데이터 추가 버튼
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.memory, size: 32, color: Colors.blue),
                        SizedBox(width: 12),
                        Text(
                          'RAM/SSD 데이터 추가',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '• BaseParts: RAM 35개, SSD 36개\n'
                      '• Parts: RAM ~75개, SSD ~75개\n'
                      '• 용량: 8GB, 16GB, 32GB (RAM)\n'
                      '• 용량: 500GB, 1TB, 2TB (SSD)\n'
                      '• 세대: DDR4, DDR5 / NVMe, SATA',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _seedRamAndSsdData,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.upload),
                      label: Text(_isLoading ? '추가 중...' : 'Firebase에 데이터 추가'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 상태 메시지
            if (_statusMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _statusMessage.contains('✅')
                      ? Colors.green.shade50
                      : _statusMessage.contains('❌')
                          ? Colors.red.shade50
                          : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _statusMessage.contains('✅')
                        ? Colors.green
                        : _statusMessage.contains('❌')
                            ? Colors.red
                            : Colors.blue,
                  ),
                ),
                child: Text(
                  _statusMessage,
                  style: TextStyle(
                    color: _statusMessage.contains('✅')
                        ? Colors.green.shade800
                        : _statusMessage.contains('❌')
                            ? Colors.red.shade800
                            : Colors.blue.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // 추가 정보
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📝 참고사항',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• 데이터 추가는 1회만 실행하세요\n'
                    '• 기존 동일 ID 데이터는 덮어씌워집니다\n'
                    '• Firebase Console에서 결과를 확인하세요\n'
                    '• 문제 발생 시 Firebase Console에서 수동 삭제',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
