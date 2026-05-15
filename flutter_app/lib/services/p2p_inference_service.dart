import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'p2p_service.dart';

enum InferenceTaskType { codeGeneration, textCompletion, imageAnalysis, translation }

class InferenceTask {
  final String id;
  final InferenceTaskType type;
  final String prompt;
  final List<String>? images;
  final DateTime createdAt;
  String? result;
  String? assignedPeer;
  bool completed;
  bool failed;

  InferenceTask({
    required this.id,
    required this.type,
    required this.prompt,
    this.images,
    DateTime? createdAt,
    this.result,
    this.assignedPeer,
    this.completed = false,
    this.failed = false,
  }) : createdAt = createdAt ?? DateTime.now();
}

class P2PInferenceService extends ChangeNotifier {
  final P2PService _p2p;
  final http.Client _client = http.Client();
  final List<InferenceTask> _tasks = [];
  final Random _random = Random();
  StreamSubscription? _p2pSub;

  final String _localAiUrl = 'http://localhost:11434';
  final String _localModel = 'gemma3:4b';

  List<InferenceTask> get tasks => List.unmodifiable(_tasks);
  List<InferenceTask> get pendingTasks => _tasks.where((t) => !t.completed && !t.failed).toList();

  P2PInferenceService(this._p2p) {
    _p2pSub = _p2p.incoming.listen(_handleP2PMessage);
  }

  void _handleP2PMessage(P2PMessage msg) {
    if (msg.type == 'inference_request') {
      final data = jsonDecode(msg.content);
      _processRemoteTask(InferenceTask(
        id: data['id'],
        type: InferenceTaskType.values.firstWhere((t) => t.name == data['type']),
        prompt: data['prompt'],
      ));
    } else if (msg.type == 'inference_result') {
      final data = jsonDecode(msg.content);
      final idx = _tasks.indexWhere((t) => t.id == data['id']);
      if (idx != -1) {
        _tasks[idx].result = data['result'];
        _tasks[idx].completed = true;
        notifyListeners();
      }
    }
  }

  Future<String> submitTask(InferenceTaskType type, String prompt, {List<String>? images}) async {
    final task = InferenceTask(
      id: 'task_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(9999)}',
      type: type,
      prompt: prompt,
      images: images,
    );
    _tasks.add(task);
    notifyListeners();

    final peers = _p2p.connectedPeers;
    if (peers.isNotEmpty) {
      task.assignedPeer = peers[_random.nextInt(peers.length)];
      _p2p.sendMessage(task.assignedPeer!, jsonEncode({
        'type': 'inference_request',
        'id': task.id,
        'type_name': type.name,
        'prompt': prompt,
      }));
    }

    _runLocal(task);

    return task.id;
  }

  Future<void> _runLocal(InferenceTask task) async {
    try {
      final body = {
        'model': _localModel,
        'messages': [
          {'role': 'user', 'content': task.prompt},
        ],
        'stream': false,
      };
      final resp = await _client.post(
        Uri.parse('$_localAiUrl/v1/chat/completions'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 60));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        task.result = data['choices'][0]['message']['content'] as String;
      } else {
        task.result = '(inference error: ${resp.statusCode})';
      }
    } catch (e) {
      task.result = '(inference error: $e)';
    }
    task.completed = true;
    notifyListeners();
  }

  Future<void> _processRemoteTask(InferenceTask task) async {
    _tasks.add(task);
    notifyListeners();
    await _runLocal(task);

    if (task.completed && !task.failed && task.result != null) {
      _p2p.broadcast(jsonEncode({
        'type': 'inference_result',
        'id': task.id,
        'result': task.result,
      }));
    }
  }

  String? getResult(String taskId) {
    try {
      return _tasks.firstWhere((t) => t.id == taskId).result;
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _p2pSub?.cancel();
    _client.close();
    super.dispose();
  }
}
