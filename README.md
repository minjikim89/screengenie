# ScreenGenie

**AI overlay that guides you through any app** — Gemini Live Agent Challenge, Track 3: UI Navigator

ScreenGenie is an Android app that places an AI-powered floating assistant on top of any app. Users tap the genie bubble, ask a question about what they see on screen, and ScreenGenie uses **Gemini 2.5 Flash** to analyze the screenshot and highlight exactly where to tap — with a spotlight overlay, animated pointer, and clear instructions.

## Demo

https://github.com/user-attachments/assets/demo.mp4

## How It Works

1. **Tap Genie** — A floating bubble sits on top of any app
2. **Ask** — Type or select a question about what you need help with
3. **Follow** — ScreenGenie highlights the exact UI element to tap with a spotlight overlay

## Architecture

```
┌─────────────────────────────────────────────┐
│                  Flutter App                 │
│  ┌──────────┐  ┌──────────┐  ┌───────────┐ │
│  │   Home    │  │ Overlay  │  │  Gemini   │ │
│  │  Screen   │  │  View    │  │  Service  │ │
│  └──────────┘  └──────────┘  └───────────┘ │
│       │              │              │        │
│  Start Genie    Bubble/Input    SDK Call     │
│       │         Guidance         │           │
│       ▼              │     ┌─────▼──────┐   │
│  flutter_overlay     │     │ Gemini 2.5  │   │
│  _window             │     │   Flash     │   │
│                      │     └────────────┘   │
│                      ▼                       │
│              ┌──────────────┐                │
│              │  Screenshot  │                │
│              │  (MediaProj) │                │
│              └──────────────┘                │
└─────────────────────────────────────────────┘
         ┌──────────────────────┐
         │  Cloud Run Backend   │
         │  FastAPI + Gemini    │
         │  (optional)          │
         └──────────────────────┘
```

## Features

- **Floating overlay** — Works on top of any Android app using `flutter_overlay_window`
- **Real AI analysis** — Gemini 2.5 Flash analyzes screenshots and returns precise UI element coordinates
- **Spotlight guidance** — Dark overlay with circular cutout highlighting the target element
- **Animated genie** — Floating genie character near the target with speech bubble
- **Risk classification** — Safety gate warns users before high-risk actions (payments, deletions)
- **Dual-mode backend** — Direct Gemini SDK call (default) or Cloud Run backend

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Mobile | Flutter (Dart) — Android |
| Overlay | `flutter_overlay_window` ^0.4.5 |
| AI Model | Gemini 2.5 Flash |
| AI SDK | `google_generative_ai` ^0.4.6 (official Dart SDK) |
| Backend | FastAPI (Python 3.12) on Cloud Run |
| Screen Capture | Android MediaProjection API |

## Google Cloud Services

- **Gemini 2.5 Flash** — AI model for screenshot analysis and UI element detection
- **Cloud Run** — Backend API deployment (FastAPI + Gemini analyzer)

## Setup

### Prerequisites
- Flutter SDK 3.11+
- Android SDK with emulator or device
- Gemini API key ([Get one here](https://aistudio.google.com/apikey))

### Build & Run

```bash
# 1. Clone and setup
git clone https://github.com/minjikim89/screengenie.git
cd screengenie

# 2. Add your API key
echo "GEMINI_API_KEY=your_key_here" > .env

# 3. Build
./build_debug.sh

# 4. Install on device/emulator
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

### Cloud Run Backend

The backend is deployed at: `https://screengenie-api-221297690016.us-central1.run.app`

```bash
# Health check
curl https://screengenie-api-221297690016.us-central1.run.app/health

# Build APK with Cloud Run backend
CLOUD_RUN_URL=https://screengenie-api-221297690016.us-central1.run.app ./build_debug.sh

# Or deploy your own instance
export GCP_PROJECT_ID=your-project-id
./deploy_cloudrun.sh
```

## Project Structure

```
screengenie/
├── lib/
│   ├── main.dart                 # App + overlay entry points
│   ├── screens/home_screen.dart  # Home UI (glassmorphism card)
│   ├── widgets/overlay_view.dart # Overlay: bubble → input → guidance
│   ├── models/overlay_data.dart  # Data models + mock responses
│   ├── services/
│   │   ├── gemini_service.dart   # Gemini AI integration (dual-mode)
│   │   └── api_client.dart       # HTTP client for Cloud Run
│   └── utils/constants.dart      # Theme, sizes, config
├── android/.../MainActivity.kt   # MediaProjection screen capture
├── backend/
│   ├── main.py                   # FastAPI server
│   ├── core/analyzer.py          # Gemini analysis logic
│   ├── core/safety_gate.py       # Risk classification
│   ├── prompts/navigation.py     # System prompt
│   └── Dockerfile                # Cloud Run container
├── assets/images/                # Genie character + demo screenshot
├── build_debug.sh                # Build script with API key
└── deploy_cloudrun.sh            # Cloud Run deploy script
```

## Hackathon

- **Challenge**: [Gemini Live Agent Challenge](https://geminiliveagentchallenge.devpost.com/)
- **Track**: Track 3 — UI Navigator
- **Requirements**: Gemini model + Google GenAI SDK + Google Cloud service
