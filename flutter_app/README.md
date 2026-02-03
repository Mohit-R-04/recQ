# Lost & Found System - Flutter Frontend

A modern Flutter mobile application for the Lost & Found System, integrated with the Spring Boot backend.

## Features

✨ **Authentication**
- User registration and login
- Secure session management
- Profile management

📱 **Item Management**
- Report lost items
- Report found items
- View all items with filters (All, Lost, Found, My Items)
- Detailed item view with images
- Edit and delete own items
- Image upload support

💬 **Comments**
- Add comments to items
- View all comments on an item

🎨 **Modern UI**
- Material Design 3
- Beautiful gradient backgrounds
- Smooth animations
- Responsive layouts
- Pull-to-refresh
- Loading states

## Prerequisites

- Flutter SDK (3.10.7 or higher)
- Dart SDK
- Android Studio / Xcode (for mobile development)
- Running Spring Boot backend on `http://localhost:8080`

## Setup Instructions

### 1. Configure Backend URL

Edit `lib/config/api_config.dart` and update the `baseUrl` if your backend is running on a different address:

```dart
static const String baseUrl = 'http://localhost:8080'; // Change this if needed
```

**Note for Android Emulator:** Use `http://10.0.2.2:8080` instead of `localhost`
**Note for iOS Simulator:** Use `http://localhost:8080` or your machine's IP address

### 2. Install Dependencies

```bash
cd flutter_app
flutter pub get
```

### 3. Run the Backend

Make sure your Spring Boot backend is running:

```bash
cd ..
./mvnw spring-boot:run
```

### 4. Run the Flutter App

For Android:
```bash
flutter run
```

For iOS:
```bash
flutter run
```

For Web:
```bash
flutter run -d chrome
```

## Project Structure

```
flutter_app/
├── lib/
│   ├── config/
│   │   └── api_config.dart          # API endpoints configuration
│   ├── models/
│   │   ├── user.dart                # User model
│   │   └── lost_found_item.dart     # Item and Comment models
│   ├── providers/
│   │   └── app_provider.dart        # State management
│   ├── screens/
│   │   ├── splash_screen.dart       # Initial loading screen
│   │   ├── login_screen.dart        # Login page
│   │   ├── register_screen.dart     # Registration page
│   │   ├── home_screen.dart         # Main items list
│   │   ├── item_detail_screen.dart  # Item details
│   │   ├── create_item_screen.dart  # Report new item
│   │   └── profile_screen.dart      # User profile
│   ├── services/
│   │   └── api_service.dart         # API communication
│   └── main.dart                    # App entry point
└── pubspec.yaml                     # Dependencies
```

## API Integration

The app communicates with the following REST API endpoints:

### Authentication
- `POST /api/auth/login` - User login
- `POST /api/auth/register` - User registration
- `POST /api/auth/logout` - User logout
- `GET /api/auth/me` - Get current user

### Items
- `GET /api/items` - Get all items
- `GET /api/items/{id}` - Get item by ID
- `GET /api/items/user/{userId}` - Get items by user
- `POST /api/items` - Create new item
- `PUT /api/items/{id}` - Update item
- `DELETE /api/items/{id}` - Delete item
- `POST /api/items/upload` - Upload image

### Comments
- `POST /api/items/{id}/comments` - Add comment to item

## Default Credentials

Use the admin account created by the backend:
- **Username:** `admin`
- **Password:** `admin`

## Features by Screen

### Home Screen
- Filter items by type (All, Lost, Found, My Items)
- Pull to refresh
- Beautiful card-based layout
- Quick navigation to item details

### Item Detail Screen
- Full item information
- Image display
- Reporter contact details
- Comments section
- Delete option (for item owner/admin)

### Create Item Screen
- Image upload with preview
- Type selection (Lost/Found)
- Category dropdown
- Date picker
- Form validation
- Auto-filled reporter info from user profile

### Profile Screen
- User information display
- Quick access to "My Items"
- Logout functionality

## Troubleshooting

### Cannot connect to backend

1. **Android Emulator:** Use `http://10.0.2.2:8080` instead of `localhost`
2. **iOS Simulator:** Make sure backend is accessible at `localhost:8080`
3. **Physical Device:** Use your computer's IP address (e.g., `http://192.168.1.100:8080`)

### Image upload not working

1. Make sure the `uploads` folder exists in `src/main/resources/static/`
2. Check file permissions
3. Verify the backend is configured to serve static files

### CORS errors

The backend has been configured to allow all origins with `@CrossOrigin(origins = "*")` in the REST controller.

## Building for Production

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

### Web
```bash
flutter build web --release
```

## Technologies Used

- **Flutter** - UI framework
- **Provider** - State management
- **HTTP** - API communication
- **Shared Preferences** - Local storage
- **Image Picker** - Image selection
- **Cached Network Image** - Image caching
- **Intl** - Date formatting
- **Material Design 3** - UI components

## License

This project is part of the Lost & Found System.
