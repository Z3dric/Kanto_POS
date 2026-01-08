# Firebase Authentication Setup Guide

This guide will help you complete the Firebase authentication setup for your Kanto POS app.

## Prerequisites
- A Google/Gmail account
- Your app is using Flutter with the latest Firebase plugins

## Step 1: Create a Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **"Create a project"**
3. Enter project name: **kanto-pos** (or your preferred name)
4. Disable Google Analytics (optional) and click **"Create project"**
5. Wait for the project to be created

## Step 2: Set Up Authentication

1. In Firebase Console, go to **Authentication** (left sidebar)
2. Click **"Get Started"**
3. Under "Sign-in method", click **"Email/Password"**
4. Enable **"Email/Password"** and click **"Save"**
5. **Important**: Enable **"Email link (passwordless sign-in)"** as well for password reset

## Step 3: Register Your Apps in Firebase

### For Android:
1. In Firebase Console, click the Android icon or go to **Project settings**
2. Click **"Add app"** → select **Android**
3. Package name: `com.example.simple_pos` (update if different)
4. App nickname: `Kanto POS Android`
5. Click **"Register app"**
6. Download `google-services.json`
7. Place it in: `android/app/google-services.json`
8. Click **"Next"** → **"Skip"** → **"Continue to console"**

### For iOS:
1. Click **"Add app"** → select **iOS**
2. iOS bundle ID: `com.example.simplepos`
3. App nickname: `Kanto POS iOS`
4. Click **"Register app"**
5. Download `GoogleService-Info.plist`
6. Open Xcode: `ios/Runner.xcworkspace`
7. Drag `GoogleService-Info.plist` into Xcode (check "Copy items if needed")
8. Click **"Next"** → **"Next"** → **"Continue to console"**

## Step 4: Get Your Firebase Configuration

1. Go to **Project Settings** (gear icon, top right)
2. Select **"Your apps"** section
3. Find your Android/iOS app configuration
4. Copy the credentials for `firebase_options.dart`

## Step 5: Update firebase_options.dart

In your project, edit `lib/firebase_options.dart`:

Replace the placeholder values with your actual Firebase credentials:

### For Web:
```dart
static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'YOUR_WEB_API_KEY',
  appId: '1:YOUR_PROJECT_NUMBER:web:YOUR_WEB_APP_ID',
  messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
  projectId: 'your-project-id',
  authDomain: 'your-project-id.firebaseapp.com',
  storageBucket: 'your-project-id.appspot.com',
);
```

### For Android:
```dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'YOUR_ANDROID_API_KEY',
  appId: '1:YOUR_PROJECT_NUMBER:android:YOUR_ANDROID_APP_ID',
  messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
  projectId: 'your-project-id',
  storageBucket: 'your-project-id.appspot.com',
);
```

### For iOS:
```dart
static const FirebaseOptions ios = FirebaseOptions(
  apiKey: 'YOUR_IOS_API_KEY',
  appId: '1:YOUR_PROJECT_NUMBER:ios:YOUR_IOS_APP_ID',
  messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
  projectId: 'your-project-id',
  storageBucket: 'your-project-id.appspot.com',
  iosBundleId: 'com.example.simplepos',
);
```

You can find these values in Firebase Console → Project Settings → Your Apps

## Step 6: Update pubspec.yaml

Run the following command to install dependencies:
```bash
flutter pub get
```

The Firebase packages should now be available.

## Step 7: Test the Setup

1. Start your app in debug mode:
```bash
flutter run
```

2. You should see the **Login** screen
3. Click **"Sign Up"** to create a new account
4. Fill in the form and click **"Sign Up"**
5. You should be logged in and see the main POS app
6. Test **"Logout"** from the home screen

## Step 8: Add Logout Button to Home Screen (Optional)

Add a logout button to your home screen:

```dart
appBar: AppBar(
  title: const Text('Kanto POS'),
  actions: [
    IconButton(
      icon: const Icon(Icons.logout),
      onPressed: () async {
        await context.read<AuthService>().logout();
      },
    ),
  ],
),
```

## Features Included

✅ User Registration (Sign Up)
✅ User Login (Email/Password)
✅ Password Reset (Forgot Password)
✅ Persistent Login (stays logged in after app restart)
✅ Logout
✅ Error Handling
✅ Loading States

## Troubleshooting

### "Target of URI doesn't exist"
- Run `flutter pub get`
- Run `flutter clean && flutter pub get`
- Rebuild: `flutter run`

### "google-services.json not found"
- Make sure you downloaded it from Firebase
- Place it in: `android/app/google-services.json` (exact path)
- Run `flutter clean && flutter run`

### "Firebase initialization failed"
- Check your firebase_options.dart has correct credentials
- Verify your project ID matches in Firebase Console
- Check that Android/iOS apps are registered in Firebase

### Authentication fails
- Verify "Email/Password" is enabled in Firebase Console
- Check that your email address is correct
- For weak password error: use at least 6 characters

## Next Steps

1. **Test on a real device** (not just emulator)
2. **Set up email verification** (send verification email on signup)
3. **Add Google Sign-In** (optional advanced feature)
4. **Set up password reset email templates** in Firebase Console
5. **Deploy to production** with proper Firebase security rules

## Security Notes

⚠️ **Important**: 
- Never commit `google-services.json` or credentials to version control
- Add to `.gitignore`:
  ```
  google-services.json
  lib/firebase_options.dart
  ```
- Use Firebase Security Rules to protect your data
- Never expose API keys in your code (they're public in Flutter apps anyway, so use Firebase security)

## Support

If you encounter issues:
1. Check [Firebase Flutter Documentation](https://firebase.google.com/docs/flutter/setup)
2. Review error messages in the Flutter console
3. Check Firebase Console for configuration issues
4. Verify all credentials match exactly
