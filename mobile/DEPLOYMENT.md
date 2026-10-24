# Deployment Guide

## Prerequisites Checklist

Before deploying the JalRakshak mobile app to production, ensure the following are complete:

### 1. Code Generation
```bash
# Fix Freezed code generation issue first (see KNOWN_ISSUES.md)
flutter pub upgrade
flutter pub run build_runner build --delete-conflicting-outputs

# Verify no errors
flutter analyze
```

### 2. Environment Configuration

Create `.env` file in project root:
```env
SUPABASE_URL=https://your-production-supabase-url.supabase.co
SUPABASE_ANON_KEY=your-production-anon-key
API_BASE_URL=https://your-production-api.com
```

### 3. Firebase Setup (Push Notifications)

#### Android
1. Create Firebase project at https://console.firebase.google.com
2. Add Android app with package name: `com.aquapulse.jalrakshak`
3. Download `google-services.json`
4. Place in `android/app/google-services.json`

#### iOS (if applicable)
1. Add iOS app to Firebase project
2. Download `GoogleService-Info.plist`
3. Place in `ios/Runner/GoogleService-Info.plist`

### 4. Update App Configuration

#### android/app/build.gradle
```gradle
android {
    defaultConfig {
        applicationId "com.aquapulse.jalrakshak"
        minSdkVersion 21
        targetSdkVersion 34
        versionCode 1
        versionName "1.0.0"
    }

    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }

    buildTypes {
        release {
            signingConfig signingConfigs.release
            shrinkResources true
            minifyEnabled true
        }
    }
}
```

#### android/key.properties (DO NOT COMMIT)
```properties
storePassword=your-keystore-password
keyPassword=your-key-password
keyAlias=your-key-alias
storeFile=../keystore.jks
```

### 5. Generate Signing Key

```bash
keytool -genkey -v -keystore android/keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias jalrakshak
```

Store passwords securely - never commit to version control.

## Build Commands

### Debug Build
```bash
flutter build apk --debug
# Output: build/app/outputs/flutter-apk/app-debug.apk
```

### Release Build (APK)
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Release Build (App Bundle - Recommended for Play Store)
```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

### iOS Build
```bash
flutter build ios --release
```

## Pre-Deployment Testing

### 1. Manual Testing Checklist

Run through complete workflow:

- [ ] Login with valid engineer credentials
- [ ] Dashboard loads with correct statistics
- [ ] Work order list shows assigned jobs
- [ ] Filtering by status works
- [ ] Work order detail displays all information
- [ ] Map shows incident and engineer location
- [ ] Accept work order transitions to EN_ROUTE
- [ ] Arrive on site with GPS validation
- [ ] Capture before photos (camera and gallery)
- [ ] Submit repair with materials and notes
- [ ] Capture after photos
- [ ] Complete repair submission
- [ ] Verify status updates in dashboard
- [ ] Check notifications received
- [ ] Test sign out and re-login

### 2. Performance Testing

```bash
# Profile mode for performance analysis
flutter run --profile

# Check app size
flutter build apk --release --analyze-size
```

### 3. Security Checklist

- [ ] API_BASE_URL uses HTTPS
- [ ] JWT tokens stored in flutter_secure_storage
- [ ] No API keys or secrets in code
- [ ] google-services.json not committed to repo
- [ ] Signing keys stored securely
- [ ] ProGuard rules configured (if using)

## Deployment Steps

### Google Play Store

1. **Prepare Store Listing**
   - App icon (512x512px)
   - Feature graphic (1024x500px)
   - Screenshots (multiple device sizes)
   - Privacy policy URL
   - App description and details

2. **Upload Release**
   ```bash
   flutter build appbundle --release
   ```
   - Upload `app-release.aab` to Play Console
   - Complete store listing
   - Set pricing and distribution
   - Submit for review

3. **Internal Testing Track**
   - Deploy to internal testing first
   - Test with actual field engineers
   - Verify Firebase notifications work
   - Check GPS and location services

4. **Staged Rollout**
   - Start with 10% of users
   - Monitor crash reports in Firebase Crashlytics
   - Gradually increase to 100%

### Direct Distribution (APK)

1. Build signed APK
   ```bash
   flutter build apk --release
   ```

2. Host APK on secure server or distribute via MDM

3. Enable "Install from Unknown Sources" on devices

4. Install APK:
   ```bash
   adb install build/app/outputs/flutter-apk/app-release.apk
   ```

## Post-Deployment Monitoring

### Firebase Console
- Monitor crash reports
- Check FCM delivery rates
- Review performance metrics

### Backend API Logs
- Monitor authentication failures
- Track API error rates
- Watch for unusual patterns

### User Feedback
- Set up feedback mechanism
- Monitor app store reviews
- Track support tickets

## Rollback Plan

If critical issues are discovered:

1. Halt staged rollout in Play Console
2. Communicate issue to users
3. Revert to previous version if needed
4. Fix issue in development
5. Re-test thoroughly
6. Redeploy with patch version

## Version Management

Use semantic versioning: `MAJOR.MINOR.PATCH`

Update in `pubspec.yaml`:
```yaml
version: 1.0.0+1  # version name + build number
```

For each release:
- Increment build number (+1)
- Update version name based on changes:
  - MAJOR: Breaking changes
  - MINOR: New features
  - PATCH: Bug fixes

## Continuous Integration (Optional)

Example GitHub Actions workflow:

```yaml
name: Flutter CI

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.11.5'
      - run: flutter pub get
      - run: flutter pub run build_runner build --delete-conflicting-outputs
      - run: flutter analyze
      - run: flutter test
      - run: flutter build apk --debug
```

## Support Contacts

- **Backend API Issues**: AquaPulse backend team
- **Firebase/FCM Issues**: DevOps team
- **Mobile App Issues**: Mobile development team
- **Play Store Issues**: Release management team

## Appendix: Environment-Specific Configs

### Development
```env
API_BASE_URL=http://10.0.2.2:8000
SUPABASE_URL=http://10.0.2.2:54321
```

### Staging
```env
API_BASE_URL=https://staging-api.aquapulse.com
SUPABASE_URL=https://staging-project.supabase.co
```

### Production
```env
API_BASE_URL=https://api.aquapulse.com
SUPABASE_URL=https://production-project.supabase.co
```
