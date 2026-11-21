#!/usr/bin/env bash
# Speak the given text with Piper TTS, then play the result with mpv.
# Usage: speak-piper.sh "text to speak"
set -euo pipefail

text="$*"
model="${PIPER_MODEL:-$HOME/.local/share/piper/voices/en_US-lessac-medium/en_US-lessac-medium.onnx}"
tmp="/tmp/piper-tts-$$"
printf '%s' "$text" > "$tmp.txt"
piper --model "$model" --input_file "$tmp.txt" --output_file "$tmp.wav" >/dev/null 2>&1
mpv --no-video --really-quiet --volume=70 "$tmp.wav" >/dev/null 2>&1 || true
rm -f "$tmp.txt" "$tmp.wav"
