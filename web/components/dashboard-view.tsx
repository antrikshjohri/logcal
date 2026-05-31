"use client";

import React, { useState, useEffect } from "react";
import { collection, query, getDocs, doc, getDoc } from "firebase/firestore";
import { auth, db } from "../lib/firebase-client";
import { ChevronLeft, ChevronRight, Flame, Award, Heart, Info } from "lucide-react";

interface DashboardViewProps {
  setActiveTab: (tab: "log" | "dashboard" | "history" | "settings") => void;
}

interface MealEntry {
  id: string;
  timestamp: any; // Firestore Timestamp
  foodText: string;
  mealType: string;
  totalCalories: number;
  rawResponseJson: string;
  hasImage?: boolean;
}

export function DashboardView({ setActiveTab }: DashboardViewProps) {
  const [selectedDate, setSelectedDate] = useState(() => {
    const today = new Date();
    return today.toISOString().split("T")[0];
  });
  
  // Goals (defaults match iOS)
  const [dailyGoal, setDailyGoal] = useState(2000);
  const [proteinGoal, setProteinGoal] = useState(150);
  const [carbsGoal, setCarbsGoal] = useState(200);
  const [fatGoal, setFatGoal] = useState(65);

  const [meals, setMeals] = useState<MealEntry[]>([]);
  const [loading, setLoading] = useState(true);

  // Fetch goals and meals from Firestore
  useEffect(() => {
    const fetchData = async () => {
      if (!auth.currentUser) return;
      const userId = auth.currentUser.uid;
      setLoading(true);

      try {
        // 1. Fetch settings/goals
        const userDocRef = doc(db, "users", userId);
        const userDocSnap = await getDoc(userDocRef);
        if (userDocSnap.exists()) {
          const userData = userDocSnap.data();
          if (userData.dailyGoal) setDailyGoal(userData.dailyGoal);
          // If custom macro targets are saved, use them
          if (userData.proteinGoal) setProteinGoal(userData.proteinGoal);
          if (userData.carbsGoal) setCarbsGoal(userData.carbsGoal);
          if (userData.fatGoal) setFatGoal(userData.fatGoal);
        }

        // 2. Fetch meals
        const mealsCollRef = collection(db, "users", userId, "meals");
        const mealsQuery = query(mealsCollRef);
        const querySnapshot = await getDocs(mealsQuery);
        
        const fetchedMeals: MealEntry[] = [];
        querySnapshot.forEach((docSnap) => {
          const data = docSnap.data();
          fetchedMeals.push({
            id: docSnap.id,
            timestamp: data.timestamp,
            foodText: data.foodText || "",
            mealType: data.mealType || "",
            totalCalories: data.totalCalories || 0,
            rawResponseJson: data.rawResponseJson || "{}"
          });
        });
        
        setMeals(fetchedMeals);
      } catch (err) {
        console.error("Error fetching dashboard data:", err);
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, []);

  // Helpers to process dates
  const isSameDay = (d1: Date, d2: Date) => {
    return (
      d1.getFullYear() === d2.getFullYear() &&
      d1.getMonth() === d2.getMonth() &&
      d1.getDate() === d2.getDate()
    );
  };

  const getMealsForDate = (dateStr: string) => {
    const targetDate = new Date(dateStr);
    return meals.filter((meal) => {
      if (!meal.timestamp) return false;
      const mealDate = meal.timestamp.toDate();
      return isSameDay(mealDate, targetDate);
    });
  };

  const todayMeals = getMealsForDate(selectedDate);
  
  // Consumed Calories for selectedDate
  const todayCalories = todayMeals.reduce((acc, meal) => acc + meal.totalCalories, 0);

  // Consumed Macros for selectedDate
  const getMacrosForDate = () => {
    let protein = 0;
    let carbs = 0;
    let fat = 0;

    todayMeals.forEach((meal) => {
      try {
        const responseObj = JSON.parse(meal.rawResponseJson);
        let p = responseObj.protein || 0;
        let c = responseObj.carbs || 0;
        let f = responseObj.fat || 0;
        
        // Fallback to sum items if top-level fields are 0
        if (p === 0 && c === 0 && f === 0 && responseObj.items) {
          responseObj.items.forEach((item: any) => {
            p += item.protein || 0;
            c += item.carbs || 0;
            f += item.fat || 0;
          });
        }
        protein += p;
        carbs += c;
        fat += f;
      } catch (e) {
        // Fallback parse error
      }
    });

    return { protein, carbs, fat };
  };

  const todayMacros = getMacrosForDate();

  // Streak Calculation
  const calculateStreak = () => {
    if (meals.length === 0) return 0;

    const calendarDates = meals
      .map((meal) => {
        if (!meal.timestamp) return null;
        const d = meal.timestamp.toDate();
        d.setHours(0, 0, 0, 0);
        return d.getTime();
      })
      .filter((t): t is number => t !== null);

    const uniqueDates = Array.from(new Set(calendarDates)).sort((a, b) => b - a);
    if (uniqueDates.length === 0) return 0;

    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const todayTime = today.getTime();

    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);
    yesterday.setHours(0, 0, 0, 0);
    const yesterdayTime = yesterday.getTime();

    const mostRecent = uniqueDates[0];
    
    // Check if the user logged today or yesterday
    if (mostRecent !== todayTime && mostRecent !== yesterdayTime) {
      return 0;
    }

    let streak = 1;
    let expectedTime = mostRecent;

    for (let i = 1; i < uniqueDates.length; i++) {
      const nextExpected = expectedTime - 24 * 60 * 60 * 1000;
      if (uniqueDates[i] === nextExpected) {
        streak++;
        expectedTime = nextExpected;
      } else {
        break;
      }
    }

    return streak;
  };

  // Weekly history (last 7 days centered on selectedDate)
  const getWeeklyData = () => {
    const anchor = new Date(selectedDate);
    const list = [];
    const weekdays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];

    for (let i = 6; i >= 0; i--) {
      const d = new Date(anchor);
      d.setDate(d.getDate() - i);
      const dayLabel = weekdays[d.getDay()];
      const dayStr = d.toISOString().split("T")[0];
      const dayMeals = getMealsForDate(dayStr);
      const dayCal = dayMeals.reduce((acc, m) => acc + m.totalCalories, 0);
      list.push({
        label: dayLabel,
        calories: dayCal,
        isToday: isSameDay(d, new Date())
      });
    }
    return list;
  };

  const weeklyData = getWeeklyData();
  const maxWeeklyCal = Math.max(...weeklyData.map((d) => d.calories), 1000);

  const getStatusText = () => {
    if (todayCalories > dailyGoal) {
      return {
        title: "Over your daily target",
        subtitle: `${Math.round(todayCalories - dailyGoal)} cal over target`,
        color: "#ff9f43"
      };
    }
    return {
      title: "On track for your goal",
      subtitle: "Great choices so far today!",
      color: "var(--green)"
    };
  };

  const status = getStatusText();

  // Progress SVG calculations
  const radius = 90;
  const circumference = 2 * Math.PI * radius;
  const progressRatio = Math.min(todayCalories / dailyGoal, 1);
  const strokeDashoffset = circumference - progressRatio * circumference;

  const changeDateByDays = (days: number) => {
    const current = new Date(selectedDate);
    current.setDate(current.getDate() + days);
    setSelectedDate(current.toISOString().split("T")[0]);
  };

  const getFormattedDateTitle = () => {
    const d = new Date(selectedDate);
    const today = new Date();
    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);

    if (isSameDay(d, today)) return "Today";
    if (isSameDay(d, yesterday)) return "Yesterday";
    
    return d.toLocaleDateString("en-US", { weekday: "long", month: "short", day: "numeric" });
  };

  if (loading) {
    return (
      <div style={{ display: "flex", justifyContent: "center", alignItems: "center", height: "50vh", fontWeight: 800, color: "var(--muted)" }}>
        Loading dashboard metrics...
      </div>
    );
  }

  return (
    <div style={{ maxWidth: "1000px", width: "100%", margin: "0 auto" }}>
      {/* Date Bar */}
      <div style={{ display: "flex", justifyContent: "center", marginBottom: "32px" }}>
        <div style={{ display: "flex", alignItems: "center", gap: "16px", background: "var(--panel)", border: "1px solid var(--line)", padding: "8px 24px", borderRadius: "999px", boxShadow: "var(--soft-shadow)" }}>
          <button
            onClick={() => changeDateByDays(-1)}
            style={{ background: "transparent", border: "none", cursor: "pointer", display: "flex", alignItems: "center", color: "var(--green)" }}
            type="button"
          >
            <ChevronLeft size={20} />
          </button>
          <span style={{ fontWeight: 800, fontSize: "16px", minWidth: "150px", textAlign: "center" }}>
            {getFormattedDateTitle()}
          </span>
          <button
            onClick={() => changeDateByDays(1)}
            style={{ background: "transparent", border: "none", cursor: "pointer", display: "flex", alignItems: "center", color: "var(--green)" }}
            disabled={isSameDay(new Date(selectedDate), new Date())}
            type="button"
          >
            <ChevronRight size={20} />
          </button>
        </div>
      </div>

      {/* Status Alert Banner */}
      <div
        className="glass-card"
        style={{
          display: "flex",
          alignItems: "center",
          gap: "20px",
          padding: "20px 32px",
          background: `rgba(${status.color === "var(--green)" ? "0, 100, 61" : "255, 159, 67"}, 0.08)`,
          borderColor: status.color,
          borderWidth: "1px",
          borderStyle: "solid"
        }}
      >
        <div style={{ width: "36px", height: "36px", borderRadius: "50%", background: status.color, color: "white", display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0 }}>
          <Award size={18} />
        </div>
        <div>
          <div style={{ fontWeight: 900, color: status.color, fontSize: "17px" }}>{status.title}</div>
          <div style={{ fontSize: "14px", color: "var(--muted)", fontWeight: 700, marginTop: "2px" }}>{status.subtitle}</div>
        </div>
        <Heart size={32} style={{ marginLeft: "auto", color: status.color, opacity: 0.15 }} />
      </div>

      {/* Main Grid */}
      <div className="dashboard-grid">
        {/* Left Column: Progress Ring & Macro Targets */}
        <div className="glass-card" style={{ display: "flex", flexDirection: "column", alignItems: "center" }}>
          <div className="goal-ring-container">
            <svg width="220" height="220" className="goal-svg-ring">
              <circle cx="110" cy="110" r={radius} className="goal-ring-bg" />
              <circle
                cx="110"
                cy="110"
                r={radius}
                className={`goal-ring-progress ${todayCalories > dailyGoal ? "over" : ""}`}
                strokeDasharray={circumference}
                strokeDashoffset={strokeDashoffset}
              />
            </svg>
            <div className="goal-ring-center">
              <span className="goal-ring-cal">{Math.round(todayCalories)}</span>
              <span className="goal-ring-label">of {dailyGoal} cal</span>
            </div>
          </div>

          <div style={{ width: "100%", marginTop: "20px" }}>
            <div className="target-macros-list">
              {/* Protein Target */}
              <div className="target-macro-item protein">
                <div className="target-macro-label">
                  <span>Protein</span>
                  <span style={{ color: "var(--muted)" }}>
                    {Math.round(todayMacros.protein)}g / {proteinGoal}g
                  </span>
                </div>
                <div className="target-macro-bar-bg">
                  <div
                    className="target-macro-bar-fill"
                    style={{ width: `${Math.min((todayMacros.protein / proteinGoal) * 100, 100)}%` }}
                  />
                </div>
              </div>

              {/* Carbs Target */}
              <div className="target-macro-item carbs">
                <div className="target-macro-label">
                  <span>Carbs</span>
                  <span style={{ color: "var(--muted)" }}>
                    {Math.round(todayMacros.carbs)}g / {carbsGoal}g
                  </span>
                </div>
                <div className="target-macro-bar-bg">
                  <div
                    className="target-macro-bar-fill"
                    style={{ width: `${Math.min((todayMacros.carbs / carbsGoal) * 100, 100)}%` }}
                  />
                </div>
              </div>

              {/* Fat Target */}
              <div className="target-macro-item fat">
                <div className="target-macro-label">
                  <span>Fat</span>
                  <span style={{ color: "var(--muted)" }}>
                    {Math.round(todayMacros.fat)}g / {fatGoal}g
                  </span>
                </div>
                <div className="target-macro-bar-bg">
                  <div
                    className="target-macro-bar-fill"
                    style={{ width: `${Math.min((todayMacros.fat / fatGoal) * 100, 100)}%` }}
                  />
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Right Column: Weekly Trend & Streak Status */}
        <div style={{ display: "flex", flexDirection: "column", gap: "24px" }}>
          {/* Weekly Calorie Bar Chart */}
          <div className="glass-card" style={{ flexGrow: 1 }}>
            <h3 style={{ margin: 0, fontWeight: 900, fontSize: "18px" }}>Weekly Calories</h3>
            <div className="weekly-chart-wrapper">
              {weeklyData.map((d, index) => {
                const heightPct = Math.round((d.calories / maxWeeklyCal) * 100);
                return (
                  <div className="weekly-chart-col" key={index}>
                    <div className="weekly-chart-bar-container">
                      <div
                        className={`weekly-chart-bar ${d.isToday ? "active" : ""}`}
                        style={{ height: `${Math.max(heightPct, 3)}%` }}
                      />
                      <div className="weekly-chart-bar-tooltip">
                        {Math.round(d.calories)} cal
                      </div>
                    </div>
                    <span className="weekly-chart-day">{d.label}</span>
                  </div>
                );
              })}
            </div>
          </div>

          {/* Quick Stats Grid */}
          <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "24px" }}>
            {/* Streak Card */}
            <div className="glass-card" style={{ display: "flex", alignItems: "center", gap: "16px", padding: "24px" }}>
              <div style={{ width: "42px", height: "42px", borderRadius: "50%", background: "rgba(255, 159, 67, 0.15)", color: "#ff9f43", display: "flex", alignItems: "center", justifyContent: "center" }}>
                <Flame size={22} fill="#ff9f43" />
              </div>
              <div>
                <div style={{ fontSize: "24px", fontWeight: 900 }}>{calculateStreak()}</div>
                <div style={{ fontSize: "13px", fontWeight: 700, color: "var(--muted)" }}>DAY STREAK</div>
              </div>
            </div>

            {/* Total Meals Card */}
            <div className="glass-card" style={{ display: "flex", alignItems: "center", gap: "16px", padding: "24px" }}>
              <div style={{ width: "42px", height: "42px", borderRadius: "50%", background: "var(--green-soft)", color: "var(--green)", display: "flex", alignItems: "center", justifyContent: "center" }}>
                <Award size={22} />
              </div>
              <div>
                <div style={{ fontSize: "24px", fontWeight: 900 }}>{todayMeals.length}</div>
                <div style={{ fontSize: "13px", fontWeight: 700, color: "var(--muted)" }}>MEALS LOGGED</div>
              </div>
            </div>
          </div>

          {/* Prompt to log a meal if empty */}
          {todayMeals.length === 0 && (
            <div className="glass-card" style={{ display: "flex", alignItems: "center", gap: "16px", padding: "20px 24px", background: "var(--panel-soft)" }}>
              <Info size={20} style={{ color: "var(--muted)", flexShrink: 0 }} />
              <p style={{ margin: 0, fontSize: "14px", fontWeight: 700, color: "var(--muted)" }}>
                You haven't logged any meals today.{" "}
                <button
                  onClick={() => setActiveTab("log")}
                  style={{ background: "transparent", border: "none", color: "var(--green)", fontWeight: 800, padding: 0, cursor: "pointer", textDecoration: "underline" }}
                  type="button"
                >
                  Log a meal now
                </button>
              </p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
