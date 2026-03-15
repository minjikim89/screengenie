# Devpost Submission Draft

## Project Name
ScreenGenie — AI Screen Guide for Any App

## Tagline
A floating AI overlay that analyzes your screen and shows you exactly where to tap

## About

### Inspiration
Millions of people struggle with unfamiliar apps daily — especially when navigating complex settings, foreign-language interfaces, or apps they've never used before. We built ScreenGenie to make any app instantly accessible by overlaying an AI guide that sees what you see and points you in the right direction.

### What it does
ScreenGenie places a friendly AI genie bubble on top of any Android app. When you need help:
1. **Tap the floating genie** — it expands to a full-screen input mode
2. **Ask your question** — "How do I sign in?" or "Change the language"
3. **Follow the guide** — ScreenGenie captures your screen, sends it to Gemini 2.5 Flash, and renders a spotlight overlay highlighting the exact UI element you need to tap, with clear instructions and an animated pointing finger

The AI understands context from the screenshot — it identifies which app you're using, reads the interface, and provides precise coordinates for the target element.

### How we built it
- **Flutter** for the Android app with `flutter_overlay_window` to create a system-wide floating overlay
- **Gemini 2.5 Flash** via the official `google_generative_ai` Dart SDK for real-time screenshot analysis
- **Custom coordinate system** — Gemini returns 0-999 normalized coordinates that we denormalize to exact screen pixels
- **PathFillType.evenOdd** rendering for the spotlight cutout (standard BlendMode.clear doesn't work in Android overlay TextureView)
- **FastAPI backend** deployable to **Cloud Run** for server-side analysis
- **MediaProjection API** for capturing the screen underneath the overlay
- **Safety Gate** risk classification — warns users before high-risk actions (payments, deletions, logins)

### Challenges we ran into
- `flutter_overlay_window` v0.4.5 has a height bug where `matchParent` calculates incorrectly — we traced it to an inverted condition in `OverlayService.java:244` and worked around it with explicit dp values
- `saveLayer + BlendMode.clear` (the standard approach for spotlight cutouts) doesn't render on overlay's transparent `FlutterTextureView` — we solved this with `PathFillType.evenOdd`
- Coordinate conversion between Gemini's normalized 0-999 space, physical pixels, and logical dp required careful math with the device pixel ratio

### Accomplishments that we're proud of
- End-to-end AI-powered overlay that works on top of ANY Android app
- ~5 second response time from screenshot to guidance overlay
- Beautiful, polished UI with glassmorphism home screen, animated genie character, and smooth spotlight transitions
- Robust fallback chain: MediaProjection → demo screenshot → mock response

### What we learned
- Android overlay rendering has fundamentally different constraints than regular app rendering
- Gemini 2.5 Flash is remarkably accurate at identifying UI elements from screenshots and returning precise coordinates
- The `google_generative_ai` Dart SDK makes it straightforward to integrate vision capabilities

### What's next for ScreenGenie
- **Voice interaction** — Ask questions by speaking instead of typing
- **Multi-step guidance** — Guide users through complex flows with sequential steps
- **Auto-tap** — Use AccessibilityService to tap the highlighted element on user confirmation
- **Learning mode** — Remember common patterns and provide proactive suggestions

## Built With
- Flutter
- Dart
- Gemini 2.5 Flash
- Google GenAI SDK
- Cloud Run
- FastAPI
- Python
- Android MediaProjection API

## Try It Out
- [GitHub Repository](https://github.com/user/screengenie)

## Tracks
- Track 3: UI Navigator
