"use client";

import React, { useState, useEffect } from "react";
import { onAuthStateChanged, User } from "firebase/auth";
import { auth } from "../../lib/firebase-client";
import { LoginView } from "../../components/login-view";
import { AppShell } from "../../components/app-shell";
import "./app-styles.css";

export default function AppPage() {
  const [user, setUser] = useState<User | null>(null);
  const [checkingAuth, setCheckingAuth] = useState(true);

  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, (currentUser) => {
      setUser(currentUser);
      setCheckingAuth(false);
    });
    return () => unsubscribe();
  }, []);

  if (checkingAuth) {
    return (
      <div style={{ display: "flex", justifyContent: "center", alignItems: "center", height: "100vh", background: "var(--page)", fontWeight: 800, color: "var(--muted)" }}>
        Authenticating session...
      </div>
    );
  }

  if (!user) {
    return <LoginView />;
  }

  return <AppShell />;
}
