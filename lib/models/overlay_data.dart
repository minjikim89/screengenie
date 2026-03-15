class Target {
  final double x;
  final double y;
  final double radius;
  final String label;

  const Target({
    required this.x,
    required this.y,
    required this.radius,
    required this.label,
  });

  factory Target.fromJson(Map<String, dynamic> json) {
    return Target(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      radius: (json['radius'] as num).toDouble(),
      label: json['label'] as String,
    );
  }
}

class OverlayData {
  final String mode; // idle | guide | confirm | block | complete
  final String instruction;
  final Target? target;
  final String risk; // low | medium | high
  final bool needsConfirmation;
  final int stepIndex;
  final int stepTotal;
  final String faceState; // idle | speaking | thinking | pointing | celebrating
  final String? voiceText;

  const OverlayData({
    required this.mode,
    required this.instruction,
    this.target,
    required this.risk,
    required this.needsConfirmation,
    required this.stepIndex,
    required this.stepTotal,
    required this.faceState,
    this.voiceText,
  });

  factory OverlayData.fromJson(Map<String, dynamic> json) {
    final overlay = json['overlay'] as Map<String, dynamic>;
    return OverlayData(
      mode: overlay['mode'] as String,
      instruction: overlay['instruction'] as String,
      target: overlay['target'] != null
          ? Target.fromJson(overlay['target'] as Map<String, dynamic>)
          : null,
      risk: overlay['risk'] as String,
      needsConfirmation: overlay['needs_confirmation'] as bool? ?? false,
      stepIndex: overlay['step_index'] as int? ?? 1,
      stepTotal: overlay['step_total'] as int? ?? 1,
      faceState: overlay['face_state'] as String? ?? 'pointing',
      voiceText: overlay['voice_text'] as String?,
    );
  }

  /// Parse Cloud Run backend response (overlay object already extracted)
  factory OverlayData.fromCloudRun(Map<String, dynamic> overlay) {
    return OverlayData(
      mode: overlay['mode'] as String? ?? 'guide',
      instruction: overlay['instruction'] as String? ?? 'Tap the highlighted area.',
      target: overlay['target'] != null
          ? Target.fromJson(overlay['target'] as Map<String, dynamic>)
          : null,
      risk: overlay['risk'] as String? ?? 'low',
      needsConfirmation: overlay['needs_confirmation'] as bool? ?? false,
      stepIndex: overlay['step_index'] as int? ?? 1,
      stepTotal: overlay['step_total'] as int? ?? 1,
      faceState: overlay['face_state'] as String? ?? 'pointing',
      voiceText: overlay['voice_text'] as String?,
    );
  }

  /// Mock responses — coordinates match real UI elements on screen
  factory OverlayData.mock(String question) {
    final q = question.toLowerCase();

    // Google.com — change language (English link at bottom)
    if (q.contains('language') || q.contains('언어') || q.contains('english')) {
      return const OverlayData(
        mode: 'guide',
        instruction: 'Tap "English" to switch Google to English.',
        target: Target(x: 560, y: 710, radius: 60, label: 'English'),
        risk: 'low',
        needsConfirmation: false,
        stepIndex: 1,
        stepTotal: 2,
        faceState: 'pointing',
        voiceText: 'See the language link below the search bar? Tap it to switch.',
      );
    }

    // Google.com — sign in (로그인 button top-right)
    if (q.contains('sign in') || q.contains('login') || q.contains('로그인') || q.contains('account')) {
      return const OverlayData(
        mode: 'guide',
        instruction: 'Tap "Sign in" to log into your Google account.',
        target: Target(x: 940, y: 260, radius: 55, label: 'Sign in'),
        risk: 'low',
        needsConfirmation: false,
        stepIndex: 1,
        stepTotal: 3,
        faceState: 'pointing',
        voiceText: 'The Sign in button is in the top-right corner.',
      );
    }

    // Google.com — search by image (camera icon in search bar)
    if (q.contains('image') || q.contains('photo') || q.contains('camera') || q.contains('이미지')) {
      return const OverlayData(
        mode: 'guide',
        instruction: 'Tap the camera icon to search by image.',
        target: Target(x: 890, y: 640, radius: 45, label: 'Camera'),
        risk: 'low',
        needsConfirmation: false,
        stepIndex: 1,
        stepTotal: 2,
        faceState: 'pointing',
        voiceText: 'Look for the camera icon inside the search bar.',
      );
    }

    // Google.com — open menu (hamburger ≡)
    if (q.contains('menu') || q.contains('setting') || q.contains('설정')) {
      return const OverlayData(
        mode: 'guide',
        instruction: 'Tap the menu icon to access Google settings.',
        target: Target(x: 80, y: 260, radius: 45, label: 'Menu'),
        risk: 'low',
        needsConfirmation: false,
        stepIndex: 1,
        stepTotal: 2,
        faceState: 'pointing',
        voiceText: 'The hamburger menu is in the top-left corner.',
      );
    }

    // Netflix / streaming — switch profile
    if (q.contains('profile') || q.contains('프로필') || q.contains('switch')) {
      return const OverlayData(
        mode: 'guide',
        instruction: 'Tap your profile icon to switch accounts.',
        target: Target(x: 1000, y: 100, radius: 45, label: 'Profile'),
        risk: 'low',
        needsConfirmation: false,
        stepIndex: 1,
        stepTotal: 2,
        faceState: 'pointing',
        voiceText: 'Your profile icon is in the top-right corner. Tap to switch.',
      );
    }

    // Subscription / cancel — medium risk
    if (q.contains('cancel') || q.contains('unsubscribe') || q.contains('subscription') || q.contains('구독')) {
      return const OverlayData(
        mode: 'confirm',
        instruction: 'Tap "Account" to manage your subscription.',
        target: Target(x: 1000, y: 100, radius: 45, label: 'Account'),
        risk: 'medium',
        needsConfirmation: true,
        stepIndex: 1,
        stepTotal: 4,
        faceState: 'pointing',
        voiceText: 'Let\'s start by opening your account settings.',
      );
    }

    // Delete / remove — high risk
    if (q.contains('delete') || q.contains('remove') || q.contains('삭제')) {
      return const OverlayData(
        mode: 'confirm',
        instruction: 'This will permanently delete data. Are you sure?',
        target: Target(x: 540, y: 800, radius: 55, label: 'Delete'),
        risk: 'high',
        needsConfirmation: true,
        stepIndex: 1,
        stepTotal: 2,
        faceState: 'pointing',
        voiceText: 'Warning: this action cannot be undone.',
      );
    }

    // Generic fallback
    return OverlayData(
      mode: 'guide',
      instruction: 'I found what you\'re looking for. Tap the highlighted area.',
      target: const Target(x: 540, y: 500, radius: 55, label: 'Target'),
      risk: 'low',
      needsConfirmation: false,
      stepIndex: 1,
      stepTotal: 1,
      faceState: 'pointing',
      voiceText: 'Tap the highlighted area on your screen.',
    );
  }
}
