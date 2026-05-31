import { initializeApp, getApps, getApp } from "firebase/app";
import { getAuth } from "firebase/auth";
import { getFirestore } from "firebase/firestore";
import { getFunctions } from "firebase/functions";

const firebaseConfig = {
  apiKey: "AIzaSyBb2-2SaQc_hcusH0gMWW-L0IJ9T8tSGjk",
  authDomain: "logcal-ai.firebaseapp.com",
  projectId: "logcal-ai",
  storageBucket: "logcal-ai.firebasestorage.app",
  messagingSenderId: "1023141890322",
  appId: "1:1023141890322:web:1ece6356766edf8503cbcb"
};

const app = getApps().length === 0 ? initializeApp(firebaseConfig) : getApp();

export const auth = getAuth(app);
export const db = getFirestore(app);
export const functions = getFunctions(app, "asia-southeast1");
