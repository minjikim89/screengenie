import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF6C5CE7);
  static const primaryLight = Color(0xFFA29BFE);
  static const accent = Color(0xFF00CEC9);
  static const danger = Color(0xFFFF6B6B);
  static const warning = Color(0xFFFFA502);
  static const success = Color(0xFF2ED573);
  static const dark = Color(0xFF2D3436);
  static const overlay = Color(0xCC000000); // 80% black
  static const bubbleGradient = [primary, primaryLight];
}

class AppSizes {
  static const bubbleSize = 70.0;
  static const bubbleIconSize = 35.0;
  static const overlayBubbleSize = 180; // pixels for showOverlay (int)
  static const overlayBubbleSizeDp = 68; // dp for resizeOverlay (int)
  static const spotlightRadius = 55.0;
  static const instructionPadding = 20.0;
}

class AppStrings {
  static const appName = 'ScreenGenie';
  static const tagline = 'AI overlay that guides you through any app';
  static const startGenie = 'Start Genie';
  static const stopGenie = 'Stop Genie';
  static const genieActive = 'Genie is floating! Go to any app.';
  static const askPrompt = 'What do you need help with?';
  static const askHint = 'Ask anything...';
  static const analyzing = 'Analyzing screen...';
  static const tapToDismiss = 'Tap anywhere to dismiss';
}

class ApiConfig {
  // Cloud Run backend (set via --dart-define=CLOUD_RUN_URL=...)
  static const cloudRunUrl = String.fromEnvironment('CLOUD_RUN_URL');
  // Android emulator uses 10.0.2.2 to reach host machine's localhost
  static const emulatorBaseUrl = 'http://10.0.2.2:8000';
  // Use Cloud Run if configured, otherwise local
  static const baseUrl = cloudRunUrl != '' ? cloudRunUrl : emulatorBaseUrl;
  static const analyzeEndpoint = '/api/analyze';
}
