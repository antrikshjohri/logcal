"use client";

import React, { useState, useEffect } from "react";
import { User, signOut } from "firebase/auth";
import { auth } from "../lib/firebase-client";
import { PlusCircle, BarChart2, Calendar, Settings, LogOut } from "lucide-react";
import Image from "next/image";

import { LogView } from "./log-view";
import { DashboardView } from "./dashboard-view";
import { HistoryView } from "./history-view";
import { SettingsView } from "./settings-view";

type TabId = "log" | "dashboard" | "history" | "settings";

export function AppShell() {
  const [activeTab, setActiveTab] = useState<TabId>("log");
  const [user, setUser] = useState<User | null>(null);

  useEffect(() => {
    const unsubscribe = auth.onAuthStateChanged((currentUser) => {
      setUser(currentUser);
    });
    return () => unsubscribe();
  }, []);

  const handleSignOut = async () => {
    try {
      await signOut(auth);
    } catch (error) {
      console.error("Error signing out:", error);
    }
  };

  const getProfileInitials = () => {
    if (!user) return "?";
    if (user.isAnonymous) return "G";
    if (user.displayName) {
      const parts = user.displayName.split(" ");
      return parts.map((n) => n[0]).join("").toUpperCase().substring(0, 2);
    }
    if (user.email) {
      return user.email[0].toUpperCase();
    }
    return "U";
  };

  const getProfileName = () => {
    if (!user) return "Loading...";
    if (user.isAnonymous) return "Guest User";
    return user.displayName || user.email?.split("@")[0] || "User";
  };

  const renderActiveView = () => {
    switch (activeTab) {
      case "log":
        return <LogView />;
      case "dashboard":
        return <DashboardView setActiveTab={setActiveTab} />;
      case "history":
        return <HistoryView />;
      case "settings":
        return <SettingsView user={user} onSignOut={handleSignOut} />;
      default:
        return <LogView />;
    }
  };

  const getTabTitle = () => {
    switch (activeTab) {
      case "log":
        return "Log a Meal";
      case "dashboard":
        return "Dashboard";
      case "history":
        return "Meal History";
      case "settings":
        return "Settings & Goals";
      default:
        return "Log";
    }
  };

  return (
    <div className="app-container">
      {/* Sidebar - Desktop */}
      <aside className="app-sidebar">
        <div className="sidebar-logo">
          <Image
            src="/images/logcal-transparent-logo-64.webp"
            alt="LogCal AI"
            width={36}
            height={36}
          />
          <span>LogCal AI</span>
        </div>

        <nav className="sidebar-menu" aria-label="App Navigation">
          <button
            onClick={() => setActiveTab("log")}
            className={`sidebar-item ${activeTab === "log" ? "active" : ""}`}
            type="button"
          >
            <PlusCircle size={20} />
            <span>Log Meal</span>
          </button>

          <button
            onClick={() => setActiveTab("dashboard")}
            className={`sidebar-item ${activeTab === "dashboard" ? "active" : ""}`}
            type="button"
          >
            <BarChart2 size={20} />
            <span>Dashboard</span>
          </button>

          <button
            onClick={() => setActiveTab("history")}
            className={`sidebar-item ${activeTab === "history" ? "active" : ""}`}
            type="button"
          >
            <Calendar size={20} />
            <span>History</span>
          </button>

          <button
            onClick={() => setActiveTab("settings")}
            className={`sidebar-item ${activeTab === "settings" ? "active" : ""}`}
            type="button"
          >
            <Settings size={20} />
            <span>Settings</span>
          </button>
        </nav>

        <div className="sidebar-profile">
          <div className="profile-avatar">{getProfileInitials()}</div>
          <div className="profile-info">
            <span className="profile-name">{getProfileName()}</span>
            <span className="profile-role">
              {user?.isAnonymous ? "Guest Mode" : "Premium Member"}
            </span>
          </div>
          <button
            onClick={handleSignOut}
            className="delete-btn"
            style={{ marginLeft: "auto", color: "var(--muted)" }}
            title="Sign Out"
            type="button"
          >
            <LogOut size={18} />
          </button>
        </div>
      </aside>

      {/* Mobile Header & Bottom Navigation */}
      <div className="app-main">
        <header className="app-header" style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
          <h1>{getTabTitle()}</h1>
          <a
            href="/"
            className="secondary-button"
            style={{
              minHeight: "36px",
              padding: "0 16px",
              fontSize: "13px",
              border: "1px solid var(--line)",
              background: "transparent",
              color: "var(--muted)",
              display: "inline-flex",
              alignItems: "center",
              borderRadius: "999px"
            }}
          >
            Back to website
          </a>
        </header>

        <main className="app-content">{renderActiveView()}</main>
      </div>

      {/* Mobile Bottom Tab Bar */}
      <nav className="app-mobile-nav" aria-label="Mobile Navigation">
        <button
          onClick={() => setActiveTab("log")}
          className={`mobile-nav-item ${activeTab === "log" ? "active" : ""}`}
          type="button"
        >
          <PlusCircle size={20} />
          <span>Log</span>
        </button>

        <button
          onClick={() => setActiveTab("dashboard")}
          className={`mobile-nav-item ${activeTab === "dashboard" ? "active" : ""}`}
          type="button"
        >
          <BarChart2 size={20} />
          <span>Dashboard</span>
        </button>

        <button
          onClick={() => setActiveTab("history")}
          className={`mobile-nav-item ${activeTab === "history" ? "active" : ""}`}
          type="button"
        >
          <Calendar size={20} />
          <span>History</span>
        </button>

        <button
          onClick={() => setActiveTab("settings")}
          className={`mobile-nav-item ${activeTab === "settings" ? "active" : ""}`}
          type="button"
        >
          <Settings size={20} />
          <span>Settings</span>
        </button>
      </nav>
    </div>
  );
}
