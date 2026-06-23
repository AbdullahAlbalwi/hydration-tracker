import { initializeApp } from "firebase-admin/app";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

// Initialize the Admin SDK exactly once. Importing `db` from here guarantees
// initialization happens before any function touches Firestore.
initializeApp();

export const db = getFirestore();
export { FieldValue };
