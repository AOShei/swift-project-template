#!/bin/bash
set -e

echo "🔨 Building Project..."
# Using -c debug for faster compilation than release
swift build --jobs 2

echo ""
echo "✅ Build Complete!"
echo "👉 To start the server, run: swift run App"
echo "------------------------------------------------"