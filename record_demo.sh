#!/bin/bash
# Record ScreenGenie demo video
# Requires: demo mode APK already installed, emulator running
set -e

ADB="/Users/minjikim/Library/Android/sdk/platform-tools/adb"
DEVICE_VIDEO="/sdcard/screengenie_demo.mp4"
LOCAL_VIDEO="demo/screengenie_demo.mp4"

mkdir -p demo

echo "=== ScreenGenie Demo Recording ==="
echo ""

# 1. Kill any existing ScreenGenie process
$ADB shell am force-stop com.screengenie.screengenie 2>/dev/null || true
sleep 1

# 2. Start screen recording in background (max 60s)
echo "[1/5] Starting screen recording..."
$ADB shell screenrecord --time-limit 55 --size 1080x2400 "$DEVICE_VIDEO" &
RECORD_PID=$!
sleep 1

# 3. Launch app
echo "[2/5] Launching ScreenGenie..."
$ADB shell am start -n com.screengenie.screengenie/.MainActivity
sleep 8

# 4. Tap Start Genie (button center ~540,1381)
echo "[3/5] Tapping Start Genie..."
$ADB shell input tap 540 1381
sleep 3

# 5. Open Chrome to Google.com
echo "[4/5] Opening Chrome..."
$ADB shell am start -a android.intent.action.VIEW -d "https://www.google.com" com.android.chrome
sleep 5

# 6. Demo mode auto-runs: bubble tap → submit question → Gemini response
echo "[5/5] Waiting for demo auto-flow (overlay expand + Gemini call)..."
# Demo mode handles: 18s delay → bubble tap → 3s → submit "How to sign in"
# Total wait: ~30s from app launch for the full flow
sleep 25

# 7. Stop recording
echo "Stopping recording..."
kill $RECORD_PID 2>/dev/null || true
sleep 3

# 8. Pull video
echo "Pulling video..."
$ADB pull "$DEVICE_VIDEO" "$LOCAL_VIDEO"
$ADB shell rm "$DEVICE_VIDEO" 2>/dev/null || true

echo ""
echo "Demo video saved to: $LOCAL_VIDEO"
echo "Duration: ~50 seconds"
