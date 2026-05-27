#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# CareSkill dev launcher
# Usage:
#   ./start_dev.sh              → start backend + ngrok, print flutter commands
#   ./start_dev.sh --web        → also launch Flutter Web automatically
#   ./start_dev.sh --android    → also launch Flutter on connected Android device
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKEND_DIR="$PROJECT_DIR/backend"
VENV="$BACKEND_DIR/.venv/bin"
WEB_PORT=5000      # fixed Flutter Web port (must match Google Cloud Console)
NGROK_API="http://localhost:4040/api/tunnels"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

# ── 1. Start backend ──────────────────────────────────────────────────────────
if curl -s --max-time 1 http://localhost:8000/ > /dev/null 2>&1; then
  echo -e "${GREEN}✓ Backend already running on :8000${NC}"
else
  echo -e "${CYAN}▶ Starting FastAPI backend...${NC}"
  cd "$BACKEND_DIR"
  "$VENV/uvicorn" app.main:app --reload --port 8000 \
    --log-level info > /tmp/careskill_backend.log 2>&1 &
  BACKEND_PID=$!
  echo "  Backend PID $BACKEND_PID  (logs → /tmp/careskill_backend.log)"

  # Wait up to 8 s for the backend to be ready
  for i in $(seq 1 16); do
    sleep 0.5
    if curl -s --max-time 1 http://localhost:8000/ > /dev/null 2>&1; then
      echo -e "${GREEN}✓ Backend ready${NC}"
      break
    fi
    if [ $i -eq 16 ]; then
      echo "Backend failed to start. Check /tmp/careskill_backend.log"
      exit 1
    fi
  done
fi

# ── 2. Start ngrok ────────────────────────────────────────────────────────────
if curl -s "$NGROK_API" > /dev/null 2>&1; then
  echo -e "${GREEN}✓ ngrok already running${NC}"
else
  echo -e "${CYAN}▶ Starting ngrok (backend tunnel via config file)...${NC}"
  # Uses ~/.config/ngrok/ngrok.yml — single process, named tunnel avoids ERR_NGROK_334
  ngrok start backend > /tmp/careskill_ngrok.log 2>&1 &
  NGROK_PID=$!
  echo "  ngrok PID $NGROK_PID  (logs → /tmp/careskill_ngrok.log)"

  # Wait up to 10 s for ngrok to get a URL
  for i in $(seq 1 20); do
    sleep 0.5
    if curl -s "$NGROK_API" > /dev/null 2>&1; then
      break
    fi
    if [ $i -eq 20 ]; then
      echo "ngrok failed to start. Make sure ngrok is installed and authenticated."
      echo "  Install: https://ngrok.com/download"
      echo "  Auth:    ngrok config add-authtoken <YOUR_TOKEN>"
      exit 1
    fi
  done
fi

# ── 3. Extract public HTTPS URL ───────────────────────────────────────────────
NGROK_URL=$(curl -s "$NGROK_API" \
  | python3 -c "
import sys, json
tunnels = json.load(sys.stdin).get('tunnels', [])
https = [t['public_url'] for t in tunnels if t['public_url'].startswith('https')]
print(https[0] if https else '')
")

if [ -z "$NGROK_URL" ]; then
  echo "Could not read ngrok URL from $NGROK_API"
  exit 1
fi

echo -e "${GREEN}✓ ngrok tunnel: ${YELLOW}$NGROK_URL${NC}"

# ── 4. Print commands ─────────────────────────────────────────────────────────
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Flutter Web  (Chrome, port $WEB_PORT):${NC}"
echo -e "  cd \"$PROJECT_DIR\""
echo -e "  flutter run -d chrome --web-port=$WEB_PORT \\"
echo -e "    --dart-define=API_BASE_URL=$NGROK_URL"
echo ""
echo -e "${GREEN}Flutter Android (physical device / emulator):${NC}"
echo -e "  flutter run -d \$(flutter devices | grep android | awk '{print \$4}' | head -1) \\"
echo -e "    --dart-define=API_BASE_URL=$NGROK_URL"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  Backend logs:  tail -f /tmp/careskill_backend.log"
echo -e "  ngrok logs:    tail -f /tmp/careskill_ngrok.log"
echo -e "  ngrok UI:      http://localhost:4040"
echo ""

# ── 5. Auto-launch if flag given ──────────────────────────────────────────────
cd "$PROJECT_DIR"

if [[ "${1:-}" == "--web" ]]; then
  echo -e "${CYAN}▶ Launching Flutter Web...${NC}"
  flutter run -d chrome --web-port=$WEB_PORT \
    --dart-define=API_BASE_URL="$NGROK_URL"
elif [[ "${1:-}" == "--android" ]]; then
  echo -e "${CYAN}▶ Launching Flutter on Android...${NC}"
  flutter run --dart-define=API_BASE_URL="$NGROK_URL"
fi
