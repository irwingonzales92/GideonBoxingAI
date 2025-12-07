# Firebase Setup Template for BoxSyncDashboard

This document provides ready-to-use templates for setting up Firebase in the BoxSyncDashboard.

---

## 1. Environment Variables Template

Create `.env.local` file in your project root:

```env
# Firebase Client Configuration (from Firebase Console > Project Settings)
NEXT_PUBLIC_FIREBASE_API_KEY=AIzaSyD...
NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN=boxsync-dashboard.firebaseapp.com
NEXT_PUBLIC_FIREBASE_PROJECT_ID=boxsync-dashboard
NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET=boxsync-dashboard.appspot.com
NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID=123456789
NEXT_PUBLIC_FIREBASE_APP_ID=1:123456789:web:abcdef...
NEXT_PUBLIC_FIREBASE_MEASUREMENT_ID=G-XXXXXXXXX

# Firebase Admin Configuration (server-side only)
# Keep this file in .gitignore and NEVER commit it
FIREBASE_PROJECT_ID=boxsync-dashboard
FIREBASE_PRIVATE_KEY=-----BEGIN PRIVATE KEY-----\nMIIE...==\n-----END PRIVATE KEY-----
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@boxsync-dashboard.iam.gserviceaccount.com
FIREBASE_DATABASE_URL=https://boxsync-dashboard.firebaseio.com
FIREBASE_STORAGE_BUCKET=boxsync-dashboard.appspot.com

# Application Configuration
NODE_ENV=development
NEXT_PUBLIC_APP_NAME=BoxSync Dashboard
```

---

## 2. Client-Side Firebase Configuration

Create `lib/firebase.ts`:

```typescript
import { initializeApp } from 'firebase/app';
import { getAuth, connectAuthEmulator } from 'firebase/auth';
import { getFirestore, connectFirestoreEmulator } from 'firebase/firestore';
import { getStorage, connectStorageEmulator } from 'firebase/storage';

const firebaseConfig = {
  apiKey: process.env.NEXT_PUBLIC_FIREBASE_API_KEY || '',
  authDomain: process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN || '',
  projectId: process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID || '',
  storageBucket: process.env.NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET || '',
  messagingSenderId: process.env.NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID || '',
  appId: process.env.NEXT_PUBLIC_FIREBASE_APP_ID || '',
  measurementId: process.env.NEXT_PUBLIC_FIREBASE_MEASUREMENT_ID || '',
};

// Validate configuration
const validateFirebaseConfig = (config: typeof firebaseConfig) => {
  const requiredFields = ['apiKey', 'authDomain', 'projectId', 'storageBucket'];
  const missingFields = requiredFields.filter((field) => !config[field as keyof typeof config]);
  
  if (missingFields.length > 0) {
    console.error('Missing Firebase configuration:', missingFields);
    throw new Error(`Firebase configuration incomplete. Missing: ${missingFields.join(', ')}`);
  }
};

try {
  validateFirebaseConfig(firebaseConfig);
} catch (error) {
  console.error('Firebase configuration error:', error);
}

// Initialize Firebase
const app = initializeApp(firebaseConfig);

// Initialize Firebase services
export const auth = getAuth(app);
export const db = getFirestore(app);
export const storage = getStorage(app);

// Connect to emulators in development
if (process.env.NODE_ENV === 'development') {
  if (typeof window !== 'undefined') {
    try {
      // Check if emulator is running before connecting
      connectAuthEmulator(auth, 'http://127.0.0.1:9099', { disableWarnings: true });
      connectFirestoreEmulator(db, '127.0.0.1', 8080);
      connectStorageEmulator(storage, '127.0.0.1', 9199);
      console.log('Connected to Firebase emulators');
    } catch (error) {
      // Emulator may not be running, continue with production Firebase
      console.log('Firebase emulators not available, using production Firebase');
    }
  }
}

export default app;
```

---

## 3. Server-Side Firebase Admin Configuration

Create `lib/firebaseAdmin.ts`:

```typescript
import * as admin from 'firebase-admin';

// Initialize Firebase Admin SDK
const initializeFirebaseAdmin = () => {
  if (admin.apps.length) {
    return admin.app();
  }

  // Verify required environment variables
  const requiredEnvVars = [
    'FIREBASE_PROJECT_ID',
    'FIREBASE_PRIVATE_KEY',
    'FIREBASE_CLIENT_EMAIL',
  ];

  const missingVars = requiredEnvVars.filter((varName) => !process.env[varName]);
  if (missingVars.length > 0) {
    throw new Error(`Missing environment variables: ${missingVars.join(', ')}`);
  }

  const serviceAccountConfig = {
    projectId: process.env.FIREBASE_PROJECT_ID!,
    privateKey: process.env.FIREBASE_PRIVATE_KEY!.replace(/\\n/g, '\n'),
    clientEmail: process.env.FIREBASE_CLIENT_EMAIL!,
  };

  return admin.initializeApp({
    credential: admin.credential.cert(serviceAccountConfig),
    databaseURL: process.env.FIREBASE_DATABASE_URL,
    storageBucket: process.env.FIREBASE_STORAGE_BUCKET,
  });
};

try {
  initializeFirebaseAdmin();
} catch (error) {
  console.error('Failed to initialize Firebase Admin SDK:', error);
  throw error;
}

export const adminAuth = admin.auth();
export const adminDb = admin.firestore();
export const adminStorage = admin.storage();

export default admin;
```

---

## 4. Authentication Setup

### 4.1 Email/Password Authentication

Create `lib/auth.ts`:

```typescript
import {
  createUserWithEmailAndPassword,
  signInWithEmailAndPassword,
  signOut,
  onAuthStateChanged,
  User,
  Auth,
} from 'firebase/auth';
import { auth } from './firebase';

export const authService = {
  async register(email: string, password: string): Promise<User> {
    try {
      const result = await createUserWithEmailAndPassword(auth, email, password);
      console.log('User registered:', result.user.uid);
      return result.user;
    } catch (error: any) {
      console.error('Registration error:', error.code);
      throw this.handleAuthError(error);
    }
  },

  async login(email: string, password: string): Promise<User> {
    try {
      const result = await signInWithEmailAndPassword(auth, email, password);
      console.log('User logged in:', result.user.uid);
      return result.user;
    } catch (error: any) {
      console.error('Login error:', error.code);
      throw this.handleAuthError(error);
    }
  },

  async logout(): Promise<void> {
    try {
      await signOut(auth);
      console.log('User logged out');
    } catch (error: any) {
      console.error('Logout error:', error.code);
      throw error;
    }
  },

  onAuthStateChanged(callback: (user: User | null) => void) {
    return onAuthStateChanged(auth, callback);
  },

  private handleAuthError(error: any): Error {
    const errorMessages: Record<string, string> = {
      'auth/email-already-in-use': 'Email is already registered',
      'auth/invalid-email': 'Invalid email address',
      'auth/weak-password': 'Password is too weak',
      'auth/user-not-found': 'User not found',
      'auth/wrong-password': 'Incorrect password',
      'auth/operation-not-allowed': 'Operation not allowed',
    };

    const message = errorMessages[error.code] || error.message;
    return new Error(message);
  },
};
```

### 4.2 Google OAuth Authentication

Create `lib/googleAuth.ts`:

```typescript
import { signInWithPopup, GoogleAuthProvider } from 'firebase/auth';
import { auth } from './firebase';

const googleProvider = new GoogleAuthProvider();

export const googleAuthService = {
  async signInWithGoogle() {
    try {
      const result = await signInWithPopup(auth, googleProvider);
      console.log('User signed in with Google:', result.user.uid);
      return result.user;
    } catch (error: any) {
      console.error('Google sign-in error:', error.code);
      
      if (error.code === 'auth/popup-blocked') {
        throw new Error('Sign-in popup was blocked. Please allow popups for this site.');
      } else if (error.code === 'auth/operation-not-allowed') {
        throw new Error('Google Sign-In is not enabled in Firebase Console');
      } else if (error.code === 'auth/unauthorized-domain') {
        throw new Error('Domain not authorized for Google Sign-In');
      }
      
      throw error;
    }
  },
};
```

---

## 5. Firestore Database Setup

### 5.1 Database Schema & Collections

```typescript
// types/database.ts

export interface User {
  uid: string;
  email: string;
  name: string;
  photoUrl?: string;
  role: 'admin' | 'trainer' | 'member';
  createdAt: Date;
  updatedAt: Date;
}

export interface BoxingSyncData {
  id: string;
  memberId: string;
  timestamp: Date;
  // Sync data from boxing analysis
  punchCount: number;
  accuracyScore: number;
  techniqueScore: number;
  metadata: Record<string, any>;
}

export interface Workout {
  id: string;
  memberId: string;
  name: string;
  description: string;
  exercises: Exercise[];
  createdAt: Date;
  updatedAt: Date;
}

export interface Exercise {
  id: string;
  name: string;
  sets: number;
  reps: number;
  duration?: number;
}
```

### 5.2 Firestore Service

Create `lib/firestore.ts`:

```typescript
import {
  collection,
  doc,
  getDoc,
  getDocs,
  setDoc,
  updateDoc,
  deleteDoc,
  query,
  where,
  Query,
  DocumentData,
} from 'firebase/firestore';
import { db } from './firebase';
import { User, BoxingSyncData, Workout } from '@/types/database';

export const firestoreService = {
  // Users Collection
  async getUser(uid: string): Promise<User | null> {
    try {
      const docRef = doc(db, 'users', uid);
      const docSnap = await getDoc(docRef);
      return docSnap.exists() ? (docSnap.data() as User) : null;
    } catch (error) {
      console.error('Error fetching user:', error);
      throw error;
    }
  },

  async createUser(uid: string, userData: Omit<User, 'uid'>): Promise<void> {
    try {
      const docRef = doc(db, 'users', uid);
      await setDoc(docRef, { uid, ...userData });
    } catch (error) {
      console.error('Error creating user:', error);
      throw error;
    }
  },

  async updateUser(uid: string, updates: Partial<User>): Promise<void> {
    try {
      const docRef = doc(db, 'users', uid);
      await updateDoc(docRef, updates);
    } catch (error) {
      console.error('Error updating user:', error);
      throw error;
    }
  },

  // Boxing Sync Data Collection
  async getBoxingSyncData(memberId: string, limit: number = 100): Promise<BoxingSyncData[]> {
    try {
      const q = query(
        collection(db, 'boxingSyncData'),
        where('memberId', '==', memberId)
      );
      const querySnapshot = await getDocs(q);
      return querySnapshot.docs.map((doc) => doc.data() as BoxingSyncData);
    } catch (error) {
      console.error('Error fetching boxing sync data:', error);
      throw error;
    }
  },

  async addBoxingSyncData(data: Omit<BoxingSyncData, 'id'>): Promise<string> {
    try {
      const docRef = doc(collection(db, 'boxingSyncData'));
      await setDoc(docRef, {
        ...data,
        createdAt: new Date(),
      });
      return docRef.id;
    } catch (error) {
      console.error('Error adding boxing sync data:', error);
      throw error;
    }
  },

  // Workouts Collection
  async getWorkouts(memberId: string): Promise<Workout[]> {
    try {
      const q = query(
        collection(db, 'workouts'),
        where('memberId', '==', memberId)
      );
      const querySnapshot = await getDocs(q);
      return querySnapshot.docs.map((doc) => doc.data() as Workout);
    } catch (error) {
      console.error('Error fetching workouts:', error);
      throw error;
    }
  },

  async createWorkout(workout: Omit<Workout, 'id'>): Promise<string> {
    try {
      const docRef = doc(collection(db, 'workouts'));
      await setDoc(docRef, workout);
      return docRef.id;
    } catch (error) {
      console.error('Error creating workout:', error);
      throw error;
    }
  },
};
```

---

## 6. Firestore Security Rules

Create in Firebase Console > Firestore > Rules:

```javascript
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    
    // Allow users to read/write their own profile
    match /users/{uid} {
      allow read, write: if request.auth.uid == uid;
    }
    
    // Allow users to read/write their own boxing sync data
    match /boxingSyncData/{document=**} {
      allow read, write: if request.auth != null && 
                            request.resource.data.memberId == request.auth.uid;
    }
    
    // Allow users to read/write their own workouts
    match /workouts/{document=**} {
      allow read, write: if request.auth != null && 
                            request.resource.data.memberId == request.auth.uid;
    }
    
    // Default: deny all other access
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

---

## 7. Cloud Storage Setup

Create `lib/storage.ts`:

```typescript
import {
  ref,
  uploadBytes,
  deleteObject,
  getDownloadURL,
} from 'firebase/storage';
import { storage } from './firebase';

export const storageService = {
  async uploadFile(
    path: string,
    file: File,
    metadata?: Record<string, string>
  ): Promise<string> {
    try {
      const fileRef = ref(storage, path);
      await uploadBytes(fileRef, file, { customMetadata: metadata });
      const downloadUrl = await getDownloadURL(fileRef);
      return downloadUrl;
    } catch (error) {
      console.error('Error uploading file:', error);
      throw error;
    }
  },

  async deleteFile(path: string): Promise<void> {
    try {
      const fileRef = ref(storage, path);
      await deleteObject(fileRef);
    } catch (error) {
      console.error('Error deleting file:', error);
      throw error;
    }
  },

  async getDownloadUrl(path: string): Promise<string> {
    try {
      const fileRef = ref(storage, path);
      return await getDownloadURL(fileRef);
    } catch (error) {
      console.error('Error getting download URL:', error);
      throw error;
    }
  },
};
```

---

## 8. Next.js API Route with Firebase Admin

Create `pages/api/protected.ts`:

```typescript
import { NextApiRequest, NextApiResponse } from 'next';
import { adminAuth } from '@/lib/firebaseAdmin';

export default async function handler(
  req: NextApiRequest,
  res: NextApiResponse
) {
  try {
    // Extract token from Authorization header
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ error: 'Missing or invalid authorization header' });
    }

    const token = authHeader.substring('Bearer '.length);

    // Verify the ID token
    const decodedToken = await adminAuth.verifyIdToken(token);
    const uid = decodedToken.uid;

    // Your protected endpoint logic here
    if (req.method === 'GET') {
      return res.status(200).json({
        message: 'Success',
        uid,
      });
    }

    return res.status(405).json({ error: 'Method not allowed' });
  } catch (error: any) {
    console.error('Authentication error:', error);
    return res.status(401).json({ error: 'Unauthorized' });
  }
}
```

---

## 9. Hooks for React Components

Create `hooks/useFirebase.ts`:

```typescript
import { useEffect, useState } from 'react';
import { User } from 'firebase/auth';
import { authService } from '@/lib/auth';
import { auth } from '@/lib/firebase';

export const useAuth = () => {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    const unsubscribe = authService.onAuthStateChanged((currentUser) => {
      setUser(currentUser);
      setLoading(false);
    });

    return () => unsubscribe();
  }, []);

  return { user, loading, error };
};

export const useAuthToken = () => {
  const [token, setToken] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const unsubscribe = authService.onAuthStateChanged(async (user) => {
      if (user) {
        const idToken = await user.getIdToken();
        setToken(idToken);
      } else {
        setToken(null);
      }
      setLoading(false);
    });

    return () => unsubscribe();
  }, []);

  return { token, loading };
};
```

---

## 10. Error Handling

Create `lib/errorHandler.ts`:

```typescript
export class FirebaseError extends Error {
  constructor(
    public code: string,
    public message: string,
    public originalError?: Error
  ) {
    super(message);
  }
}

export const handleFirebaseError = (error: any): FirebaseError => {
  const errorMap: Record<string, string> = {
    'auth/email-already-in-use': 'This email is already registered',
    'auth/invalid-email': 'Please enter a valid email address',
    'auth/weak-password': 'Password must be at least 6 characters',
    'auth/user-not-found': 'No account found with this email',
    'auth/wrong-password': 'Incorrect password',
    'auth/operation-not-allowed': 'This operation is not allowed',
    'firestore/permission-denied': 'You do not have permission to access this data',
    'storage/object-not-found': 'File not found',
    'storage/unauthorized': 'You do not have permission to access this file',
  };

  const message = errorMap[error.code] || error.message || 'An unexpected error occurred';

  return new FirebaseError(error.code, message, error);
};
```

---

## Deployment Checklist

- [ ] Environment variables set in production
- [ ] Firebase security rules reviewed and tightened
- [ ] API keys restricted (HTTP referrer, IP address)
- [ ] Firestore backups enabled
- [ ] Emulators disabled in production
- [ ] Error handling implemented
- [ ] Logging configured
- [ ] Rate limiting configured
- [ ] CORS properly set

---

**Last Updated**: December 7, 2025

