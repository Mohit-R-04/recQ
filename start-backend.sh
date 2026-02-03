#!/bin/bash

echo "========================================="
echo "Starting Backend Only"
echo "========================================="
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

# Check if port 8080 is already in use
if lsof -Pi :8080 -sTCP:LISTEN -t > /dev/null ; then
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

echo "🚀 Starting Spring Boot backend..."
echo "   Backend will run on http://localhost:8080"
echo ""

# Start backend
mvn spring-boot:run

echo ""
echo "========================================="
echo "Backend stopped"
echo "========================================="
