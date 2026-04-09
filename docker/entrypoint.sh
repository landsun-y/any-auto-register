#!/bin/sh
set -eu

APP_DIR="/app"
RUNTIME_DIR="${APP_RUNTIME_DIR:-/runtime}"

mkdir -p "${RUNTIME_DIR}" "${RUNTIME_DIR}/logs" "${RUNTIME_DIR}/smstome_used"
touch \
  "${RUNTIME_DIR}/account_manager.db" \
  "${RUNTIME_DIR}/smstome_all_numbers.txt" \
  "${RUNTIME_DIR}/smstome_uk_deep_numbers.txt" \
  "${RUNTIME_DIR}/logs/solver.log"

ln -sfn "${RUNTIME_DIR}/account_manager.db" "${APP_DIR}/account_manager.db"
ln -sfn "${RUNTIME_DIR}/smstome_used" "${APP_DIR}/smstome_used"
ln -sfn "${RUNTIME_DIR}/smstome_all_numbers.txt" "${APP_DIR}/smstome_all_numbers.txt"
ln -sfn "${RUNTIME_DIR}/smstome_uk_deep_numbers.txt" "${APP_DIR}/smstome_uk_deep_numbers.txt"
ln -sfn "${RUNTIME_DIR}/logs/solver.log" "${APP_DIR}/services/turnstile_solver/solver.log"

DISPLAY_NUM=99
export DISPLAY=":${DISPLAY_NUM}"

echo "[entrypoint] Starting Xvfb on display :${DISPLAY_NUM} ..."
Xvfb ":${DISPLAY_NUM}" -screen 0 1920x1080x24 -nolisten tcp -ac &
XVFB_PID=$!

sleep 1
if kill -0 "$XVFB_PID" 2>/dev/null; then
  echo "[entrypoint] Xvfb started (PID=${XVFB_PID})"
else
  echo "[entrypoint] WARNING: Xvfb failed to start, continuing without virtual display"
  unset DISPLAY
fi

cleanup() {
  echo "[entrypoint] Shutting down ..."
  kill "$XVFB_PID" 2>/dev/null || true
  wait "$XVFB_PID" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

echo "[entrypoint] Starting backend (python main.py) ..."
exec python main.py
