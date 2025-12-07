#!/bin/bash

# Firebase Configuration Diagnostic Script
# Purpose: Automated diagnosis of Firebase configuration issues
# Usage: ./FIREBASE_DIAGNOSTIC.sh

echo "=========================================="
echo "Firebase Configuration Diagnostic Tool"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counter for issues
ISSUES=0

# Function to print success
success() {
  echo -e "${GREEN}✓${NC} $1"
}

# Function to print error
error() {
  echo -e "${RED}✗${NC} $1"
  ((ISSUES++))
}

# Function to print warning
warning() {
  echo -e "${YELLOW}⚠${NC} $1"
}

# Check 1: Environment Variables
echo "1. Checking Environment Variables..."
echo "======================================"

if [ -f ".env.local" ]; then
  success ".env.local file exists"
else
  error ".env.local file not found"
fi

if [ -f ".env.example" ]; then
  success ".env.example file exists"
else
  warning ".env.example file not found (recommended for documentation)"
fi

# Check for required env vars
REQUIRED_VARS=(
  "NEXT_PUBLIC_FIREBASE_API_KEY"
  "NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN"
  "NEXT_PUBLIC_FIREBASE_PROJECT_ID"
  "NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET"
)

for var in "${REQUIRED_VARS[@]}"; do
  if grep -q "^${var}=" .env.local 2>/dev/null; then
    value=$(grep "^${var}=" .env.local | cut -d'=' -f2 | head -c 20)...
    success "$var is set"
  else
    error "$var is missing"
  fi
done

echo ""

# Check 2: Package.json and Dependencies
echo "2. Checking Dependencies..."
echo "============================"

if [ -f "package.json" ]; then
  success "package.json exists"
  
  if grep -q '"firebase"' package.json; then
    FIREBASE_VERSION=$(grep '"firebase"' package.json | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+')
    success "firebase package found (version: $FIREBASE_VERSION)"
  else
    error "firebase package not found in package.json"
  fi
  
  if grep -q '"firebase-admin"' package.json; then
    success "firebase-admin package found"
  else
    warning "firebase-admin package not found (required for backend)"
  fi
  
  if grep -q '"next"' package.json; then
    NEXT_VERSION=$(grep '"next"' package.json | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+')
    success "next.js package found (version: $NEXT_VERSION)"
  else
    error "next.js package not found"
  fi
else
  error "package.json not found"
fi

# Check 3: Node modules
echo ""
echo "3. Checking Installed Node Modules..."
echo "======================================"

if [ -d "node_modules" ]; then
  success "node_modules directory exists"
  
  if [ -d "node_modules/firebase" ]; then
    success "firebase module installed"
  else
    error "firebase module not installed (run: npm install)"
  fi
  
  if [ -d "node_modules/firebase-admin" ]; then
    success "firebase-admin module installed"
  else
    error "firebase-admin module not installed (run: npm install)"
  fi
else
  warning "node_modules not installed (run: npm install)"
fi

# Check 4: Firebase Configuration Files
echo ""
echo "4. Checking Firebase Configuration Files..."
echo "============================================"

if [ -f "lib/firebase.ts" ] || [ -f "lib/firebase.js" ]; then
  success "Firebase client config file exists"
else
  warning "Firebase client config file not found (should be at lib/firebase.ts)"
fi

if [ -f "lib/firebaseAdmin.ts" ] || [ -f "lib/firebaseAdmin.js" ]; then
  success "Firebase admin config file exists"
else
  warning "Firebase admin config file not found (should be at lib/firebaseAdmin.ts)"
fi

# Check 5: Git ignore
echo ""
echo "5. Checking Git Configuration..."
echo "================================="

if [ -f ".gitignore" ]; then
  if grep -q ".env.local" .gitignore || grep -q ".env" .gitignore; then
    success ".env files are ignored in git"
  else
    error ".env files are NOT ignored in git (add to .gitignore!)"
  fi
else
  warning ".gitignore file not found"
fi

# Check 6: Network connectivity
echo ""
echo "6. Checking Network Connectivity..."
echo "===================================="

if command -v curl &> /dev/null; then
  if curl -s -o /dev/null -w "%{http_code}" https://firestore.googleapis.com > /dev/null 2>&1; then
    success "Can reach firestore.googleapis.com"
  else
    error "Cannot reach firestore.googleapis.com"
  fi
else
  warning "curl not available (skipping network test)"
fi

# Check 7: Port availability (for emulator)
echo ""
echo "7. Checking Firebase Emulator Ports..."
echo "======================================"

if command -v lsof &> /dev/null; then
  if ! lsof -Pi :8080 -sTCP:LISTEN -t >/dev/null 2>&1; then
    warning "Port 8080 (Firestore emulator) not in use"
  else
    success "Port 8080 is in use (emulator may be running)"
  fi
  
  if ! lsof -Pi :9099 -sTCP:LISTEN -t >/dev/null 2>&1; then
    warning "Port 9099 (Auth emulator) not in use"
  else
    success "Port 9099 is in use (emulator may be running)"
  fi
else
  warning "lsof not available (skipping port check)"
fi

# Summary
echo ""
echo "=========================================="
echo "Diagnostic Summary"
echo "=========================================="

if [ $ISSUES -eq 0 ]; then
  echo -e "${GREEN}No critical issues found!${NC}"
  echo ""
  echo "Next steps:"
  echo "1. Verify Firebase Console configuration"
  echo "2. Test authentication flow"
  echo "3. Test Firestore queries"
else
  echo -e "${RED}Found $ISSUES critical issues${NC}"
  echo ""
  echo "Please fix the errors listed above before proceeding."
fi

echo ""
echo "For more detailed debugging, see: DEBUG_FIREBASE.md"
echo ""

