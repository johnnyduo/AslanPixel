import * as admin from "firebase-admin";

// Initialize once — guard for emulator multi-import
if (!admin.apps.length) {
  admin.initializeApp();
}

export const db = admin.firestore();
export const auth = admin.auth();
export const messaging = admin.messaging();
export { admin };
