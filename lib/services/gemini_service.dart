import 'dart:convert';
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import '../models/overlay_data.dart';
import '../utils/constants.dart';

const _systemPrompt = '''You are ScreenGenie, an AI assistant that helps users navigate any app on their Android phone.

You will receive a screenshot of the user's current screen and their question about how to do something.

Your task:
1. Analyze the screenshot to understand which app/screen the user is on
2. Identify the UI element the user needs to tap
3. Return the EXACT coordinates (in the 0-999 normalized range) of the target element
4. Provide a clear, friendly instruction

Response format (JSON only, no markdown):
{
  "target": {
    "gemini_x": <0-999 integer>,
    "gemini_y": <0-999 integer>,
    "label": "<element description>"
  },
  "instruction": "<clear action instruction>",
  "voice_text": "<friendly conversational version of the instruction>",
  "risk": "low",
  "step_index": 1,
  "step_total": 1,
  "needs_confirmation": false
}

Guidelines:
- Be precise with coordinates — point to the CENTER of the target element
- Use simple, non-technical language in instructions
- Start instructions with friendly words like "Right here!", "Here!", "Just tap", "Found it!" to feel warm and encouraging
- Keep instructions short (1-2 sentences max)
- voice_text should be conversational, warm, and encouraging — like a helpful friend guiding you
- If the target action involves payments, deletion, or login, set risk to "high"
- If the action modifies settings, set risk to "medium"
- For simple navigation, set risk to "low"
- If you can't find the target, set target coordinates to the most relevant element and explain
''';

class GeminiService {
  static const _apiKey = String.fromEnvironment('GEMINI_API_KEY');

  GenerativeModel? _model;
  final http.Client _httpClient = http.Client();

  /// True when Cloud Run backend is configured
  bool get _useCloudRun => ApiConfig.cloudRunUrl.isNotEmpty;

  GeminiService() {
    if (_apiKey.isNotEmpty && !_useCloudRun) {
      _model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: _apiKey,
        systemInstruction: Content.system(_systemPrompt),
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
        ),
      );
    }
  }

  bool get hasApiKey => _apiKey.isNotEmpty || _useCloudRun;

  Future<OverlayData> analyze({
    required Uint8List screenshotBytes,
    required String question,
    required int screenWidth,
    required int screenHeight,
  }) async {
    if (_useCloudRun) {
      return _analyzeViaCloudRun(
        screenshotBytes: screenshotBytes,
        question: question,
        screenWidth: screenWidth,
        screenHeight: screenHeight,
      );
    }
    return _analyzeDirectly(
      screenshotBytes: screenshotBytes,
      question: question,
      screenWidth: screenWidth,
      screenHeight: screenHeight,
    );
  }

  /// Direct Gemini SDK call (default)
  Future<OverlayData> _analyzeDirectly({
    required Uint8List screenshotBytes,
    required String question,
    required int screenWidth,
    required int screenHeight,
  }) async {
    if (_model == null) {
      throw Exception('GEMINI_API_KEY not configured');
    }

    final content = [
      Content.multi([
        TextPart('User question: $question'),
        DataPart('image/png', screenshotBytes),
      ]),
    ];

    final response = await _model!.generateContent(content);
    final text = response.text;

    if (text == null || text.isEmpty) {
      throw Exception('Empty response from Gemini');
    }

    final result = jsonDecode(text) as Map<String, dynamic>;
    return _buildOverlayData(result, screenWidth, screenHeight);
  }

  /// Cloud Run backend call (when CLOUD_RUN_URL is set)
  Future<OverlayData> _analyzeViaCloudRun({
    required Uint8List screenshotBytes,
    required String question,
    required int screenWidth,
    required int screenHeight,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.analyzeEndpoint}');
    final screenshotB64 = base64Encode(screenshotBytes);

    final response = await _httpClient.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'screenshot': screenshotB64,
        'question': question,
        'context': {
          'screen_width': screenWidth,
          'screen_height': screenHeight,
          'previous_steps': [],
        },
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Cloud Run error: ${response.statusCode}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final overlay = body['overlay'] as Map<String, dynamic>? ?? body;
    return OverlayData.fromCloudRun(overlay);
  }

  OverlayData _buildOverlayData(
    Map<String, dynamic> result,
    int screenWidth,
    int screenHeight,
  ) {
    final target = result['target'] as Map<String, dynamic>?;
    final geminiX = (target?['gemini_x'] as num?)?.toDouble() ?? 500;
    final geminiY = (target?['gemini_y'] as num?)?.toDouble() ?? 500;

    // Denormalize 0-999 to screen pixels
    final pixelX = (geminiX / 1000) * screenWidth;
    final pixelY = (geminiY / 1000) * screenHeight;

    final instruction =
        result['instruction'] as String? ?? 'Tap the highlighted area.';
    final risk = result['risk'] as String? ?? 'low';

    return OverlayData(
      mode: 'guide',
      instruction: instruction,
      target: Target(
        x: pixelX,
        y: pixelY,
        radius: 55,
        label: target?['label'] as String? ?? 'Target',
      ),
      risk: risk,
      needsConfirmation:
          result['needs_confirmation'] as bool? ?? (risk != 'low'),
      stepIndex: result['step_index'] as int? ?? 1,
      stepTotal: result['step_total'] as int? ?? 1,
      faceState: 'pointing',
      voiceText: result['voice_text'] as String?,
    );
  }

  void dispose() {
    _httpClient.close();
  }
}
