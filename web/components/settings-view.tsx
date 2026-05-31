"use client";

import React, { useState, useEffect } from "react";
import { User } from "firebase/auth";
import { doc, getDoc, setDoc, Timestamp } from "firebase/firestore";
import { db } from "../lib/firebase-client";
import { Settings, Save, AlertTriangle, LogOut, CheckCircle } from "lucide-react";

interface SettingsViewProps {
  user: User | null;
  onSignOut: () => Promise<void>;
}

export function SettingsView({ user, onSignOut }: SettingsViewProps) {
  // Goal States
  const [dailyGoal, setDailyGoal] = useState("2000");
  const [proteinGoal, setProteinGoal] = useState("150");
  const [carbsGoal, setCarbsGoal] = useState("200");
  const [fatGoal, setFatGoal] = useState("65");

  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [success, setSuccess] = useState(false);

  // Fetch current goals on mount
  useEffect(() => {
    const fetchGoals = async () => {
      if (!user) return;
      setLoading(true);
      try {
        const userDocRef = doc(db, "users", user.uid);
        const docSnap = await getDoc(userDocRef);
        if (docSnap.exists()) {
          const data = docSnap.data();
          if (data.dailyGoal !== undefined) setDailyGoal(String(data.dailyGoal));
          if (data.proteinGoal !== undefined) setProteinGoal(String(data.proteinGoal));
          if (data.carbsGoal !== undefined) setCarbsGoal(String(data.carbsGoal));
          if (data.fatGoal !== undefined) setFatGoal(String(data.fatGoal));
        }
      } catch (err) {
        console.error("Error loading goals:", err);
      } finally {
        setLoading(false);
      }
    };
    fetchGoals();
  }, [user]);

  const handleSaveGoals = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!user) return;
    setSaving(true);
    setSuccess(false);

    try {
      const userDocRef = doc(db, "users", user.uid);
      await setDoc(
        userDocRef,
        {
          dailyGoal: Number(dailyGoal) || 2000,
          proteinGoal: Number(proteinGoal) || 150,
          carbsGoal: Number(carbsGoal) || 200,
          fatGoal: Number(fatGoal) || 65,
          updatedAt: Timestamp.fromDate(new Date())
        },
        { merge: true }
      );
      setSuccess(true);
      setTimeout(() => setSuccess(false), 3000);
    } catch (err) {
      console.error("Error saving goals:", err);
      alert("Failed to save goals. Please try again.");
    } finally {
      setSaving(false);
    }
  };

  if (loading) {
    return (
      <div style={{ display: "flex", justifyContent: "center", alignItems: "center", height: "50vh", fontWeight: 800, color: "var(--muted)" }}>
        Loading settings...
      </div>
    );
  }

  return (
    <div style={{ maxWidth: "700px", width: "100%", margin: "0 auto" }}>
      {/* Guest Mode Warning */}
      {user?.isAnonymous && (
        <div className="guest-link-banner">
          <AlertTriangle size={24} style={{ color: "#8e6212", flexShrink: 0 }} />
          <div>
            <p>You are logged in as a Guest</p>
            <span style={{ fontSize: "13px", color: "var(--muted)" }}>
              Your food logs are stored temporarily and will be lost if you clear your browser cache.
              Sign out and log in with Google to create a permanent account and sync data with your iPhone.
            </span>
          </div>
        </div>
      )}

      {/* Goal Settings */}
      <div className="glass-card">
        <h3 className="settings-section-title" style={{ display: "flex", alignItems: "center", gap: "10px", margin: "0 0 24px" }}>
          <Settings size={20} />
          <span>Calorie & Macro Goals</span>
        </h3>

        <form onSubmit={handleSaveGoals}>
          <div className="form-grid">
            <div className="form-group">
              <label htmlFor="dailyGoal">Daily Calorie Goal</label>
              <input
                id="dailyGoal"
                type="number"
                value={dailyGoal}
                onChange={(e) => setDailyGoal(e.target.value)}
                className="form-control"
                placeholder="2000"
                min="500"
                max="10000"
                required
              />
            </div>
            
            <div className="form-group">
              <label htmlFor="proteinGoal">Protein Target (g)</label>
              <input
                id="proteinGoal"
                type="number"
                value={proteinGoal}
                onChange={(e) => setProteinGoal(e.target.value)}
                className="form-control"
                placeholder="150"
                min="0"
                required
              />
            </div>

            <div className="form-group">
              <label htmlFor="carbsGoal">Carbs Target (g)</label>
              <input
                id="carbsGoal"
                type="number"
                value={carbsGoal}
                onChange={(e) => setCarbsGoal(e.target.value)}
                className="form-control"
                placeholder="200"
                min="0"
                required
              />
            </div>

            <div className="form-group">
              <label htmlFor="fatGoal">Fat Target (g)</label>
              <input
                id="fatGoal"
                type="number"
                value={fatGoal}
                onChange={(e) => setFatGoal(e.target.value)}
                className="form-control"
                placeholder="65"
                min="0"
                required
              />
            </div>
          </div>

          <div style={{ display: "flex", alignItems: "center", gap: "16px" }}>
            <button
              type="submit"
              disabled={saving}
              className="primary-btn"
              style={{ display: "flex", alignItems: "center", gap: "8px", padding: "12px 28px" }}
            >
              <Save size={16} />
              <span>{saving ? "Saving..." : "Save Goals"}</span>
            </button>

            {success && (
              <span style={{ display: "flex", alignItems: "center", gap: "6px", color: "var(--green)", fontWeight: 800, fontSize: "14px" }}>
                <CheckCircle size={16} />
                <span>Goals updated successfully!</span>
              </span>
            )}
          </div>
        </form>
      </div>

      {/* Account Info */}
      <div className="glass-card">
        <h3 className="settings-section-title" style={{ margin: "0 0 20px" }}>Account Information</h3>
        <div style={{ display: "flex", flexDirection: "column", gap: "12px", fontSize: "15px" }}>
          <div>
            <strong style={{ color: "var(--muted)", marginRight: "8px" }}>Sign-in Provider:</strong>
            <span>{user?.isAnonymous ? "Guest Mode" : user?.providerData[0]?.providerId === "google.com" ? "Google" : "Email"}</span>
          </div>
          <div>
            <strong style={{ color: "var(--muted)", marginRight: "8px" }}>User ID:</strong>
            <code style={{ background: "var(--panel-soft)", padding: "2px 6px", borderRadius: "4px", fontSize: "13px" }}>{user?.uid}</code>
          </div>
          {!user?.isAnonymous && user?.email && (
            <div>
              <strong style={{ color: "var(--muted)", marginRight: "8px" }}>Email:</strong>
              <span>{user.email}</span>
            </div>
          )}
        </div>

        <hr style={{ border: "none", borderTop: "1px solid var(--line)", margin: "24px 0" }} />

        <button
          onClick={onSignOut}
          className="google-btn"
          style={{ width: "fit-content", borderColor: "#ff4d4d", color: "#ff4d4d", background: "transparent", display: "flex", alignItems: "center", gap: "8px", padding: "10px 24px" }}
          type="button"
        >
          <LogOut size={16} />
          <span>Sign Out</span>
        </button>
      </div>
    </div>
  );
}
