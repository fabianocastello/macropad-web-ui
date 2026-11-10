#!/bin/bash
# Build "MacroPad UI.app" for macOS: a double-clickable app (Dock-friendly) that starts the
# local server and opens the UI in your browser.
#
#   scripts/make_app.sh [--install] [--port N] [--out DIR]
#
#   --install   also copy the app to /Applications
#   --port N    port the app uses (default 8777)
#   --out DIR   output folder (default ./build)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PORT=8777; INSTALL=0; OUT="$ROOT/build"
while [ $# -gt 0 ]; do
  case "$1" in
    --install) INSTALL=1 ;;
    --port) PORT="$2"; shift ;;
    --out) OUT="$2"; shift ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac; shift
done

[ "$(uname)" = "Darwin" ] || { echo "This script builds a macOS app; run it on a Mac."; exit 1; }
PY="$(command -v python3 || true)"
[ -n "$PY" ] || { echo "python3 not found."; exit 1; }
"$PY" -c "import yaml" 2>/dev/null || { echo "PyYAML is missing for $PY. Run:  $PY -m pip install pyyaml"; exit 1; }

TOOL=""
for c in "${MACROPAD_TOOL:-}" "$ROOT/bin/ch57x-keyboard-tool" "$(command -v ch57x-keyboard-tool || true)" \
         "$HOME/.cargo/bin/ch57x-keyboard-tool" /opt/homebrew/bin/ch57x-keyboard-tool /usr/local/bin/ch57x-keyboard-tool; do
  if [ -n "$c" ] && [ -x "$c" ]; then TOOL="$c"; break; fi
done
[ -n "$TOOL" ] || echo "warning: ch57x-keyboard-tool not found. The app will still build; install the tool (see README) before using it."

APP="$OUT/MacroPad UI.app"
WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT
mkdir -p "$OUT"; rm -rf "$APP"

# 1) launcher (AppleScript applet): starts the server if needed, then opens the browser
cat > "$WORK/launcher.applescript" <<'AS'
on run
	set resDir to POSIX path of (path to me) & "Contents/Resources/macropad_ui"
	set pyPath to "@PY@"
	set toolPath to "@TOOL@"
	if toolPath is "BUNDLED" then set toolPath to POSIX path of (path to me) & "Contents/Resources/ch57x-keyboard-tool"
	set portNum to "@PORT@"
	set serverOn to true
	try
		do shell script "/usr/bin/curl -s -m 2 -o /dev/null http://127.0.0.1:" & portNum & "/api/device"
	on error
		set serverOn to false
	end try
	if not serverOn then
		set cmd to "cd " & quoted form of resDir & " && MACROPAD_PORT=" & portNum & " "
		if toolPath is not "" then set cmd to cmd & "MACROPAD_TOOL=" & quoted form of toolPath & " "
		set cmd to cmd & "nohup " & quoted form of pyPath & " server.py --no-open > \"$HOME/Library/Logs/macropad-ui.log\" 2>&1 &"
		do shell script cmd
		delay 1.5
	end if
	open location "http://127.0.0.1:" & portNum
end run
AS
TOOL_ARG=""; [ -n "$TOOL" ] && TOOL_ARG="BUNDLED"
"$PY" - "$WORK/launcher.applescript" "$PY" "$TOOL_ARG" "$PORT" <<'PYEOF'
import sys
p, py, tool, port = sys.argv[1:5]
s = open(p).read().replace("@PY@", py).replace("@TOOL@", tool).replace("@PORT@", port)
open(p, "w").write(s)
PYEOF
osacompile -o "$APP" "$WORK/launcher.applescript"

# 2) bundle the server + UI (and the tool, if found) inside the app, so it is self-contained
if [ -n "$TOOL" ]; then
  cp "$TOOL" "$APP/Contents/Resources/ch57x-keyboard-tool"
fi
rsync -a --exclude '__pycache__' "$ROOT/macropad_ui/" "$APP/Contents/Resources/macropad_ui/"

# 3) icon
ICONSET="$WORK/icon.iconset"; mkdir -p "$ICONSET"
for s in 16 32 128 256 512; do
  sips -z $s $s "$ROOT/assets/icon.png" --out "$ICONSET/icon_${s}x${s}.png" >/dev/null
  sips -z $((s*2)) $((s*2)) "$ROOT/assets/icon.png" --out "$ICONSET/icon_${s}x${s}@2x.png" >/dev/null
done
iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/applet.icns"
# osacompile adds a default asset-catalog icon that can override applet.icns: remove it
/usr/libexec/PlistBuddy -c "Delete :CFBundleIconName" "$APP/Contents/Info.plist" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Set :CFBundleIconFile applet" "$APP/Contents/Info.plist" 2>/dev/null || true
rm -f "$APP/Contents/Resources/Assets.car"
touch "$APP"
codesign --force --deep -s - "$APP" >/dev/null 2>&1 || true

echo "Built: $APP"
if [ "$INSTALL" = 1 ]; then
  rm -rf "/Applications/MacroPad UI.app"
  cp -R "$APP" /Applications/
  echo "Installed to /Applications/MacroPad UI.app"
fi
