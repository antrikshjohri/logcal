"use client";

import React, { useState, useEffect } from "react";
import { signInWithPopup, GoogleAuthProvider, signInAnonymously } from "firebase/auth";
import { auth } from "../lib/firebase-client";
import { LogIn, Mic, ArrowDown } from "lucide-react";

interface LoginViewProps {
  onSuccess?: () => void;
}

const demoMeals = [
  { text: "One bowl of grilled chicken salad and garlic bread", calories: 520 },
  { text: "A large burrito bowl with guacamole", calories: 620 },
  { text: "Butter chicken with 1 naan and rice", calories: 680 },
  { text: "Salmon teriyaki and rice", calories: 580 },
  { text: "One bowl of caesar salad with grilled chicken", calories: 450 },
  { text: "Two slices of margherita pizza", calories: 290 },
  { text: "One plate of dal makhani with roti", calories: 480 },
  { text: "Two slices of avocado toast with poached eggs", calories: 420 },
  { text: "1 bowl Fish and chips", calories: 650 },
  { text: "One plate of pad thai with vegetables", calories: 520 }
];

export function LoginView({ onSuccess }: LoginViewProps) {
  const [currentMealIndex, setCurrentMealIndex] = useState(0);
  const [showPhase, setShowPhase] = useState<"text" | "arrow" | "calories" | "fade">("text");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Animate the meal logging sequence (text -> arrow -> calories -> fade -> next)
  useEffect(() => {
    let active = true;
    const runAnimation = async () => {
      while (active) {
        if (!active) break;
        setShowPhase("text");
        await new Promise((resolve) => setTimeout(resolve, 1500));

        if (!active) break;
        setShowPhase("arrow");
        await new Promise((resolve) => setTimeout(resolve, 800));

        if (!active) break;
        setShowPhase("calories");
        await new Promise((resolve) => setTimeout(resolve, 2500));

        if (!active) break;
        setShowPhase("fade");
        await new Promise((resolve) => setTimeout(resolve, 600));

        if (active) {
          setCurrentMealIndex((prev) => (prev + 1) % demoMeals.length);
        }
      }
    };
    runAnimation();

    return () => {
      active = false;
    };
  }, []);

  const handleGoogleSignIn = async () => {
    setLoading(true);
    setError(null);
    const provider = new GoogleAuthProvider();
    try {
      await signInWithPopup(auth, provider);
      onSuccess?.();
    } catch (err: any) {
      console.error("Error signing in with Google:", err);
      // Suppress popup-closed errors
      if (err.code !== "auth/popup-closed-by-user") {
        setError(err.message || "Failed to sign in with Google.");
      }
    } finally {
      setLoading(false);
    }
  };

  const handleGuestSignIn = async () => {
    setLoading(true);
    setError(null);
    try {
      await signInAnonymously(auth);
      onSuccess?.();
    } catch (err: any) {
      console.error("Error signing in anonymously:", err);
      setError(err.message || "Failed to continue as guest.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="login-container">
      <div className="glass-card login-card" style={{ position: "relative" }}>
        <a
          href="/"
          style={{
            position: "absolute",
            top: "20px",
            left: "24px",
            color: "var(--muted)",
            fontSize: "14px",
            fontWeight: 800,
            textDecoration: "none",
            display: "flex",
            alignItems: "center",
            gap: "6px"
          }}
        >
          &larr; Back to website
        </a>
        <div className="login-icon-circle">
          <Mic size={36} />
        </div>
        <h2>Welcome to LogCal</h2>
        <p className="login-subtitle">Speak or write to track your calories</p>

        {/* Rotating Animation Mockup */}
        <div className="rotation-box">
          <div
            className="rotation-meal-text"
            style={{
              opacity: showPhase !== "fade" ? 1 : 0,
              transition: "opacity 300ms ease"
            }}
          >
            &ldquo;{demoMeals[currentMealIndex].text}&rdquo;
          </div>
          
          <div
            className="rotation-meal-arrow"
            style={{
              opacity: showPhase === "arrow" || showPhase === "calories" ? 1 : 0,
              transition: "opacity 300ms ease"
            }}
          >
            <ArrowDown size={20} />
          </div>

          <div
            className="rotation-meal-cal"
            style={{
              opacity: showPhase === "calories" ? 1 : 0,
              transition: "opacity 300ms ease"
            }}
          >
            {demoMeals[currentMealIndex].calories} cal
          </div>
        </div>

        {error && (
          <div style={{ color: "#ff4d4d", marginBottom: "20px", fontWeight: 700, fontSize: "14px" }}>
            {error}
          </div>
        )}

        <div className="login-buttons">
          <button
            onClick={handleGoogleSignIn}
            disabled={loading}
            className="google-btn"
            type="button"
          >
            <svg viewBox="0 0 24 24" width="20" height="20">
              <path
                fill="#4285F4"
                d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"
              />
              <path
                fill="#34A853"
                d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"
              />
              <path
                fill="#FBBC05"
                d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.06H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.94l3.66-2.85z"
              />
              <path
                fill="#EA4335"
                d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.06l3.66 2.85c.87-2.6 3.3-4.53 6.16-4.53z"
              />
            </svg>
            <span>{loading ? "Signing in..." : "Continue with Google"}</span>
          </button>

          <button
            onClick={handleGuestSignIn}
            disabled={loading}
            className="guest-btn"
            type="button"
          >
            {loading ? "Please wait..." : "Continue as Guest"}
          </button>
        </div>
      </div>
    </div>
  );
}
