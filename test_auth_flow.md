# 🧪 Authentication Flow Testing Guide

## Overview
This guide helps you test the mobile app's authentication and token storage functionality.

## Testing Steps

### 1. Run the Mobile App
```bash
cd mobile
flutter run
```

### 2. Login Test
1. **Navigate to Login Screen**: The app should show the login screen
2. **Use Development Panel**: Look for the "Development Auto-Login" panel
3. **Choose Test Account**: Click on "👤 John User" (user@pulselink.com)
4. **Watch Logs**: Monitor the console for authentication logs

### 3. Expected Login Logs
Look for these log messages in the console:
```
I/flutter: 🔐 Setting auth token in API client...
I/flutter: ✅ Auth token set in API client: eyJhbGciOiJIUzI1NiIs...
I/flutter: ✅ Auth token set in service locator
I/flutter: 💾 Storing tokens securely...
I/flutter: ✅ Tokens stored securely in device storage
I/flutter: 🔍 Verification - Access token stored: true
I/flutter: 🔍 Verification - Refresh token stored: true
```

### 4. Test Authenticated API Calls
1. **After successful login**: Look for the "Test Auth API Calls" button
2. **Click the button**: This will test making authenticated requests
3. **Watch for logs**: Should see authentication headers being sent

### 5. Expected API Test Logs
```
I/flutter: 🧪 Testing authenticated API calls...
I/flutter: 🔑 Has auth token: true
I/flutter: 📱 Making authenticated request to get matching suggestions...
I/flutter: 🔑 Auth token added to request: eyJhbGciOiJIUzI1NiIs...
I/flutter: 🚀 GET https://apilink.pulsetek.co.za/api/v1/matching/suggestions?offset=0&limit=5
I/flutter: ✅ Successfully retrieved 5 suggestions
```

## Test Accounts Available
- **User**: user@pulselink.com / User123!
- **Moderator**: moderator@pulselink.com / Mod123!
- **Admin**: admin@pulselink.com / Admin123!
- **Super Admin**: superadmin@pulselink.com / SuperAdmin123!

## What to Verify

### ✅ Token Storage
- [ ] Access token is stored after login
- [ ] Refresh token is stored after login
- [ ] Tokens persist between app restarts

### ✅ Token Usage
- [ ] Auth header is automatically added to requests
- [ ] API calls succeed with valid token
- [ ] 401 errors trigger token refresh

### ✅ Error Handling
- [ ] Login failures are handled gracefully
- [ ] Invalid tokens trigger re-authentication
- [ ] Network errors are handled properly

## Troubleshooting

### No Auth Token Available
- Make sure you've logged in successfully
- Check that login response contains valid tokens
- Verify token storage is working

### API Calls Failing
- Check network connectivity
- Verify backend is running
- Ensure tokens haven't expired

### Development Panel Not Visible
- Make sure app is running in debug mode
- Check `TestCredentials.isDevelopmentMode` is true

## Success Criteria
✅ **Login works**: User can log in with test credentials
✅ **Tokens stored**: Access and refresh tokens are saved securely  
✅ **Auth headers**: Requests automatically include Bearer token
✅ **API calls work**: Authenticated endpoints return data successfully
✅ **Persistence**: Tokens survive app restarts