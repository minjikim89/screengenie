import os
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

from core.analyzer import ScreenAnalyzer
from core.safety_gate import SafetyGate

analyzer: ScreenAnalyzer | None = None


@asynccontextmanager
async def lifespan(app: FastAPI):
    global analyzer
    if os.environ.get("GOOGLE_API_KEY") or os.environ.get("GOOGLE_GENAI_API_KEY"):
        analyzer = ScreenAnalyzer()
    yield


app = FastAPI(title="ScreenGenie API", version="1.0.0", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


class ScreenContext(BaseModel):
    screen_width: int = 1080
    screen_height: int = 2400
    previous_steps: list[str] = []


class AnalyzeRequest(BaseModel):
    screenshot: str = ""
    question: str
    context: ScreenContext = ScreenContext()


@app.get("/health")
async def health():
    return {"status": "ok", "gemini": analyzer is not None}


@app.post("/api/analyze")
async def analyze_screen(req: AnalyzeRequest):
    if analyzer and req.screenshot:
        # Real Gemini analysis
        result = await analyzer.analyze(
            screenshot_b64=req.screenshot,
            question=req.question,
            screen_width=req.context.screen_width,
            screen_height=req.context.screen_height,
        )
        return result

    # Mock response when no API key or no screenshot
    return _mock_response(req.question, req.context.screen_width, req.context.screen_height)


def _mock_response(question: str, width: int, height: int) -> dict:
    q = question.lower()
    safety = SafetyGate()

    if "wi-fi" in q or "wifi" in q:
        instruction = 'Tap on "Wi-Fi" to open wireless settings.'
        target = {"x": width * 0.5, "y": height * 0.175, "radius": 55, "label": "Wi-Fi"}
        step_index, step_total = 1, 2
    elif "wallpaper" in q or "background" in q:
        instruction = 'Open "Display" settings to change your wallpaper.'
        target = {"x": width * 0.5, "y": height * 0.283, "radius": 55, "label": "Display"}
        step_index, step_total = 1, 3
    elif "battery" in q:
        instruction = 'Tap "Battery" to check usage and enable power saving.'
        target = {"x": width * 0.5, "y": height * 0.375, "radius": 55, "label": "Battery"}
        step_index, step_total = 1, 2
    elif "bluetooth" in q:
        instruction = 'Tap "Bluetooth" to manage paired devices.'
        target = {"x": width * 0.5, "y": height * 0.217, "radius": 55, "label": "Bluetooth"}
        step_index, step_total = 1, 3
    else:
        instruction = "I found what you're looking for. Tap the highlighted area."
        target = {"x": width * 0.5, "y": height * 0.25, "radius": 55, "label": "Target element"}
        step_index, step_total = 1, 1

    risk = safety.classify_risk(instruction)

    return {
        "overlay": {
            "mode": "guide",
            "instruction": instruction,
            "target": target,
            "risk": risk,
            "needs_confirmation": risk in ("medium", "high"),
            "step_index": step_index,
            "step_total": step_total,
            "face_state": "pointing",
            "voice_text": f"Look for the {target['label']} option on your screen.",
        }
    }
