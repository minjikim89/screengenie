# ScreenGenie — Technical Architecture

> AI screen overlay that works on top of ANY app
> Track 3: UI Navigator — Gemini Live Agent Challenge
> Platform: Android (Flutter)

## 1. System Overview

```
┌──────────────────────────────────────────────────────┐
│              User's Android Phone                     │
│                                                      │
│   ┌──────────────────────────────────────────┐       │
│   │         Any App (Netflix, Settings, etc.) │       │
│   │                                          │       │
│   │                                  ┌────┐  │       │
│   │                                  │ 🧞 │  │ ← Floating bubble
│   │                                  └──┬─┘  │   (flutter_overlay_window)
│   └──────────────────────────────────────┘       │
│                                    │                  │
│              User taps bubble / speaks                │
│                                    │                  │
│   ┌────────────────────────────────┴─────────┐       │
│   │          ScreenGenie Flutter App          │       │
│   │                                          │       │
│   │  ┌──────────┐  ┌───────────┐  ┌───────┐ │       │
│   │  │ Screen   │  │ Overlay   │  │ Voice │ │       │
│   │  │ Capture  │  │ Renderer  │  │ I/O   │ │       │
│   │  │ (Media   │  │ (Widgets) │  │ (STT/ │ │       │
│   │  │ Project.)│  │           │  │  TTS) │ │       │
│   │  └────┬─────┘  └─────▲────┘  └───────┘ │       │
│   └───────┼──────────────┼──────────────────┘       │
│           │              │                           │
└───────────┼──────────────┼───────────────────────────┘
            │ Screenshot   │ Overlay JSON
            │ (base64 PNG) │
            ▼              │
┌──────────────────────────┴───────────────────────────┐
│              Backend (FastAPI @ Cloud Run)             │
│                                                      │
│   ┌──────────────┐  ┌────────────┐  ┌─────────────┐ │
│   │ Gemini       │  │ Safety     │  │ Overlay     │ │
│   │ Computer Use │  │ Gate       │  │ Composer    │ │
│   │ (Analysis)   │  │            │  │             │ │
│   └──────┬───────┘  └────────────┘  └─────────────┘ │
│          │                                           │
│   ┌──────┴───────┐  ┌────────────┐  ┌─────────────┐ │
│   │ Gemini API   │  │ Firestore  │  │ Cloud       │ │
│   │              │  │ (sessions) │  │ Storage     │ │
│   └──────────────┘  └────────────┘  └─────────────┘ │
└──────────────────────────────────────────────────────┘
```

## 2. Tech Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Mobile App** | Flutter (Dart) | App shell + overlay rendering |
| **Overlay** | `flutter_overlay_window` | Draw over other apps |
| **Screen Capture** | MediaProjection API | Capture current screen |
| **Voice Input** | `speech_to_text` package | Speech-to-text |
| **Voice Output** | `flutter_tts` / Gemini Live API | Text-to-speech |
| **Backend** | FastAPI (Python 3.12) | API server |
| **AI Analysis** | Gemini Computer Use model | Screenshot → coordinates + instructions |
| **AI Voice** | Gemini Live API | Real-time voice conversation |
| **Database** | Cloud Firestore | Session logs |
| **Storage** | Cloud Storage | Screenshot storage |
| **Deploy** | Cloud Run | Backend hosting |
| **SDK** | Google GenAI SDK (`google-genai`) | Gemini API access |

## 3. Project Structure

```
screengenie/
├── lib/                             # Flutter Dart source
│   ├── main.dart                    # App entry point
│   ├── app.dart                     # MaterialApp config
│   │
│   ├── services/
│   │   ├── overlay_service.dart     # Floating bubble + overlay lifecycle
│   │   ├── screen_capture.dart      # MediaProjection screenshot
│   │   ├── api_client.dart          # Backend API calls
│   │   ├── voice_service.dart       # STT/TTS
│   │   └── permission_handler.dart  # Android permissions management
│   │
│   ├── models/
│   │   ├── overlay_data.dart        # OverlayData model
│   │   └── analysis_result.dart     # Gemini response model
│   │
│   ├── widgets/
│   │   ├── genie_bubble.dart        # Floating Genie character bubble
│   │   ├── spotlight.dart           # Dark overlay + circular cutout
│   │   ├── ghost_hand.dart          # Pointing finger with bounce animation
│   │   ├── speech_bubble.dart       # Genie's instruction text
│   │   ├── subtitle_bar.dart        # Bottom instruction bar + step indicator
│   │   ├── action_buttons.dart      # Repeat / Do it / Stop buttons
│   │   └── zoom_lens.dart           # Magnification circle
│   │
│   ├── screens/
│   │   ├── home_screen.dart         # Main screen (start/stop Genie)
│   │   └── settings_screen.dart     # App settings
│   │
│   └── utils/
│       ├── constants.dart           # Colors, sizes, strings
│       └── coordinates.dart         # Gemini 0-999 → screen pixel conversion
│
├── android/                         # Android native config
│   └── app/src/main/
│       └── AndroidManifest.xml      # Permissions (SYSTEM_ALERT_WINDOW, etc.)
│
├── backend/                         # FastAPI backend
│   ├── Dockerfile
│   ├── requirements.txt
│   ├── main.py                      # FastAPI app with CORS
│   ├── core/
│   │   ├── analyzer.py              # Gemini Computer Use integration
│   │   ├── safety_gate.py           # Risk classification
│   │   └── overlay_composer.py      # Build overlay JSON from analysis
│   └── prompts/
│       └── navigation.py            # System prompt for Gemini
│
├── pubspec.yaml                     # Flutter dependencies
└── README.md
```

## 4. Core Loop

```
┌──────────────────────────────────────────────────────┐
│                  ScreenGenie Loop                     │
│                                                      │
│  ┌───────────┐    ┌──────────┐    ┌───────────────┐ │
│  │ Capture    │───▶│ Gemini   │───▶│ Safety Gate   │ │
│  │ Screen     │    │ Analyze  │    │ (risk check)  │ │
│  └───────────┘    └──────────┘    └───────┬───────┘ │
│       ▲                                    │         │
│       │                           ┌────────▼───────┐ │
│       │                           │ low/med/high?  │ │
│       │                           │ ├─ LOW → show  │ │
│       │                           │ ├─ MED → ask   │ │
│       │                           │ └─ HIGH → block│ │
│       │                           └────────┬───────┘ │
│       │                                    │         │
│  ┌────┴─────┐    ┌──────────┐    ┌────────▼───────┐ │
│  │ Next     │◀───│ Update   │◀───│ Render         │ │
│  │ Screen   │    │ State    │    │ Overlay        │ │
│  └──────────┘    └──────────┘    └────────────────┘ │
└──────────────────────────────────────────────────────┘
```

### Step-by-step

1. **Capture**: MediaProjection takes screenshot of current screen
2. **Send**: Screenshot (base64) + user question → Backend API
3. **Analyze**: Gemini Computer Use model analyzes screenshot
4. **Safety**: Check risk level of suggested action
5. **Compose**: Build OverlayData JSON (target coords, instruction, risk)
6. **Render**: Flutter draws overlay widgets on screen (spotlight, pointer, bubble)
7. **Wait**: User taps target or says "Do it"
8. **Repeat**: Capture new screen → analyze → next step

## 5. Overlay Data Protocol

```dart
// lib/models/overlay_data.dart

class OverlayData {
  final String mode;        // "idle" | "guide" | "confirm" | "block" | "complete"
  final String instruction; // Text shown in speech bubble
  final Target? target;     // Where to point
  final String risk;        // "low" | "medium" | "high"
  final bool needsConfirmation;
  final int stepIndex;
  final int stepTotal;
  final String faceState;   // "idle" | "speaking" | "thinking" | "pointing" | "celebrating"
  final String? voiceText;  // Text for TTS
}

class Target {
  final double x;           // Pixel X on screen
  final double y;           // Pixel Y on screen
  final double radius;      // Highlight circle radius
  final String label;       // Element description
}
```

## 6. Coordinate System

Gemini Computer Use outputs coordinates in 0-999 normalized range.
Convert to actual screen pixels:

```dart
// lib/utils/coordinates.dart

class CoordinateConverter {
  static Offset denormalize(int geminiX, int geminiY, Size screenSize) {
    final actualX = (geminiX / 1000) * screenSize.width;
    final actualY = (geminiY / 1000) * screenSize.height;
    return Offset(actualX, actualY);
  }
}
```

## 7. Android Permissions

```xml
<!-- android/app/src/main/AndroidManifest.xml -->

<!-- Draw over other apps (floating bubble) -->
<uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW" />

<!-- Screen capture -->
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PROJECTION" />

<!-- Microphone for voice input -->
<uses-permission android:name="android.permission.RECORD_AUDIO" />

<!-- Internet for API calls -->
<uses-permission android:name="android.permission.INTERNET" />
```

## 8. API Design

### POST /api/analyze

```json
// Request
{
  "screenshot": "<base64 PNG>",
  "question": "Where do I cancel my subscription?",
  "context": {
    "screen_width": 1080,
    "screen_height": 2400,
    "previous_steps": []
  }
}

// Response
{
  "overlay": {
    "mode": "guide",
    "instruction": "Tap the profile icon in the top-right corner.",
    "target": {
      "x": 980,
      "y": 120,
      "radius": 35,
      "label": "Profile"
    },
    "risk": "low",
    "needs_confirmation": false,
    "step_index": 1,
    "step_total": 4,
    "face_state": "pointing",
    "voice_text": "See that small circle in the top-right? Tap on it."
  }
}
```

## 9. Safety Gate

```python
# backend/core/safety_gate.py

class SafetyGate:
    HIGH_RISK_KEYWORDS = [
        "payment", "pay", "purchase", "buy",
        "delete", "remove", "unsubscribe",
        "submit", "confirm order",
        "login", "sign in", "password",
        "transfer", "send money",
    ]

    MEDIUM_RISK_KEYWORDS = [
        "settings", "account", "switch",
        "change", "update", "modify",
    ]

    def classify_risk(self, action_text: str) -> str:
        text_lower = action_text.lower()
        for kw in self.HIGH_RISK_KEYWORDS:
            if kw in text_lower:
                return "high"
        for kw in self.MEDIUM_RISK_KEYWORDS:
            if kw in text_lower:
                return "medium"
        return "low"
```

## 10. Gemini Integration

```python
# backend/core/analyzer.py

from google import genai
from google.genai import types
import base64

class ScreenAnalyzer:
    MODEL = "gemini-2.5-computer-use-preview-10-2025"

    def __init__(self):
        self.client = genai.Client()
        self.config = types.GenerateContentConfig(
            tools=[
                types.Tool(
                    computer_use=types.ComputerUse(
                        environment=types.Environment.ENVIRONMENT_BROWSER,
                    )
                )
            ],
            system_instruction=SYSTEM_PROMPT,
            thinking_config=types.ThinkingConfig(include_thoughts=True),
        )

    async def analyze(self, screenshot_b64: str, question: str) -> dict:
        contents = [
            types.Content(
                role="user",
                parts=[
                    types.Part(text=f"User question: {question}"),
                    types.Part(
                        inline_data=types.Blob(
                            mime_type="image/png",
                            data=base64.b64decode(screenshot_b64),
                        )
                    ),
                ],
            )
        ]

        response = self.client.models.generate_content(
            model=self.MODEL,
            contents=contents,
            config=self.config,
        )

        return self._parse_response(response)
```

## 11. Key Technical Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Platform | Android (Flutter) | Overlay on any app requires native access |
| Framework | Flutter (not Kotlin) | Overlay plugin simplifies OS-level work, faster UI dev |
| Screen capture | MediaProjection | Standard Android API, user-consented |
| Backend language | Python | Gemini Computer Use SDK requires Python |
| Coordinate system | 0-999 normalized | Gemini model output format |
| Voice | STT/TTS packages + Live API | Basic first, upgrade to Live API if time allows |
| Deploy | Cloud Run | Hackathon GCP requirement |
