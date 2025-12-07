# Firebase Configuration Investigation & Debugging Guide

**Status**: BoxSyncDashboard codebase not found - Creating setup/debugging guide for future implementation

**Date**: December 7, 2025  
**Repo**: GideonBoxingAI

---

## Executive Summary

This document provides a comprehensive Firebase configuration debugging guide for the BoxSyncDashboard. Since the dashboard codebase has not been created yet, this serves as both a:
1. **Debugging checklist** for when Firebase issues occur
2. **Setup guide** for initial Firebase configuration
3. **Troubleshooting reference** for common Firebase problems

---

## Table of Contents

1. [Environment Variables Check](#environment-variables-check)
2. [Firebase Initialization Verification](#firebase-initialization-verification)
3. [Common Firebase Configuration Issues](#common-firebase-configuration-issues)
4. [Firestore Query Debugging](#firestore-query-debugging)
5. [Authentication Issues](#authentication-issues)
6. [Package Dependencies Check](#package-dependencies-check)
7. [Network & Connectivity Issues](#network--connectivity-issues)
8. [Debugging Workflow](#debugging-workflow)
9. [Recommended Fixes](#recommended-fixes)

---

## 1. Environment Variables Check

### 1.1 Expected Firebase Environment Variables

Firebase requires the following environment variables for proper configuration:

#### **Client-Side (Frontend - .env.local or .env)**
```
NEXT_PUBLIC_FIREBASE_API_KEY=<your-api-key>
NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN=<your-project>.firebaseapp.com
NEXT_PUBLIC_FIREBASE_PROJECT_ID=<your-project-id>
NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET=<your-project>.appspot.com
NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID=<sender-id>
NEXT_PUBLIC_FIREBASE_APP_ID=<app-id>
NEXT_PUBLIC_FIREBASE_MEASUREMENT_ID=<measurement-id>
```

#### **Server-Side (Backend/Node.js - .env or .env.local)**
```
FIREBASE_PROJECT_ID=<your-project-id>
FIREBASE_PRIVATE_KEY=<your-private-key>
FIREBASE_CLIENT_EMAIL=<service-account-email>
FIREBASE_DATABASE_URL=https://<project-id>.firebaseio.com
FIREBASE_STORAGE_BUCKET=<your-project>.appspot.com
```

### 1.2 How to Check Environment Variables

#### **For Next.js / React Dashboard:**
```bash
# 1. Check if .env.local exists
ls -la .env.local

# 2. Verify the file contains Firebase config
cat .env.local | grep NEXT_PUBLIC_FIREBASE

# 3. Check if variables are properly formatted (key=value)
# Should look like: NEXT_PUBLIC_FIREBASE_API_KEY=AIzaSyD...

# 4. Verify no extra spaces or quotes
# WRONG: NEXT_PUBLIC_FIREBASE_API_KEY = "AIzaSyD..."
# RIGHT: NEXT_PUBLIC_FIREBASE_API_KEY=AIzaSyD...
```

#### **For Node.js Backend:**
```bash
# Check server-side env file
cat .env | grep FIREBASE

# Verify private key is properly escaped
# The private key should have escaped newlines: -----BEGIN PRIVATE KEY-----\n...
grep -A 5 FIREBASE_PRIVATE_KEY .env

# Test environment variables are loaded
node -e "console.log(process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID)"
```

### 1.3 Common Environment Variable Issues

| Issue | Cause | Fix |
|-------|-------|-----|
| `undefined` when accessing `process.env.NEXT_PUBLIC_FIREBASE_API_KEY` | Variables not loaded | Restart dev server after adding .env.local |
| Wrong config values | Copied wrong values from Firebase Console | Re-copy from Firebase Console > Project Settings |
| API Key not working | API Key has restrictions | In Firebase Console, edit restrictions to allow all APIs |
| "This API key is not authorized" | Missing API enablement | Enable required APIs in Google Cloud Console |
| Environment var with spaces | Copy-paste included spaces | Remove leading/trailing spaces: `KEY=value` not `KEY = value ` |

---

## 2. Firebase Initialization Verification

### 2.1 Client-Side Firebase Initialization (Next.js/React)

#### **File: `lib/firebase.ts` or `config/firebase.ts`**

**Correct Implementation:**
```typescript
import { initializeApp } from 'firebase/app';
import { getAuth } from 'firebase/auth';
import { getFirestore } from 'firebase/firestore';
import { getStorage } from 'firebase/storage';

const firebaseConfig = {
  apiKey: process.env.NEXT_PUBLIC_FIREBASE_API_KEY,
  authDomain: process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN,
  projectId: process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID,
  storageBucket: process.env.NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET,
  messagingSenderId: process.env.NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID,
  appId: process.env.NEXT_PUBLIC_FIREBASE_APP_ID,
  measurementId: process.env.NEXT_PUBLIC_FIREBASE_MEASUREMENT_ID,
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);

// Initialize Firebase services
export const auth = getAuth(app);
export const db = getFirestore(app);
export const storage = getStorage(app);

export default app;
```

**Debug Checklist:**
```typescript
// Add this to diagnose initialization issues
console.log('Firebase Config:', firebaseConfig);
console.log('App initialized:', app.name);
console.log('Auth initialized:', auth);
console.log('Firestore initialized:', db);
console.log('Storage initialized:', storage);

// Check if any config values are undefined
const missingKeys = Object.entries(firebaseConfig)
  .filter(([key, value]) => !value)
  .map(([key]) => key);

if (missingKeys.length > 0) {
  console.error('Missing Firebase config keys:', missingKeys);
}
```

### 2.2 Server-Side Firebase Admin SDK Initialization

#### **File: `lib/firebaseAdmin.ts` or `config/firebaseAdmin.ts`**

**Correct Implementation:**
```typescript
import * as admin from 'firebase-admin';

// Method 1: Using service account JSON
const serviceAccount = require('../path/to/serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: `https://${process.env.FIREBASE_PROJECT_ID}.firebaseio.com`,
  storageBucket: process.env.FIREBASE_STORAGE_BUCKET,
});

// Method 2: Using environment variables (recommended for prod)
admin.initializeApp({
  credential: admin.credential.cert({
    projectId: process.env.FIREBASE_PROJECT_ID,
    privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
    clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
  }),
  storageBucket: process.env.FIREBASE_STORAGE_BUCKET,
});

export const adminAuth = admin.auth();
export const adminDb = admin.firestore();
export const adminStorage = admin.storage();

export default admin;
```

**Debug Checklist:**
```typescript
// Test admin SDK initialization
async function testFirebaseAdmin() {
  try {
    const adminApp = admin.app();
    console.log('Admin app initialized:', adminApp.name);

    // Test Firestore connection
    const testDoc = await admin.firestore()
      .collection('_test')
      .doc('test')
      .get();
    console.log('Firestore connection: OK');

    // Test Auth
    const users = await admin.auth().listUsers(1);
    console.log('Auth connection: OK');

    // Test Storage
    const bucket = admin.storage().bucket();
    console.log('Storage bucket:', bucket.name);
  } catch (error) {
    console.error('Firebase Admin initialization error:', error);
  }
}

testFirebaseAdmin();
```

### 2.3 Common Initialization Issues

| Issue | Symptom | Solution |
|-------|---------|----------|
| Config undefined | "Cannot read property of undefined" | Check .env.local exists and variables are prefixed with `NEXT_PUBLIC_` |
| App not initialized | "Firebase App named [DEFAULT] already exists" | Don't call `initializeApp()` multiple times |
| Wrong credential format | "service account must contain required fields" | Verify private key has escaped newlines: `.replace(/\\n/g, '\n')` |
| Missing package | Module not found: 'firebase/app' | Run `npm install firebase firebase-admin` |

---

## 3. Common Firebase Configuration Issues

### 3.1 API Key Issues

**Problem: "API key invalid" or "Unauthorized"**

```bash
# Check API Key in Firebase Console
# Project Settings > API keys > Copy the Web API Key

# Verify API Key restrictions:
# 1. Go to Google Cloud Console
# 2. APIs & Services > Credentials
# 3. Click on your API key
# 4. Under API restrictions, select "All APIs"
# 5. Save changes

# Test API key with curl (client-side)
curl -X POST "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"returnSecureToken": true}'
```

### 3.2 Project ID Mismatch

**Problem: "The project ID is not set"**

```bash
# Verify project ID in multiple places

# 1. .env.local
grep FIREBASE_PROJECT_ID .env.local

# 2. Firebase Console URL
# firebase.google.com/project/<PROJECT_ID>/overview

# 3. Google Cloud Console
# console.cloud.google.com > Select project from dropdown

# 4. Service account key file
cat serviceAccountKey.json | grep project_id

# All should match!
```

### 3.3 Authentication Domain Misconfiguration

**Problem: "Authorization domain mismatch" or "CORS error"**

```bash
# 1. Check configured domain in Firebase Console
# Project Settings > Authorized domains

# 2. Your localhost should be there
# - localhost
# - 127.0.0.1

# 3. Your production domain should be there
# - yourdomain.com
# - www.yourdomain.com

# 4. Verify in code:
# console.log(process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN)
# Should output: your-project.firebaseapp.com
```

### 3.4 Storage Bucket Configuration

**Problem: "Cannot read property 'name' of undefined"**

```bash
# Check storage bucket exists
# Firebase Console > Storage tab

# Correct bucket format
# your-project.appspot.com (NOT gs://your-project.appspot.com)

# Verify in code
const storage = getStorage(app);
console.log('Storage bucket:', storage.bucket); // Should not be undefined
```

---

## 4. Firestore Query Debugging

### 4.1 Collection Path Issues

**Problem: Collection not found or queries returning empty**

```typescript
// Incorrect path patterns
db.collection('Users').get(); // Wrong: Firestore is case-sensitive
db.collection('users ').get(); // Wrong: Extra space
db.collection('users').doc('user-id/subcollection').get(); // Wrong: Can't nest like this

// Correct patterns
db.collection('users').get(); // Correct: lowercase
db.collection('users').doc('user-id').get(); // Correct: two-level path
db.collection('users')
  .doc('user-id')
  .collection('orders')
  .get(); // Correct: nested collection

// Debug queries
const snapshot = await db.collection('users').limit(1).get();
console.log('Collection exists:', !snapshot.empty);
console.log('Document count:', snapshot.size);
snapshot.forEach(doc => {
  console.log('Sample doc:', doc.id, doc.data());
});
```

### 4.2 Firestore Rules Issues

**Problem: "Missing or insufficient permissions"**

```javascript
// 1. Check current Firestore rules
// Firebase Console > Firestore Database > Rules tab

// For DEVELOPMENT (allow all - UNSAFE!)
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if true;
    }
  }
}

// For PRODUCTION with authentication
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Authenticated users can only read/write their own data
    match /users/{uid} {
      allow read, write: if request.auth.uid == uid;
    }
    
    // Public read, authenticated write
    match /products/{document=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}

// Debug rule violations
// Open browser DevTools > Console
// Errors will show "Missing or insufficient permissions"
// Check: Is user authenticated? Does uid match path?
```

### 4.3 Data Type Mismatches

**Problem: "Could not find Java class" or query filters not working**

```typescript
// Incorrect: Mixing types
const snapshot = await db.collection('users')
  .where('age', '==', '25') // Age is string, but field is number
  .get();

// Correct: Type consistency
const snapshot = await db.collection('users')
  .where('age', '==', 25) // Both number
  .get();

// Debugging data types in Firestore
const doc = await db.collection('users').doc('user-id').get();
const data = doc.data();

console.log('Field types:');
Object.entries(data).forEach(([key, value]) => {
  console.log(`${key}: ${typeof value} = ${value}`);
});
```

### 4.4 Query Limitation Issues

**Problem: Query results incomplete or "FAILED_PRECONDITION"**

```typescript
// Issue 1: Querying on unindexed fields
const snapshot = await db.collection('users')
  .where('status', '==', 'active')
  .where('createdAt', '>=', new Date('2024-01-01'))
  .where('role', '==', 'admin')
  .get(); // May fail without composite index

// Fix: Create composite index
// Firebase will suggest creating index in error message
// Go to Firebase Console > Firestore > Indexes > Create index

// Issue 2: AND/OR filter complexity
// Firestore limitations:
// - Max 10 inequality filters per query
// - Only one inequality filter on different fields
// - OR queries require multiple query executions

// Issue 3: Too much data
const snapshot = await db.collection('large-collection').get(); // May timeout
// Fix: Use pagination
const snapshot = await db.collection('large-collection')
  .limit(100)
  .get();
```

---

## 5. Authentication Issues

### 5.1 Sign-In Not Working

**Problem: "Cannot sign in" or "Invalid credential"**

```typescript
import { signInWithEmailAndPassword, signInWithPopup, GoogleAuthProvider } from 'firebase/auth';
import { auth } from '@/lib/firebase';

// Debug email/password sign-in
try {
  const userCredential = await signInWithEmailAndPassword(auth, email, password);
  console.log('User signed in:', userCredential.user);
} catch (error) {
  console.error('Sign-in error:', {
    code: error.code,
    message: error.message,
    // Common codes: auth/user-not-found, auth/wrong-password, auth/invalid-email
  });
}

// Debug Google sign-in
try {
  const provider = new GoogleAuthProvider();
  const result = await signInWithPopup(auth, provider);
  console.log('User signed in with Google:', result.user);
} catch (error) {
  console.error('Google sign-in error:', error.code);
  // Common codes: auth/popup-blocked, auth/operation-not-allowed, auth/unauthorized-domain
}
```

### 5.2 CORS Issues with Authentication

**Problem: "Cross-Origin Request Blocked"**

```bash
# 1. Ensure localhost is authorized
# Firebase Console > Authentication > Settings > Authorized domains
# Add: localhost, 127.0.0.1

# 2. Ensure production domain is authorized
# Add: yourdomain.com, www.yourdomain.com

# 3. Check browser console for specific error:
# If error mentions "identitytoolkit.googleapis.com", update Google Cloud credentials
```

### 5.3 Token Issues

**Problem: "auth/invalid-api-key" or "Unauthenticated"**

```typescript
// Get current user and ID token
auth.onAuthStateChanged(async (user) => {
  if (user) {
    const idToken = await user.getIdToken();
    console.log('ID Token:', idToken); // Should be JWT format
    
    // Use token in API requests
    const response = await fetch('/api/protected-endpoint', {
      headers: {
        'Authorization': `Bearer ${idToken}`
      }
    });
  }
});

// Server-side: Verify ID token
import { adminAuth } from '@/lib/firebaseAdmin';

app.post('/api/protected', async (req, res) => {
  const token = req.headers.authorization?.split('Bearer ')[1];
  
  if (!token) {
    return res.status(401).json({ error: 'No token provided' });
  }
  
  try {
    const decodedToken = await adminAuth.verifyIdToken(token);
    console.log('User UID:', decodedToken.uid);
    // Continue with authenticated request
  } catch (error) {
    console.error('Token verification error:', error);
    return res.status(401).json({ error: 'Invalid token' });
  }
});
```

---

## 6. Package Dependencies Check

### 6.1 Required Firebase Packages

#### **For Next.js/React Dashboard:**
```json
{
  "dependencies": {
    "firebase": "^10.0.0 or higher",
    "react": "^18.0.0",
    "next": "^13.0.0 or higher"
  },
  "devDependencies": {
    "typescript": "^5.0.0",
    "@types/react": "^18.0.0",
    "@types/node": "^20.0.0"
  }
}
```

#### **For Node.js Backend:**
```json
{
  "dependencies": {
    "firebase-admin": "^12.0.0 or higher",
    "express": "^4.18.0",
    "dotenv": "^16.0.0"
  }
}
```

### 6.2 How to Check and Fix Dependencies

```bash
# 1. Check installed versions
npm list firebase firebase-admin

# 2. Verify package.json has correct versions
cat package.json | grep -A 5 '"dependencies"'

# 3. Check for version conflicts
npm ls firebase

# Expected: single version for firebase package

# 4. Update if needed
npm install firebase@latest
npm install firebase-admin@latest

# 5. Verify installation
npm ls firebase firebase-admin

# 6. Clear cache if having issues
rm -rf node_modules package-lock.json
npm install
```

### 6.3 Common Dependency Issues

| Issue | Cause | Fix |
|-------|-------|-----|
| "Cannot find module 'firebase'" | Not installed | `npm install firebase` |
| Version conflict | Different versions required | Update to compatible versions |
| Module not found: 'firebase/auth' | Old Firebase SDK | Update: `npm install firebase@latest` |
| "admin.firestore is not a function" | firebase-admin not initialized | Call `admin.initializeApp()` first |

---

## 7. Network & Connectivity Issues

### 7.1 Firestore Connection Issues

```bash
# 1. Check internet connectivity
ping google.com

# 2. Check if Firestore is reachable
curl -I https://firestore.googleapis.com

# 3. Check if Firebase services are operational
# Visit: https://status.firebase.google.com

# 4. Check browser network tab
# Open DevTools > Network > filter by 'firestore'
# Look for failed requests to firestore.googleapis.com
```

### 7.2 Debugging Network Requests

```typescript
// Add network request logging
import { connectFirestoreEmulator } from 'firebase/firestore';

// For development, use emulator
if (process.env.NODE_ENV === 'development') {
  try {
    connectFirestoreEmulator(db, 'localhost', 8080);
    console.log('Connected to Firestore emulator');
  } catch (error) {
    console.log('Already connected to emulator or emulator not running');
  }
}

// Log all Firestore requests
const originalGet = db.collection;
db.collection = function(path) {
  console.log('Firestore collection called:', path);
  return originalGet.call(this, path);
};
```

### 7.3 Timeout Issues

**Problem: "Timeout waiting for Firestore response"**

```typescript
// Add timeout handling to queries
const TIMEOUT_MS = 10000;

async function firestoreQueryWithTimeout(query, timeoutMs = TIMEOUT_MS) {
  return Promise.race([
    query.get(),
    new Promise((_, reject) =>
      setTimeout(() => reject(new Error('Firestore query timeout')), timeoutMs)
    )
  ]);
}

// Usage
try {
  const snapshot = await firestoreQueryWithTimeout(
    db.collection('users').limit(1)
  );
} catch (error) {
  if (error.message === 'Firestore query timeout') {
    console.error('Firestore request timed out after 10s');
    // Fallback: use cached data, retry, or show error to user
  }
}
```

---

## 8. Debugging Workflow

### 8.1 Step-by-Step Debugging Process

```bash
# Step 1: Check environment variables
echo "Checking environment variables..."
cat .env.local | grep FIREBASE
echo "---"

# Step 2: Check if Firebase packages are installed
echo "Checking Firebase packages..."
npm list firebase firebase-admin | grep firebase
echo "---"

# Step 3: Check browser console for errors
echo "Open browser DevTools (F12) > Console tab"
echo "Look for Firebase initialization errors"
echo "---"

# Step 4: Test Firebase initialization
echo "Creating test file: test-firebase.js"
cat > test-firebase.js << 'TESTEOF'
import { initializeApp } from 'firebase/app';

const firebaseConfig = {
  apiKey: process.env.NEXT_PUBLIC_FIREBASE_API_KEY,
  projectId: process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID,
  // ... other config
};

try {
  const app = initializeApp(firebaseConfig);
  console.log('✓ Firebase initialized successfully');
  console.log('App:', app);
} catch (error) {
  console.error('✗ Firebase initialization failed:', error.message);
}
TESTEOF

# Step 5: Run the test
node test-firebase.js

# Step 6: Check Firestore rules in Firebase Console
echo "Go to: Firebase Console > Firestore Database > Rules"
```

### 8.2 Debugging Checklist

```
[ ] Environment variables exist and are non-empty
    [ ] .env.local file exists
    [ ] All NEXT_PUBLIC_FIREBASE_* variables present
    [ ] No extra spaces or quotes around values
    
[ ] Firebase packages installed
    [ ] firebase package installed (npm list firebase)
    [ ] firebase-admin package installed (npm list firebase-admin)
    [ ] Versions compatible
    
[ ] Firebase initialization working
    [ ] initializeApp() called successfully
    [ ] getAuth(), getFirestore(), getStorage() return valid objects
    [ ] No console errors in browser DevTools
    
[ ] Firebase Console configured correctly
    [ ] Project settings match .env values
    [ ] Authorized domains include localhost and production domain
    [ ] API Key restrictions set to "All APIs"
    
[ ] Firestore configured
    [ ] Collections exist with correct names (case-sensitive)
    [ ] Security rules allow current user access
    [ ] Indexes created for complex queries
    
[ ] Authentication configured
    [ ] Sign-in method enabled (Email, Google, etc.)
    [ ] Authorized domains include localhost
    [ ] OAuth consent screen configured
    
[ ] Network connectivity
    [ ] Internet connection working
    [ ] firestore.googleapis.com is reachable
    [ ] No VPN/proxy blocking Firebase requests
```

---

## 9. Recommended Fixes

### 9.1 Quick Fix Checklist

```bash
# 1. Restart development server (most common fix)
npm run dev  # Re-run after adding .env.local

# 2. Clear cache
rm -rf .next
npm run dev

# 3. Reinstall dependencies
rm -rf node_modules package-lock.json
npm install

# 4. Check all environment variables are set
echo "API Key: $NEXT_PUBLIC_FIREBASE_API_KEY"
echo "Project ID: $NEXT_PUBLIC_FIREBASE_PROJECT_ID"
echo "Auth Domain: $NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN"

# 5. Verify Firebase console configuration
# Visit: Firebase Console > Project Settings > General
# Copy entire config object and verify in .env.local

# 6. Check Firestore rules
# Visit: Firebase Console > Firestore Database > Rules
# Set to test mode for development
```

### 9.2 Security Best Practices

```javascript
// DO NOT: Commit .env.local to git
// DO: Add to .gitignore
echo ".env.local" >> .gitignore
echo ".env" >> .gitignore

// DO: Use environment variables for sensitive data
// DO NOT: Hardcode Firebase config in code

// DO: Use separate Firebase projects for dev/staging/prod
// Project names: my-app-dev, my-app-staging, my-app-prod

// DO: Implement proper Firestore security rules
// DO NOT: Use allow read, write: if true in production

// DO: Restrict API Keys
// In Google Cloud Console > APIs & Services > Credentials
// Add application restrictions (HTTP referrer, IP address)

// DO: Enable Firebase Authentication
// Use custom claims for authorization
```

### 9.3 Production Deployment Checklist

```bash
# Before deploying to production:

[ ] All environment variables set in production environment
[ ] No hardcoded credentials in code
[ ] Firebase security rules reviewed and tightened
[ ] API keys have proper restrictions
[ ] Firestore backup enabled
[ ] Authentication methods tested
[ ] Error handling implemented for failed requests
[ ] Rate limiting configured
[ ] Monitoring and logging enabled
[ ] CORS properly configured for production domain
[ ] SSL/HTTPS enforced
```

---

## Appendix: Common Error Messages & Solutions

### Error: "Cannot read property 'getAuth' of undefined"
**Cause**: Firebase not initialized  
**Fix**: Ensure `initializeApp(firebaseConfig)` is called before accessing services

### Error: "Missing or insufficient permissions"
**Cause**: Firestore security rules denying access  
**Fix**: Update rules in Firebase Console > Firestore > Rules

### Error: "Quota exceeded for quota metric 'datastore_reads_per_doc'"
**Cause**: Too many reads in short period  
**Fix**: Implement caching, reduce query frequency, or upgrade plan

### Error: "auth/invalid-continue-uri"
**Cause**: Continue URI not in authorized domains list  
**Fix**: Add domain to Firebase Console > Authentication > Authorized domains

### Error: "Unindexed field"
**Cause**: Query uses unindexed field combination  
**Fix**: Click link in error message to create index

### Error: "PERMISSION_DENIED"
**Cause**: API permission not enabled or auth credentials invalid  
**Fix**: Enable required APIs in Google Cloud Console

---

## Related Documentation

- [Firebase Documentation](https://firebase.google.com/docs)
- [Firestore Security Rules](https://firebase.google.com/docs/firestore/security/start)
- [Firebase Admin SDK](https://firebase.google.com/docs/admin/setup)
- [Next.js Environment Variables](https://nextjs.org/docs/basic-features/environment-variables)

---

**Last Updated**: December 7, 2025  
**Status**: Ready for BoxSyncDashboard implementation

