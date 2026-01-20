#!/bin/bash

echo "========================================="
echo "Lost & Found System - Quick Start"
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

# Check if Java is installed
if ! command -v java &> /dev/null; then
    echo "❌ Java is not installed!"
    echo "Please install Java 11 or higher"
    exit 1
fi

echo "✅ Java is installed"
java -version
echo ""

# Create uploads directory if it doesn't exist
echo "📁 Creating uploads directory..."
mkdir -p src/main/resources/static/uploads
echo "✅ Uploads directory ready"
echo ""

# Start backend in background
echo "🚀 Starting Spring Boot backend..."
echo "   Backend will run on http://localhost:8080"
echo ""

# Check if port 8080 is already in use
if lsof -Pi :8080 -sTCP:LISTEN -t >/dev/null ; then
    echo "⚠️  Port 8080 is already in use!"
    echo "   Do you want to kill the existing process? (y/n)"
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        echo "   Killing process on port 8080..."
        lsof -ti:8080 | xargs kill -9
        sleep 2
    else
        echo "   Please stop the process manually and try again"
        exit 1
    fi
fi

# Start backend
./mvnw spring-boot:run > backend.log 2>&1 &
BACKEND_PID=$!
echo "✅ Backend started (PID: $BACKEND_PID)"
echo "   Logs: tail -f backend.log"
echo ""

# Wait for backend to start
echo "⏳ Waiting for backend to start..."
sleep 10

# Check if backend is running
if curl -s http://localhost:8080/actuator/health > /dev/null 2>&1 || curl -s http://localhost:8080 > /dev/null 2>&1; then
    echo "✅ Backend is running!"
else
    echo "⚠️  Backend might still be starting... Check backend.log for details"
fi
echo ""

# Flutter setup
echo "📱 Setting up Flutter app..."
cd flutter_app

if [ ! -d ".dart_tool" ]; then
    echo "   Installing Flutter dependencies..."
    flutter pub get
fi

echo ""
echo "========================================="
echo "✅ Setup Complete!"
echo "========================================="
echo ""
echo "Backend is running at: http://localhost:8080"
echo "Backend PID: $BACKEND_PID"
echo ""
echo "To run the Flutter app:"
echo "  cd flutter_app"
echo "  flutter run              # Run on default device"
echo "  flutter run -d chrome    # Run on web browser"
echo "  flutter run -d macos     # Run on macOS"
echo ""
echo "To stop the backend:"
echo "  kill $BACKEND_PID"
echo ""
echo "Default login credentials:"
echo "  Username: admin"
echo "  Password: admin"
echo ""
echo "View backend logs:"
echo "  tail -f backend.log"
echo ""
echo "========================================="
