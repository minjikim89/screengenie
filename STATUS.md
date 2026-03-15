# ScreenGenie — Project Status

> Track 3: UI Navigator — Gemini Live Agent Challenge
> Deadline: 2026-03-16 (PDT 17:00) = 2026-03-17 KST 09:00

## Current Phase: Gemini Integration Done — Submission Prep

## Blockers
- None

## Completed
- [x] Competitive research (2026-03-07)
- [x] Architecture design v1 — web app (2026-03-07)
- [x] Concept pivot: web app → Android Flutter overlay (2026-03-08)
- [x] PLAN.md v2 finalized (2026-03-08)
- [x] Language decision: all English (2026-03-08)
- [x] Flutter + Android SDK setup (2026-03-15)
- [x] Flutter project scaffolding (2026-03-15)
- [x] Home screen — glassmorphism card UI (2026-03-15)
- [x] Floating Genie bubble overlay (flutter_overlay_window) (2026-03-15)
- [x] Overlay UI: bubble → input → spotlight + pointer + instruction (2026-03-15)
- [x] Custom genie character + pointer finger images (2026-03-15)
- [x] Mock data flow with API fallback (2026-03-15)
- [x] FastAPI backend with mock + Gemini endpoints (2026-03-15)
- [x] Safety Gate risk classification — false positive fix (2026-03-15)
- [x] Coordinate conversion: physical pixels → dp (2026-03-15)
- [x] Adaptive instruction bubble positioning (2026-03-15)
- [x] Debug APK build + emulator install (2026-03-15)
- [x] Demo flow verified: home → start → bubble → input mode (2026-03-15)
- [x] SpotlightPainter fix: saveLayer+BlendMode.clear → PathFillType.evenOdd (2026-03-15)
- [x] Gemini API integration via google_generative_ai SDK (2026-03-15)
- [x] System prompt with 0-999 coordinate system + JSON response format (2026-03-15)
- [x] .env + build_debug.sh for secure API key management (2026-03-15)
- [x] Demo screenshot asset + fallback loading chain (2026-03-15)
- [x] MediaProjection native code (MainActivity.kt MethodChannel) (2026-03-15)
- [x] End-to-end verified: demo screenshot → Gemini 2.5 Flash → real coordinates → overlay render (2026-03-15)

## What Works (Demo Flow)
1. Home screen with glassmorphism card + custom genie avatar
2. "Start Genie" activates floating bubble overlay
3. Genie bubble floats on top of any app (tested with Chrome)
4. Tap bubble → expands to full-screen input mode
5. Suggestion chips + text input for asking questions
6. **REAL Gemini 2.5 Flash** API call with screenshot → JSON response (~5s)
7. Guidance mode: dark overlay + spotlight cutout + bouncing genie finger + instruction bubble
8. AI-generated instruction + voice_text + risk classification
9. Safety Gate: risk-aware warnings for medium/high risk actions
10. Close/dismiss returns to bubble mode

- [x] Cloud Run deployment files: Dockerfile + deploy_cloudrun.sh (2026-03-15)
- [x] Dual-mode GeminiService: direct SDK (default) + Cloud Run backend (optional) (2026-03-15)
- [x] Auto-test code removed + debug prints cleaned up (2026-03-15)

## Hackathon Requirements Checklist
- [x] Gemini model — `gemini-2.5-flash` via `google_generative_ai` SDK
- [x] Google GenAI SDK — `google_generative_ai: ^0.4.6` (Dart official SDK)
- [x] Google Cloud service — Cloud Run backend (Dockerfile + deploy script ready)
- [ ] Demo video
- [ ] Devpost submission

## Remaining Tasks (Priority Order)
1. [ ] Record demo video (requires physical device — adb tap doesn't work with overlay)
2. [ ] Deploy backend to Cloud Run (requires gcloud CLI + GCP project)
3. [ ] Devpost submission (title, description, screenshots, video)

## Demo Assets Ready (demo/ folder)
- `screenshot_home.png` — Home screen with Start Genie
- `screenshot_home_active.png` — Home screen with Stop Genie + status
- `screenshot_bubble.png` — Chrome with floating Genie bubble
- `devpost_submission.md` — Full Devpost submission draft
- `README.md` — Project README for GitHub

## Technical Decisions
| Decision | Choice | Reason |
|----------|--------|--------|
| AI model | `gemini-2.5-flash` | Latest available, fast (~5s response) |
| SDK | `google_generative_ai` (Dart) | Official Google GenAI SDK, satisfies hackathon requirement |
| Coordinate system | 0-999 normalized → denormalize to pixels | Gemini standard for spatial tasks |
| Spotlight rendering | `PathFillType.evenOdd` | `saveLayer + BlendMode.clear` doesn't work in overlay TextureView |
| Overlay height bug | Pass 915dp instead of WindowSize.matchParent | flutter_overlay_window 0.4.5 OverlayService.java:244 has inverted height condition |
| API key | `.env` → `build_debug.sh` → `--dart-define` | Secure, gitignored |
| Screenshot | MediaProjection file → demo asset fallback | Graceful degradation |

## Key Files
| File | Purpose |
|------|---------|
| `lib/main.dart` | App + overlay entry points |
| `lib/screens/home_screen.dart` | Home screen UI (glassmorphism) |
| `lib/widgets/overlay_view.dart` | Overlay: bubble, input, loading, guidance modes |
| `lib/models/overlay_data.dart` | OverlayData + Target models with mock |
| `lib/services/gemini_service.dart` | **NEW** Gemini AI integration (google_generative_ai SDK) |
| `lib/services/api_client.dart` | HTTP client for backend API (legacy) |
| `backend/Dockerfile` | **NEW** Cloud Run container config |
| `deploy_cloudrun.sh` | **NEW** GCP Cloud Run deploy script |
| `lib/utils/constants.dart` | Colors, sizes, strings, API config |
| `android/.../MainActivity.kt` | **Rewritten** MediaProjection MethodChannel |
| `backend/main.py` | FastAPI server (health + analyze) |
| `backend/core/analyzer.py` | Gemini analysis logic |
| `backend/prompts/navigation.py` | System prompt for Gemini |
| `assets/images/genie.png` | Custom genie character |
| `assets/images/genie_finger.png` | Custom pointing finger |
| `assets/images/demo_screenshot.png` | Google.com demo screenshot |
| `.env` | API key (gitignored) |
| `build_debug.sh` | Build script with API key injection |

## Build & Run
```bash
# Build with API key
./build_debug.sh

# Or manually
flutter build apk --debug --dart-define="GEMINI_API_KEY=your_key_here"

# Install
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

## Tech Stack
- Mobile: Flutter (Dart) — Android overlay
- Overlay: `flutter_overlay_window` ^0.4.5
- AI SDK: `google_generative_ai` ^0.4.6 (Dart)
- AI Model: `gemini-2.5-flash`
- Backend: FastAPI (Python 3.12) — for Cloud Run deployment
- Package: `com.screengenie.screengenie`

## Key Links
- Hackathon: https://geminiliveagentchallenge.devpost.com/
- flutter_overlay_window: https://pub.dev/packages/flutter_overlay_window
- google_generative_ai: https://pub.dev/packages/google_generative_ai
