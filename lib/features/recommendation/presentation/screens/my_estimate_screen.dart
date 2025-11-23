import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:pi_com/features/recommendation/data/models/spec_profile_model.dart';
import 'package:pi_com/features/recommendation/domain/entities/recommendation_entity.dart';
import 'package:pi_com/features/recommendation/presentation/providers/recommendation_provider.dart';
import 'package:pi_com/features/recommendation/presentation/screens/pc_assembly_screen.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../web_public/presentation/widgets/web_navbar_v2.dart';

class MyEstimateScreen extends ConsumerStatefulWidget {
  const MyEstimateScreen({super.key});
  @override
  ConsumerState<MyEstimateScreen> createState() => _MyEstimateScreenState();
}

class _MyEstimateScreenState extends ConsumerState<MyEstimateScreen> {
  static const Map<String, Map<String, dynamic>> _questionData = { 'Q1': { 'text': '컴퓨터를 주로 어떻게 사용하시나요?', 'subtitle': '가장 많이 사용할 용도를 선택해주세요', 'options': {'🎮 게임 (롤, 배그, 오버워치 등)': 'G', '🎨 영상편집/디자인 (유튜브, 포토샵 등)': 'C', '💼 업무/개발 (문서작업, 코딩 등)': 'O'},}, 'Q2': { 'text': '총 예산은 얼마인가요?', 'subtitle': '중고 부품 기준 예상 비용입니다', 'options': 'BUDGET_SINGLE', }, 'Q4G': { 'text': '주로 어떤 게임을 하시나요?', 'subtitle': '가장 무거운 게임 기준으로 선택해주세요', 'options': {'🎯 가벼운 게임 (롤, 오버워치, 발로란트)': 'light', '⚔️ 중간 게임 (배그, 로스트아크, 피파)': 'medium', '🔥 무거운 게임 (사이버펑크, GTA5, 발할라)': 'heavy', '🌟 최신 AAA급 (스타필드, 호그와트, 원신)': 'ultra'},}, 'Q5G': { 'text': '모니터 크기는 어떻게 되시나요?', 'subtitle': '모니터 크기로 해상도를 자동 판단합니다', 'options': {'📺 24인치 이하\n→ FHD (1920x1080)': 'FHD', '🖥️ 27인치\n→ QHD (2560x1440)': 'QHD', '📽️ 32인치 이상\n→ 4K (3840x2160)': '4K'},}, 'Q6G': { 'text': '게임 화면이 얼마나 부드러워야 하나요?', 'subtitle': '숫자가 높을수록 부드럽지만 비쌉니다', 'options': {'✅ 기본 (보통 게임에 적당)\n→ 60FPS': 60, '⚡ 부드럽게 (FPS 게임 추천)\n→ 100-120FPS': 120, '🚀 매우 부드럽게 (프로게이머급)\n→ 144-165FPS': 144, '💫 최고로 부드럽게 (최상급)\n→ 240FPS': 240},}, 'Q7G': { 'text': '게임 그래픽 품질은 얼마나 중요한가요?', 'subtitle': '품질이 높을수록 예쁘지만 비쌉니다', 'options': {'✅ 기본 (부드럽게 돌아가면 됨)\n→ 낮음~보통': '보통', '⭐ 예쁘게 (디테일 중요)\n→ 높음': '높음', '💎 최고 화질 (모든 옵션 최대)\n→ 울트라': '최고', '🌈 레이트레이싱 (빛 반사 효과)\n→ RTX ON': '레이트레이싱'},}, 'Q4C': { 'text': '어떤 작업을 주로 하시나요?', 'subtitle': '가장 무거운 작업 기준으로 선택해주세요', 'options': {'📸 사진 편집 (포토샵, 라이트룸)': '포토샵/라이트룸', '🎬 영상 편집 (프리미어, 파이널컷)': '프리미어', '🎨 3D 작업 (블렌더, 시네마4D)': '블렌더', '✨ 특수효과 (애프터이펙트)': 'AE', '💼 기타 창작 작업': '기타'},}, 'Q5C': { 'text': '작업하는 영상/이미지 크기는?', 'subtitle': '큰 파일일수록 성능이 더 필요합니다', 'options': {'📱 유튜브/인스타용\n→ FHD (1920x1080)': 'FHD', '🖥️ 고화질 영상\n→ QHD (2560x1440)': 'QHD', '📽️ 전문 영상\n→ 4K (3840x2160)': '4K', '🎥 최고급 영상\n→ 8K (7680x4320)': '8K'},}, 'Q6C': { 'text': '프로젝트 규모는 어느 정도인가요?', 'subtitle': '프로젝트가 클수록 메모리가 더 필요합니다', 'options': {'👤 혼자서 간단하게\n→ 개인 프로젝트': '개인', '👥 소규모 팀 작업\n→ 소규모 프로젝트': '소규모', '🏢 큰 프로젝트\n→ 대규모 작업': '대규모', '🎬 전문 스튜디오급\n→ 방송/영화 수준': '스튜디오급'},}, 'Q7C': { 'text': '렌더링은 얼마나 자주 하시나요?', 'subtitle': '렌더링: 편집한 영상을 최종 파일로 만드는 작업', 'options': {'⏰ 가끔 (주 1-2회)\n→ 기다려도 괜찮음': '가끔', '⚡ 자주 (거의 매일)\n→ 빠르면 좋음': '자주', '🚀 실시간 (라이브)\n→ 최대한 빨라야 함': '실시간'},}, 'Q4O': { 'text': '주로 어떤 업무를 하시나요?', 'subtitle': '가장 무거운 작업 기준으로 선택해주세요', 'options': {'📝 문서 작업 (한글, 워드, 엑셀)': '문서', '🌐 인터넷/이메일 (웹서핑, 메일)': '웹서핑/이메일', '💻 개발/코딩 (프로그래밍)': '개발/코딩', '📊 데이터 분석 (빅데이터, AI)': '데이터분석', '💼 기타 업무': '기타'},}, 'Q5O': { 'text': '프로그램을 몇 개나 동시에 켜두시나요?', 'subtitle': '크롬 탭 여러개 + 엑셀 + 카톡 등 모두 포함', 'options': {'✅ 적게 (3-5개 정도)\n→ 크롬 + 문서 정도': '5개 미만', '⚡ 보통 (5-10개 정도)\n→ 멀티태스킹 적당히': '5~10개', '🔥 많이 (10개 이상)\n→ 작업이 많음': '10개 이상'},}, 'Q6O': { 'text': '모니터는 몇 개 쓰시나요?', 'subtitle': '듀얼/트리플 모니터 사용 시 선택', 'options': {'🖥️ 1개\n→ 모니터 하나만': '1개', '🖥️🖥️ 2개\n→ 듀얼 모니터': '2개', '🖥️🖥️🖥️ 3개 이상\n→ 트리플 이상': '3개 이상'},}, 'Q7O': { 'text': '저장할 파일이 얼마나 많나요?', 'subtitle': '문서, 사진, 자료 등 모든 파일 포함', 'options': {'📁 적당히 (문서 위주)\n→ 100GB 미만': '100GB 미만', '📂 많이 (사진/자료 많음)\n→ 100GB~1TB': '1TB 미만', '🗄️ 아주 많이 (대용량 파일)\n→ 1TB 이상': '1TB 이상'},},};
  final List<String> _history = ['Q1'];
  final Map<String, dynamic> _answers = {};
  final TextEditingController _textController = TextEditingController();

  SpecProfileModel? _specProfile;
  bool _isLoading = false;
  String? _error;
  String get _currentQCode => _history.last;
  bool get _isFinished => _currentQCode == 'Q_FINISH';

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  String _getNextQCode() {
    switch (_currentQCode) {
      case 'Q1': return 'Q2';
      case 'Q2': final usage = _answers['Q1']; return 'Q4$usage';
      case 'Q4G': return 'Q5G';
      case 'Q5G': return 'Q6G';
      case 'Q6G': return 'Q7G';
      case 'Q4C': return 'Q5C';
      case 'Q5C': return 'Q6C';
      case 'Q6C': return 'Q7C';
      case 'Q4O': return 'Q5O';
      case 'Q5O': return 'Q6O';
      case 'Q6O': return 'Q7O';
      default: return 'Q_FINISH';
    }
  }

  void _onNext() {
    final currentQuestion = _questionData[_currentQCode]!;
    dynamic answer;
    if (_currentQCode == 'Q2') {
      // 단일 예산 입력 → 자동으로 -10% ~ +0% 범위 생성
      final budget = _textController.text.trim();
      if (budget.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('예산을 입력해주세요.')));
        return;
      }
      final budgetVal = int.tryParse(budget) ?? 0;
      if (budgetVal <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('올바른 예산을 입력해주세요.')));
        return;
      }
      // 예산의 90% ~ 100% 범위로 설정 (여유 10%)
      final minBudget = (budgetVal * 0.9).round();
      final maxBudget = budgetVal;
      answer = '$minBudget ~ $maxBudget';
    } else if (currentQuestion['options'] == 'N/A') {
      if (_textController.text.trim().isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('답변을 입력해주세요.'))); return; }
      answer = _textController.text.trim();
    } else {
      if (!_answers.containsKey(_currentQCode)) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('답변을 선택해주세요.'))); return; }
      answer = _answers[_currentQCode];
    }
    setState(() {
      _answers[_currentQCode] = answer;
      _textController.clear();
      final nextQ = _getNextQCode();
      _history.add(nextQ);
      if (nextQ == 'Q_FINISH') {
        _processResults();
      }
    });
  }

  void _onBack() {
    if (_history.length > 1) {
      setState(() {
        _specProfile = null;
        _error = null;
        final lastQ = _history.removeLast();
        _answers.remove(lastQ);
        _textController.clear();
        final prevQ = _questionData[_currentQCode]!;
        final prevAnswer = _answers[_currentQCode];
        if (prevAnswer != null) {
          // 예산 입력이나 일반 텍스트 입력인 경우 복원
          if (prevQ['options'] == 'BUDGET_SINGLE' || prevQ['options'] == 'N/A') {
            // 예산 입력의 경우 "min ~ max" 형식에서 max 값만 추출
            if (_currentQCode == 'Q2') {
              final parts = prevAnswer.toString().split(' ~ ');
              if (parts.length == 2) {
                _textController.text = parts[1];  // max 값만 사용
              }
            } else {
              _textController.text = prevAnswer.toString();
            }
          }
        }
      });
    }
  }

  void _onRestart() {
    setState(() {
      _history.clear();
      _history.add('Q1');
      _answers.clear();
      _textController.clear();
      _specProfile = null;
      _isLoading = false;
      _error = null;
    });
  }

  Future<void> _processResults() async {
    setState(() { _isLoading = true; _error = null; _specProfile = null; });
    try {
      final useCase = ref.read(getRecommendationUseCaseProvider);
      final result = await useCase(userAnswers: _answers);

      setState(() {
        _specProfile = SpecProfileModel(
          cpuSocket: result.profile.cpuSocket,
          ramType: result.profile.ramType,
          motherboardFormFactor: result.profile.motherboardFormFactor,
          cpuPerformanceTier: result.profile.cpuPerformanceTier,
          gpuPerformanceTier: result.profile.gpuPerformanceTier,
          recommendedPsuWattage: result.profile.recommendedPsuWattage,
          recommendationText: result.recommendation,
        );
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  int get _totalQuestions => 7;
  int get _currentQuestionNumber => _history.length;
  double get _progress => _currentQuestionNumber / _totalQuestions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: kIsWeb
          ? const WebNavBarV2()
          : AppBar(
              leading: _history.length > 1 && !_isFinished
                ? IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: _onBack,
                  )
                : null,
              title: const Text('나만의 PC 견적'),
              elevation: 0,
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
      body: ResponsiveHelper.centeredMaxWidthContainer(
        context: context,
        child: Column(
          children: [
            if (!_isFinished) _buildProgressBar(),
            Expanded(
              child: _isFinished ? _buildResultView() : _buildQuestionView(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _isFinished ? null : _buildNextButton(),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      color: Theme.of(context).primaryColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '질문 $_currentQuestionNumber / $_totalQuestions',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${(_progress * 100).toInt()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: _progress,
              backgroundColor: Colors.white.withValues(alpha: 0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionView() {
    final question = _questionData[_currentQCode]!;
    final text = question['text'] as String;
    final subtitle = question['subtitle'] as String?;
    final options = question['options'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Q$_currentQuestionNumber',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    text,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  if (options == 'BUDGET_SINGLE') _buildBudgetQuestion()
                  else if (options == 'N/A') _buildTextQuestion()
                  else _buildOptions(options as Map<String, dynamic>),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetQuestion() {
    return Column(
      children: [
        TextField(
          controller: _textController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: '예산',
            hintText: '예: 100 (100만원)',
            suffixText: '만원',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '예산은 만원 단위로 입력해주세요\n(입력한 금액의 90~100% 범위에서 최적 견적을 찾아드립니다)',
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }


  Widget _buildTextQuestion() {
    return TextField(
      controller: _textController,
      decoration: InputDecoration(
        hintText: _questionData[_currentQCode]!['hint'] as String? ?? '답변을 입력하세요',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      maxLines: 3,
    );
  }

  Widget _buildOptions(Map<String, dynamic> options) {
    return Column(
      children: options.entries.map((entry) {
        final key = entry.key;
        final value = entry.value;
        final isSelected = _answers[_currentQCode] == value;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() => _answers[_currentQCode] = value),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                    ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                    : Colors.white,
                  border: Border.all(
                    color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.grey[300]!,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                            ? Theme.of(context).primaryColor
                            : Colors.grey[400]!,
                          width: 2,
                        ),
                        color: isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.transparent,
                      ),
                      child: isSelected
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        key,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildResultView() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                strokeWidth: 5,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '견적을 분석하고 있습니다...',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange[700],
                      size: 60,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '현실적이지 않은 조합입니다',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _onRestart,
                      child: const Text('다시 시작하기', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (_specProfile == null || _specProfile!.recommendationText == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.error_outline,
                      color: Colors.red[700],
                      size: 60,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '추천 견적을 찾지 못했습니다',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '조건에 맞는 견적이 없습니다.\n다시 시도해주세요.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _onRestart,
                      child: const Text('다시 시작하기', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 성공 아이콘
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                color: Colors.green[600],
                size: 60,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 타이틀
          const Text(
            '회원님을 위한 추천 견적',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '실제 구매 가능한 중고 부품 기준으로 추천된 견적입니다.\n가격과 재고는 실시간으로 변동될 수 있습니다.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),

          // 추천 사양 카드
          _buildRecommendationCard(_specProfile!.recommendationText!),

          const SizedBox(height: 24),

          // 중고 부품 찾기 버튼
          ElevatedButton.icon(
            icon: const Icon(Icons.search, size: 24),
            label: const Text(
              '이 사양으로 중고 부품 찾기',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PcAssemblyScreen(
                    specProfile: _specProfile,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 12),

          // 다시 만들기 버튼
          OutlinedButton(
            onPressed: _onRestart,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: Theme.of(context).primaryColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              '견적 다시 만들기',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(RecommendationEntity rec) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.computer,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  '추천 PC 사양',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: Column(
              children: [
                _buildSpecRow(Symbols.developer_board, 'CPU', rec.cpu, rec.cpuPrice),
                _buildSpecRow(Symbols.ac_unit, 'CPU 쿨러', rec.cpuCooler, rec.cpuCoolerPrice),
                _buildSpecRow(Symbols.view_in_ar, '메인보드', rec.mainboard, rec.mainboardPrice),
                _buildSpecRow(Symbols.memory, '메모리', rec.memory, rec.memoryPrice),
                _buildSpecRow(Symbols.screenshot_monitor, '그래픽카드', rec.gpu, rec.gpuPrice),
                _buildSpecRow(Symbols.storage, 'SSD', rec.ssd, rec.ssdPrice),
                _buildSpecRow(Symbols.desktop_windows, '케이스', rec.pcCase, rec.pcCasePrice),
                _buildSpecRow(Symbols.power, '파워', rec.psu, rec.psuPrice),
              ],
            ),
          ),
          // 총 가격 표시
          if (rec.totalPrice != null)
            Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).primaryColor,
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '총 예상 가격',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  Text(
                    '${(rec.totalPrice! / 10000).toStringAsFixed(0)}만원',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSpecRow(IconData icon, String title, String? value, int? price) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          // 가격 표시
          if (price != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${(price / 10000).toStringAsFixed(1)}만',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNextButton() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 56),
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
          onPressed: _onNext,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_getNextQCode() == 'Q_FINISH' ? '결과 보기' : '다음'),
              const SizedBox(width: 8),
              Icon(
                _getNextQCode() == 'Q_FINISH'
                  ? Icons.check_circle_outline
                  : Icons.arrow_forward,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
