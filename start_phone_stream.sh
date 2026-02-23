#!/bin/bash

# Script to stream IP Webcam from Android phone to virtual webcam device
# This creates a virtual webcam at /dev/video20 that can be used by OpenCV

set -e

echo "=== IP Webcam to Virtual Device Setup ==="
echo ""

# Check if v4l2loopback is installed
if ! modinfo v4l2loopback &>/dev/null; then
    echo "ERROR: v4l2loopback kernel module not found!"
    echo "Please install it first with:"
    echo "  sudo apt update && sudo apt install -y v4l2loopback-dkms v4l2loopback-utils"
    exit 1
fi

# Check if ffmpeg is installed
if ! command -v ffmpeg &>/dev/null; then
    echo "ERROR: ffmpeg not found!"
    echo "Please install it with: sudo apt install -y ffmpeg"
    exit 1
fi

# Load v4l2loopback module if not already loaded
if ! lsmod | grep -q v4l2loopback; then
    echo "Loading v4l2loopback kernel module..."
    sudo modprobe v4l2loopback devices=1 video_nr=20 card_label="IPWebcam" exclusive_caps=1
    echo "Virtual webcam created at /dev/video20"
else
    echo "v4l2loopback module already loaded"
fi

# Verify the device exists
if [ ! -e /dev/video20 ]; then
    echo "ERROR: /dev/video20 does not exist!"
    echo "Try reloading the module:"
    echo "  sudo modprobe -r v4l2loopback"
    echo "  sudo modprobe v4l2loopback devices=1 video_nr=20 card_label=\"IPWebcam\" exclusive_caps=1"
    exit 1
fi

echo ""
echo "Virtual webcam ready at /dev/video20"
echo ""

# Prompt for phone IP address
echo "=== IP Webcam Setup Instructions ==="
echo "1. Install 'IP Webcam' app from Google Play Store on your Android phone"
echo "2. Open the app and scroll down to 'Start server'"
echo "3. Tap 'Start server' - it will show an IP address like 192.168.x.x:8080"
echo ""
read -p "Enter your phone's IP address (e.g., 192.168.1.100): " PHONE_IP

# Validate IP format (basic check)
if [[ ! $PHONE_IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "ERROR: Invalid IP address format"
    exit 1
fi

STREAM_URL="http://${PHONE_IP}:8080/video"
echo ""
echo "Testing connection to $STREAM_URL..."

# Test if we can reach the stream
if ! curl -s --max-time 5 "$STREAM_URL" >/dev/null 2>&1; then
    echo "WARNING: Cannot connect to IP Webcam stream!"
    echo "Make sure:"
    echo "  - Your phone and computer are on the same WiFi network"
    echo "  - IP Webcam server is running on your phone"
    echo "  - The IP address is correct: $PHONE_IP"
    echo ""
    read -p "Do you want to continue anyway? (y/n): " CONTINUE
    if [[ ! $CONTINUE =~ ^[Yy] ]]; then
        exit 1
    fi
fi

echo ""
echo "Starting ffmpeg stream from phone to /dev/video20..."
echo "This will run in the background. Press Ctrl+C to stop."
echo ""

# Stream from IP Webcam to virtual device
# -f mjpeg: Input format from IP Webcam
# -i: Input URL
# -vcodec rawvideo: Output raw video for v4l2
# -pix_fmt yuyv422: Pixel format compatible with most applications
# -f v4l2: Output to v4l2 device
ffmpeg -f mjpeg \
    -i "$STREAM_URL" \
    -vcodec rawvideo \
    -pix_fmt yuyv422 \
    -f v4l2 \
    /dev/video20

# If ffmpeg exits, show message
echo ""
echo "Stream stopped."
echo "To restart, run: ./start_phone_stream.sh"
