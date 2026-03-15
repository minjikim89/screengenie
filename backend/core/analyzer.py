import json
import base64
import os

from google import genai
from google.genai import types

from prompts.navigation import SYSTEM_PROMPT
from core.safety_gate import SafetyGate


class ScreenAnalyzer:
    MODEL = "gemini-2.5-flash-preview-05-20"

    def __init__(self):
        self.client = genai.Client()
        self.safety_gate = SafetyGate()

    async def analyze(
        self,
        screenshot_b64: str,
        question: str,
        screen_width: int = 1080,
        screen_height: int = 2400,
    ) -> dict:
        parts = [types.Part(text=f"User question: {question}")]

        if screenshot_b64:
            parts.append(
                types.Part(
                    inline_data=types.Blob(
                        mime_type="image/png",
                        data=base64.b64decode(screenshot_b64),
                    )
                )
            )

        contents = [types.Content(role="user", parts=parts)]

        config = types.GenerateContentConfig(
            system_instruction=SYSTEM_PROMPT,
            response_mime_type="application/json",
        )

        response = await self.client.aio.models.generate_content(
            model=self.MODEL,
            contents=contents,
            config=config,
        )

        result = json.loads(response.text)
        return self._build_overlay(result, screen_width, screen_height)

    def _build_overlay(
        self, result: dict, screen_width: int, screen_height: int
    ) -> dict:
        target = result.get("target", {})
        gemini_x = target.get("gemini_x", 500)
        gemini_y = target.get("gemini_y", 500)

        # Denormalize 0-999 coordinates to actual screen pixels
        pixel_x = (gemini_x / 1000) * screen_width
        pixel_y = (gemini_y / 1000) * screen_height

        instruction = result.get("instruction", "Tap the highlighted area.")
        risk = self.safety_gate.classify_risk(instruction)

        return {
            "overlay": {
                "mode": "guide",
                "instruction": instruction,
                "target": {
                    "x": pixel_x,
                    "y": pixel_y,
                    "radius": 55,
                    "label": target.get("label", "Target"),
                },
                "risk": risk,
                "needs_confirmation": risk in ("medium", "high"),
                "step_index": result.get("step_index", 1),
                "step_total": result.get("step_total", 1),
                "face_state": "pointing",
                "voice_text": result.get("voice_text"),
            }
        }
