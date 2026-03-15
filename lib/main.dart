import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'widgets/overlay_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ScreenGenieApp());
}

/// Overlay entry point — runs in a separate Flutter engine
/// This is called by flutter_overlay_window when the overlay service starts
@pragma("vm:entry-point")
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Material(
      color: Colors.transparent,
      child: OverlayView(),
    ),
  ));
}

class ScreenGenieApp extends StatelessWidget {
  const ScreenGenieApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ScreenGenie',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C5CE7),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
