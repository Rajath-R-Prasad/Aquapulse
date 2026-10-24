# JalRakshak - Field Engineer Mobile App

A Flutter mobile application for field engineers working with the AquaPulse water leak detection system. Engineers can view assigned work orders, navigate to incident locations, capture evidence, and submit repair reports.

## Features

- **Authentication**: Supabase login with persistent sessions and engineer self-signup
- **Engineer Dashboard**: Real-time statistics, high-priority alerts, and recent work orders feed
- **Work Order Management**: View assigned jobs with filtering, sorting, and status tracking
- **Interactive Maps**: OpenStreetMap integration showing incident locations and engineer position
- **Location Services**: GPS tracking with permission handling and geofence validation
- **Evidence Capture**: Photo capture from camera/gallery with GPS tagging and SHA-256 hashing
- **Repair Submission**: Complete forms with repair type, materials, labour time, and notes
- **Push Notifications**: FCM integration for work order assignments and updates
- **Profile Management**: View engineer details, skills, and app version information

## Requirements

- Flutter 3.11.5 or higher
- Dart 3.11.5 or higher
- Android API 21+ (Android 5.0 Lollipop) or iOS 12+
- Active internet connection for API calls
- GPS/location services enabled for field work
- Camera permissions for evidence capture

## Android Permissions

The app requires the following permissions (declared in `android/app/src/main/AndroidManifest.xml`):

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

## Configuration

### Environment Variables

The app defaults to the AquaPulse hosted Supabase project and Android-emulator
backend URL, so from `mobile/` you can start the Android emulator app with:

```powershell
flutter run
```

The bundled Supabase anon/publishable key is intended for client apps; never
put a Supabase service-role key in the mobile app. Override the defaults for a
different Supabase project or backend with Dart defines (the app does not load
a `.env` file):

```powershell
flutter run -d chrome `
  --dart-define=SUPABASE_URL=https://your-project-ref.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=your-supabase-publishable-or-anon-key `
  --dart-define=API_BASE_URL=http://localhost:8000
```

The default API URL `http://10.0.2.2:8000` is for an Android emulator. For a
physical Android phone, make sure the backend is running on the computer with
`--host 0.0.0.0`, connect the phone and computer to the same Wi-Fi, and pass
the computer's current LAN IP:

```powershell
flutter run --dart-define=API_BASE_URL=http://<computer-lan-ip>:8000
```

Windows Firewall must allow inbound connections to port 8000 on the private
network. The LAN IP can change when reconnecting to Wi-Fi. For Chrome on the
computer, use `--dart-define=API_BASE_URL=http://localhost:8000`.

The default Supabase URL and anon key target the hosted AquaPulse project. The
local Supabase URL (`http://10.0.2.2:54321`) is only appropriate when the local
Supabase stack is running in an Android emulator.

### Firebase Cloud Messaging Setup

Firebase Messaging is optional. To receive assignment pushes, configure the
mobile app and backend to use the same Firebase project:

1. Create a Firebase project at [https://console.firebase.google.com](https://console.firebase.google.com)

2. Add an Android app to your Firebase project:
   - Package name: `com.aquapulse.jalrakshak`
   - Download `google-services.json`
   - Place it in `android/app/` directory

3. Set the backend `FCM_CREDENTIALS_JSON` to a Firebase service-account JSON
   key from that same project and restart the backend.
4. Run the Android app with Firebase messaging enabled:
   ```powershell
   flutter run --dart-define=ENABLE_FIREBASE_MESSAGING=true
   ```

The Android Google Services Gradle plugin is already configured and is applied
when `android/app/google-services.json` exists. Without Firebase configuration,
the app remains usable: Supabase Realtime delivers new assignment notices while
the app is connected, local notifications can be shown while it is open, and a
five-second check is retained as a fallback. Firebase is required for
operating-system push delivery while the app is in the background or closed.

**Template**: See `android/app/google-services.json.template` for the expected structure.

### Map Tiles Configuration

The app uses OpenStreetMap tiles (no API key required). Default configuration in code:

```dart
urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'
```

For production, consider:
- Self-hosted tile server
- Commercial tile provider (Mapbox, Maptiler)
- Caching strategy for offline support

## Installation

### Development Build

```bash
# Install dependencies
flutter pub get

# Run code generation for Freezed models
flutter pub run build_runner build --delete-conflicting-outputs

# Run on connected device/emulator
flutter run

# Run in release mode
flutter run --release
```

### Production Build

```bash
# Android APK
flutter build apk --release

# Android App Bundle (recommended for Play Store)
flutter build appbundle --release

# iOS
flutter build ios --release
```

Built artifacts:
- APK: `build/app/outputs/flutter-apk/app-release.apk`
- App Bundle: `build/app/outputs/bundle/release/app-release.aab`

## Architecture

### State Management

- **Riverpod 2.6.1**: Provider-based state management with automatic dependency injection
- **Providers**: Data fetching and caching with auto-dispose for memory efficiency
- **Notifiers**: Mutable state for authentication and complex workflows

### Data Layer

- **Freezed Models**: Immutable data classes with JSON serialization
- **API Client**: Dio-based HTTP client with interceptors for:
  - JWT token injection
  - RFC 9457 error handling
  - Request/response logging
- **Services**: Separate services for auth, work orders, location, evidence, notifications

### Navigation

- **GoRouter 14.8.1**: Declarative routing with:
  - Authentication guards (redirect to login if session expired)
  - Deep linking support for notifications
  - Nested routes for work order details and repair submission
  - Shell route for bottom navigation

### Key Directories

```
lib/
├── app/                    # App initialization, routing, shell
├── core/
│   ├── config/            # Environment configuration
│   ├── models/            # Freezed data models
│   ├── network/           # API client, interceptors
│   ├── services/          # Location, evidence, FCM services
│   ├── theme/             # App theme and colors
│   └── widgets/           # Reusable widgets
└── features/
    ├── auth/              # Login, session management
    ├── dashboard/         # Engineer dashboard
    ├── jobs/              # Work order list
    ├── workorders/        # Detail, repair submission
    ├── notifications/     # Notification list
    └── profile/           # Engineer profile
```

## Backend API Integration

### Base URL
Configure in `.env` file: `API_BASE_URL=https://your-backend-api.com`

### Endpoints Used

- `POST /v1/auth/login` - Email/password authentication
- `GET /v1/me` - Current user profile
- `GET /v1/me/workorders` - Assigned work orders (with filtering)
- `GET /v1/workorders/:id` - Work order details
- `POST /v1/workorders/:id/accept` - Accept work order
- `POST /v1/workorders/:id/arrive` - Mark arrival on site
- `POST /v1/workorders/:id/evidence/upload-url` - Get signed upload URL
- `POST /v1/workorders/:id/evidence` - Register evidence after upload
- `POST /v1/workorders/:id/submit` - Submit repair completion
- `GET /v1/notifications` - Fetch notifications
- `POST /v1/notifications/:id/read` - Mark notification as read
- `POST /v1/me/push-token` - Register FCM push token

### Authentication

- JWT tokens stored in `flutter_secure_storage`
- Engineers can create accounts from the login screen; the backend assigns the `ENGINEER` role
- Automatic token injection via Dio interceptor
- Session refresh on app restart
- Auto-redirect to login on 401 responses

### Error Handling

- RFC 9457 Problem Details parsing
- User-friendly error messages
- Retry mechanisms for transient failures
- Offline detection with `connectivity_plus`

## Known Limitations

1. **Map Tiles**: OpenStreetMap tiles rate-limited for heavy use (consider commercial provider for production)
2. **Offline Support**: Limited offline functionality (cached data only, no offline-first architecture)
3. **Image Compression**: Evidence photos not automatically compressed (10MB limit enforced)
4. **FCM Setup**: Requires manual Firebase configuration (google-services.json)
5. **iOS Testing**: Development primarily on Android (iOS may need additional configuration)
6. **Geofence Override**: Manual override available if GPS accuracy insufficient (requires confirmation)

## Troubleshooting

### "Failed to load work orders"

- Check API_BASE_URL in `.env`
- Verify backend is running and accessible
- Check authentication token validity
- Review Dio logs in console

### Location Services Not Working

- Ensure location permissions granted in device settings
- Check GPS is enabled
- Test in outdoor environment for better signal
- Review `LocationService` logs

### Evidence Upload Fails

- Verify image size under 10MB
- Check network connectivity
- Confirm signed URL not expired (5-minute TTL)
- Review backend storage configuration

### Push Notifications Not Received

- Confirm `google-services.json` properly configured
- Check FCM token registered with backend
- Verify notification permissions granted
- Test with Firebase Console test message

### Build Errors

```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run
```

### Freezed Generation Issues

```bash
# Delete conflicting outputs and regenerate
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

## Testing

### Manual Testing Checklist

1. **Authentication Flow**
   - [ ] Login with valid credentials
   - [ ] Session persistence across app restarts
   - [ ] Auto-logout on token expiry
   - [ ] Error handling for invalid credentials

2. **Dashboard**
   - [ ] Statistics display correctly
   - [ ] High-priority alerts visible
   - [ ] Pull-to-refresh updates data
   - [ ] Navigation to work orders works

3. **Work Order Workflow**
   - [ ] List shows assigned jobs
   - [ ] Filtering by status works
   - [ ] Detail screen shows all information
   - [ ] Map displays incident and engineer location
   - [ ] Accept/decline actions work
   - [ ] Status transitions (EN_ROUTE → ON_SITE → SUBMITTED)
   - [ ] Timeline shows all transitions

4. **Evidence Capture**
   - [ ] Camera permission requested
   - [ ] Photo capture works (camera and gallery)
   - [ ] GPS tagging includes coordinates
   - [ ] Upload progress indicator displays
   - [ ] Evidence appears in detail screen

5. **Repair Submission**
   - [ ] All form fields validate correctly
   - [ ] Materials can be added/removed
   - [ ] Evidence required for submission
   - [ ] Success confirmation displays
   - [ ] Work order status updates

6. **Notifications**
   - [ ] List shows all notifications
   - [ ] Unread indicators display correctly
   - [ ] Tap opens relevant work order
   - [ ] Push notifications arrive (if FCM configured)

7. **Profile**
   - [ ] Engineer details display
   - [ ] App version shows correctly
   - [ ] Sign out works with confirmation

## Support

For issues or questions:
- Backend API: Contact AquaPulse backend team
- Mobile App: Review logs and error messages
- Firebase: Check Firebase Console for FCM issues

## License

Proprietary - AquaPulse Water Leak Detection System
