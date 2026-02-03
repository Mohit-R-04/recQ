# Lost & Found System

A comprehensive Lost & Found management system with a **Spring Boot** backend and **Flutter** mobile application.

## 🌟 Overview

This system allows users to report and find lost items through a modern mobile application. It features user authentication, item management with images, comments, and filtering capabilities.

## 🏗️ Architecture

### Backend
- **Framework:** Spring Boot 2.x
- **Language:** Java 11
- **Database:** H2 (configurable for MySQL/PostgreSQL)
- **Security:** Spring Security with session-based auth
- **API:** RESTful JSON API

### Frontend
- **Framework:** Flutter 3.10.7+
- **Language:** Dart
- **State Management:** Provider
- **Platforms:** Android, iOS, Web, Desktop (macOS, Windows, Linux)
- **UI:** Material Design 3

## ✨ Features

### User Management
- ✅ User registration and login
- ✅ Role-based access (Admin/User)
- ✅ Profile management
- ✅ Session persistence

### Item Management
- ✅ Report lost items
- ✅ Report found items
- ✅ Upload item images
- ✅ View all items with filters
- ✅ Detailed item view
- ✅ Edit/delete own items
- ✅ Admin can manage all items

### Social Features
- ✅ Comment on items
- ✅ View all comments
- ✅ Contact reporter directly

### UI/UX
- ✅ Modern Material Design 3
- ✅ Gradient backgrounds
- ✅ Smooth animations
- ✅ Pull-to-refresh
- ✅ Loading states
- ✅ Error handling
- ✅ Responsive layouts

## 🚀 Quick Start

### Prerequisites
- Java 11 or higher
- Maven 3.6+
- Flutter 3.10.7+
- Android Studio / Xcode (for mobile development)

### Option 1: Using the Start Script

```bash
# Make script executable (first time only)
chmod +x start.sh

# Run the script
./start.sh

# In another terminal, run Flutter app
cd flutter_app
flutter run
```

### Option 2: Manual Setup

**Terminal 1 - Start Backend:**
```bash
./mvnw spring-boot:run
```

**Terminal 2 - Run Flutter App:**
```bash
cd flutter_app
flutter pub get
flutter run
```

The backend will be available at `http://localhost:8080`

### Authentication

This system uses **Spring Security** for secure user authentication:

- Username/Password authentication
- Session-based authentication
- Role-based access control (USER, ADMIN)
- Beautiful Flutter login UI

**Default Admin Credentials:**
- Username: `admin`
- Password: `Admin11@`

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

## 📊 Project Statistics

### Backend
- **Controllers:** 1 (REST API only)
- **Services:** 4
- **Repositories:** 5
- **Domain Models:** 8
- **REST Endpoints:** 12+
- **Architecture:** Pure REST API (no web UI)

### Flutter App
- **Screens:** 7
- **Models:** 3
- **Services:** 1
- **Providers:** 1
- **Total Lines of Code:** ~2,500
- **Dependencies:** 78 packages

## 📁 Project Structure

```
recQ/
├── src/                                    # Spring Boot Backend
│   ├── main/
│   │   ├── java/.../lostandfoundsystem/
│   │   │   ├── config/                    # Security, CORS
│   │   │   ├── domain/                    # Entities
│   │   │   ├── repositories/              # Data access
│   │   │   ├── services/                  # Business logic
│   │   │   ├── web/controller/            # REST API Controller
│   │   │   └── LostAndFoundSystemApplication.java
│   │   └── resources/
│   │       ├── static/uploads/            # Uploaded images
│   │       └── application.properties
│   └── test/
├── flutter_app/                           # Flutter Frontend
│   ├── lib/
│   │   ├── config/                        # API config
│   │   ├── models/                        # Data models
│   │   ├── providers/                     # State management
│   │   ├── screens/                       # UI screens
│   │   ├── services/                      # API services
│   │   └── main.dart
│   ├── android/                           # Android config
│   ├── ios/                               # iOS config
│   ├── web/                               # Web config
│   └── pubspec.yaml
├── pom.xml                                # Maven config
├── start.sh                               # Quick start script
├── CLEANUP_SUMMARY.md                     # Cleanup details
├── MIGRATION_SUMMARY.md                   # Migration details
├── FLUTTER_MIGRATION.md                   # Complete guide
└── README.md                              # This file
```

## 🔌 API Endpoints

### Authentication
```
POST   /api/auth/login          - User login
POST   /api/auth/register       - User registration
POST   /api/auth/logout         - User logout
GET    /api/auth/me             - Get current user
```

### Items
```
GET    /api/items               - Get all items
GET    /api/items/{id}          - Get item by ID
GET    /api/items/user/{id}     - Get user's items
POST   /api/items               - Create item
PUT    /api/items/{id}          - Update item
DELETE /api/items/{id}          - Delete item
POST   /api/items/upload        - Upload image
```

### Comments
```
POST   /api/items/{id}/comments - Add comment
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

## 🧪 Testing

### Test Backend API

```bash
# Login
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin"}'

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
