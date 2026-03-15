# ScreenGenie 기획서 v2

> 어떤 앱 위에서든 작동하는 AI 화면 안내 오버레이
> Gemini Live Agent Challenge — Track 3: UI Navigator
> 마감: 2026-03-16 (PDT 17:00)

---

## 1. 프로젝트 개요

### 한 줄 정의

**아무 앱 위에 떠서, 음성으로 물어보면 화면을 분석하고 "여기 누르세요" 하고 가리켜주는 AI 오버레이 앱**

### 제품명

- **ScreenGenie** — Your AI screen guide
- 캐릭터: **Genie** — 플로팅 버블로 항상 대기

### v1 → v2 피봇

| v1 (폐기) | v2 (현재) |
|-----------|-----------|
| 웹앱 (Next.js) | **Android 앱 (Flutter)** |
| 가짜 데모앱 3개 안에서만 작동 | **아무 앱 위에서 작동** |
| 특정 시나리오만 가능 | **아무 질문이나 가능** |
| Lovable/Replit로 개발 | **Android Studio + Claude Code** |
| 브라우저 전용 | **모바일 네이티브** |

### 해결하는 문제

| 문제 | 구체적 상황 |
|------|------------|
| **화면에서 길을 잃음** | 어디를 눌러야 하는지 모름 (설정, 해지, 로그인 등) |
| **텍스트 안내 한계** | "오른쪽 상단 설정 클릭" — 어디인지 모름 |
| **검색해도 답 못 찾음** | 구글링 → 스크린샷 없는 텍스트 설명 → 포기 |
| **누군가에게 물어보기 민망** | 간단한 건데 매번 물어봐야 함 |

### 핵심 차별점

**"말로 설명"이 아니라 "지금 내 화면 위에서 가리켜 줌"**

- 기존 CUA: 별도 브라우저에서 자동 조작 → 내 화면이 아님
- 기존 챗봇: 텍스트로 설명 → 내 화면에서 못 찾음
- **ScreenGenie**: 내가 쓰고 있는 앱 **바로 위에** 손가락이 뜸

### 경쟁 환경

| 제품 | 방식 | ScreenGenie 차별점 |
|------|------|-------------------|
| Gemini CUA | 별도 브라우저 자동 조작 | 사용자 화면 위 오버레이 |
| Claude Computer Use | 별도 데스크탑 자동 조작 | 모바일, 오버레이 방식 |
| Techy Seniors | 웹 AI 비서 (오버레이 미출시) | 실제 작동하는 오버레이 |
| ScreenHelp | 스크린샷 → 텍스트 답변 | 실시간 화면 위 안내 |
| 구글 Circle to Search | 화면 검색 | 검색이 아닌 액션 안내 |

**핵심**: "지금 내 화면을 AI가 보고, 내 화면 위에 안내를 띄워주는" 제품은 없음.

---

## 2. 동작 방식

### 사용자 플로우

```
1. ScreenGenie 앱 실행 → Genie 버블이 화면에 뜸
2. 아무 앱으로 전환 (Netflix, 설정, 카카오택시 등)
3. Genie 버블 탭 or 음성: "Where do I cancel my subscription?"
4. Genie가 현재 화면 캡처 → Gemini 분석
5. "Tap here" + 스포트라이트 + 포인터가 화면 위에 뿅
6. 사용자 탭 → 새 화면 → 다시 분석 → 다음 안내
7. 완료: "Done! Your subscription is cancelled."
```

### 시스템 플로우

```
┌──────────────────────────────────┐
│     User's Phone (Any App)       │
│                                  │
│  ┌─────┐  Floating Bubble        │
│  │ 🧞  │  (flutter_overlay_window)│
│  └──┬──┘                        │
│     │ Tap / Voice                │
│     ▼                            │
│  ┌──────────────┐               │
│  │ MediaProjection│  Screen capture│
│  └──────┬───────┘               │
│         │ Screenshot (PNG)       │
└─────────┼────────────────────────┘
          │ HTTPS
          ▼
┌──────────────────────────────────┐
│   Backend (FastAPI @ Cloud Run)  │
│                                  │
│  Screenshot + Question           │
│         │                        │
│         ▼                        │
│  ┌──────────────┐               │
│  │ Gemini        │               │
│  │ Computer Use  │ → Analyze     │
│  │ Model         │ → Coordinates │
│  └──────┬───────┘               │
│         │                        │
│         ▼                        │
│  ┌──────────────┐               │
│  │ Overlay       │               │
│  │ Composer      │ → JSON        │
│  └──────────────┘               │
│                                  │
│  Firestore (logs)                │
│  Cloud Storage (screenshots)     │
└──────────┬───────────────────────┘
           │ Overlay JSON
           ▼
┌──────────────────────────────────┐
│   Flutter Overlay Rendering      │
│                                  │
│  🔦 Spotlight (highlight target) │
│  👆 Pointer (bounce animation)   │
│  💬 Speech bubble ("Tap here!")  │
│  📝 Subtitle bar                │
└──────────────────────────────────┘
```

### Gemini 모델 활용

| 모델 | 용도 |
|------|------|
| **Computer Use** (`gemini-2.5-computer-use-preview`) | 스크린샷 분석 → 어디를 눌러야 하는지 좌표 추출 |
| **Live API** (`gemini-2.5-flash-native-audio`) | 실시간 음성 대화 (질문 → 답변) |
| **Gemini + Google Search** | "How to cancel Netflix" 웹 검색 → 절차 파악 |

---

## 3. 핵심 기능

### 기본 기능 (Must Have)

| 기능 | 설명 |
|------|------|
| **Floating Bubble** | 어떤 앱 위에서든 Genie 버블이 떠있음 |
| **Screen Capture** | 현재 화면 스크린샷 (MediaProjection) |
| **AI Analysis** | Gemini가 화면 분석 → 타깃 좌표 반환 |
| **Overlay Guide** | 스포트라이트 + 포인터 + 말풍선으로 안내 |
| **Voice Input** | 음성으로 질문 (STT → Gemini) |
| **Step-by-step** | 여러 단계를 하나씩 안내 (1/5, 2/5...) |

### 고급 기능 (Should Have)

| 기능 | 설명 |
|------|------|
| **Voice Output** | Gemini Live API 또는 TTS로 음성 안내 |
| **Auto-tap (Toggle)** | "Do it for me" → 자동 클릭 (AccessibilityService) |
| **Web Search** | 모르는 앱 → 웹 검색으로 절차 파악 후 안내 |
| **Safety Gate** | 결제/삭제/로그인 등 위험 동작 차단 |

### Bonus (Nice to Have)

| 기능 | 설명 |
|------|------|
| **History** | 이전 안내 기록 (Firestore) |
| **Multi-language** | 영어/한국어/일본어 안내 전환 |
| **Hands-free mode** | 완전 음성 제어 (핸즈프리) |

---

## 4. UX 설계

### Genie 버블 (항상 떠있음)

```
┌──────────────────────────────────────┐
│                                      │
│   사용자가 쓰고 있는 아무 앱           │
│                                      │
│                                      │
│                                      │
│                              ┌────┐  │
│                              │ 🧞 │  │ ← Floating bubble
│                              └────┘  │   드래그로 위치 이동 가능
│                                      │
└──────────────────────────────────────┘
```

### 안내 모드 (Guidance Active)

```
┌──────────────────────────────────────┐
│                                      │
│   ████████████████████████████████   │ ← 어두운 오버레이
│   ████████████████████████████████   │
│   ████████ ╔══════════╗ █████████   │
│   ████████ ║  Target  ║ █████████   │ ← 스포트라이트 cutout
│   ████████ ╚══════════╝ █████████   │
│   ██████████████ 👆 █████████████   │ ← 포인터 (bounce)
│   ████████████████████████████████   │
│                                      │
│  ┌────┐ ┌────────────────────────┐  │
│  │ 🧞 │ │ "Tap the profile icon  │  │ ← 말풍선
│  │    │ │  in the top-right."    │  │
│  └────┘ └────────────────────────┘  │
│                                      │
│  ┌────────────────────────────────┐  │
│  │   "Tap the profile icon"      │  │ ← 자막 바
│  │              Step 1 of 3      │  │
│  └────────────────────────────────┘  │
│                                      │
│  [Repeat] [Do it ✓] [Stop ✕]       │ ← 액션 버튼
└──────────────────────────────────────┘
```

### 상호작용

| 사용자 행동 | 시스템 반응 |
|------------|-----------|
| Genie 버블 탭 | 입력 모드 (음성 or 텍스트) |
| 음성 질문 | 화면 캡처 → 분석 → 안내 |
| "Where?" | 줌 렌즈 + 위치 재설명 |
| "Repeat" | 동일 안내 다시 |
| "Do it" | 자동 탭 (안전 확인 후) |
| 직접 올바른 곳 탭 | "Great job!" → 다음 단계 |
| "Stop" | 안내 종료 → 버블 대기 |

### 안전 정책

| 위험도 | 예시 | UX |
|--------|------|-----|
| **Low** | 스크롤, 메뉴 열기 | 바로 안내 |
| **Medium** | 설정 변경, 계정 전환 | "Should I do this?" 확인 |
| **High** | 결제, 삭제, 로그인 | "This is sensitive. Please do it yourself." 차단 |

---

## 5. 기술 아키텍처

### 기술 스택

| 계층 | 기술 | 용도 |
|------|------|------|
| **모바일 앱** | Flutter (Dart) | UI + 오버레이 렌더링 |
| **오버레이** | `flutter_overlay_window` | 다른 앱 위에 표시 |
| **화면 캡처** | MediaProjection API | 현재 화면 스크린샷 |
| **음성 입력** | `speech_to_text` 패키지 | STT |
| **음성 출력** | `flutter_tts` 또는 Gemini Live API | TTS |
| **백엔드** | FastAPI (Python 3.12) | API 서버 |
| **AI 분석** | Gemini Computer Use 모델 | 화면 이해 + 좌표 추출 |
| **AI 음성** | Gemini Live API | 실시간 음성 대화 |
| **DB** | Cloud Firestore | 세션 로깅 |
| **스토리지** | Cloud Storage | 스크린샷 저장 |
| **배포** | Cloud Run | 백엔드 호스팅 |
| **개발 도구** | Android Studio + Claude Code/Cursor | AI 코딩 어시스턴트 |

### 프로젝트 구조

```
screengenie/
├── android/                         # Flutter Android config
├── lib/                             # Flutter Dart source
│   ├── main.dart                    # App entry
│   ├── app.dart                     # MaterialApp setup
│   │
│   ├── services/
│   │   ├── overlay_service.dart     # Floating bubble + overlay management
│   │   ├── screen_capture.dart      # MediaProjection screenshot
│   │   ├── api_client.dart          # Backend API calls
│   │   ├── voice_service.dart       # STT/TTS
│   │   └── permission_handler.dart  # Android permissions
│   │
│   ├── models/
│   │   ├── overlay_data.dart        # OverlayData class
│   │   ├── session.dart             # Session state
│   │   └── analysis_result.dart     # Gemini response model
│   │
│   ├── widgets/
│   │   ├── genie_bubble.dart        # Floating Genie character
│   │   ├── spotlight.dart           # Dark overlay + circular cutout
│   │   ├── ghost_hand.dart          # Pointing finger animation
│   │   ├── speech_bubble.dart       # Genie's speech text
│   │   ├── subtitle_bar.dart        # Bottom instruction bar
│   │   ├── action_buttons.dart      # Repeat / Do it / Stop
│   │   └── zoom_lens.dart           # Magnification effect
│   │
│   ├── screens/
│   │   ├── home_screen.dart         # Main app screen (start Genie)
│   │   └── settings_screen.dart     # App settings
│   │
│   └── utils/
│       ├── constants.dart           # Colors, sizes
│       └── coordinates.dart         # Gemini coord → screen pixel
│
├── backend/                         # FastAPI backend
│   ├── Dockerfile
│   ├── requirements.txt
│   ├── main.py
│   ├── core/
│   │   ├── analyzer.py              # Gemini Computer Use
│   │   ├── safety_gate.py           # Risk classification
│   │   └── overlay_composer.py      # JSON overlay generation
│   └── prompts/
│       └── navigation.py            # System prompts
│
├── pubspec.yaml                     # Flutter dependencies
└── README.md
```

### API 설계

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/analyze` | Screenshot + question → overlay data |
| `POST` | `/api/voice` | Voice transcription → goal extraction |
| `POST` | `/api/search` | Web search for how-to instructions |
| `GET`  | `/api/health` | Health check |

#### POST /api/analyze
```json
// Request
{
  "screenshot": "<base64 PNG>",
  "question": "Where do I cancel my subscription?",
  "context": {
    "app_name": "Netflix",
    "previous_steps": [],
    "screen_width": 1080,
    "screen_height": 2400
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

### 해커톤 필수 조건 충족

| 요구사항 | 충족 방법 |
|---------|----------|
| Gemini 모델 1개+ | Computer Use + Live API |
| GenAI SDK 또는 ADK | GenAI SDK (Python backend) |
| Google Cloud 1개+ | Cloud Run + Firestore + Cloud Storage |
| Public repo | GitHub |
| Architecture diagram | PNG (위 다이어그램 기반) |
| Cloud deployment proof | Cloud Run 배포 스크린샷 |
| 4분 이하 데모 영상 | Android 화면 녹화 |

---

## 6. 개발 로드맵 (8일)

### Phase 1: Flutter 기본 + 오버레이 (3/8-10, 3일)

| 작업 | 산출물 |
|------|--------|
| Flutter 프로젝트 세팅 + Android Studio | 빌드 가능한 빈 앱 |
| `flutter_overlay_window` 연동 | 다른 앱 위에 Genie 버블 뜸 |
| MediaProjection 스크린샷 캡처 | 현재 화면 캡처 가능 |
| 기본 오버레이 UI (스포트라이트 + 포인터) | 화면 위에 안내 표시 |
| Genie 말풍선 + 자막 바 | 텍스트 안내 |
| **Mock 데이터로 전체 플로우 작동** | 버블 탭 → 캡처 → 하드코딩 안내 표시 |

### Phase 2: Gemini 연동 (3/11-12, 2일)

| 작업 | 산출물 |
|------|--------|
| FastAPI 백엔드 | /api/analyze 엔드포인트 |
| Gemini Computer Use 연동 | 실제 화면 분석 |
| 좌표 변환 (0-999 → 실제 픽셀) | 정확한 타깃 포인팅 |
| Flutter → Backend API 호출 | 실제 분석 기반 오버레이 |
| 기본 음성 입력 (STT) | 음성으로 질문 |

### Phase 3: UX 폴리시 + 음성 (3/13-14, 2일)

| 작업 | 산출물 |
|------|--------|
| 포인터 바운스 애니메이션 | 부드러운 안내 |
| Genie 캐릭터 상태 애니메이션 | speaking/thinking/celebrating |
| 줌 렌즈 (작은 버튼 확대) | "Where?" 시 확대 |
| 안전 판단기 | 위험도별 UX 분기 |
| TTS 음성 출력 | 음성 안내 |
| Auto-tap 토글 (시간 여유 시) | "Do it for me" |
| Gemini Live API (시간 여유 시) | 실시간 음성 대화 |

### Phase 4: 배포 + 제출 (3/15-16, 2일)

| 작업 | 산출물 |
|------|--------|
| Cloud Run 배포 (백엔드) | 작동하는 GCP 배포 |
| Firestore 세션 로깅 | 세션/스텝 기록 |
| 아키텍처 다이어그램 (PNG) | 제출용 |
| **데모 영상 촬영 (Android 화면 녹화)** | 4분 이내 |
| README 작성 | 설치/실행 가이드 |
| Devpost 제출 | 최종 제출 |

---

## 7. 데모 영상 구성 (4분)

### 시나리오: 진짜 앱에서 시연

| 시간 | 내용 | 앱 |
|------|------|-----|
| 0:00-0:20 | **문제 제시**: "We all get lost on screens." | - |
| 0:20-0:40 | **Genie 소개**: 앱 실행 → 버블 떠있는 모습 | ScreenGenie |
| 0:40-1:30 | **시나리오 1**: "How do I switch profiles?" | Netflix (또는 유사 앱) |
| 1:30-2:10 | **시나리오 2**: "Turn on subtitles" | 동영상 앱 |
| 2:10-2:50 | **시나리오 3**: "Cancel my subscription" (차단 시연) | 설정/구독 앱 |
| 2:50-3:10 | **"Do it for me"** 자동 탭 시연 | 아무 앱 |
| 3:10-3:30 | **아키텍처 설명** | 다이어그램 |
| 3:30-4:00 | **마무리**: "ScreenGenie — your AI screen guide." | - |

### 와우 포인트

1. **진짜 Netflix에서 작동** — 가짜 앱이 아님
2. **버블이 항상 떠있는 장면** — 실제 제품 느낌
3. **음성으로 질문 → 즉시 화면에 안내** — 매직 모먼트
4. **위험한 동작 차단** — 신뢰성

---

## 8. 심사 전략

| 심사 기준 (비중) | 우리의 강점 |
|----------------|-----------|
| **Innovation & Multimodal UX (40%)** | 앱 위 오버레이 = text box를 넘은 UX. 음성+시각+터치 |
| **Technical Implementation (30%)** | Gemini CU + Live API + Cloud Run + Firestore |
| **Demo & Presentation (30%)** | 진짜 앱에서 실시간 시연, 아키텍처 명확 |

---

## 9. 리스크 & 대응

| 리스크 | 확률 | 대응 |
|--------|------|------|
| Flutter overlay 플러그인 불안정 | 중 | 대안: 네이티브 Kotlin으로 오버레이 부분만 작성 |
| MediaProjection 권한 문제 | 낮 | Android 10+ 정상 지원, 사용자 동의 팝업 |
| Gemini 좌표 부정확 | 중 | 좌표 보정 로직 + 넉넉한 radius |
| Live API 세션 끊김 | 중 | 기본 STT/TTS 폴백 |
| 8일 시간 부족 | 중 | Phase 3 고급 기능은 축소 가능 |
| 데모 영상에서 앱 상표 이슈 | 낮 | 설정 앱, 자체 테스트 앱으로 대체 가능 |

---

## 10. 프로젝트 정보

| 항목 | 내용 |
|------|------|
| 위치 | `_ideas/screengenie/` |
| 제품명 | ScreenGenie |
| 버전 | v2 (Flutter Android 앱) |
| 단계 | 기획 완료 → Flutter 개발 시작 |
| 마감 | 2026-03-16 (PDT 17:00) |
| 남은 시간 | 8일 |
| 개발 도구 | Android Studio + Claude Code/Cursor |
| 언어 | 전체 영어 (글로벌 해커톤) |
