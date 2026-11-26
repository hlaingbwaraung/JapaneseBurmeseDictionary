#!/usr/bin/env bash
set -euo pipefail

# One-step Mac -> iPhone installer for JapaneseBurmeseDictionary
# Usage on macOS (with iPhone plugged in via USB):
#   ./install_to_iphone.sh

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

echo "========================================================"
echo " 🇯🇵 ⇄ 🇲🇲 Japanese–Burmese Dictionary — iPhone Installer"
echo "========================================================"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "❌ Error: This installer must be run on your Mac with Xcode installed."
  exit 1
fi

if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "❌ Error: Xcode is not installed or xcode-select is not configured."
  echo "   Install Xcode from the Mac App Store, then run:"
  echo "   sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"
  exit 1
fi

echo "🔍 Looking for your plugged-in iPhone..."

DEVICE_INFO="$(/usr/bin/python3 - <<'PY'
import json, os, re, subprocess, tempfile

# 1. Try Xcode 15/16+ CoreDevice (devicectl)
tmp = tempfile.NamedTemporaryFile(suffix=".json", delete=False)
tmp.close()
try:
    res = subprocess.run(
        ["xcrun", "devicectl", "list", "devices", "--json-output", tmp.name],
        capture_output=True, text=True, timeout=15
    )
    if res.returncode == 0 and os.path.exists(tmp.name):
        data = json.load(open(tmp.name))
        devices = data.get("result", {}).get("devices", [])
        for d in devices:
            hw = d.get("hardwareProperties", {})
            conn = d.get("connectionProperties", {})
            dev_props = d.get("deviceProperties", {})
            if hw.get("platform") == "iOS" and hw.get("reality") == "physical":
                state = conn.get("tunnelState", "")
                pairing = conn.get("pairingState", "")
                transport = conn.get("transportType", "")
                if pairing == "paired" and (transport in ("wired", "localNetwork") or state in ("connected", "available", "unavailable")):
                    udid = hw.get("udid") or d.get("identifier", "")
                    name = dev_props.get("name", "iPhone")
                    if udid:
                        print(f"{udid}\t{name}\tdevicectl")
                        raise SystemExit(0)
except SystemExit:
    raise
except Exception:
    pass
finally:
    try:
        os.unlink(tmp.name)
    except OSError:
        pass

# 2. Fallback to xctrace (supports iOS 16 and wired devices)
try:
    out = subprocess.check_output(["xcrun", "xctrace", "list", "devices"], stderr=subprocess.STDOUT, text=True, timeout=15)
    in_devices = False
    for line in out.splitlines():
        s = line.strip()
        if s == "== Devices ==":
            in_devices = True
            continue
        if s.startswith("==") and s != "== Devices ==":
            in_devices = False
            continue
        if in_devices and s:
            # Skip Mac entries
            if "Mac" in s and "iPhone" not in s and "iPad" not in s:
                continue
            m = re.match(r"^(.+?)\s+\([0-9.]+\)\s+\(([0-9A-Fa-f-]+)\)$", s)
            if m:
                print(f"{m.group(2)}\t{m.group(1)}\txctrace")
                raise SystemExit(0)
except SystemExit:
    raise
except Exception:
    pass
PY
)"

if [[ -z "$DEVICE_INFO" ]]; then
  echo "⚠️  Could not auto-detect a paired iPhone over USB."
  echo "   Make sure:"
  echo "   1. Your iPhone is plugged into your Mac and unlocked."
  echo "   2. You tapped 'Trust This Computer' on your iPhone."
  echo "   3. On iOS 16+, Settings → Privacy & Security → Developer Mode is ON."
  echo ""
  echo "👉 Opening Xcode now so you can select your iPhone and press Cmd + R..."
  open "$ROOT_DIR/JapaneseBurmeseDictionary.xcodeproj"
  exit 1
fi

DEVICE_UDID="$(printf '%s' "$DEVICE_INFO" | cut -f1)"
DEVICE_NAME="$(printf '%s' "$DEVICE_INFO" | cut -f2)"
DEVICE_MODE="$(printf '%s' "$DEVICE_INFO" | cut -f3)"
echo "✅ Found iPhone: $DEVICE_NAME ($DEVICE_UDID)"

# Detect Apple Development Team ID from Xcode preferences (or TEAM_ID env var)
TEAM_ID="${TEAM_ID:-}"
if [[ -z "$TEAM_ID" ]]; then
  TEAM_ID="$(/usr/bin/python3 - <<'PY'
import json, os, subprocess

plist_path = os.path.expanduser("~/Library/Preferences/com.apple.dt.Xcode.plist")
if os.path.exists(plist_path):
    try:
        raw = subprocess.check_output(["plutil", "-convert", "json", "-o", "-", plist_path], text=True)
        data = json.loads(raw)
        teams_map = data.get("IDEProvisioningTeams", {})
        for _, teams in teams_map.items():
            if isinstance(teams, list):
                for t in teams:
                    tid = t.get("teamID")
                    if tid:
                        print(tid)
                        raise SystemExit(0)
    except SystemExit:
        raise
    except Exception:
        pass
PY
)"
fi

if [[ -z "$TEAM_ID" ]]; then
  echo "⚠️  No Apple ID Development Team found in Xcode yet."
  echo "   Opening JapaneseBurmeseDictionary.xcodeproj in Xcode..."
  open "$ROOT_DIR/JapaneseBurmeseDictionary.xcodeproj"
  echo ""
  echo "   In Xcode (takes 20 seconds):"
  echo "   1. Open Xcode → Settings (Cmd + ,) → Accounts → click '+' → sign in with your Apple ID."
  echo "   2. Click 'JapaneseBurmeseDictionary' in the left sidebar → 'Signing & Capabilities' → pick your Team."
  echo "   3. Select '$DEVICE_NAME' at the top and press Cmd + R!"
  exit 0
fi

USER_SLUG="$(id -un | tr -cd 'a-zA-Z0-9' | tr '[:upper:]' '[:lower:]')"
BUNDLE_ID="${BUNDLE_ID:-com.${USER_SLUG:-user}.jpmmdictionary}"
DERIVED_DATA="$ROOT_DIR/build/DerivedData"

echo "✅ Using Apple Team ID: $TEAM_ID"
echo "📦 Bundle Identifier:   $BUNDLE_ID"
echo "🔨 Building native SwiftUI app for $DEVICE_NAME..."

if ! xcodebuild \
  -project "$ROOT_DIR/JapaneseBurmeseDictionary.xcodeproj" \
  -scheme JapaneseBurmeseDictionary \
  -configuration Debug \
  -destination "platform=iOS,id=$DEVICE_UDID" \
  -derivedDataPath "$DERIVED_DATA" \
  -allowProvisioningUpdates \
  DEVELOPMENT_TEAM="$TEAM_ID" \
  PRODUCT_BUNDLE_IDENTIFIER="$BUNDLE_ID" \
  CODE_SIGN_STYLE=Automatic \
  build; then
  echo ""
  echo "⚠️  CLI build/signing needed interactive Xcode confirmation."
  echo "👉 Opening project in Xcode — select your Team in 'Signing & Capabilities' and press Cmd + R!"
  open "$ROOT_DIR/JapaneseBurmeseDictionary.xcodeproj"
  exit 1
fi

APP_PATH="$DERIVED_DATA/Build/Products/Debug-iphoneos/JapaneseBurmeseDictionary.app"

if [[ "$DEVICE_MODE" == "devicectl" ]]; then
  echo "📲 Installing JapaneseBurmeseDictionary onto $DEVICE_NAME..."
  xcrun devicectl device install app --device "$DEVICE_UDID" "$APP_PATH"
  echo "🚀 Launching app on $DEVICE_NAME..."
  xcrun devicectl device process launch --device "$DEVICE_UDID" "$BUNDLE_ID" || true
  echo ""
  echo "🎉 Installed! Look at your iPhone!"
  echo "   (If iOS shows 'Untrusted Developer' on first run: open iPhone Settings → General → VPN & Device Management → Trust your Apple ID.)"
else
  echo "✅ Build succeeded at: $APP_PATH"
  echo "👉 Opening Xcode — press Cmd + R to finish installing onto $DEVICE_NAME!"
  open "$ROOT_DIR/JapaneseBurmeseDictionary.xcodeproj"
fi
