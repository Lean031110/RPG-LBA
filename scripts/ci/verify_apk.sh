#!/usr/bin/env bash
# Static verification of the RPG LBA Android debug APK.
# Checks that the APK compiled well, is signed with the project's open-source
# debug autofirma and is structurally valid for installation.
#
# Usage:
#   verify_apk.sh <apk-path> [--build-tools <dir>] [--report <file>]
#
# Environment:
#   ANDROID_BUILD_TOOLS  dir with apksigner/zipalign/aapt2
#                        (default: $ANDROID_SDK_ROOT/build-tools/35.0.1)
#   EXPECTED_CERT_SHA256  lowercase hex, no colons (default: the project autofirma)
#
# Exit codes: 0 = all checks PASS, 1 = at least one FAIL, 2 = usage/setup error.
#
# NOTE: this is static verification. It proves the APK is valid to install;
# it does NOT replace the emulator install/launch test of the workflow or a
# real physical device test.
set -uo pipefail

APK="${1:-}"
BUILD_TOOLS="${ANDROID_BUILD_TOOLS:-${ANDROID_SDK_ROOT:-}/build-tools/35.0.1}"
REPORT="${2:-}"
EXPECTED_CERT_SHA256="${EXPECTED_CERT_SHA256:-edf1066f37a3d1321be8a1584266feae64d95d9fa9e86ea1a0feefa3570bbbab}"
EXPECTED_DN="CN=RPG LBA Debug, O=LBA Games, C=CU"
MIN_SIZE_MB=10
MIN_ASSET_ENTRIES=100

if [[ -z "$APK" || ! -f "$APK" ]]; then
  echo "ERROR: APK not found: '$APK'" >&2
  exit 2
fi
if [[ -z "$BUILD_TOOLS" || ! -x "$BUILD_TOOLS/apksigner" ]]; then
  echo "ERROR: build-tools not found at '$BUILD_TOOLS' (set ANDROID_BUILD_TOOLS or ANDROID_SDK_ROOT)" >&2
  exit 2
fi
if [[ -z "$REPORT" ]]; then
  REPORT="$(dirname "$APK")/apk_verification_report.txt"
fi

FAILURES=0
pass() { echo "PASS: $1" | tee -a "$REPORT"; }
fail() { echo "FAIL: $1" | tee -a "$REPORT"; FAILURES=$((FAILURES + 1)); }
note() { echo "note: $1" | tee -a "$REPORT"; }

{
  echo "RPG LBA - Android debug APK verification"
  echo "APK: $APK"
  echo "Date: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "build-tools: $BUILD_TOOLS"
  echo
} > "$REPORT"

# 1. Size + checksum
SIZE_BYTES=$(stat -c %s "$APK")
SHA256=$(sha256sum "$APK" | cut -d' ' -f1)
note "size: $SIZE_BYTES bytes; sha256: $SHA256"
if (( SIZE_BYTES >= MIN_SIZE_MB * 1024 * 1024 )); then
  pass "APK size ${SIZE_BYTES} bytes >= ${MIN_SIZE_MB} MB"
else
  fail "APK size ${SIZE_BYTES} bytes < ${MIN_SIZE_MB} MB (suspiciously small; export truncated?)"
fi

# 2. zipalign
if "$BUILD_TOOLS/zipalign" -c 4 "$APK" >/dev/null 2>&1; then
  pass "zipalign -c 4 (uncompressed entries aligned on 4-byte boundaries)"
else
  fail "zipalign -c 4 (misaligned APK may be rejected by newer Android versions)"
fi

# 3. Signature: our open-source debug autofirma
CERTS=$("$BUILD_TOOLS/apksigner" verify --print-certs "$APK" 2>/dev/null || true)
DN=$(echo "$CERTS" | grep -m1 "certificate DN" | sed 's/.*DN: *//' | xargs)
DIGEST=$(echo "$CERTS" | grep -m1 "SHA-256 digest" | sed 's/.*digest: *//' | tr -d ':' | tr 'A-F' 'a-f' | xargs)
if [[ "$DN" == "$EXPECTED_DN" ]]; then
  pass "signer certificate DN matches the project autofirma: $DN"
else
  fail "signer certificate DN is '$DN', expected '$EXPECTED_DN' (APK not signed with the project autofirma)"
fi
if [[ -n "$DIGEST" && "$DIGEST" == "$EXPECTED_CERT_SHA256" ]]; then
  pass "signer SHA-256 digest matches the project autofirma"
else
  fail "signer SHA-256 digest '$DIGEST' does not match the project autofirma"
fi

VERBOSE=$("$BUILD_TOOLS/apksigner" verify --verbose "$APK" 2>/dev/null || true)
if echo "$VERBOSE" | grep "v2 scheme (APK Signature Scheme v2): true" >/dev/null 2>&1; then
  pass "apksigner verify: APK Signature Scheme v2 present (required on modern Android)"
  echo "$VERBOSE" | grep "Verified using" | sed 's/^/note: /' | tee -a "$REPORT" >/dev/null
else
  fail "apksigner verify: v2 signature missing (install will fail on Android 10+)"
fi

# 4. Badging: identity, SDK levels, ABIs
BADGING=$("$BUILD_TOOLS/aapt2" dump badging "$APK" 2>/dev/null || true)
PKG=$(echo "$BADGING" | grep -m1 "^package:" | sed "s/^package: name='\([^']*\)'.*/\1/")
if [[ "$PKG" == "com.lbagames.rpglba" ]]; then
  pass "package name: $PKG"
else
  fail "package name is '$PKG', expected 'com.lbagames.rpglba'"
fi
MIN_SDK=$(echo "$BADGING" | grep -m1 "minSdkVersion" | sed "s/.*:'\([0-9]*\)'.*/\1/")
if [[ -n "$MIN_SDK" && "$MIN_SDK" -ge 24 ]]; then
  pass "minSdkVersion: $MIN_SDK (covers the project's supported Android range)"
else
  fail "minSdkVersion missing or < 24: '$MIN_SDK'"
fi
TARGET_SDK=$(echo "$BADGING" | grep -m1 "targetSdkVersion" | sed "s/.*:'\([0-9]*\)'.*/\1/")
note "targetSdkVersion: ${TARGET_SDK:-unknown}"
NATIVE=$(echo "$BADGING" | grep -m1 "native-code")
for ABI in arm64-v8a x86_64; do
  if echo "$NATIVE" | grep "'$ABI'" >/dev/null 2>&1; then
    pass "native-code contains $ABI"
  else
    fail "native-code missing $ABI (preset architectures must enable it)"
  fi
done

# 5. Launchable entry (MAIN/LAUNCHER intent filter in the manifest)
MANIFEST=$("$BUILD_TOOLS/aapt2" dump xmltree "$APK" --file AndroidManifest.xml 2>/dev/null || true)
if echo "$MANIFEST" | grep "android.intent.category.LAUNCHER" >/dev/null 2>&1 \
  && echo "$MANIFEST" | grep "android.intent.action.MAIN" >/dev/null 2>&1; then
  # Godot's template exposes the launcher entry through an activity-alias.
  ALIAS=$(echo "$MANIFEST" | grep -A4 "E: activity-alias" | grep -m1 "name(0x" | sed 's/.*="\([^"]*\)".*/\1/')
  pass "launchable MAIN/LAUNCHER intent-filter present (entry: ${ALIAS:-see manifest})"
else
  fail "no MAIN/LAUNCHER intent-filter found: the APK would not be launchable"
fi
ORIENTATION=$(echo "$MANIFEST" | grep -m1 "screenOrientation" | sed 's/.*screenOrientation(0x[0-9a-f]*)=\([0-9]*\).*/\1/')
note "activity screenOrientation code: ${ORIENTATION:-unknown} (written from the project setting sensor_landscape; recorded, not asserted)"

# 6. Structural: engine, game data and dex
LISTING=$(unzip -l "$APK" 2>/dev/null || true)
for ENTRY in \
  "classes.dex" \
  "lib/arm64-v8a/libgodot_android.so" \
  "lib/x86_64/libgodot_android.so" \
  "assets/scenes/arpg/menu/main_menu.tscn.remap"; do
  # NOTE: no grep -q here. With set -o pipefail, grep -q can exit before the
  # producer finishes on big listings, SIGPIPE the echo and turn a match into
  # a false FAIL. Plain grep reads to EOF.
  if echo "$LISTING" | grep "$ENTRY" >/dev/null 2>&1; then
    pass "entry present: $ENTRY"
  else
    fail "entry missing: $ENTRY"
  fi
done
ASSET_COUNT=$(echo "$LISTING" | grep -c "assets/")
if (( ASSET_COUNT >= MIN_ASSET_ENTRIES )); then
  pass "embedded game data: $ASSET_COUNT assets/ entries (>= $MIN_ASSET_ENTRIES)"
else
  fail "embedded game data: only $ASSET_COUNT assets/ entries (< $MIN_ASSET_ENTRIES); game content missing?"
fi

echo | tee -a "$REPORT"
if (( FAILURES == 0 )); then
  echo "RESULT: PASS ($(( $(grep -c '^PASS:' "$REPORT") )) checks, 0 failures) - APK is valid for installation; emulate/device test still recommended." | tee -a "$REPORT"
  exit 0
else
  echo "RESULT: FAIL ($FAILURES failing checks) - see above." | tee -a "$REPORT"
  exit 1
fi
