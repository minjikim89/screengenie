import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/overlay_data.dart';
import '../utils/constants.dart';

class ApiClient {
  final String baseUrl;
  final http.Client _client;

  ApiClient({
    this.baseUrl = ApiConfig.baseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  Future<OverlayData> analyze({
    required String screenshotBase64,
    required String question,
    required int screenWidth,
    required int screenHeight,
    List<String>? previousSteps,
  }) async {
    final uri = Uri.parse('$baseUrl${ApiConfig.analyzeEndpoint}');

    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'screenshot': screenshotBase64,
        'question': question,
        'context': {
          'screen_width': screenWidth,
          'screen_height': screenHeight,
          'previous_steps': previousSteps ?? [],
        },
      }),
    );

    if (response.statusCode == 200) {
      return OverlayData.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('API error: ${response.statusCode} - ${response.body}');
    }
  }

  void dispose() {
    _client.close();
  }
}
