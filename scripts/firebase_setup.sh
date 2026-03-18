#!/bin/bash
# Aslan Pixel — Firebase Project Setup Script
# Account: admin@aslanwealth.com
# Run after: firebase login (as admin@aslanwealth.com)

set -e

PROJECT_ID="aslan-pixel"
REGION="asia-southeast1"
ACCOUNT="admin@aslanwealth.com"

echo "=== Aslan Pixel Firebase Setup ==="
echo "Project: $PROJECT_ID"
echo "Region: $REGION"
echo "Account: $ACCOUNT"
echo ""

# 1. Set active project
firebase use $PROJECT_ID --account $ACCOUNT 2>/dev/null || \
  firebase projects:create $PROJECT_ID --display-name "Aslan Pixel" --account $ACCOUNT

echo "✓ Project set: $PROJECT_ID"

# 2. Deploy Firestore rules + indexes
echo "Deploying Firestore rules and indexes..."
firebase deploy --only firestore:rules,firestore:indexes \
  --project $PROJECT_ID --account $ACCOUNT
echo "✓ Firestore rules deployed"

# 3. Deploy Storage rules
echo "Deploying Storage rules..."
firebase deploy --only storage \
  --project $PROJECT_ID --account $ACCOUNT
echo "✓ Storage rules deployed"

# 4. Set Remote Config defaults via Firebase CLI (if rc template exists)
if [ -f "remoteconfig.template.json" ]; then
  firebase remoteconfig:set remoteconfig.template.json \
    --project $PROJECT_ID --account $ACCOUNT
  echo "✓ Remote Config defaults set"
fi

echo ""
echo "=== Manual steps required (Firebase Console) ==="
echo "1. Enable Authentication providers:"
echo "   - Google Sign-In"
echo "   - Sign in with Apple"
echo "   - Email/Password"
echo ""
echo "2. Enable services (if not already):"
echo "   - Firestore Database (Native mode, $REGION)"
echo "   - Firebase Storage ($REGION)"
echo "   - Firebase Messaging (FCM)"
echo "   - Firebase Crashlytics"
echo "   - Firebase Analytics"
echo "   - Firebase Remote Config"
echo "   - App Check (PlayIntegrity + DeviceCheck)"
echo ""
echo "3. Cloud Functions (deploy after writing functions/):"
echo "   firebase deploy --only functions --project $PROJECT_ID"
echo ""
echo "4. Secret Manager (GCP Console > Secret Manager):"
echo "   - broker-encryption-key  (AES-256 random bytes)"
echo "   - gemini-api-key          (Google AI Studio)"
echo "   - claude-api-key          (Anthropic Console)"
echo "   - price-oracle-api-key    (CoinGecko)"
echo ""
echo "5. Generate firebase_options.dart:"
echo "   flutterfire configure --project $PROJECT_ID"
echo ""
echo "=== Setup complete ==="
