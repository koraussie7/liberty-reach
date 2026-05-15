import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class HomeVideo {
  final String id;
  final String title;
  final String videoUrl;
  final String? thumbnailUrl;
  final int viewCount;

  HomeVideo({
    required this.id,
    required this.title,
    required this.videoUrl,
    this.thumbnailUrl,
    this.viewCount = 0,
  });

  factory HomeVideo.fromJson(Map<String, dynamic> json) => HomeVideo(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? 'Untitled',
        videoUrl: json['video_url'] as String? ?? '',
        thumbnailUrl: json['thumbnail_url'] as String?,
        viewCount: json['view_count'] as int? ?? 0,
      );
}

class HomeService {
  final String _baseUrl = 'https://muhantube.com';
  final http.Client _client;

  HomeService() : _client = http.Client();

  Future<List<HomeVideo>> getFeed() async {
    try {
      final response = await _client
          .get(Uri.parse('$_baseUrl/home/feed'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = data['data'] as List? ?? [];
        if (list.isNotEmpty) {
          return list.map((e) => HomeVideo.fromJson(e as Map<String, dynamic>)).toList();
        }
      }
    } catch (e) {
      debugPrint('[Home] Feed error: $e');
    }
    return [];
  }

  void dispose() {
    _client.close();
  }
}
