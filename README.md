# Lost & Found System

A comprehensive Lost & Found management system with a **Spring Boot** backend and **Flutter** mobile application.

## 🌟 Overview

This system allows users to report and find lost items through a modern mobile application. It includes an ML service for classification, embeddings, and item matching, plus user authentication, item management with images, comments, and filtering capabilities.

## 🏗️ Architecture

### Backend

- **Framework:** Spring Boot 2.6.2
- **Language:** Java 17
- **Database:** H2 (configurable for MySQL/PostgreSQL)
- **Security:** Spring Security with session-based auth
- **API:** RESTful JSON API

### ML Service

- **Framework:** Flask
- **Language:** Python
- **ML:** TensorFlow (classification + image embeddings), SBERT text embeddings
- **Purpose:** Image/text embeddings, matching, and question generation
- **Default port:** 5000

### Frontend

- **Framework:** Flutter 3.10.7+
- **Language:** Dart
- **State Management:** Provider
- **Platforms:** Android, iOS, Web, Desktop (macOS, Windows, Linux)
- **UI:** Material Design 3

## ✨ Features

### Core User Flow

- ✅ Register/login with session-based auth
- ✅ Report lost/found items with images
- ✅ Browse and filter items (All/Lost/Found/My/Given)
- ✅ View item details and comments

### Matching & Claims

- ✅ ML-powered matching (image + text)
- ✅ Match confirmation and dismissal
- ✅ Claim workflow with verification questions
- ✅ Admin review of claims and status updates

### Notifications

- ✅ Match and claim notifications
- ✅ Unread counts and mark-as-read

### Admin Capabilities

- ✅ Manage all items
- ✅ Review and resolve claims
- ✅ View restricted item details

### UI/UX

- ✅ Modern Material Design 3
- ✅ Gradient backgrounds
- ✅ Pull-to-refresh
- ✅ Loading and error states
- ✅ Responsive layouts

## 🚀 Quick Start

### Prerequisites

- Java 17
- Maven 3.6+
- Flutter 3.10.7+
- Python 3 + pip (for `ml_service`)
- Android Studio / Xcode (for mobile development)

### Option 1: Using the Start Script

```bash
# Make script executable (first time only)
chmod +x start.sh

# Run the script
./start.sh

# In another terminal, start the ML service
cd ml_service
python -m pip install -r requirements.txt
python app.py

# In another terminal, run Flutter app
cd flutter_app
flutter run
```

> Note: `start.sh`/`start-*.sh` are bash scripts. On Windows, run them via Git Bash/WSL or use the manual steps below.

### Option 2: Manual Setup

**Terminal 1 - Start Backend:**

```bash
./mvnw spring-boot:run
```

Ensure the uploads folder exists at `src/main/resources/static/uploads`.

**Terminal 2 - Start ML Service:**

```bash
cd ml_service
python -m pip install -r requirements.txt
python app.py
```

**Terminal 3 - Run Flutter App:**

```bash
cd flutter_app
flutter pub get
flutter run
```

The backend will be available at `http://localhost:8080`
The ML service will be available at `http://localhost:5000`

## 🧭 Workflows

### Reporting an Item

1. User reports a lost/found item with title, description, category, and image.
2. The ML service performs image classification (using EfficientNetB0) to suggest item category based on the uploaded image.
3. Backend stores the item and image under `static/uploads`.
4. Backend requests embeddings from the ML service.
5. Matches are generated for the new item.

### Matching & Confirmation

1. System proposes matches based on ML similarity.
2. Lost-item owner can confirm a match or dismiss it.
3. Confirmed matches unlock the claim workflow.

### Claiming an Item

1. Lost-item owner submits a claim for the found item.
2. ML service generates verification questions for the claim.
3. Admin reviews the claim and approves or rejects it.

### Notifications

1. Users receive notifications for matches and claim updates.
2. Notifications can be marked as read or cleared.

## 🧰 Developer Workflows

**Scripts (bash):**

- `./start.sh` - Quick start (backend + Flutter setup)
- `./start-backend.sh` - Backend only
- `./start-frontend.sh` - Flutter only (prompts for device)

**Common commands:**

```bash
./mvnw clean package -DskipTests
cd flutter_app
flutter pub get
flutter run
```

### Authentication

This system uses **Spring Security** for secure user authentication:

- Username/Password authentication
- Session-based authentication
- Role-based access control (USER, ADMIN)
- Beautiful Flutter login UI

**Default Admin Credentials:**

- Username: `admin`
- Password: `Admin@123`

## 📱 Running on Different Platforms

```bash
cd flutter_app

# Android
flutter run -d android

# iOS
flutter run -d ios

# Web
flutter run -d chrome

# macOS
flutter run -d macos

# Windows
flutter run -d windows

# Linux
flutter run -d linux
```

## 📁 Project Structure

```
recQ/
├── src/                                    # Spring Boot backend
│   ├── main/
│   │   ├── java/.../lostandfoundsystem/
│   │   │   ├── config/                    # Security, CORS
│   │   │   ├── domain/                    # Entities
│   │   │   ├── repositories/              # Data access
│   │   │   ├── services/                  # Business logic
│   │   │   ├── web/controller/            # REST API controller
│   │   │   └── LostAndFoundSystemApplication.java
│   │   └── resources/
│   │       ├── static/uploads/            # Uploaded images
│   │       └── application.properties
│   └── test/
├── ml_service/                             # Flask ML service
│   ├── app.py                              # API entry point
│   ├── requirements.txt
│   └── models/
├── flutter_app/                            # Flutter frontend
│   ├── lib/
│   │   ├── config/                        # API config
│   │   ├── models/                        # Data models
│   │   ├── providers/                     # State management
│   │   ├── screens/                       # UI screens
│   │   ├── services/                      # API services
│   │   └── main.dart
│   ├── android/
│   ├── ios/
│   ├── web/
│   └── pubspec.yaml
├── pom.xml                                 # Maven config
├── start.sh                                # Quick start script
├── start-backend.sh                        # Backend script
├── start-frontend.sh                       # Frontend script
├── Dockerfile
├── CLEANUP_SUMMARY.md
├── MIGRATION_SUMMARY.md
├── FLUTTER_MIGRATION.md
└── README.md
```

## 🔌 API Endpoints

### Backend (Spring Boot)

**Authentication**

```
POST   /api/auth/login
POST   /api/auth/register
POST   /api/auth/logout
GET    /api/auth/me
POST   /api/auth/send-otp
POST   /api/auth/verify-otp
GET    /api/auth/can-resend-otp
POST   /api/auth/reset-password
```

**Items & Comments**

```
GET    /api/items
GET    /api/items/{itemId}
GET    /api/items/user/{userId}
POST   /api/items
POST   /api/items/upload
PUT    /api/items/{itemId}
PUT    /api/items/{itemId}/description
DELETE /api/items/{itemId}
POST   /api/items/{itemId}/comments
POST   /api/items/{itemId}/find-matches
```

**Matches**

```
GET    /api/matches
GET    /api/matches/all
GET    /api/matches/{matchId}
POST   /api/matches/{matchId}/confirm
POST   /api/matches/{matchId}/dismiss
GET    /api/matches/count
```

**Notifications**

```
GET    /api/notifications
GET    /api/notifications/unread
GET    /api/notifications/count
POST   /api/notifications/{notificationId}/read
POST   /api/notifications/read-all
DELETE /api/notifications/{notificationId}
```

**Claims**

```
GET    /api/claims/questions/{itemId}
POST   /api/claims
GET    /api/claims/my
GET    /api/claims/item/{itemId}
GET    /api/claims/admin/all
GET    /api/claims/{claimId}
POST   /api/claims/{claimId}/review
GET    /api/claims/check/{itemId}
```

### ML Service (Flask)

**What it does**

- Image classification for item category mapping (EfficientNetB0)
- Text embeddings (SBERT) and image embeddings (EfficientNetB0)
- Match scoring and retrieval
- Claim question generation (templates + optional T5)

```
GET    /health
POST   /classify
GET    /categories
POST   /embeddings/text
POST   /embeddings/image
POST   /embeddings/item
POST   /matching/register
POST   /matching/find
POST   /matching/compare
GET    /matching/all
DELETE /matching/unregister/<item_id>
GET    /matching/stats
POST   /generate-questions
```

## ⚙️ Configuration

### Backend Configuration

Edit `src/main/resources/application.properties`:

```properties
# Server port
server.port=8080

# Database (H2 default)
spring.datasource.url=jdbc:h2:mem:testdb
spring.datasource.driverClassName=org.h2.Driver

# For MySQL
# spring.datasource.url=jdbc:mysql://localhost:3306/lostandfound
# spring.datasource.username=root
# spring.datasource.password=password
```

### Flutter Configuration

Edit `flutter_app/lib/config/api_config.dart`:

```dart
class ApiConfig {
  static const String baseUrl = 'http://localhost:8080';
  // For Android emulator: 'http://10.0.2.2:8080'
  // For physical device: 'http://YOUR_IP:8080'
}
```

### ML Service Configuration

The ML service reads optional environment variables from `ml_service/.env`:

```
QG_USE_TRANSFORMER=true   # Enable transformer-based question generation
QG_T5_MODEL=valhalla/t5-small-qg-hl
```

## 🧪 Testing

### Test Backend API

```bash
# Login
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"Admin@123"}'

# Get all items
curl http://localhost:8080/api/items
```

### Test Flutter App

1. Launch the app
2. Login with admin credentials
3. Create a new item with image
4. View item details
5. Add comments
6. Test filtering
7. Test logout

## 📦 Building for Production

### Backend

```bash
# Build JAR
./mvnw clean package -DskipTests

# Run JAR
java -jar target/lost-and-found-system-0.0.1-SNAPSHOT.jar
```

### Flutter

**Android:**

```bash
cd flutter_app
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

**iOS:**

```bash
flutter build ios --release
# Then archive via Xcode
```

**Web:**

```bash
flutter build web --release
# Deploy build/web folder
```

## 🐛 Troubleshooting

### Backend Issues

**Port 8080 already in use:**

```bash
lsof -ti:8080 | xargs kill -9
```

**Windows alternative:**

```powershell
netstat -ano | findstr :8080
taskkill /PID <PID> /F
```

**Port 5000 already in use (ML service):**

```bash
lsof -ti:5000 | xargs kill -9
```

**Database errors:**

- Check `application.properties`
- Access H2 console at `/h2-console`

### Flutter Issues

**Cannot connect to backend:**

- Android emulator: Use `10.0.2.2:8080`
- iOS simulator: Use `localhost:8080`
- Physical device: Use your machine's IP

**Dependencies not resolving:**

```bash
cd flutter_app
flutter clean
flutter pub get
```

**Build errors:**

```bash
flutter clean
flutter pub get
flutter run
```

### ML Service Issues

**First run is slow:**

- The service downloads ML models (TensorFlow, SBERT, optional T5) on first run.
- If you don't need transformer-based question generation, set `QG_USE_TRANSFORMER=false`.

## 📚 Documentation

- **[CLEANUP_SUMMARY.md](CLEANUP_SUMMARY.md)** - Details of removed web UI files
- **[MIGRATION_SUMMARY.md](MIGRATION_SUMMARY.md)** - Quick migration overview
- **[FLUTTER_MIGRATION.md](FLUTTER_MIGRATION.md)** - Complete migration guide
- **[ARCHITECTURE.md](ARCHITECTURE.md)** - System architecture diagrams
- **[flutter_app/README.md](flutter_app/README.md)** - Flutter app documentation

## 🎯 Key Features Checklist

- [x] User authentication (login/register)
- [x] Report lost items
- [x] Report found items
- [x] Upload images
- [x] View all items
- [x] Filter items (All/Lost/Found/My Items)
- [x] Item details with comments
- [x] Add comments
- [x] Edit/delete items
- [x] User profile
- [x] Session persistence
- [x] Pull-to-refresh
- [x] Error handling
- [x] Loading states
- [x] Responsive design
- [x] Cross-platform support

## 🚀 Next Steps

### Recommended Enhancements

1. **Authentication:** Implement JWT tokens
2. **Features:** Add search, push notifications, real-time updates
3. **UI:** Add dark mode, animations, image gallery
4. **Backend:** Add pagination, email notifications, rate limiting
5. **Testing:** Add unit tests, integration tests, E2E tests

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is an educational Lost & Found System.

## 🙏 Acknowledgments

- Spring Boot team for the excellent framework
- Flutter team for the amazing cross-platform toolkit
- Material Design for the beautiful UI components

---

## 💡 Tips

- **For Android Emulator:** Always use `10.0.2.2` instead of `localhost`
- **For iOS Simulator:** Use `localhost` or your machine's IP
- **For Physical Devices:** Use your computer's IP address
- **Check Backend Logs:** `tail -f backend.log` (if using start.sh)
- **Check Flutter Logs:** Look at console output when running app

## 📞 Support

For issues:

1. Check the troubleshooting section
2. Review documentation files
3. Check backend and Flutter logs
4. Verify network connectivity

---

**Built with ❤️ using Spring Boot and Flutter**
