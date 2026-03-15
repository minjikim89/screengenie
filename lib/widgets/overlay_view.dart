import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import '../models/overlay_data.dart';
import '../services/gemini_service.dart';
import '../utils/constants.dart';

class OverlayView extends StatefulWidget {
  const OverlayView({super.key});

  @override
  State<OverlayView> createState() => _OverlayViewState();
}

class _OverlayViewState extends State<OverlayView> {
  bool _expanded = false;
  OverlayData? _guidanceData;
  final _geminiService = GeminiService();
  bool _loading = false;
  final _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  void _onBubbleTap() async {
    if (!_expanded) {
      try {
        const overlayChannel = MethodChannel('x-slayer/overlay');
        await overlayChannel.invokeMethod('updateOverlayPosition', {'x': 0, 'y': 0});
      } catch (_) {}
      // NOTE: WindowSize.matchParent (-1) is buggy for height in flutter_overlay_window 0.4.5.
      // Workaround: pass screen height in dp (2400px / 2.625 = ~915dp).
      await FlutterOverlayWindow.resizeOverlay(
        WindowSize.matchParent,
        915,
        false,
      );
      setState(() => _expanded = true);
    }
  }

  void _onDismiss() async {
    await FlutterOverlayWindow.resizeOverlay(
      AppSizes.overlayBubbleSizeDp,
      AppSizes.overlayBubbleSizeDp,
      true,
    );
    setState(() {
      _expanded = false;
      _guidanceData = null;
      _loading = false;
      _textController.clear();
    });
  }

  Future<Uint8List> _loadScreenshot() async {
    final capturedFile = File(
      '/data/data/com.screengenie.screengenie/files/screenshot.png',
    );
    if (await capturedFile.exists()) {
      return await capturedFile.readAsBytes();
    }
    final byteData = await rootBundle.load('assets/images/demo_screenshot.png');
    return byteData.buffer.asUint8List();
  }

  Future<void> _onSubmitQuestion(String question) async {
    if (question.trim().isEmpty) return;
    setState(() => _loading = true);

    try {
      final screenshotBytes = await _loadScreenshot();
      final result = await _geminiService.analyze(
        screenshotBytes: screenshotBytes,
        question: question,
        screenWidth: 1080,
        screenHeight: 2400,
      );
      setState(() {
        _guidanceData = result;
        _loading = false;
      });
    } catch (e) {
      debugPrint('[ScreenGenie] Gemini error: $e');
      setState(() {
        _guidanceData = OverlayData.mock(question);
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _geminiService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_expanded) return _buildBubble();
    if (_loading) return _buildLoading();
    if (_guidanceData != null) return _buildGuidance();
    return _buildInputMode();
  }

  // ─── Bubble mode (small floating circle) ────────────────────
  Widget _buildBubble() {
    return GestureDetector(
      onTap: _onBubbleTap,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Image.asset('assets/images/genie.png', fit: BoxFit.contain),
      ),
    );
  }

  // ─── Loading state ──────────────────────────────────────────
  Widget _buildLoading() {
    return Container(
      color: Colors.black.withValues(alpha: 0.7),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/genie.png', width: 100, height: 100),
            const SizedBox(height: 20),
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                color: AppColors.primaryLight,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              AppStrings.analyzing,
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Input mode (ask question) ──────────────────────────────
  Widget _buildInputMode() {
    return Container(
      color: Colors.black.withValues(alpha: 0.85),
      child: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: GestureDetector(
                  onTap: _onDismiss,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 24),
                  ),
                ),
              ),
            ),
            const Spacer(),
            Image.asset('assets/images/genie.png', width: 120, height: 120),
            const SizedBox(height: 20),
            const Text(
              AppStrings.askPrompt,
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _suggestionChip('Change language'),
                  _suggestionChip('How to sign in'),
                  _suggestionChip('Switch profile'),
                  _suggestionChip('Search by image'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 20),
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                        decoration: const InputDecoration(
                          hintText: AppStrings.askHint,
                          hintStyle: TextStyle(color: Colors.white38),
                          border: InputBorder.none,
                        ),
                        onSubmitted: _onSubmitQuestion,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _onSubmitQuestion(_textController.text),
                      child: Container(
                        margin: const EdgeInsets.all(6),
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: AppColors.bubbleGradient,
                          ),
                        ),
                        child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _suggestionChip(String text) {
    return GestureDetector(
      onTap: () => _onSubmitQuestion(text),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Text(
          text,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
      ),
    );
  }

  // ─── Guidance mode (spotlight + genie + speech bubble) ──────
  Widget _buildGuidance() {
    final data = _guidanceData!;
    final screenSize = MediaQuery.of(context).size;
    final dpr = MediaQuery.of(context).devicePixelRatio;

    final targetXDp = (data.target?.x ?? 540) / dpr;
    final targetYDp = (data.target?.y ?? 600) / dpr;
    final radiusDp = (data.target?.radius ?? AppSizes.spotlightRadius) / dpr * 1.8;

    final clampedX = targetXDp.clamp(radiusDp, screenSize.width - radiusDp);
    final clampedY = targetYDp.clamp(radiusDp, screenSize.height - radiusDp);
    final targetInTopHalf = clampedY < screenSize.height * 0.5;

    // Genie: prefer LEFT of spotlight, fallback RIGHT
    const genieSize = 70.0;
    final spaceOnLeft = clampedX - radiusDp - 16;
    final genieOnLeft = spaceOnLeft >= genieSize;
    double genieLeft = genieOnLeft
        ? clampedX - radiusDp - genieSize - 4
        : clampedX + radiusDp + 4;
    genieLeft = genieLeft.clamp(8.0, screenSize.width - genieSize - 8);
    final genieTop = (clampedY - genieSize * 0.3)
        .clamp(50.0, screenSize.height - genieSize - 100);

    // Speech bubble: NEXT TO genie (horizontal)
    // Try right of genie → left of genie → fallback below
    double bubbleLeft, bubbleRight, bubbleTop;
    final rightSpace = screenSize.width - genieLeft - genieSize - 18;
    final leftSpace = genieLeft - 18;

    if (rightSpace >= 140) {
      // Bubble to the RIGHT of genie
      bubbleLeft = genieLeft + genieSize + 6;
      bubbleRight = 12;
      bubbleTop = genieTop + 8;
    } else if (leftSpace >= 140) {
      // Bubble to the LEFT of genie
      bubbleLeft = 12;
      bubbleRight = screenSize.width - genieLeft + 6;
      bubbleTop = genieTop + 8;
    } else {
      // Fallback: below genie
      bubbleLeft = 12;
      bubbleRight = 12;
      bubbleTop = genieTop + genieSize + 8;
    }

    return GestureDetector(
      onTap: _onDismiss,
      child: Stack(
        children: [
          // Spotlight overlay
          CustomPaint(
            size: Size.infinite,
            painter: SpotlightPainter(
              targetX: clampedX,
              targetY: clampedY,
              radius: radiusDp,
            ),
          ),

          // Floating genie near spotlight
          if (data.target != null)
            Positioned(
              left: genieLeft,
              top: genieTop,
              child: const _FloatingGenie(),
            ),

          // Speech bubble next to genie
          Positioned(
            left: bubbleLeft,
            right: bubbleRight,
            top: bubbleTop,
            child: _buildSpeechBubble(data),
          ),

          // Dismiss hint
          const Positioned(
            left: 0,
            right: 0,
            bottom: 16,
            child: Text(
              AppStrings.tapToDismiss,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ),

          // Close button
          Positioned(
            right: 16,
            top: 40,
            child: GestureDetector(
              onTap: _onDismiss,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.5),
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeechBubble(OverlayData data) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.93),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.15),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            data.instruction,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
          if (data.voiceText != null) ...[
            const SizedBox(height: 6),
            Text(
              data.voiceText!,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black45,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          if (data.risk == 'medium' || data.risk == 'high') ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: data.risk == 'high'
                    ? AppColors.danger.withValues(alpha: 0.1)
                    : AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                data.risk == 'high'
                    ? 'High risk — please confirm before proceeding'
                    : 'This action may modify settings',
                style: TextStyle(
                  fontSize: 12,
                  color: data.risk == 'high' ? AppColors.danger : AppColors.warning,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Floating genie animation widget ─────────────────────────────
class _FloatingGenie extends StatefulWidget {
  const _FloatingGenie();

  @override
  State<_FloatingGenie> createState() => _FloatingGenieState();
}

class _FloatingGenieState extends State<_FloatingGenie>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween(begin: 0.0, end: 8.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -_animation.value),
          child: child,
        );
      },
      child: Image.asset('assets/images/genie.png', width: 70, height: 70),
    );
  }
}

// ─── Spotlight painter (dark overlay with circular cutout) ──────
class SpotlightPainter extends CustomPainter {
  final double targetX;
  final double targetY;
  final double radius;

  SpotlightPainter({
    required this.targetX,
    required this.targetY,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Use evenOdd fill to punch a transparent hole — works reliably in overlay TextureView
    // (saveLayer + BlendMode.clear doesn't render on overlay's transparent background)
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(Rect.fromCircle(center: Offset(targetX, targetY), radius: radius))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, Paint()..color = Colors.black.withValues(alpha: 0.65));

    // Glowing ring around spotlight
    canvas.drawCircle(
      Offset(targetX, targetY),
      radius + 2,
      Paint()
        ..color = AppColors.primaryLight
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // Outer glow
    canvas.drawCircle(
      Offset(targetX, targetY),
      radius + 6,
      Paint()
        ..color = AppColors.primaryLight.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant SpotlightPainter old) {
    return old.targetX != targetX || old.targetY != targetY || old.radius != radius;
  }
}
