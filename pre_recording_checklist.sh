#!/bin/bash

# Pre-session checklist - run this before starting a recording session
# Verifies everything is ready

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║          Pre-Recording Session Checklist                      ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

checks_passed=0
checks_total=0

# Function to check and report
check() {
    local name="$1"
    local command="$2"
    checks_total=$((checks_total + 1))
    
    if eval "$command" > /dev/null 2>&1; then
        echo "✓ $name"
        checks_passed=$((checks_passed + 1))
        return 0
    else
        echo "✗ $name"
        return 1
    fi
}

echo "════════ System Checks ════════"
echo ""

check "ffmpeg installed" "which ffmpeg"
check "uv installed" "which uv"
check "v4l2loopback module available" "modinfo v4l2loopback"
check "v4l2loopback loaded" "lsmod | grep -q v4l2loopback"
check "Virtual webcam exists (/dev/video20)" "test -e /dev/video20"

echo ""
echo "════════ Project Files ════════"
echo ""

check "start_phone_stream.sh exists" "test -f start_phone_stream.sh"
check "record_session.sh exists" "test -f record_session.sh"
check "create_twitter_video.sh exists" "test -f create_twitter_video.sh"
check "capture_timelapse.py exists" "test -f capture_timelapse.py"

echo ""
echo "════════ Directories ════════"
echo ""

# Create if missing
mkdir -p timelapse_imgs videos

check "timelapse_imgs/ directory exists" "test -d timelapse_imgs"
check "videos/ directory exists" "test -d videos"

echo ""
echo "════════ Results ════════"
echo ""
echo "Passed: $checks_passed / $checks_total checks"
echo ""

if [ $checks_passed -eq $checks_total ]; then
    echo "✓ All checks passed! System is ready."
    echo ""
    echo "Next steps:"
    echo "  1. Position your phone and start IP Webcam app"
    echo "  2. Terminal 1: ./start_phone_stream.sh"
    echo "  3. Terminal 2: ./record_session.sh --hours 8"
    echo ""
    echo "For detailed guide: ./USAGE_GUIDE.sh"
    exit 0
else
    echo "⚠ Some checks failed. Please fix the issues above."
    echo ""
    
    # Provide specific help
    if ! lsmod | grep -q v4l2loopback; then
        echo "To load v4l2loopback:"
        echo "  sudo modprobe v4l2loopback devices=1 video_nr=20 card_label=\"IPWebcam\" exclusive_caps=1"
        echo ""
    fi
    
    if ! test -e /dev/video20; then
        echo "Virtual webcam missing. Run ./start_phone_stream.sh to create it."
        echo ""
    fi
    
    exit 1
fi
