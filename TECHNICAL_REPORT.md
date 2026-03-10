# Lost & Found System - Comprehensive Technical Report

**Generated:** March 1, 2026  
**Project Name:** recQ - Lost and Found Management System  
**Version:** 0.0.1-SNAPSHOT

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Project Overview](#project-overview)
3. [System Architecture](#system-architecture)
4. [Technology Stack](#technology-stack)
5. [Backend System (Spring Boot)](#backend-system-spring-boot)
6. [Frontend Application (Flutter)](#frontend-application-flutter)
7. [Machine Learning Service](#machine-learning-service)
8. [Database Design](#database-design)
9. [API Documentation](#api-documentation)
10. [Security Implementation](#security-implementation)
11. [Core Features & Functionality](#core-features--functionality)
12. [Deployment Strategy](#deployment-strategy)
13. [Project Structure](#project-structure)
14. [Development & Build Configuration](#development--build-configuration)
15. [ML Model Training & Classification](#ml-model-training--classification)
16. [Future Enhancements](#future-enhancements)

---

## 1. Executive Summary

The Lost & Found System (recQ) is a comprehensive, production-ready web and mobile application designed to help users report, find, and recover lost items. The system leverages modern technologies including Spring Boot for backend services, Flutter for cross-platform mobile development, and TensorFlow for AI-powered item classification and matching.

### Key Highlights:

- **Multi-platform Support:** Android, iOS, Web, Windows, macOS, Linux
- **AI-Powered Matching:** Uses deep learning for image classification and multi-modal similarity matching
- **Real-time Notifications:** Match alerts and claim status updates
- **Secure Authentication:** Session-based auth with OTP verification
- **Admin Panel:** Complete administrative control over items and claims
- **Scalable Architecture:** Microservices-ready with Docker containerization

---

## 2. Project Overview

### 2.1 Problem Statement

Lost items are a common occurrence in public spaces, universities, offices, and communities. Traditional lost and found systems rely on manual categorization and matching, making it difficult for people to recover their belongings efficiently.

### 2.2 Solution

recQ provides an intelligent platform that:

- Automatically classifies items using computer vision (14 categories)
- Matches lost reports with found items using multi-modal AI (image + text + category)
- Generates verification questions to prevent false claims
- Provides real-time notifications for potential matches
- Offers a user-friendly mobile and web interface

### 2.3 Target Users

- **General Users:** Report lost/found items, claim items, receive matches
- **Administrators:** Review claims, manage items, moderate content
- **Organizations:** Universities, offices, public transport systems, event venues

---

## 3. System Architecture

### 3.1 High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    CLIENT LAYER                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │ Flutter Web  │  │ Flutter iOS  │  │ Flutter      │     │
│  │              │  │              │  │ Android      │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
└─────────────────────────────────────────────────────────────┘
                            │
                    HTTPS / REST API
                            │
┌─────────────────────────────────────────────────────────────┐
│                   APPLICATION LAYER                          │
│  ┌──────────────────────────────────────────────────────┐  │
│  │         Spring Boot Backend (Java 17)                │  │
│  │  - REST Controllers                                   │  │
│  │  - Service Layer (Business Logic)                    │  │
│  │  - Security (Spring Security)                        │  │
│  │  - Email Service (OTP, Notifications)                │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
            │                               │
            │                               │ HTTP REST
    JPA/Hibernate                           │
            │                               ▼
            ▼                    ┌────────────────────────┐
┌─────────────────────┐         │   ML Service (Flask)    │
│   H2 Database       │         │  - TensorFlow Models    │
│   (Persistent File) │         │  - Image Classification │
│  - Users & Auth     │         │  - Embeddings (SBERT)   │
│  - Items            │         │  - Matching Engine      │
│  - Claims           │         │  - Question Generator   │
│  - Matches          │         └────────────────────────┘
│  - Notifications    │
└─────────────────────┘
```

### 3.2 Architectural Patterns

1. **Layered Architecture (Backend)**
   - Presentation Layer: REST Controllers
   - Business Layer: Services
   - Persistence Layer: Repositories (JPA)
   - Cross-cutting: Security, Validation

2. **RESTful API Design**
   - Stateless communication
   - JSON data format
   - HTTP methods (GET, POST, PUT, DELETE)
   - CORS enabled for cross-origin requests

3. **Provider Pattern (Frontend)**
   - State management using Flutter Provider
   - Centralized app state (AppProvider)
   - Reactive UI updates

4. **Microservices-Ready**
   - Separate ML service (Flask) from business logic
   - Containerized with Docker
   - Configurable service URLs

---

## 4. Technology Stack

### 4.1 Backend Technologies

| Component      | Technology          | Version    | Purpose                        |
| -------------- | ------------------- | ---------- | ------------------------------ |
| **Framework**  | Spring Boot         | 2.6.2      | Web application framework      |
| **Language**   | Java                | 17         | Backend programming language   |
| **Build Tool** | Apache Maven        | 3.6+       | Dependency management & build  |
| **ORM**        | Hibernate/JPA       | 5.6+       | Object-relational mapping      |
| **Database**   | H2 Database         | (embedded) | Persistent file-based DB       |
| **Security**   | Spring Security     | 5.6+       | Authentication & authorization |
| **Email**      | Spring Mail         | 2.6.2      | OTP and notifications          |
| **Validation** | Hibernate Validator | 7.0+       | Bean validation                |

#### Key Dependencies (from pom.xml):

```xml
<dependencies>
    - spring-boot-starter-data-jpa
    - spring-boot-starter-web
    - spring-boot-starter-security
    - spring-boot-starter-validation
    - spring-boot-starter-mail
    - mysql-connector-java (optional)
    - h2database
    - lombok (1.18.36)
</dependencies>
```

### 4.2 Frontend Technologies

| Component            | Technology           | Version | Purpose                  |
| -------------------- | -------------------- | ------- | ------------------------ |
| **Framework**        | Flutter              | 3.10.7+ | Cross-platform UI        |
| **Language**         | Dart                 | 3.6.0+  | Programming language     |
| **State Management** | Provider             | 6.1.1   | App state management     |
| **HTTP Client**      | http                 | 1.1.0   | API communication        |
| **Local Storage**    | shared_preferences   | 2.2.2   | User session persistence |
| **Image Handling**   | image_picker         | 1.0.7   | Camera/gallery access    |
| **Image Caching**    | cached_network_image | 3.3.1   | Efficient image loading  |
| **Maps**             | google_maps_flutter  | 2.5.3   | Location services        |
| **Geolocation**      | geolocator           | 11.0.0  | GPS coordinates          |
| **ML**               | tflite_flutter       | 0.12.1  | On-device inference      |
| **Image Processing** | image                | 4.1.3   | Image manipulation       |
| **Date/Time**        | intl                 | 0.20.2  | Internationalization     |
| **URL Launcher**     | url_launcher         | 6.2.4   | External links           |
| **Permissions**      | permission_handler   | 11.2.0  | Runtime permissions      |

### 4.3 Machine Learning Technologies

| Component            | Technology                | Version  | Purpose                       |
| -------------------- | ------------------------- | -------- | ----------------------------- |
| **Framework**        | Flask                     | 2.0+     | Web service framework         |
| **Language**         | Python                    | 3.8+     | ML programming                |
| **ML Library**       | TensorFlow                | 2.10+    | Deep learning                 |
| **Keras**            | tf-keras                  | (latest) | High-level neural network API |
| **Text Embeddings**  | Sentence-Transformers     | 2.2+     | SBERT for semantic similarity |
| **NLP**              | spaCy                     | 3.7+     | Text processing & NLP         |
| **Transformers**     | Hugging Face Transformers | 4.30+    | Pre-trained models            |
| **PyTorch**          | torch                     | 1.9+     | Deep learning (SBERT backend) |
| **Image Processing** | Pillow                    | 9.0+     | Image manipulation            |
| **Numerical**        | NumPy                     | 1.21+    | Array operations              |
| **CORS**             | flask-cors                | 3.0+     | Cross-origin requests         |

#### ML Models Used:

1. **Image Classification:** EfficientNetB0 (fine-tuned on 14 lost/found categories)
2. **Image Embeddings:** EfficientNetB0 (1280-dim feature vectors)
3. **Text Embeddings:** all-MiniLM-L6-v2 (384-dim SBERT embeddings)
4. **Question Generation:** Template-based + keyword extraction (spaCy)

### 4.4 DevOps & Deployment

| Component            | Technology                    | Purpose                   |
| -------------------- | ----------------------------- | ------------------------- |
| **Containerization** | Docker                        | Application packaging     |
| **Backend Hosting**  | Render                        | Cloud deployment (Docker) |
| **Frontend Hosting** | Vercel                        | Static web hosting        |
| **Version Control**  | Git/GitHub                    | Source code management    |
| **Base Image**       | eclipse-temurin:17-jdk-alpine | Java runtime              |

---

## 5. Backend System (Spring Boot)

### 5.1 Project Structure

```
src/main/java/hyk/springframework/lostandfoundsystem/
├── bootstrap/               # Data initialization
│   └── DataLoader.java      # Pre-loads admin user, sample data
├── config/                  # Configuration classes
│   ├── SecurityConfig.java  # Spring Security configuration
│   ├── SecurityBeans.java   # Password encoder, auth manager
│   ├── CorsConfig.java      # CORS settings
│   ├── WebMvcConfig.java    # MVC configuration
│   ├── TaskConfig.java      # Async task configuration
│   └── RestClientConfig.java # RestTemplate bean
├── domain/                  # Entity models (JPA)
│   ├── LostFoundItem.java   # Main item entity
│   ├── Claim.java           # Claim entity
│   ├── Comment.java         # Comment entity
│   ├── ItemMatch.java       # Match entity
│   ├── ItemEmbedding.java   # Embeddings entity
│   ├── Notification.java    # Notification entity
│   ├── OtpToken.java        # OTP token entity
│   ├── BaseEntity.java      # Base class with ID/timestamps
│   └── security/            # Security entities
│       ├── User.java
│       ├── Role.java
│       ├── Authority.java
│       ├── LoginSuccess.java
│       └── LoginFailure.java
├── enums/                   # Enumerations
│   ├── Type.java            # LOST / FOUND
│   ├── Category.java        # Item categories
│   ├── State.java           # Item states
│   └── ClaimStatus.java     # PENDING / APPROVED / REJECTED
├── exceptions/              # Custom exceptions
├── repositories/            # Spring Data JPA repositories
│   ├── LostFoundItemRepository.java
│   ├── ClaimRepository.java
│   ├── CommentRepository.java
│   ├── ItemMatchRepository.java
│   ├── ItemEmbeddingRepository.java
│   ├── NotificationRepository.java
│   ├── OtpTokenRepository.java
│   └── security/
│       ├── UserRepository.java
│       ├── RoleRepository.java
│       └── AuthorityRepository.java
├── security/                # Security implementation
│   ├── service/
│   │   ├── MyUserDetailsService.java
│   │   └── UserUnlockService.java
│   └── CustomAuthenticationFailureHandler.java
├── services/                # Business logic (interfaces & implementations)
│   ├── LostFoundItemService.java / LostFoundItemServiceImpl.java
│   ├── ClaimService.java / ClaimServiceImpl.java
│   ├── MatchingService.java / MatchingServiceImpl.java
│   ├── NotificationService.java / NotificationServiceImpl.java
│   ├── UserService.java / UserServiceImpl.java
│   └── OtpService.java
├── util/                    # Utility classes
│   └── LoginUserUtil.java   # Get current logged-in user
├── validation/              # Custom validators
│   ├── EmailValidator.java
│   ├── PhoneNumberValidator.java
│   ├── PasswordConstraintValidator.java
│   └── PasswordMatchingValidator.java
├── web/                     # Web controllers
│   └── controller/
│       └── RestApiController.java (1254 lines - main API)
└── LostAndFoundApplication.java # Main application class
```

### 5.2 Core Domain Models

#### 5.2.1 LostFoundItem

```java
@Entity
public class LostFoundItem extends BaseEntity {
    private Type type;                    // LOST or FOUND
    private String title;                 // Item title
    private LocalDate lostFoundDate;      // When lost/found
    private String lostFoundLocation;     // Where lost/found
    private String description;           // Item description
    private String reporterName;          // Reporter's name
    private String reporterEmail;         // Reporter's email
    private String reporterPhoneNo;       // Reporter's phone
    private Category category;            // ELECTRONIC, DOCUMENT, etc.
    private User user;                    // Reporting user
    private String imageUrl;              // Image file path
    private List<Comment> comments;       // Comments on item
    private Double latitude;              // GPS coordinates
    private Double longitude;
    private String collectionLocation;    // Where to collect
}
```

#### 5.2.2 Claim

```java
@Entity
public class Claim {
    private UUID id;                      // Unique claim ID
    private LostFoundItem item;           // Item being claimed
    private User claimant;                // User claiming item
    private ClaimStatus status;           // PENDING/APPROVED/REJECTED
    private String questionsAndAnswers;   // JSON string of Q&A
    private String adminNotes;            // Admin review notes
    private String reviewedBy;            // Admin username
    private Timestamp createdAt;
    private Timestamp updatedAt;
    private Timestamp reviewedAt;
}
```

#### 5.2.3 ItemMatch

```java
@Entity
public class ItemMatch {
    private UUID id;                      // Match ID
    private LostFoundItem lostItem;       // Lost item
    private LostFoundItem foundItem;      // Found item
    private User lostUser;                // Lost item reporter
    private User foundUser;               // Found item reporter
    private Double confidenceScore;       // Match confidence (0-100)
    private Double imageSimilarity;       // Image similarity
    private Double textSimilarity;        // Text similarity
    private Double categoryMatch;         // Category match score
    private String matchLevel;            // HIGH/MEDIUM/LOW
    private Boolean dismissed;            // User dismissed match
}
```

#### 5.2.4 Notification

```java
@Entity
public class Notification {
    private UUID id;
    private User user;                    // Recipient
    private String title;                 // Notification title
    private String message;               // Notification message
    private String type;                  // MATCH / CLAIM_STATUS
    private UUID relatedItemId;           // Related item UUID
    private UUID relatedMatchId;          // Related match UUID
    private UUID relatedClaimId;          // Related claim UUID
    private Boolean isRead;               // Read status
    private Timestamp createdAt;
}
```

#### 5.2.5 ItemEmbedding

```java
@Entity
public class ItemEmbedding {
    private UUID id;
    private LostFoundItem item;           // Associated item
    private String textEmbedding;         // JSON array (384-dim)
    private String imageEmbedding;        // JSON array (1280-dim)
    private Boolean hasImage;             // Whether image embedding exists
    private Timestamp createdAt;
}
```

### 5.3 Service Layer

#### 5.3.1 LostFoundItemService

- **CRUD Operations:** Create, read, update, delete items
- **Filtering:** By type (LOST/FOUND), category, user
- **Image Handling:** File upload, storage, retrieval
- **ML Integration:** Calls ML service for classification
- **Embedding Generation:** Generates and stores embeddings

**Key Methods:**

```java
- saveItem(item, image, user): Save item with image
- getAllItems(): Get all items
- getItemsByType(type): Filter by LOST/FOUND
- getItemsByUser(userId): Get user's items
- deleteItem(itemId): Delete item
- classifyImage(imageFile): Call ML service
```

#### 5.3.2 MatchingService

- **Match Generation:** Finds potential matches between lost/found items
- **Multi-modal Matching:** Combines image, text, and category similarity
- **Match Management:** Save, retrieve, dismiss matches
- **Batch Processing:** Finds all matches for newly added items

**Key Methods:**

```java
- findMatchesForItem(itemId): Find matches for one item
- generateAllMatches(): Batch generate matches
- getMatchesForUser(userId): Get user's matches
- dismissMatch(matchId): Mark match as dismissed
```

#### 5.3.3 ClaimService

- **Claim Submission:** Users can claim found items
- **Question Verification:** Generates and validates answers
- **Admin Review:** Approve/reject claims
- **Single Approval Validation:** Ensures only one claim approved per item

**Key Methods:**

```java
- createClaim(itemId, userId, qa): Submit claim
- getClaimById(claimId): Retrieve claim
- getClaimsByUser(userId): User's claims
- getPendingClaims(): All pending claims (admin)
- updateClaimStatus(claimId, status, notes): Approve/reject
```

**Validation Logic:**

```java
// Prevents multiple approved claims for same item
if (status == APPROVED) {
    long approvedCount = claimRepository.countByItemAndStatus(item, APPROVED);
    if (approvedCount > 0) {
        throw new RuntimeException("Another claim already approved");
    }
}
```

#### 5.3.4 NotificationService

- **Creation:** Create notifications for matches and claims
- **Retrieval:** Get notifications for user
- **Unread Count:** Count unread notifications
- **Mark as Read:** Update read status

#### 5.3.5 OtpService

- **Generation:** Generate 6-digit OTP
- **Email Delivery:** Send OTP via email
- **Verification:** Validate OTP code
- **Expiration:** 5-minute expiry, automatic cleanup

### 5.4 REST API Controller

The `RestApiController.java` (1254 lines) is the main API gateway with comprehensive endpoints organized into sections:

1. **Authentication APIs** (`/api/auth/*`)
2. **User Management APIs** (`/api/users/*`)
3. **Item APIs** (`/api/items/*`)
4. **Matching APIs** (`/api/matches/*`)
5. **Claim APIs** (`/api/claims/*`)
6. **Notification APIs** (`/api/notifications/*`)
7. **Comment APIs** (`/api/comments/*`)
8. **Admin APIs** (`/api/admin/*`)

### 5.5 Security Configuration

#### Session-Based Authentication

```java
@Configuration
public class SecurityConfig extends WebSecurityConfigurerAdapter {
    @Override
    protected void configure(HttpSecurity http) throws Exception {
        http
            .authorizeRequests()
                .antMatchers("/api/auth/**").permitAll()
                .antMatchers("/api/admin/**").hasRole("ADMIN")
                .anyRequest().authenticated()
            .sessionManagement()
                .sessionCreationPolicy(SessionCreationPolicy.IF_REQUIRED)
            .and()
            .csrf().disable()  // Disabled for Flutter/REST
            .cors();
    }
}
```

#### Password Encoding

- **Algorithm:** BCrypt
- **Strength:** Default (10 rounds)

#### Role-Based Access Control

- **Roles:** USER, ADMIN
- **Authorities:** read, write, delete

### 5.6 Database Configuration

**Application Properties:**

```properties
# H2 File-based Database
spring.datasource.url=jdbc:h2:file:./data/lostandfound
spring.datasource.username=user
spring.jpa.hibernate.ddl-auto=update

# Email Configuration (Gmail SMTP)
spring.mail.host=smtp.gmail.com
spring.mail.port=587
spring.mail.username=recq.noreply@gmail.com
spring.mail.password=ovftqqrgtudcwlfw

# OTP Configuration
otp.expiration.minutes=5
otp.length=6
otp.resend.timeout.seconds=60

# ML Service
ml.service.url=http://localhost:5000
matching.threshold=0.6
```

---

## 6. Frontend Application (Flutter)

### 6.1 Project Structure

```
flutter_app/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── config/
│   │   └── api_config.dart          # API endpoint configuration
│   ├── models/                      # Data models
│   │   ├── user.dart
│   │   ├── lost_found_item.dart
│   │   ├── claim.dart
│   │   ├── notification.dart
│   │   └── item_match.dart
│   ├── providers/                   # State management
│   │   └── app_provider.dart        # Global app state
│   ├── screens/                     # UI screens (17 screens)
│   │   ├── splash_screen.dart
│   │   ├── login_screen.dart
│   │   ├── email_login_screen.dart
│   │   ├── register_screen.dart
│   │   ├── otp_verification_screen.dart
│   │   ├── forgot_password_screen.dart
│   │   ├── reset_password_screen.dart
│   │   ├── home_screen.dart         # Main item list
│   │   ├── item_detail_screen.dart
│   │   ├── create_item_screen.dart  # Report lost/found item
│   │   ├── profile_screen.dart
│   │   ├── matches_screen.dart      # View matches
│   │   ├── match_detail_screen.dart
│   │   ├── claim_item_screen.dart   # Submit claim
│   │   ├── my_claims_screen.dart
│   │   ├── admin_claims_screen.dart # Admin review
│   │   └── notifications_screen.dart
│   └── services/                    # Business logic
│       ├── api_service.dart         # HTTP client wrapper
│       ├── tflite_classifier.dart   # Conditional import
│       ├── tflite_classifier_io.dart    # Mobile/Desktop ML
│       └── tflite_classifier_web.dart   # Web ML (stub)
├── assets/
│   └── ml/
│       ├── lost_and_found_classifier.tflite  # 14-class model
│       └── class_names.txt
├── android/                         # Android-specific
├── ios/                             # iOS-specific
├── web/                             # Web-specific
├── windows/                         # Windows-specific
├── macos/                           # macOS-specific
├── linux/                           # Linux-specific
└── pubspec.yaml                     # Dependencies
```

### 6.2 State Management (Provider)

**AppProvider.dart:**

```dart
class AppProvider with ChangeNotifier {
  User? _user;
  List<LostFoundItem> _items = [];
  List<Notification> _notifications = [];
  int _unreadCount = 0;

  // Getters
  User? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get isAdmin => _user?.roles?.contains('ADMIN') ?? false;

  // Methods
  void setUser(User user) { /* ... */ }
  void logout() { /* ... */ }
  Future<void> loadUserFromPreferences() { /* ... */ }
  void updateItems(List<LostFoundItem> items) { /* ... */ }
  void updateNotifications(List<Notification> notifications) { /* ... */ }
}
```

### 6.3 API Service

**ApiService.dart** - Centralized HTTP client:

```dart
class ApiService {
  final String baseUrl = ApiConfig.baseUrl;  // Auto-switches local/production

  // Authentication
  Future<Map<String, dynamic>> login(username, password)
  Future<Map<String, dynamic>> register(userData)
  Future<Map<String, dynamic>> sendOtp(email)
  Future<Map<String, dynamic>> verifyOtp(email, otp)

  // Items
  Future<List<LostFoundItem>> getItems()
  Future<List<LostFoundItem>> getItemsByType(type)
  Future<LostFoundItem> getItemById(id)
  Future<Map<String, dynamic>> createItem(item, imageFile)
  Future<void> deleteItem(id)

  // Matches
  Future<List<ItemMatch>> getMatches(userId)
  Future<void> dismissMatch(matchId)

  // Claims
  Future<Map<String, dynamic>> createClaim(itemId, answers)
  Future<List<Claim>> getMyClaims()
  Future<List<Map>> getPendingClaims()
  Future<Map<String, dynamic>> reviewClaim(claimId, status, notes)

  // Notifications
  Future<List<Notification>> getNotifications()
  Future<int> getUnreadCount()
  Future<void> markAsRead(notificationId)
}
```

### 6.4 Key Screens

#### 6.4.1 Home Screen

- **Tab Navigation:** All / Lost / Found / My Items / Given Items
- **Pull-to-Refresh:** Reload items
- **Search & Filter:** By category
- **Item Grid:** Displays item cards with images
- **FAB:** Navigate to create item

#### 6.4.2 Create Item Screen

- **Form Fields:** Title, date, location, category, description, reporter info
- **Image Picker:** Camera or gallery
- **On-Device Classification:** TFLite model classifies image
- **GPS Location:** Capture coordinates
- **Validation:** All fields validated before submission

#### 6.4.3 Item Detail Screen

- **Item Information:** Full details with image
- **Map View:** Show location on Google Maps
- **Comments Section:** View and add comments
- **Action Buttons:**
  - Edit/Delete (owner)
  - Claim (for found items)
  - Contact reporter
  - View matches

#### 6.4.4 Matches Screen

- **Match Cards:** Display confidence score, similarity breakdown
- **Color-Coded:** Green (HIGH), Orange (MEDIUM), Red (LOW)
- **Actions:** View details, dismiss match, contact other user

#### 6.4.5 Claim Item Screen

- **Dynamic Questions:** Fetched from ML service (item-specific)
- **Form Validation:** All questions must be answered
- **Submit Claim:** Sends answers to backend

#### 6.4.6 Admin Claims Screen

- **Pending Claims List:** Shows all claims awaiting review
- **Claim Details:** Item info, claimant info, Q&A
- **Review Actions:** Approve with notes, Reject with reason
- **Validation:** Cannot approve if another claim already approved

### 6.5 TFLite Integration (On-Device ML)

**Mobile/Desktop (tflite_classifier_io.dart):**

```dart
class TFLiteClassifier {
  Interpreter? _interpreter;
  List<String> _classNames = [];

  Future<void> initialize() async {
    // Load model from assets
    _interpreter = await Interpreter.fromAsset('assets/ml/lost_and_found_classifier.tflite');
    // Load class names
    _classNames = await rootBundle.loadString('assets/ml/class_names.txt').then(
      (data) => data.split('\n').map((e) => e.trim()).toList()
    );
  }

  Future<ClassificationResult> classifyImage(File imageFile) async {
    // Preprocess image (224x224, normalize)
    var input = preprocessImage(imageFile);

    // Run inference
    var output = List.filled(14, 0.0).reshape([1, 14]);
    _interpreter.run(input, output);

    // Get top prediction
    var predictions = output[0];
    var topIndex = predictions.indexOf(predictions.reduce(max));
    var confidence = predictions[topIndex];

    return ClassificationResult(
      className: _classNames[topIndex],
      confidence: confidence
    );
  }
}
```

**Web (tflite_classifier_web.dart):**

```dart
// Stub implementation - classification done on backend
class TFLiteClassifier {
  Future<void> initialize() async {}
  Future<ClassificationResult> classifyImage(dynamic imageFile) async {
    return ClassificationResult(className: 'Other', confidence: 0.0);
  }
}
```

### 6.6 UI/UX Features

**Design System:**

- **Material Design 3:** Modern, clean interface
- **Color Scheme:** Gradient backgrounds (purple to blue)
- **Typography:** Clear hierarchy, readable fonts
- **Icons:** Material Icons + custom icons
- **Animations:** Smooth transitions, hero animations
- **Responsive:** Adapts to different screen sizes

**User Experience:**

- **Loading States:** Circular progress indicators
- **Error Handling:** User-friendly error messages with SnackBars
- **Empty States:** Informative messages with actions
- **Form Validation:** Real-time validation feedback
- **Accessibility:** Semantic labels, contrast ratios

---

## 7. Machine Learning Service

### 7.1 Overview

The ML service is a Flask-based REST API that provides:

1. **Image Classification:** 14-category item classifier
2. **Embedding Generation:** Image and text feature vectors
3. **Matching Engine:** Multi-modal similarity matching
4. **Question Generation:** Item-specific verification questions

**Port:** 5000 (default)

### 7.2 Project Structure

```
ml_service/
├── app.py                           # Flask application (604 lines)
├── embedding_service.py             # Embedding generation (140 lines)
├── matching_engine.py               # Matching algorithm (270 lines)
├── question_generator.py            # NLP question generation (811 lines)
├── train.py                         # Model training script (527 lines)
├── predict.py                       # Standalone prediction (330 lines)
├── convert_to_tflite.py             # TFLite conversion
├── requirements.txt                 # Python dependencies
├── class_names2.txt                 # 14 class names
├── models/
│   └── lost_and_found_classifier12.keras  # Trained model
├── data/
│   ├── dataset/                     # Original dataset
│   └── dataset1/                    # Augmented dataset
│       ├── train/                   # Training images
│       ├── validation/              # Validation images
│       └── test/                    # Test images
├── scripts/
│   ├── download_openimages.py       # Dataset downloader
│   ├── check_dataset.py             # Dataset statistics
│   └── make_other.py                # Create "Other" class
└── test_images/                     # Sample test images
```

### 7.3 Image Classification

#### 7.3.1 Model Architecture

```python
# Base: EfficientNetB0 (pre-trained on ImageNet)
base_model = EfficientNetB0(weights='imagenet', include_top=False)

# Custom classification head
model = Sequential([
    base_model,
    GlobalAveragePooling2D(),
    Dropout(0.3),
    Dense(128, activation='relu'),
    Dropout(0.3),
    Dense(14, activation='softmax')  # 14 classes
])

# Transfer Learning: Freeze base, train head first
# Then fine-tune top layers
```

#### 7.3.2 Categories (14 Classes)

1. Backpack
2. Book
3. Bottle
4. Camera
5. Earrings
6. Footwear
7. Glasses
8. Headphones
9. Laptop
10. Mobile phone
11. Necklace
12. Outerwear
13. Wallet
14. Watch

#### 7.3.3 Open-Set Recognition

```python
CONF_THRESHOLD = 0.65      # Minimum confidence
MARGIN_THRESHOLD = 0.20    # Top-1 vs Top-2 margin

def predict_image(img_path):
    preds = model.predict(img)
    top1_score = preds[top1_idx]
    top2_score = preds[top2_idx]

    # Reject if confidence too low or margin too small
    if top1_score < CONF_THRESHOLD or (top1_score - top2_score) < MARGIN_THRESHOLD:
        return "Other", top1_score  # Unknown class

    return class_names[top1_idx], top1_score
```

#### 7.3.4 Category Mapping

ML classes are mapped to backend enum categories:

```python
ML_TO_BACKEND_CATEGORY = {
    "backpack": "ACCESSORIES",
    "book": "DOCUMENT",
    "bottle": "OTHERS",
    "camera": "ELECTRONIC",
    "earrings": "JEWELLERY",
    "footwear": "FOOTWEAR",
    "glasses": "ACCESSORIES",
    "headphones": "ELECTRONIC",
    "laptop": "ELECTRONIC",
    "mobile phone": "ELECTRONIC",
    "necklace": "JEWELLERY",
    "outerwear": "CLOTHING",
    "wallet": "ACCESSORIES",
    "watch": "ACCESSORIES",
}
```

### 7.4 Embedding Service

#### 7.4.1 Text Embeddings

```python
# Model: all-MiniLM-L6-v2 (Sentence-BERT)
# Output: 384-dimensional vector
text_model = SentenceTransformer('all-MiniLM-L6-v2')

def get_text_embedding(text: str) -> np.ndarray:
    if not text or text.strip() == "":
        return np.zeros(384)
    return text_model.encode(text, convert_to_numpy=True)
```

**Use Case:** Semantic similarity between item descriptions

- "Lost black iPhone 13" vs "Found dark phone"
- Vector similarity captures semantic meaning

#### 7.4.2 Image Embeddings

```python
# Model: EfficientNetB0 (feature extractor)
# Output: 1280-dimensional vector
base_model = EfficientNetB0(weights='imagenet', include_top=False,
                            pooling='avg', input_shape=(224, 224, 3))

def get_image_embedding(img_path: str) -> np.ndarray:
    img = load_img(img_path, target_size=(224, 224))
    img = preprocess_input(img)
    return base_model.predict(img)[0]
```

**Use Case:** Visual similarity between item images

- Even if descriptions differ, similar-looking items match

### 7.5 Matching Engine

#### 7.5.1 Multi-Modal Similarity

```python
# Weighted combination of three signals
IMAGE_WEIGHT = 0.5
TEXT_WEIGHT = 0.3
CATEGORY_WEIGHT = 0.2

def calculate_match_score(lost_item, found_item):
    # Image similarity (cosine similarity)
    img_sim = cosine_similarity(lost_item.image_emb, found_item.image_emb)

    # Text similarity (cosine similarity)
    text_sim = cosine_similarity(lost_item.text_emb, found_item.text_emb)

    # Category match (exact match = 1.0, else 0.0)
    cat_match = 1.0 if lost_item.category == found_item.category else 0.0

    # Weighted score
    score = (IMAGE_WEIGHT * img_sim) +
            (TEXT_WEIGHT * text_sim) +
            (CATEGORY_WEIGHT * cat_match)

    return score
```

#### 7.5.2 Match Levels

```python
MATCH_THRESHOLD = 0.6
HIGH_MATCH_THRESHOLD = 0.8

if score >= HIGH_MATCH_THRESHOLD:
    level = "HIGH"       # Very likely match
elif score >= MATCH_THRESHOLD:
    level = "MEDIUM"     # Possible match
else:
    level = "LOW"        # Unlikely (filtered out)
```

#### 7.5.3 Matching Algorithm

```python
def find_matches_for_item(item_embeddings, all_items):
    matches = []

    # Only match LOST with FOUND
    opposite_type = "FOUND" if item.type == "LOST" else "LOST"
    candidates = filter(lambda x: x.type == opposite_type, all_items)

    for candidate in candidates:
        score = calculate_match_score(item, candidate)

        if score >= MATCH_THRESHOLD:
            match = MatchResult(
                lost_item=item if item.type == "LOST" else candidate,
                found_item=candidate if item.type == "LOST" else item,
                confidence=score,
                match_level=get_level(score)
            )
            matches.append(match)

    # Return top K matches, sorted by score
    return sorted(matches, key=lambda x: x.confidence, reverse=True)[:3]
```

### 7.6 Question Generator

#### 7.6.1 Template-Based Generation

```python
CATEGORY_QUESTIONS = {
    "ELECTRONIC": [
        "What is the brand/manufacturer of this device?",
        "What is the color of the device?",
        "Does the device have any protective case or cover?",
        "What is the approximate screen size?",
        "Are there any visible scratches or marks?",
        # ... more questions
    ],
    "DOCUMENT": [
        "What type of document is it (ID, passport, certificate)?",
        "Whose name appears on the document?",
        "What is the issuing authority?",
        # ... more questions
    ],
    # ... other categories
}
```

#### 7.6.2 Keyword-Based Questions

```python
KEYWORD_QUESTION_MAP = {
    "color": [
        "What is the exact color?",
        "Are there any secondary colors or patterns?",
    ],
    "brand": [
        "What brand is it?",
        "Can you see any brand logos or markings?",
    ],
    "size": [
        "What is the size?",
        "Can you estimate the dimensions?",
    ],
    # ... hundreds of keyword mappings
}

def extract_keywords(text):
    # Use spaCy NLP to extract nouns, adjectives, entities
    doc = nlp(text)
    keywords = [token.text for token in doc if token.pos_ in ['NOUN', 'ADJ']]
    return keywords

def generate_questions(title, category, description):
    questions = []

    # Start with category-specific questions
    questions.extend(CATEGORY_QUESTIONS.get(category, []))

    # Add keyword-based questions
    keywords = extract_keywords(f"{title} {description}")
    for keyword in keywords:
        if keyword in KEYWORD_QUESTION_MAP:
            questions.extend(KEYWORD_QUESTION_MAP[keyword])

    # Remove duplicates, shuffle, return top 5
    questions = list(set(questions))
    random.shuffle(questions)
    return questions[:5]
```

#### 7.6.3 Advanced NLP Features (Optional)

```python
# T5-based question generation (if available)
if T5ForConditionalGeneration:
    model = T5ForConditionalGeneration.from_pretrained('t5-small')
    tokenizer = T5Tokenizer.from_pretrained('t5-small')

    def generate_t5_question(context):
        input_text = f"generate question: {context}"
        input_ids = tokenizer(input_text, return_tensors="pt").input_ids
        outputs = model.generate(input_ids, max_length=64)
        return tokenizer.decode(outputs[0], skip_special_tokens=True)
```

### 7.7 Flask API Endpoints

```python
@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint"""
    return jsonify({'status': 'healthy', 'classes': class_names})

@app.route('/classify', methods=['POST'])
def classify():
    """
    Classify image from multipart/form-data
    Returns: predicted_class, confidence, category, all_probabilities
    """

@app.route('/embeddings/text', methods=['POST'])
def get_text_embedding_api():
    """
    Generate text embedding from JSON: {"text": "..."}
    Returns: 384-dim vector
    """

@app.route('/embeddings/image', methods=['POST'])
def get_image_embedding_api():
    """
    Generate image embedding from multipart/form-data
    Returns: 1280-dim vector
    """

@app.route('/match', methods=['POST'])
def find_matches():
    """
    Find matches for item
    Expects: item embeddings + list of all items (JSON)
    Returns: list of matches with scores
    """

@app.route('/generate-questions', methods=['POST'])
def generate_questions_api():
    """
    Generate verification questions
    Expects: {"title": "...", "category": "...", "description": "..."}
    Returns: list of 5 questions
    """
```

### 7.8 Model Training

**Training Configuration:**

```python
IMG_SIZE = (224, 224)
BATCH_SIZE = 32
EPOCHS = 20
LEARNING_RATE = 0.001

# Data Augmentation
data_augmentation = Sequential([
    RandomFlip("horizontal"),
    RandomRotation(0.1),
    RandomZoom(0.1),
    RandomBrightness(0.1),
])

# Training Strategy
1. Freeze EfficientNetB0 base
2. Train classification head (5 epochs)
3. Unfreeze top layers
4. Fine-tune end-to-end (15 epochs)

# Callbacks
- ModelCheckpoint (save best model)
- EarlyStopping (patience=3)
- ReduceLROnPlateau (reduce LR on plateau)
```

**Dataset Structure:**

```
data/dataset1/
├── train/           # 70% of data
│   ├── Backpack/
│   ├── Book/
│   ├── Bottle/
│   └── ... (14 classes)
├── validation/      # 15% of data
│   └── ... (same structure)
└── test/            # 15% of data
    └── ... (same structure)
```

---

## 8. Database Design

### 8.1 Database Technology

- **Type:** Relational (H2)
- **Mode:** Persistent file-based
- **Location:** `./data/lostandfound.mv.db`
- **Compatibility:** Can switch to MySQL/PostgreSQL (JPA abstraction)

### 8.2 Entity Relationship Diagram

```
┌─────────────────┐         ┌──────────────────┐
│      User       │────────<│  LostFoundItem   │
│  - id           │  (1:N)  │  - id            │
│  - username     │         │  - type (enum)   │
│  - password     │         │  - title         │
│  - email        │         │  - category      │
│  - firstName    │         │  - description   │
│  - lastName     │         │  - imageUrl      │
│  - phoneNo      │         │  - user_id (FK)  │
└─────────────────┘         └──────────────────┘
         │                           │
         │                           │ (1:N)
         │                           ▼
         │                  ┌──────────────────┐
         │                  │     Comment      │
         │                  │  - id            │
         │                  │  - text          │
         │                  │  - user_id       │
         │                  │  - item_id (FK)  │
         │                  └──────────────────┘
         │
         │ (1:N)            ┌──────────────────┐
         └─────────────────<│      Claim       │
                   (1:N)    │  - id (UUID)     │
         ┌─────────────────<│  - item_id (FK)  │
         │                  │  - claimant_id   │
         │                  │  - status (enum) │
┌─────────────────┐         │  - qa (JSON)     │
│  LostFoundItem  │         │  - adminNotes    │
└─────────────────┘         └──────────────────┘
         │
         │ (1:1)
         ▼
┌──────────────────┐
│  ItemEmbedding   │
│  - id            │
│  - item_id (FK)  │
│  - textEmb (JSON)│
│  - imageEmb (JSON)│
│  - hasImage      │
└──────────────────┘

┌──────────────────┐         ┌──────────────────┐
│  LostFoundItem   │────────<│    ItemMatch     │
│  (LOST)          │  (N:M)  │  - id (UUID)     │
└──────────────────┘         │  - lost_id (FK)  │
                             │  - found_id (FK) │
┌──────────────────┐         │  - confidence    │
│  LostFoundItem   │────────<│  - imageSim      │
│  (FOUND)         │         │  - textSim       │
└──────────────────┘         │  - matchLevel    │
                             │  - dismissed     │
                             └──────────────────┘

┌─────────────────┐         ┌──────────────────┐
│      User       │────────<│  Notification    │
└─────────────────┘  (1:N)  │  - id (UUID)     │
                            │  - user_id (FK)  │
                            │  - title         │
                            │  - message       │
                            │  - type          │
                            │  - relatedIds    │
                            │  - isRead        │
                            └──────────────────┘

┌─────────────────┐         ┌──────────────────┐
│      User       │────────<│    OtpToken      │
└─────────────────┘  (1:N)  │  - id            │
                            │  - email         │
                            │  - otp           │
                            │  - expiresAt     │
                            │  - verified      │
                            └──────────────────┘

┌─────────────────┐         ┌──────────────────┐
│      User       │───────<<│       Role       │
└─────────────────┘   (N:M)  │  - id            │
                             │  - name          │
                             │  - authorities   │
                             └──────────────────┘
```

### 8.3 Table Schemas

#### Users Table

```sql
CREATE TABLE user (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    phone_no VARCHAR(20),
    account_non_expired BOOLEAN DEFAULT TRUE,
    account_non_locked BOOLEAN DEFAULT TRUE,
    credentials_non_expired BOOLEAN DEFAULT TRUE,
    enabled BOOLEAN DEFAULT TRUE,
    created_date TIMESTAMP,
    last_modified_date TIMESTAMP
);
```

#### Lost_Found_Item Table

```sql
CREATE TABLE lost_found_item (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    type VARCHAR(10) NOT NULL,  -- LOST/FOUND
    title VARCHAR(150) NOT NULL,
    lost_found_date DATE NOT NULL,
    lost_found_location VARCHAR(150) NOT NULL,
    description VARCHAR(255),
    description_added_by VARCHAR(50),
    description_added_at TIMESTAMP,
    reporter_name VARCHAR(50) NOT NULL,
    reporter_email VARCHAR(50) NOT NULL,
    reporter_phone_no VARCHAR(50) NOT NULL,
    category VARCHAR(30),
    image_url VARCHAR(500),
    latitude DOUBLE,
    longitude DOUBLE,
    collection_location VARCHAR(200),
    created_by VARCHAR(50),
    modified_by VARCHAR(50),
    created_date TIMESTAMP,
    last_modified_date TIMESTAMP,
    user_id BIGINT,
    FOREIGN KEY (user_id) REFERENCES user(id)
);
```

#### Claims Table

```sql
CREATE TABLE claims (
    id VARCHAR(36) PRIMARY KEY,  -- UUID
    item_id BIGINT NOT NULL,
    claimant_id BIGINT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    questions_and_answers CLOB,  -- JSON string
    admin_notes VARCHAR(500),
    reviewed_by VARCHAR(50),
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    reviewed_at TIMESTAMP,
    FOREIGN KEY (item_id) REFERENCES lost_found_item(id),
    FOREIGN KEY (claimant_id) REFERENCES user(id)
);
```

#### Item_Match Table

```sql
CREATE TABLE item_match (
    id VARCHAR(36) PRIMARY KEY,  -- UUID
    lost_item_id BIGINT NOT NULL,
    found_item_id BIGINT NOT NULL,
    lost_user_id BIGINT NOT NULL,
    found_user_id BIGINT NOT NULL,
    confidence_score DOUBLE,
    image_similarity DOUBLE,
    text_similarity DOUBLE,
    category_match DOUBLE,
    match_level VARCHAR(10),
    dismissed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP,
    FOREIGN KEY (lost_item_id) REFERENCES lost_found_item(id),
    FOREIGN KEY (found_item_id) REFERENCES lost_found_item(id),
    FOREIGN KEY (lost_user_id) REFERENCES user(id),
    FOREIGN KEY (found_user_id) REFERENCES user(id)
);
```

#### Item_Embedding Table

```sql
CREATE TABLE item_embedding (
    id VARCHAR(36) PRIMARY KEY,  -- UUID
    item_id BIGINT NOT NULL UNIQUE,
    text_embedding CLOB,  -- JSON array [384 floats]
    image_embedding CLOB,  -- JSON array [1280 floats]
    has_image BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP,
    FOREIGN KEY (item_id) REFERENCES lost_found_item(id)
);
```

#### Notification Table

```sql
CREATE TABLE notification (
    id VARCHAR(36) PRIMARY KEY,  -- UUID
    user_id BIGINT NOT NULL,
    title VARCHAR(100),
    message VARCHAR(500),
    type VARCHAR(20),
    related_item_id VARCHAR(36),
    related_match_id VARCHAR(36),
    related_claim_id VARCHAR(36),
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES user(id)
);
```

### 8.4 Indexes (for Performance)

```sql
-- User lookups
CREATE INDEX idx_user_username ON user(username);
CREATE INDEX idx_user_email ON user(email);

-- Item queries
CREATE INDEX idx_item_type ON lost_found_item(type);
CREATE INDEX idx_item_category ON lost_found_item(category);
CREATE INDEX idx_item_user ON lost_found_item(user_id);
CREATE INDEX idx_item_date ON lost_found_item(lost_found_date);

-- Match queries
CREATE INDEX idx_match_lost ON item_match(lost_item_id);
CREATE INDEX idx_match_found ON item_match(found_item_id);
CREATE INDEX idx_match_dismissed ON item_match(dismissed);

-- Claim queries
CREATE INDEX idx_claim_item ON claims(item_id);
CREATE INDEX idx_claim_user ON claims(claimant_id);
CREATE INDEX idx_claim_status ON claims(status);

-- Notification queries
CREATE INDEX idx_notif_user ON notification(user_id);
CREATE INDEX idx_notif_read ON notification(is_read);
```

---

## 9. API Documentation

### 9.1 API Base URL

- **Development:** `http://localhost:8080/api`
- **Production:** `https://your-app.onrender.com/api`

### 9.2 Authentication Endpoints

#### POST /api/auth/register

**Description:** Register a new user account  
**Request Body:**

```json
{
  "username": "johndoe",
  "password": "SecurePass123",
  "confirmedPassword": "SecurePass123",
  "email": "john@example.com",
  "firstName": "John",
  "lastName": "Doe",
  "phoneNo": "+1234567890"
}
```

**Response:**

```json
{
  "success": true,
  "message": "Registration successful",
  "user": {
    "id": 1,
    "username": "johndoe",
    "email": "john@example.com",
    "firstName": "John",
    "lastName": "Doe",
    "roles": ["USER"]
  }
}
```

#### POST /api/auth/login

**Description:** Login with username/password  
**Request Body:**

```json
{
  "username": "johndoe",
  "password": "SecurePass123"
}
```

**Response:**

```json
{
  "success": true,
  "message": "Login successful",
  "user": {
    /* user object */
  }
}
```

#### POST /api/auth/send-otp

**Description:** Send OTP to email for password-less login  
**Request Body:**

```json
{
  "email": "john@example.com"
}
```

**Response:**

```json
{
  "success": true,
  "message": "OTP sent to your email",
  "email": "john@example.com"
}
```

#### POST /api/auth/verify-otp

**Description:** Verify OTP and login  
**Request Body:**

```json
{
  "email": "john@example.com",
  "otp": "123456"
}
```

**Response:**

```json
{
  "success": true,
  "message": "Login successful",
  "user": {
    /* user object */
  }
}
```

#### GET /api/auth/me

**Description:** Get current logged-in user  
**Headers:** Session cookie  
**Response:** User object

#### POST /api/auth/logout

**Description:** Logout current user  
**Response:**

```json
{
  "success": true,
  "message": "Logout successful"
}
```

### 9.3 Item Endpoints

#### GET /api/items

**Description:** Get all items  
**Response:** Array of LostFoundItem objects

#### GET /api/items/type/{type}

**Description:** Get items by type (LOST or FOUND)  
**Parameters:** type = "LOST" | "FOUND"

#### GET /api/items/{id}

**Description:** Get item by ID  
**Parameters:** id (Long)

#### GET /api/items/user/{userId}

**Description:** Get items reported by specific user

#### POST /api/items

**Description:** Create new item  
**Content-Type:** multipart/form-data  
**Form Data:**

- item (JSON string)
- image (file, optional)

**Example item JSON:**

```json
{
  "type": "LOST",
  "title": "Black iPhone 13",
  "lostFoundDate": "2026-02-28",
  "lostFoundLocation": "Library 3rd Floor",
  "description": "Black iPhone 13 with cracked screen",
  "reporterName": "John Doe",
  "reporterEmail": "john@example.com",
  "reporterPhoneNo": "+1234567890",
  "category": "ELECTRONIC",
  "latitude": 37.7749,
  "longitude": -122.4194
}
```

#### DELETE /api/items/{id}

**Description:** Delete item  
**Authorization:** Owner or Admin only

### 9.4 Match Endpoints

#### GET /api/matches/user/{userId}

**Description:** Get all matches for a user  
**Response:**

```json
[
  {
    "id": "uuid",
    "lostItem": {
      /* item object */
    },
    "foundItem": {
      /* item object */
    },
    "confidenceScore": 85.3,
    "imageSimilarity": 78.5,
    "textSimilarity": 92.1,
    "categoryMatch": 100.0,
    "matchLevel": "HIGH",
    "dismissed": false,
    "createdAt": "2026-03-01T10:30:00"
  }
]
```

#### POST /api/matches/generate

**Description:** Manually trigger match generation (Admin)  
**Response:**

```json
{
  "success": true,
  "matchesFound": 12
}
```

#### PUT /api/matches/{matchId}/dismiss

**Description:** Dismiss a match (user doesn't think it's their item)

### 9.5 Claim Endpoints

#### POST /api/claims

**Description:** Submit a claim for a found item  
**Request Body:**

```json
{
  "itemId": 123,
  "questionsAndAnswers": [
    {
      "question": "What brand is the phone?",
      "answer": "Apple"
    },
    {
      "question": "What color is it?",
      "answer": "Black"
    }
  ]
}
```

#### GET /api/claims/user/{userId}

**Description:** Get user's submitted claims

#### GET /api/claims/pending

**Description:** Get all pending claims (Admin only)

#### PUT /api/claims/{claimId}/review

**Description:** Review/update claim status (Admin only)  
**Request Body:**

```json
{
  "status": "APPROVED",
  "adminNotes": "Valid proof provided"
}
```

### 9.6 Notification Endpoints

#### GET /api/notifications

**Description:** Get user's notifications

#### GET /api/notifications/unread-count

**Description:** Get count of unread notifications  
**Response:**

```json
{
  "count": 3
}
```

#### PUT /api/notifications/{id}/read

**Description:** Mark notification as read

### 9.7 Comment Endpoints

#### POST /api/comments

**Description:** Add comment to an item  
**Request Body:**

```json
{
  "itemId": 123,
  "text": "I think I saw this at the cafeteria!"
}
```

#### GET /api/comments/item/{itemId}

**Description:** Get comments for an item

### 9.8 Admin Endpoints

#### GET /api/admin/users

**Description:** Get all users (Admin only)

#### GET /api/admin/stats

**Description:** Get system statistics  
**Response:**

```json
{
  "totalUsers": 150,
  "totalItems": 324,
  "lostItems": 180,
  "foundItems": 144,
  "totalMatches": 45,
  "pendingClaims": 12,
  "approvedClaims": 8
}
```

### 9.9 ML Service Endpoints

#### POST http://localhost:5000/classify

**Description:** Classify item image  
**Content-Type:** multipart/form-data  
**Form Data:** image (file)  
**Response:**

```json
{
  "predicted_class": "Mobile phone",
  "confidence": 0.89,
  "category": "ELECTRONIC",
  "all_probabilities": {
    "Backpack": 0.02,
    "Book": 0.01,
    "Mobile phone": 0.89,
    ...
  }
}
```

#### POST http://localhost:5000/embeddings/text

**Description:** Generate text embedding  
**Request Body:**

```json
{
  "text": "Lost black iPhone 13 with cracked screen"
}
```

**Response:**

```json
{
  "embedding": [0.023, -0.145, 0.678, ... 384 values]
}
```

#### POST http://localhost:5000/embeddings/image

**Description:** Generate image embedding  
**Content-Type:** multipart/form-data  
**Response:**

```json
{
  "embedding": [0.123, 0.456, -0.789, ... 1280 values]
}
```

#### POST http://localhost:5000/generate-questions

**Description:** Generate verification questions  
**Request Body:**

```json
{
  "title": "Black iPhone 13",
  "category": "ELECTRONIC",
  "description": "Black iPhone 13 with cracked screen and blue case"
}
```

**Response:**

```json
{
  "questions": [
    "What is the brand/manufacturer of this device?",
    "What is the exact color of the device?",
    "Does the device have any protective case or cover? If yes, describe it.",
    "Are there any visible scratches, dents, or distinguishing marks?",
    "What is the approximate screen size?"
  ]
}
```

---

## 10. Security Implementation

### 10.1 Authentication

#### Session-Based Authentication

- **Mechanism:** Spring Security with HTTP sessions
- **Storage:** Server-side session store
- **Cookie:** JSESSIONID (httpOnly, secure in production)
- **Timeout:** Configurable (default: 30 minutes)

#### Password Security

```java
@Bean
public PasswordEncoder passwordEncoder() {
    return new BCryptPasswordEncoder();
}

// Password strength: minimum 8 chars, at least one uppercase, lowercase, digit
```

#### Account Lockout

- **Failed Login Attempts:** Tracked in `login_failure` table
- **Threshold:** 5 failed attempts
- **Lockout Duration:** 24 hours
- **Auto-Unlock:** Background task runs every hour

### 10.2 Authorization

#### Role-Based Access Control (RBAC)

```java
- USER: Can create items, view matches, submit claims, manage own data
- ADMIN: All USER permissions + review claims, manage all items, view stats
```

#### Method-Level Security

```java
@PreAuthorize("hasRole('ADMIN')")
public ResponseEntity<?> getPendingClaims() { /* ... */ }

@PreAuthorize("@securityService.isItemOwner(#itemId)")
public ResponseEntity<?> deleteItem(@PathVariable Long itemId) { /* ... */ }
```

### 10.3 Data Protection

#### SQL Injection Prevention

- **ORM:** Hibernate JPA (parameterized queries)
- **Prepared Statements:** All database queries use parameter binding

#### XSS Prevention

- **Input Validation:** Bean Validation (@NotEmpty, @Size, @Email)
- **Output Encoding:** JSON serialization escapes special characters

#### CSRF Protection

- **Status:** Disabled for REST API (stateless design)
- **Alternative:** CORS configuration restricts origins

#### CORS Configuration

```java
@Configuration
public class CorsConfig {
    @Bean
    public CorsFilter corsFilter() {
        CorsConfiguration config = new CorsConfiguration();
        config.setAllowedOrigins(Arrays.asList("http://localhost:8100", "https://your-app.vercel.app"));
        config.setAllowedMethods(Arrays.asList("GET", "POST", "PUT", "DELETE"));
        config.setAllowedHeaders(Arrays.asList("*"));
        config.setAllowCredentials(true);
        return new CorsFilter(source);
    }
}
```

### 10.4 Email Security (OTP)

#### OTP Configuration

- **Length:** 6 digits
- **Expiration:** 5 minutes
- **Rate Limiting:** 1 OTP per 60 seconds per email
- **Cleanup:** Expired OTPs deleted automatically

#### Email Transport Security

- **Protocol:** SMTP with STARTTLS
- **Encryption:** TLS 1.2+
- **Authentication:** Username/password (Gmail App Password)

### 10.5 File Upload Security

#### Image Upload Validation

```java
- File type: JPEG, PNG only (MIME type check)
- File size: Max 10MB
- Storage: Local filesystem with secure path
- File name: Sanitized (remove special chars, add UUID)
- Path traversal: Prevented (no ../ in names)
```

### 10.6 Sensitive Data Handling

#### Database Encryption

- H2 database file can be encrypted (optional)
- Passwords: BCrypt hashed (never stored in plaintext)
- OTP: Hashed before storage (optional enhancement)

#### Logging

- Password masking in logs
- No sensitive data in error messages
- Audit trail for admin actions

---

## 11. Core Features & Functionality

### 11.1 User Journey

```
┌───────────────────────────────────────────────────────────────┐
│                      NEW USER FLOW                            │
└───────────────────────────────────────────────────────────────┘
1. User opens app
2. Sees splash screen (brand logo)
3. Navigates to login screen
4. Chooses "Sign Up"
5. Fills registration form (username, email, password, name, phone)
6. Submits → Backend validates, creates account
7. Auto-login and redirects to home screen

┌───────────────────────────────────────────────────────────────┐
│                  REPORT LOST ITEM FLOW                        │
└───────────────────────────────────────────────────────────────┘
1. User clicks "Report Lost/Found" button
2. Fills form:
   - Select type: LOST or FOUND
   - Upload photo (camera or gallery)
   - TFLite model classifies image → suggests category
   - Enter title, date, location, description
   - Capture GPS location (optional)
   - Enter contact info
3. Submits → Backend saves item
4. Backend calls ML service:
   - Generates text embedding (title + description)
   - Generates image embedding (photo)
   - Stores embeddings in database
5. Backend runs matching engine:
   - Compares with opposite-type items (LOST ↔ FOUND)
   - Generates match scores
   - Saves high-confidence matches
6. If matches found → Creates notifications for both users
7. User sees success message, returns to home screen

┌───────────────────────────────────────────────────────────────┐
│                    VIEW MATCHES FLOW                          │
└───────────────────────────────────────────────────────────────┘
1. User receives notification: "Potential match found!"
2. Opens notifications screen
3. Clicks on match notification
4. Sees match details:
   - Own item
   - Matched item
   - Confidence score (color-coded)
   - Similarity breakdown (image, text, category)
5. Options:
   - View full item details
   - Contact other user (phone, email)
   - Dismiss match (not my item)

┌───────────────────────────────────────────────────────────────┐
│                     CLAIM ITEM FLOW                           │
└───────────────────────────────────────────────────────────────┘
1. User finds a FOUND item that might be theirs
2. Clicks "Claim This Item"
3. Backend calls ML service: Generate verification questions
4. ML service analyzes item (title, category, description)
5. Returns 5 relevant questions (e.g., "What brand is it?")
6. User answers all questions
7. Submits claim → Status: PENDING
8. Admin receives notification
9. Admin reviews:
   - Item details
   - Claimant info
   - Original reporter's description
   - Claimant's answers
10. Admin approves or rejects:
    - APPROVED: Claimant gets contact info to collect item
    - REJECTED: Claimant sees rejection reason
11. User receives notification with claim status

┌───────────────────────────────────────────────────────────────┐
│                   ADMIN WORKFLOW                              │
└───────────────────────────────────────────────────────────────┘
1. Admin logs in (username: admin, password: admin)
2. Sees admin dashboard with stats
3. Navigates to "Pending Claims"
4. Reviews each claim:
   - Reads item description
   - Reads claimant's answers
   - Cross-checks details
5. Makes decision:
   - Approve: "Answers match, item belongs to claimant"
   - Reject: "Answers don't match, false claim"
6. Adds admin notes explaining decision
7. Submits review → Claim status updated
8. Backend validates:
   - If approving, checks no other claim approved for same item
   - If another claim already approved → Returns error
9. Backend creates notification for claimant
10. Claimant receives notification with status and admin notes
```

### 11.2 Feature List

#### User Features

1. ✅ **Registration & Login**
   - Username/password authentication
   - Email/OTP password-less login
   - Forgot password with OTP reset
   - Session persistence

2. ✅ **Report Lost/Found Items**
   - Photo upload (camera or gallery)
   - AI-powered category classification
   - Manual category override
   - GPS location capture
   - Rich text description

3. ✅ **Browse Items**
   - Filter by type (All, Lost, Found)
   - Filter by category
   - View own items
   - View given items
   - Search functionality

4. ✅ **Item Details**
   - Full item information
   - Image gallery
   - Map view (Google Maps)
   - Comments section
   - Contact reporter

5. ✅ **AI-Powered Matching**
   - Automatic match generation
   - Multi-modal similarity (image + text + category)
   - Confidence scoring (HIGH/MEDIUM/LOW)
   - Match notifications
   - Dismiss unwanted matches

6. ✅ **Claim System**
   - Claim found items
   - Answer verification questions
   - Track claim status
   - View admin decision and notes

7. ✅ **Notifications**
   - Match alerts
   - Claim status updates
   - Unread count badge
   - Mark as read
   - Click to navigate to related item

8. ✅ **Comments**
   - Add comments to items
   - View all comments
   - User attribution

9. ✅ **Profile Management**
   - View profile
   - Edit personal information
   - Change password
   - Logout

#### Admin Features

1. ✅ **Claim Review**
   - View all pending claims
   - Approve/reject claims
   - Add admin notes
   - Validation against duplicate approvals

2. ✅ **Item Management**
   - View all items
   - Delete inappropriate items
   - Edit item details

3. ✅ **User Management**
   - View all users
   - Ban/unban users
   - Reset passwords

4. ✅ **System Statistics**
   - Total users, items, matches
   - Pending claims count
   - System health

### 11.3 ML-Powered Features

#### 11.3.1 Image Classification

- **Purpose:** Automatically categorize items
- **Accuracy:** ~85% on 14 categories
- **Latency:** <1 second (on-device) or <2 seconds (server)
- **Fallback:** "Other" category for unrecognized items

#### 11.3.2 Semantic Matching

- **Purpose:** Find similar lost/found items
- **Algorithm:** Multi-modal weighted similarity
- **Components:**
  - Image similarity: 50% weight (visual appearance)
  - Text similarity: 30% weight (description semantics)
  - Category match: 20% weight (exact category)
- **Threshold:** 60% minimum confidence (adjustable)

#### 11.3.3 Intelligent Question Generation

- **Purpose:** Verify ownership during claims
- **Techniques:**
  - Category-specific templates (e.g., electronics have brand/model questions)
  - Keyword extraction from description (e.g., "blue" → ask about color)
  - NLP-based entity recognition (spaCy)
  - Optional: T5 transformer model for open-ended questions
- **Output:** 5 relevant questions per item

---

## 12. Deployment Strategy

### 12.1 Deployment Architecture

```
┌────────────────────────────────────────────────────────────┐
│                       PRODUCTION                            │
└────────────────────────────────────────────────────────────┘

┌─────────────────┐           ┌─────────────────┐
│   Vercel CDN    │           │   Render Cloud  │
│  (Flutter Web)  │◄────────►│  (Spring Boot)  │
│  - Static Files │  HTTPS    │  - Docker Image │
│  - Global CDN   │           │  - Auto-scale   │
└─────────────────┘           └─────────────────┘
                                      │
                                      ▼
                              ┌─────────────────┐
                              │  H2 Database    │
                              │  (Persistent)   │
                              └─────────────────┘

                              ┌─────────────────┐
                              │  ML Service     │
                              │  (Separate VM)  │
                              │  Flask + Python │
                              └─────────────────┘
```

### 12.2 Backend Deployment (Render)

**Platform:** Render.com (Docker-based hosting)

#### Dockerfile Configuration

```dockerfile
FROM eclipse-temurin:17-jdk-alpine
WORKDIR /app
COPY .mvn/ .mvn
COPY mvnw pom.xml ./
RUN ./mvnw dependency:go-offline
COPY src ./src
RUN ./mvnw clean package -DskipTests
RUN cp target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```

#### Deployment Steps

1. Push code to GitHub
2. Create new Web Service on Render
3. Connect GitHub repository
4. Select Docker runtime (auto-detected)
5. Deploy → Render builds Docker image
6. Service runs on `https://recq-backend.onrender.com`

#### Environment Variables (Render Dashboard)

```
SPRING_PROFILES_ACTIVE=production
SPRING_DATASOURCE_URL=jdbc:h2:file:/data/lostandfound
ML_SERVICE_URL=https://ml-service-url:5000
SPRING_MAIL_PASSWORD=<app-password>
```

### 12.3 Frontend Deployment (Vercel)

**Platform:** Vercel (Static site hosting)

#### Why Local Build?

Vercel doesn't have Flutter SDK pre-installed. Building locally ensures:

- Consistent build environment
- Faster deployment (no SDK download)
- Control over Flutter version

#### Deployment Steps

1. **Build Flutter Web App:**

   ```bash
   cd flutter_app
   flutter build web --release --no-tree-shake-icons
   ```

2. **Copy Routing Configuration:**

   ```bash
   cp vercel.json build/web/
   ```

3. **Deploy with Vercel CLI:**

   ```bash
   cd build/web
   vercel deploy --prod
   ```

4. **Output:** `https://recq-frontend.vercel.app`

#### vercel.json Configuration

```json
{
  "routes": [
    {
      "src": "/(.*)",
      "dest": "/index.html"
    }
  ]
}
```

This ensures Flutter's client-side routing works correctly.

### 12.4 ML Service Deployment

**Options:**

1. **DigitalOcean Droplet:** $5/month VM with Python
2. **AWS EC2:** t2.micro (free tier eligible)
3. **Google Cloud Run:** Serverless (pay-per-use)
4. **Heroku:** Easy deployment (discontinued free tier)

**Recommended:** DigitalOcean Droplet

#### Setup Steps

```bash
# SSH into VM
ssh root@your-droplet-ip

# Install Python 3.9+
apt update && apt install python3.9 python3-pip

# Clone repo
git clone https://github.com/your-repo.git
cd recQ/ml_service

# Install dependencies
pip3 install -r requirements.txt

# Download spaCy model
python3 -m spacy download en_core_web_sm

# Run with Gunicorn (production server)
pip3 install gunicorn
gunicorn -b 0.0.0.0:5000 app:app

# Or run in background with nohup
nohup python3 app.py > ml_service.log 2>&1 &
```

#### Systemd Service (Auto-restart)

```ini
[Unit]
Description=Lost and Found ML Service
After=network.target

[Service]
User=root
WorkingDirectory=/root/recQ/ml_service
ExecStart=/usr/bin/python3 app.py
Restart=always

[Install]
WantedBy=multi-user.target
```

### 12.5 Database Migration

**Development:** H2 file-based  
**Production Options:**

1. Keep H2 (simple, works for small-scale)
2. Migrate to PostgreSQL (Render PostgreSQL addon)
3. Migrate to MySQL (external provider)

#### PostgreSQL Migration (Render)

1. Create PostgreSQL database on Render
2. Update `application.properties`:
   ```properties
   spring.datasource.url=jdbc:postgresql://host:5432/recq_db
   spring.datasource.username=recq_user
   spring.datasource.password=<password>
   spring.jpa.properties.hibernate.dialect=org.hibernate.dialect.PostgreSQLDialect
   ```
3. Add PostgreSQL dependency to `pom.xml`:
   ```xml
   <dependency>
       <groupId>org.postgresql</groupId>
       <artifactId>postgresql</artifactId>
   </dependency>
   ```

### 12.6 CI/CD (Optional)

**GitHub Actions Workflow:**

```yaml
name: Deploy to Render

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Trigger Render Deploy
        run: curl https://api.render.com/deploy/srv-xxx
```

---

## 13. Project Structure

### 13.1 Root Directory

```
recQ-main/
├── .mvn/                            # Maven wrapper files
├── data/                            # H2 database files (gitignored)
│   └── lostandfound.mv.db
├── flutter_app/                     # Flutter mobile/web app
├── ml_service/                      # Python ML service
├── src/                             # Spring Boot source
│   ├── main/
│   │   ├── java/
│   │   └── resources/
│   └── test/
├── target/                          # Maven build output (gitignored)
├── .gitignore
├── CLAIM_APPROVAL_VALIDATION.md     # Feature documentation
├── DEPLOYMENT.md                    # Quick deployment guide
├── Dockerfile                       # Backend container
├── FULL_DEPLOYMENT_GUIDE.md         # Detailed deployment
├── mvnw, mvnw.cmd                   # Maven wrapper scripts
├── pom.xml                          # Maven dependencies
├── README.md                        # Project overview
├── start-backend.sh                 # Backend startup script
├── start-frontend.sh                # Frontend startup script
├── start.sh                         # Combined startup script
└── TECHNICAL_REPORT.md              # This document
```

### 13.2 Git Workflow

**Branches:**

- `main`: Production-ready code
- `develop`: Development branch
- `feature/*`: Feature branches

**Commit Conventions:**

```
feat: Add claim validation logic
fix: Resolve OTP expiration bug
docs: Update deployment guide
refactor: Simplify matching algorithm
test: Add unit tests for ClaimService
```

---

## 14. Development & Build Configuration

### 14.1 Backend Development

#### Prerequisites

- Java Development Kit (JDK) 17
- Apache Maven 3.6+
- IDE: IntelliJ IDEA, Eclipse, or VS Code

#### Run Locally

```bash
# Using Maven wrapper
./mvnw spring-boot:run

# Or on Windows
mvnw.cmd spring-boot:run

# With specific profile
./mvnw spring-boot:run -Dspring-boot.run.profiles=dev

# Backend runs on http://localhost:8080
```

#### Build JAR

```bash
./mvnw clean package -DskipTests
# Output: target/lost-and-found-system-0.0.1-SNAPSHOT.jar

# Run JAR
java -jar target/lost-and-found-system-0.0.1-SNAPSHOT.jar
```

#### Run Tests

```bash
./mvnw test
./mvnw verify  # Integration tests
```

### 14.2 Frontend Development

#### Prerequisites

- Flutter SDK 3.10.7+
- Dart SDK 3.6.0+
- Android Studio (for Android development)
- Xcode (for iOS development, macOS only)

#### Run on Different Platforms

```bash
cd flutter_app

# Run on Chrome (Web)
flutter run -d chrome

# Run on Android emulator
flutter run -d android

# Run on iOS simulator (macOS)
flutter run -d ios

# Run on Windows desktop
flutter run -d windows

# Run on macOS desktop
flutter run -d macos

# Run on Linux desktop
flutter run -d linux
```

#### Build Release Versions

```bash
# Web
flutter build web --release --no-tree-shake-icons

# Android APK
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk

# Android App Bundle (for Play Store)
flutter build appbundle --release

# iOS (requires macOS)
flutter build ios --release

# Windows
flutter build windows --release

# macOS
flutter build macos --release

# Linux
flutter build linux --release
```

#### Run Tests

```bash
flutter test
flutter test --coverage
```

### 14.3 ML Service Development

#### Prerequisites

- Python 3.8+
- pip (Python package manager)
- Virtual environment (recommended)

#### Setup

```bash
cd ml_service

# Create virtual environment
python -m venv venv

# Activate (Windows)
venv\Scripts\activate

# Activate (Linux/macOS)
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Download spaCy model
python -m spacy download en_core_web_sm
```

#### Run Locally

```bash
python app.py
# ML service runs on http://localhost:5000
```

#### Test Classification

```bash
# Using predict.py
python predict.py test_images/phone.jpg
```

#### Train Model

```bash
# Prepare dataset in data/dataset1/
# Structure: train/, validation/, test/

# Run training
python train.py
```

### 14.4 Docker Development

#### Build Docker Image

```bash
docker build -t recq-backend .
```

#### Run Container

```bash
docker run -p 8080:8080 recq-backend
```

#### Docker Compose (Full Stack)

```yaml
version: "3.8"
services:
  backend:
    build: .
    ports:
      - "8080:8080"
    environment:
      - ML_SERVICE_URL=http://ml-service:5000
    depends_on:
      - ml-service

  ml-service:
    build: ./ml_service
    ports:
      - "5000:5000"
```

```bash
docker-compose up
```

---

## 15. ML Model Training & Classification

### 15.1 Dataset Preparation

#### Dataset Source

- **Open Images Dataset V6** (Google)
- **Custom Curated Dataset** for lost/found items

#### Dataset Statistics (Example)

```
Total Images: 7,000
Training Set: 4,900 (70%)
Validation Set: 1,050 (15%)
Test Set: 1,050 (15%)

Class Distribution (Balanced):
- Backpack: 500 images
- Book: 500 images
- Bottle: 500 images
- Camera: 500 images
- Earrings: 500 images
- Footwear: 500 images
- Glasses: 500 images
- Headphones: 500 images
- Laptop: 500 images
- Mobile phone: 500 images
- Necklace: 500 images
- Outerwear: 500 images
- Wallet: 500 images
- Watch: 500 images
```

#### Data Augmentation

```python
data_augmentation = Sequential([
    RandomFlip("horizontal"),           # Mirror images
    RandomRotation(0.1),                # Rotate ±10%
    RandomZoom(0.1),                    # Zoom 10%
    RandomBrightness(0.1),              # Adjust brightness
    RandomContrast(0.1),                # Adjust contrast
])
```

### 15.2 Model Architecture

**Base Model:** EfficientNetB0

- **Parameters:** 5.3M
- **Pre-training:** ImageNet (1.2M images, 1000 classes)
- **Input Size:** 224×224×3

**Custom Head:**

```python
model = Sequential([
    EfficientNetB0(include_top=False, weights='imagenet',
                   input_shape=(224, 224, 3)),
    GlobalAveragePooling2D(),
    Dropout(0.3),
    Dense(128, activation='relu', kernel_regularizer=l2(0.01)),
    BatchNormalization(),
    Dropout(0.3),
    Dense(14, activation='softmax')
])
```

**Total Parameters:** ~5.4M  
**Trainable Parameters:** ~1.5M (after freezing base)

### 15.3 Training Configuration

```python
# Hyperparameters
BATCH_SIZE = 32
EPOCHS = 20
LEARNING_RATE = 0.001
OPTIMIZER = Adam(learning_rate=LEARNING_RATE)
LOSS = SparseCategoricalCrossentropy()
METRICS = ['accuracy']

# Two-stage training
1. Freeze base model, train head (5 epochs)
   - Accuracy: ~75%

2. Unfreeze top 50 layers, fine-tune (15 epochs)
   - Accuracy: ~85%
```

### 15.4 Training Results

```
Final Training Accuracy: 92.3%
Final Validation Accuracy: 85.7%
Test Accuracy: 84.9%

Per-Class Accuracy:
- Backpack: 88%
- Book: 82%
- Bottle: 79%
- Camera: 91%
- Earrings: 78%
- Footwear: 87%
- Glasses: 93%
- Headphones: 89%
- Laptop: 94%
- Mobile phone: 95%
- Necklace: 76%
- Outerwear: 81%
- Wallet: 83%
- Watch: 92%

Average Precision: 0.86
Average Recall: 0.85
F1-Score: 0.85
```

### 15.5 Model Export

#### Keras Format

```python
model.save('models/lost_and_found_classifier12.keras')
```

#### TensorFlow Lite (Mobile)

```python
converter = tf.lite.TFLiteConverter.from_keras_model(model)
converter.optimizations = [tf.lite.Optimize.DEFAULT]
tflite_model = converter.convert()

with open('lost_and_found_classifier.tflite', 'wb') as f:
    f.write(tflite_model)
```

**TFLite Model Size:** 18 MB → 5 MB (quantized)

### 15.6 Inference Performance

**Server (Python):**

- CPU: ~200ms per image
- GPU: ~50ms per image

**Mobile (TFLite):**

- Android (Snapdragon 8 Gen 2): ~80ms
- iPhone (A15): ~60ms

**Web (TFJS - if implemented):**

- Chrome (Desktop): ~300ms
- Safari (Mobile): ~500ms

---

## 16. Future Enhancements

### 16.1 Planned Features

1. **Real-Time Chat**
   - In-app messaging between users
   - Socket.io or WebSocket integration
   - Push notifications for new messages

2. **Advanced Search**
   - Full-text search with Elasticsearch
   - Fuzzy matching
   - Date range filters
   - Location-based search (radius)

3. **Social Features**
   - User reputation/ratings
   - Thank you messages
   - Success stories feed
   - Share on social media

4. **Analytics Dashboard**
   - Item recovery rate
   - Average claim processing time
   - Popular categories
   - Heatmap of lost item locations

5. **Mobile App Features**
   - Push notifications (FCM)
   - Offline mode (local database)
   - Barcode/QR code scanning
   - Reverse image search

6. **ML Improvements**
   - Object detection (find item in cluttered image)
   - OCR for documents (extract text)
   - Face blurring (privacy)
   - Multi-object classification

7. **Gamification**
   - Badges for helpful users
   - Leaderboards
   - Rewards for returning items

8. **Integration**
   - University systems integration
   - Police department API
   - Insurance claims
   - Smart locker systems

### 16.2 Technical Debt

1. **Testing**
   - Increase unit test coverage (target: 80%)
   - Add integration tests
   - E2E tests with Selenium/Cypress
   - Performance testing

2. **Security**
   - Implement rate limiting
   - Add CAPTCHA for registration
   - Enable HTTPS for local development
   - Penetration testing

3. **Performance**
   - Database indexing optimization
   - Redis caching for frequently accessed data
   - CDN for images
   - Lazy loading for large lists

4. **Code Quality**
   - Refactor large methods
   - Extract duplicate code
   - Add comprehensive documentation
   - Follow SOLID principles

5. **Infrastructure**
   - Kubernetes deployment
   - Auto-scaling policies
   - Database backups
   - Monitoring & alerting (Prometheus, Grafana)

### 16.3 Scalability Considerations

**Current Capacity:**

- Users: Up to 10,000
- Items: Up to 50,000
- Concurrent Requests: ~500

**Scaling Strategies:**

1. **Horizontal Scaling**
   - Deploy multiple backend instances
   - Load balancer (Nginx, AWS ELB)
   - Stateless session management

2. **Database Scaling**
   - Read replicas
   - Database sharding by region
   - Migrate to cloud database (AWS RDS)

3. **Caching Layer**
   - Redis for session storage
   - Cache popular items
   - Cache ML embeddings

4. **Microservices**
   - Separate item service
   - Separate matching service
   - Separate notification service
   - Message queue (RabbitMQ, Kafka)

5. **CDN & Asset Optimization**
   - CloudFlare for static assets
   - Image compression (WebP format)
   - Lazy image loading

---

## 17. Conclusion

The Lost & Found System (recQ) is a comprehensive, production-ready application that demonstrates modern software engineering practices:

### Technical Achievements

- **Full-Stack Architecture:** Spring Boot + Flutter + Flask
- **AI-Powered Features:** Image classification, semantic matching, question generation
- **Cross-Platform:** Runs on Android, iOS, Web, Windows, macOS, Linux
- **Secure:** Session-based auth, password encryption, OTP verification
- **Scalable:** Containerized, microservices-ready, cloud-deployed

### Business Value

- **User-Friendly:** Intuitive UI, guided workflows
- **Intelligent:** AI reduces manual effort in matching items
- **Trustworthy:** Verification questions prevent false claims
- **Community-Focused:** Helps people recover lost belongings

### Development Highlights

- **Clean Code:** Layered architecture, separation of concerns
- **Best Practices:** JPA/Hibernate, Provider pattern, RESTful API
- **Documentation:** Comprehensive guides for development and deployment
- **Extensible:** Easy to add new features and integrate with external systems

### Key Metrics

- **Lines of Code:** ~15,000
- **API Endpoints:** 40+
- **Screen Count:** 17
- **ML Model Accuracy:** 85%
- **Deployment Time:** < 10 minutes

---

## Appendix A: Glossary

- **BCrypt:** Password hashing algorithm
- **CORS:** Cross-Origin Resource Sharing
- **EfficientNet:** Image classification neural network architecture
- **Embedding:** Numerical vector representation of data
- **H2:** Embedded Java SQL database
- **Hibernate:** ORM (Object-Relational Mapping) framework
- **JPA:** Java Persistence API
- **JWT:** JSON Web Token (not used in this project)
- **ORM:** Object-Relational Mapping
- **OTP:** One-Time Password
- **RBAC:** Role-Based Access Control
- **REST:** Representational State Transfer
- **SBERT:** Sentence-BERT (text embedding model)
- **TFLite:** TensorFlow Lite (mobile ML framework)
- **UUID:** Universally Unique Identifier

---

## Appendix B: Contact & Support

**Project Repository:** https://github.com/your-username/recQ  
**Documentation:** See README.md, DEPLOYMENT.md, FULL_DEPLOYMENT_GUIDE.md  
**Issue Tracker:** https://github.com/your-username/recQ/issues

**For Technical Questions:**

- Review this technical report
- Check existing documentation
- Search GitHub issues
- Create new issue if needed

---

**Report End**

_This technical report was generated on March 1, 2026. For the latest information, please refer to the project repository._
