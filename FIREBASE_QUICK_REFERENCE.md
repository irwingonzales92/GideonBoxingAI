# Firebase Configuration - Quick Reference Guide

**Use this checklist when setting up BoxSyncDashboard with Firebase**

---

## Pre-Setup Checklist

- [ ] Firebase project created at console.firebase.google.com
- [ ] Google Cloud project linked
- [ ] Billing enabled (even for testing)
- [ ] Service account created with admin privileges

---

## Environment Variables Checklist

### Client-Side (.env.local)
```
[ ] NEXT_PUBLIC_FIREBASE_API_KEY=<paste-from-firebase-console>
[ ] NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN=<project>.firebaseapp.com
[ ] NEXT_PUBLIC_FIREBASE_PROJECT_ID=<project-id>
[ ] NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET=<project>.appspot.com
[ ] NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID=<sender-id>
[ ] NEXT_PUBLIC_FIREBASE_APP_ID=<app-id>
[ ] NEXT_PUBLIC_FIREBASE_MEASUREMENT_ID=<measurement-id> (optional)
```

### Server-Side (.env.local - keep in .gitignore)
```
[ ] FIREBASE_PROJECT_ID=<project-id>
[ ] FIREBASE_PRIVATE_KEY=<service-account-private-key>
[ ] FIREBASE_CLIENT_EMAIL=<service-account-email>
[ ] FIREBASE_DATABASE_URL=https://<project>.firebaseio.com
[ ] FIREBASE_STORAGE_BUCKET=<project>.appspot.com
```

---

## Installation Checklist

```bash
[ ] npm install firebase
[ ] npm install firebase-admin
[ ] npm install typescript @types/node @types/react
```

---

## Configuration Files Checklist

### Client-Side
- [ ] Create `lib/firebase.ts` with initialization code
- [ ] Create `lib/auth.ts` for authentication service
- [ ] Create `hooks/useAuth.ts` for React hooks
- [ ] Create types for Firestore documents

### Server-Side
- [ ] Create `lib/firebaseAdmin.ts` with admin SDK
- [ ] Create `pages/api/protected-route.ts` example
- [ ] Create `lib/firestore.ts` for database operations

---

## Firebase Console Configuration

### Authentication
- [ ] Enable Email/Password sign-in
- [ ] Enable Google OAuth (if using)
- [ ] Add authorized redirect URIs
- [ ] Add authorized domains:
  - [ ] `localhost`
  - [ ] `127.0.0.1`
  - [ ] Production domain (when ready)

### Firestore Database
- [ ] Create database (Start in test mode for dev)
- [ ] Create required collections:
  - [ ] `users`
  - [ ] `boxingSyncData`
  - [ ] `workouts`
  - [ ] Add other collections as needed

### Security Rules
- [ ] Review and update security rules (test mode is insecure!)
- [ ] Implement user-scoped access
- [ ] Test rules with simulator

### Cloud Storage
- [ ] Create storage bucket
- [ ] Set security rules for file uploads

### API Keys
- [ ] Restrict API Key to required APIs
- [ ] Add HTTP referrer restrictions (production)
- [ ] Add IP address restrictions (backend services)

---

## Testing Checklist

```bash
[ ] npm run dev              # Start development server
[ ] Check browser console    # Look for Firebase errors
[ ] Run diagnostic script    # ./FIREBASE_DIAGNOSTIC.sh
[ ] Test sign-up flow       # Can you create a new user?
[ ] Test sign-in flow       # Can you log in?
[ ] Test data read          # Can you load data from Firestore?
[ ] Test data write         # Can you save data to Firestore?
[ ] Test file upload        # Can you upload files to Storage?
```

---

## Common Issues & Quick Fixes

### Issue: "Cannot find module 'firebase'"
**Fix**: `npm install firebase`

### Issue: "config.apiKey is undefined"
**Fix**: 
1. Check `.env.local` exists
2. Check variables start with `NEXT_PUBLIC_`
3. Restart dev server: `npm run dev`

### Issue: "Missing or insufficient permissions"
**Fix**:
1. Open Firebase Console > Firestore > Rules
2. Check if user is authenticated
3. Check if rule allows user's UID
4. Update rules if needed

### Issue: "auth/operation-not-allowed"
**Fix**:
1. Go to Firebase Console > Authentication > Sign-in methods
2. Enable the sign-in method you're trying to use
3. Try again

### Issue: "Cannot reach firestore.googleapis.com"
**Fix**:
1. Check internet connection
2. Check if VPN/firewall is blocking
3. Check Firebase status page

### Issue: "Popup was blocked"
**Fix**:
1. Allow popups for localhost in browser
2. Use redirect method instead of popup

---

## Security Checklist (Before Production)

- [ ] Remove `.env.local` from version control
- [ ] Add `.env.local` to `.gitignore`
- [ ] Update Firebase security rules (remove test mode)
- [ ] Restrict API Keys
- [ ] Use separate Firebase project for production
- [ ] Enable Firestore backups
- [ ] Implement input validation
- [ ] Enable HTTPS
- [ ] Set up monitoring and logging
- [ ] Test all authentication flows
- [ ] Load test Firestore queries

---

## Debugging Commands

```bash
# Check environment variables
grep NEXT_PUBLIC_FIREBASE .env.local

# Check if Firebase is installed
npm list firebase firebase-admin

# Check for TypeScript errors
npx tsc --noEmit

# Test API endpoint
curl -X GET http://localhost:3000/api/protected \
  -H "Authorization: Bearer YOUR_ID_TOKEN"

# Check Firestore rules syntax
# In Firebase Console > Firestore > Rules > Simulator tab
```

---

## Documentation Reference

| Document | Purpose |
|----------|---------|
| `DEBUG_FIREBASE.md` | Comprehensive troubleshooting guide |
| `FIREBASE_SETUP_TEMPLATE.md` | Code templates and examples |
| `FIREBASE_DIAGNOSTIC.sh` | Automated diagnostic script |
| `FIREBASE_INVESTIGATION_REPORT.md` | Full investigation report |
| This file | Quick reference guide |

---

## Contact & Support

For issues not covered here:
1. Check `DEBUG_FIREBASE.md` (has 50+ common issues)
2. Check `FIREBASE_SETUP_TEMPLATE.md` (has code examples)
3. Run `./FIREBASE_DIAGNOSTIC.sh` (automated checks)
4. Visit [Firebase Documentation](https://firebase.google.com/docs)

---

**Last Updated**: December 7, 2025  
**Maintenance**: Update as you encounter new issues

