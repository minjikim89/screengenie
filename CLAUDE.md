# ScreenGenie — Project Rules

## Project Overview
- **Name**: ScreenGenie
- **Purpose**: AI screen overlay that works on top of ANY app, guiding users step-by-step
- **Hackathon**: Gemini Live Agent Challenge — Track 3: UI Navigator
- **Deadline**: 2026-03-16 (PDT 17:00)
- **Platform**: Android (Flutter)

## Tech Stack
- Mobile: Flutter (Dart) — Android app with floating overlay
- Overlay: `flutter_overlay_window` package
- Screen Capture: MediaProjection API
- Backend: FastAPI (Python 3.12) — API server on Cloud Run
- AI: Gemini Computer Use model (screen analysis) + Live API (voice)
- Cloud: Cloud Run + Firestore + Cloud Storage
- Voice: `speech_to_text` + `flutter_tts` (fallback), Gemini Live API (advanced)

## Architecture
- Flutter app creates a floating bubble on top of any app
- User taps bubble or speaks → app captures current screen (MediaProjection)
- Screenshot sent to backend → Gemini Computer Use analyzes → returns overlay data
- Flutter renders overlay: spotlight, pointer, speech bubble, subtitle bar
- User taps the target OR says "Do it" → auto-tap (AccessibilityService)

## Code Conventions
- Flutter/Dart: follow Dart style guide, use StatefulWidget/StatelessWidget
- Backend: Python, type hints, async/await
- API: RESTful, JSON responses
- All text in English (global hackathon)
- No excessive comments

## Safety Rules
- Never auto-execute high-risk actions (payment, delete, login, submit)
- Always require user confirmation for medium+ risk
- .env files must never be committed
- API keys via environment variables only

## Key Constraints
- Gemini Computer Use model coordinates: 0-999 normalized → denormalize to actual screen pixels
- Python backend required (Computer Use preview only supports Python SDK)
- All cloud infra must be on Google Cloud (hackathon requirement)
- `flutter_overlay_window` requires Android "Draw over other apps" permission
- MediaProjection requires user consent dialog each time
