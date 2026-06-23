import * as admin from "firebase-admin";

// Initialize the Admin SDK exactly once. Importing `db` from here guarantees
// initialization happens before any function touches Firestore.
admin.initializeApp();

export const db = admin.firestore();
export const FieldValue = admin.firestore.FieldValue;
