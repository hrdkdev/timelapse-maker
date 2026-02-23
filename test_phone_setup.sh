#!/bin/bash

# Quick test to verify phone webcam setup is working
# This does a 2-minute test capture with 10-second intervals

set -e

echo "=== Phone Webcam Test ==="
echo ""
echo "This will capture 12 frames over 2 minutes (10s intervals)"
echo "to verify your setup is working."
echo ""

# Check if virtual webcam exists
if [ ! -e /dev/video20 ]; then
  echo "ERROR: Virtual webcam /dev/video20 not found!"
  echo ""
  echo "Make sure to run './start_phone_stream.sh' first!"
  exit 1
fi

echo "Virtual webcam found at /dev/video20"
echo ""

# Create test directory
TEST_DIR="test_capture"
mkdir -p "$TEST_DIR"

echo "Starting 2-minute test capture..."
echo "Watch for errors. Press Ctrl+C to stop early if needed."
echo ""

# Run capture
uv run capture_timelapse.py \
  --hours 0.033 \
  --interval 10 \
  --output-dir "$TEST_DIR" \
  --width 1280 \
  --height 720 \
  --camera-index 20

echo ""
echo "=== Test Complete! ==="
echo ""

# Count frames
NUM_FRAMES=$(find "$TEST_DIR" -name "*.jpg" | wc -l)
echo "Captured $NUM_FRAMES frames"

if [ "$NUM_FRAMES" -eq 0 ]; then
  echo "ERROR: No frames captured!"
  echo "Check if start_phone_stream.sh is still running"
  exit 1
fi

echo ""
echo "Creating test video..."
./create_twitter_video.sh --input "$TEST_DIR" --output test_video.mp4

echo ""
echo "=== Success! ==="
echo "Test frames: $TEST_DIR/"
echo "Test video: videos/test_video.mp4"
echo ""
echo "View the video to verify quality and framing:"
echo "  xdg-open videos/test_video.mp4"
echo ""
echo "If everything looks good, you're ready to record full sessions!"
echo "To clean up test files:"
echo "  rm -rf $TEST_DIR videos/test_video.mp4"
