# Lost & Found System - Running Guide

## 🚀 Quick Start

### Option 1: Run Everything Together
```bash
./start.sh
```
This will start both backend and frontend automatically.

---

## 🔧 Running Backend and Frontend Separately

### Backend Only
```bash
./start-backend.sh
```
- Runs on: `http://localhost:8080`
- Database: H2 (file-based at `./data/lostandfound`)
- H2 Console: `http://localhost:8080/h2-console`

### Frontend Only
```bash
./start-frontend.sh
```
- Interactive menu to choose device (Chrome/macOS/Default)
- Checks if backend is running before starting

---

## 📋 Current Status

### Backend
- **Status**: ✅ Running
- **PID**: 62772
- **URL**: http://localhost:8080
- **Logs**: `tail -f backend.log`

### Frontend
- **Status**: ✅ Running on Chrome
- **Command ID**: 32ff34b9-591d-4626-b8c5-f673afb4b844

---

## 🛑 Stopping Services

### Stop Backend
```bash
# Find the process
lsof -ti:8080

# Kill the process
kill $(lsof -ti:8080)

# Or force kill
kill -9 $(lsof -ti:8080)
```

### Stop Frontend
Press `q` in the terminal where Flutter is running, or:
```bash
# Press Ctrl+C in the Flutter terminal
```

---

## 🔑 Default Credentials

- **Username**: `admin`
- **Password**: `admin`

---

## 📱 Flutter Run Options

When running frontend separately, you can choose:

1. **Chrome** (Web Browser) - Recommended for development
   ```bash
   cd flutter_app
   flutter run -d chrome
   ```

2. **macOS** (Desktop App)
   ```bash
   cd flutter_app
   flutter run -d macos
   ```

3. **Default Device**
   ```bash
   cd flutter_app
   flutter run
   ```

---

## 🔥 Flutter Hot Reload Commands

When the Flutter app is running:
- `r` - Hot reload
- `R` - Hot restart
- `h` - List all available commands
- `d` - Detach (keep app running)
- `c` - Clear the screen
- `q` - Quit

---

## 🛠️ Useful Commands

### Check Backend Health
```bash
curl http://localhost:8080/actuator/health
```

### View Backend Logs
```bash
tail -f backend.log
```

### Check Running Processes
```bash
# Check backend
lsof -ti:8080

# Check all Java processes
ps aux | grep java
```

### Rebuild Backend
```bash
./mvnw clean install
```

### Flutter Clean Build
```bash
cd flutter_app
flutter clean
flutter pub get
flutter run -d chrome
```

---

## 📂 Project Structure

```
recQ/
├── src/                          # Backend source code
│   └── main/
│       ├── java/                 # Java source files
│       └── resources/            # Configuration files
│           └── static/uploads/   # File uploads directory
├── flutter_app/                  # Frontend Flutter app
│   ├── lib/                      # Dart source files
│   └── pubspec.yaml              # Flutter dependencies
├── data/                         # H2 Database files
├── backend.log                   # Backend logs
├── start.sh                      # Start both services
├── start-backend.sh              # Start backend only
├── start-frontend.sh             # Start frontend only
└── RUNNING.md                    # This file
```

---

## 🐛 Troubleshooting

### Port 8080 Already in Use
```bash
# Kill the process using port 8080
lsof -ti:8080 | xargs kill -9
```

### Backend Won't Start
1. Check Java version: `java -version` (need Java 11+)
2. Check logs: `tail -f backend.log`
3. Clean and rebuild: `./mvnw clean install`

### Frontend Won't Start
1. Check Flutter: `flutter doctor`
2. Clean Flutter: `cd flutter_app && flutter clean && flutter pub get`
3. Ensure backend is running: `curl http://localhost:8080`

### Database Issues
1. Stop backend
2. Delete database: `rm -rf data/`
3. Restart backend (will recreate database)

---

## 📊 System Requirements

- **Java**: 11 or higher (Currently using OpenJDK 21.0.8)
- **Flutter**: 3.0+ (Currently using 3.38.6)
- **Dart**: 3.0+ (Currently using 3.10.7)
- **Maven**: Included via Maven Wrapper (./mvnw)

---

## 🌐 API Endpoints

- **Base URL**: http://localhost:8080
- **H2 Console**: http://localhost:8080/h2-console
- **Health Check**: http://localhost:8080/actuator/health

---

## 📝 Notes

- The backend uses an H2 file-based database stored in `./data/lostandfound`
- Uploaded files are stored in `src/main/resources/static/uploads/`
- DevTools are enabled for Spring Boot (LiveReload on port 35729)
- Data loader skips initialization if data already exists
