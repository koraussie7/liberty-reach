import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';

/// AI Preference 화면
/// 3개 탭: 예측(Predict) / 학습(Train) / 피드백(Feedback)
/// 각 탭마다 간단한 입력 폼 + API 결과 표시
class AiPreferenceScreen extends StatefulWidget {
  const AiPreferenceScreen({super.key});

  @override
  State<AiPreferenceScreen> createState() => _AiPreferenceScreenState();
}

class _AiPreferenceScreenState extends State<AiPreferenceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ── Predict ──
  final _predictIdController = TextEditingController(text: 'user_001');
  String? _predictResult;
  bool _predictLoading = false;

  // ── Train ──
  final _trainDataController =
      TextEditingController(text: '{"feature": "sample", "label": "A"}');
  String? _trainResult;
  bool _trainLoading = false;

  // ── Feedback ──
  final _feedbackUserController = TextEditingController(text: 'user_001');
  final _feedbackScoreController = TextEditingController(text: '4.5');
  final _feedbackCommentController = TextEditingController(text: 'Great service');
  String? _feedbackResult;
  bool _feedbackLoading = false;

  final String _baseUrl = AppConstants.apiBaseUrl;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _predictIdController.dispose();
    _trainDataController.dispose();
    _feedbackUserController.dispose();
    _feedbackScoreController.dispose();
    _feedbackCommentController.dispose();
    super.dispose();
  }

  // ── API Calls ──

  Future<void> _callPredict() async {
    setState(() {
      _predictLoading = true;
      _predictResult = null;
    });
    try {
      final body = {'user_id': _predictIdController.text.trim()};
      final res = await http
          .post(
            Uri.parse('$_baseUrl/ai/preference/predict'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        setState(() => _predictResult = _formatJson(data));
      } else {
        setState(
            () => _predictResult = 'Error: HTTP ${res.statusCode}\n${res.body}');
      }
    } catch (e) {
      setState(() => _predictResult = 'Request failed: $e');
    }
    if (mounted) setState(() => _predictLoading = false);
  }

  Future<void> _callTrain() async {
    setState(() {
      _trainLoading = true;
      _trainResult = null;
    });
    try {
      final body = {'data': _trainDataController.text.trim()};
      final res = await http
          .post(
            Uri.parse('$_baseUrl/ai/preference/train'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        setState(() => _trainResult = _formatJson(data));
      } else {
        setState(
            () => _trainResult = 'Error: HTTP ${res.statusCode}\n${res.body}');
      }
    } catch (e) {
      setState(() => _trainResult = 'Request failed: $e');
    }
    if (mounted) setState(() => _trainLoading = false);
  }

  Future<void> _callFeedback() async {
    setState(() {
      _feedbackLoading = true;
      _feedbackResult = null;
    });
    try {
      final body = {
        'user_id': _feedbackUserController.text.trim(),
        'score': double.tryParse(_feedbackScoreController.text.trim()) ?? 0.0,
        'comment': _feedbackCommentController.text.trim(),
      };
      final res = await http
          .post(
            Uri.parse('$_baseUrl/ai/preference/feedback'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        setState(() => _feedbackResult = _formatJson(data));
      } else {
        setState(() =>
            _feedbackResult = 'Error: HTTP ${res.statusCode}\n${res.body}');
      }
    } catch (e) {
      setState(() => _feedbackResult = 'Request failed: $e');
    }
    if (mounted) setState(() => _feedbackLoading = false);
  }

  String _formatJson(Map<String, dynamic> data) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        title: const Text('🤖 AI Preference'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF9F7AEA),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.analytics), text: '예측'),
            Tab(icon: Icon(Icons.model_training), text: '학습'),
            Tab(icon: Icon(Icons.feedback), text: '피드백'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPredictTab(),
          _buildTrainTab(),
          _buildFeedbackTab(),
        ],
      ),
    );
  }

  // ── Predict Tab ──

  Widget _buildPredictTab() {
    return _tabContent(
      children: [
        _sectionTitle('사용자 선호도 예측'),
        const SizedBox(height: 12),
        _inputField(_predictIdController, 'User ID', Icons.person),
        const SizedBox(height: 16),
        _actionButton('예측 실행', Icons.analytics, _predictLoading, _callPredict),
        const SizedBox(height: 20),
        if (_predictResult != null) _resultBox(_predictResult!),
      ],
    );
  }

  // ── Train Tab ──

  Widget _buildTrainTab() {
    return _tabContent(
      children: [
        _sectionTitle('모델 학습 데이터 전송'),
        const SizedBox(height: 12),
        _inputField(_trainDataController, 'Training Data (JSON)', Icons.data_array, maxLines: 5),
        const SizedBox(height: 16),
        _actionButton('학습 실행', Icons.model_training, _trainLoading, _callTrain),
        const SizedBox(height: 20),
        if (_trainResult != null) _resultBox(_trainResult!),
      ],
    );
  }

  // ── Feedback Tab ──

  Widget _buildFeedbackTab() {
    return _tabContent(
      children: [
        _sectionTitle('피드백 제출'),
        const SizedBox(height: 12),
        _inputField(_feedbackUserController, 'User ID', Icons.person),
        const SizedBox(height: 12),
        _inputField(_feedbackScoreController, 'Score (0.0 ~ 5.0)', Icons.star, keyboardType: TextInputType.number),
        const SizedBox(height: 12),
        _inputField(_feedbackCommentController, 'Comment', Icons.comment, maxLines: 3),
        const SizedBox(height: 16),
        _actionButton('피드백 전송', Icons.send, _feedbackLoading, _callFeedback),
        const SizedBox(height: 20),
        if (_feedbackResult != null) _resultBox(_feedbackResult!),
      ],
    );
  }

  // ── Shared Widgets ──

  Widget _tabContent({required List<Widget> children}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _inputField(
    TextEditingController controller,
    String label,
    IconData icon, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: const Color(0xFF9F7AEA)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF9F7AEA)),
        ),
      ),
    );
  }

  Widget _actionButton(String label, IconData icon, bool isLoading, VoidCallback onPressed) {
    return SizedBox(
      height: 48,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6B46C1),
          disabledBackgroundColor: Colors.white12,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _resultBox(String result) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📤 결과',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF9F7AEA),
            ),
          ),
          const SizedBox(height: 8),
          SelectableText(
            result,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
