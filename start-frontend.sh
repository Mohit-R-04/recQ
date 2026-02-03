#!/bin/bash

echo "========================================="
echo "Starting Frontend Only"
echo "========================================="
echo ""

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed!"
    echo "Please install Flutter from: https://flutter.dev/docs/get-started/install"
    exit 1
fi

echo "✅ Flutter is installed"
flutter --version
echo ""

# Check if backend is running
if ! curl -s http://localhost:8080 > /dev/null 2>&1; then
    echo "⚠️  Warning: Backend doesn't seem to be running on http://localhost:8080"
    echo "   Please start the backend first using: ./start-backend.sh"
    echo ""
    echo "   Do you want to continue anyway? (y/n)"
    read -r response
    if [[ ! "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        exit 1
    fi
fi

# Navigate to flutter_app directory
cd flutter_app

# Install dependencies if needed
if [ ! -d ".dart_tool" ]; then
    echo "📦 Installing Flutter dependencies..."
    flutter pub get
    echo ""
fi

echo "🚀 Starting Flutter app..."
echo ""
echo "Available options:"
echo "  1) Chrome (Web Browser)"
echo "  2) macOS (Desktop App)"
echo "  3) Default Device"
echo ""
echo "Enter your choice (1-3) or press Enter for Chrome:"
read -r choice

case $choice in
    2)
        echo "Starting on macOS..."
        flutter run -d macos
        ;;
    3)
        echo "Starting on default device..."
        flutter run
        ;;
    *)
        echo "Starting on Chrome..."
        flutter run -d chrome
        ;;
esac

echo ""
echo "========================================="
echo "Frontend stopped"
echo "========================================="
