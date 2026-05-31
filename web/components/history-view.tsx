"use client";

import React, { useState, useEffect } from "react";
import { collection, query, getDocs, doc, deleteDoc, orderBy } from "firebase/firestore";
import { auth, db } from "../lib/firebase-client";
import { Trash2, Calendar as CalendarIcon, Clock, Sparkles } from "lucide-react";

interface MealItem {
  name: string;
  quantity: string;
  calories: number;
  protein?: number;
  carbs?: number;
  fat?: number;
}

interface MealEntry {
  id: string;
  timestamp: any; // Firestore Timestamp
  createdAt?: any;
  foodText: string;
  mealType: string;
  totalCalories: number;
  rawResponseJson: string;
  hasImage?: boolean;
}

interface DayGroup {
  dateStr: string;
  formattedDate: string;
  meals: MealEntry[];
  totalCalories: number;
  totalProtein: number;
  totalCarbs: number;
  totalFat: number;
}

export function HistoryView() {
  const [dayGroups, setDayGroups] = useState<DayGroup[]>([]);
  const [loading, setLoading] = useState(true);

  const fetchHistory = async () => {
    if (!auth.currentUser) return;
    const userId = auth.currentUser.uid;
    setLoading(true);

    try {
      const mealsCollRef = collection(db, "users", userId, "meals");
      // Query meals sorted by timestamp descending
      const q = query(mealsCollRef, orderBy("timestamp", "desc"));
      const querySnapshot = await getDocs(q);
      
      const fetchedMeals: MealEntry[] = [];
      querySnapshot.forEach((docSnap) => {
        const data = docSnap.data();
        fetchedMeals.push({
          id: docSnap.id,
          timestamp: data.timestamp,
          createdAt: data.createdAt,
          foodText: data.foodText || "",
          mealType: data.mealType || "",
          totalCalories: data.totalCalories || 0,
          rawResponseJson: data.rawResponseJson || "{}"
        });
      });

      // Group by day
      const groupsMap: Record<string, MealEntry[]> = {};
      fetchedMeals.forEach((meal) => {
        if (!meal.timestamp) return;
        const d = meal.timestamp.toDate();
        const dateStr = d.toISOString().split("T")[0]; // YYYY-MM-DD
        if (!groupsMap[dateStr]) {
          groupsMap[dateStr] = [];
        }
        groupsMap[dateStr].push(meal);
      });

      const sortedDates = Object.keys(groupsMap).sort((a, b) => b.localeCompare(a));
      
      const computedGroups: DayGroup[] = sortedDates.map((dateStr) => {
        const dayMeals = groupsMap[dateStr];
        const d = new Date(dateStr);
        
        let totalCalories = 0;
        let totalProtein = 0;
        let totalCarbs = 0;
        let totalFat = 0;

        dayMeals.forEach((m) => {
          totalCalories += m.totalCalories;
          try {
            const responseObj = JSON.parse(m.rawResponseJson);
            let p = responseObj.protein || 0;
            let c = responseObj.carbs || 0;
            let f = responseObj.fat || 0;
            
            if (p === 0 && c === 0 && f === 0 && responseObj.items) {
              responseObj.items.forEach((item: any) => {
                p += item.protein || 0;
                c += item.carbs || 0;
                f += item.fat || 0;
              });
            }
            totalProtein += p;
            totalCarbs += c;
            totalFat += f;
          } catch (e) {
            // ignore JSON parse error
          }
        });

        // Format Date beautifully
        const today = new Date();
        const yesterday = new Date();
        yesterday.setDate(yesterday.getDate() - 1);
        
        let formattedDate = "";
        const mealDay = new Date(dateStr);
        
        if (mealDay.toDateString() === today.toDateString()) {
          formattedDate = "Today";
        } else if (mealDay.toDateString() === yesterday.toDateString()) {
          formattedDate = "Yesterday";
        } else {
          formattedDate = mealDay.toLocaleDateString("en-US", {
            weekday: "long",
            month: "short",
            day: "numeric",
            year: "numeric"
          });
        }

        return {
          dateStr,
          formattedDate,
          meals: dayMeals,
          totalCalories,
          totalProtein,
          totalCarbs,
          totalFat
        };
      });

      setDayGroups(computedGroups);
    } catch (err) {
      console.error("Error fetching history:", err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchHistory();
  }, []);

  const handleDeleteMeal = async (mealId: string) => {
    if (!auth.currentUser) return;
    const confirmDelete = window.confirm("Are you sure you want to delete this meal entry?");
    if (!confirmDelete) return;

    const userId = auth.currentUser.uid;
    try {
      // 1. Delete from users/{userId}/meals/{mealId}
      await deleteDoc(doc(db, "users", userId, "meals", mealId));
      
      // 2. Delete from mealLogs/{mealId}
      await deleteDoc(doc(db, "mealLogs", mealId));

      // 3. Refresh list
      await fetchHistory();
    } catch (err) {
      console.error("Failed to delete meal:", err);
      alert("Failed to delete meal entry. Please try again.");
    }
  };

  const parseMealTime = (meal: MealEntry) => {
    if (!meal.timestamp) return "";
    const d = meal.timestamp.toDate();
    return d.toLocaleTimeString("en-US", { hour: "numeric", minute: "2-digit" });
  };

  const getMealMacrosSummary = (meal: MealEntry) => {
    try {
      const responseObj = JSON.parse(meal.rawResponseJson);
      let p = responseObj.protein || 0;
      let c = responseObj.carbs || 0;
      let f = responseObj.fat || 0;
      
      if (p === 0 && c === 0 && f === 0 && responseObj.items) {
        responseObj.items.forEach((item: any) => {
          p += item.protein || 0;
          c += item.carbs || 0;
          f += item.fat || 0;
        });
      }
      if (p || c || f) {
        return `P: ${Math.round(p)}g | C: ${Math.round(c)}g | F: ${Math.round(f)}g`;
      }
    } catch (e) {
      // ignore
    }
    return "";
  };

  if (loading) {
    return (
      <div style={{ display: "flex", justifyContent: "center", alignItems: "center", height: "50vh", fontWeight: 800, color: "var(--muted)" }}>
        Loading meal logs...
      </div>
    );
  }

  if (dayGroups.length === 0) {
    return (
      <div className="glass-card" style={{ display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", padding: "64px 32px", textAlign: "center" }}>
        <CalendarIcon size={48} style={{ color: "var(--muted)", marginBottom: "20px" }} />
        <h2 style={{ margin: 0, fontWeight: 900, color: "var(--text)", fontSize: "22px" }}>No history recorded</h2>
        <p style={{ color: "var(--muted)", fontWeight: 700, margin: "8px 0 0", fontSize: "15px" }}>Meals you log will appear here grouped by day.</p>
      </div>
    );
  }

  return (
    <div style={{ maxWidth: "800px", width: "100%", margin: "0 auto" }}>
      {dayGroups.map((group) => (
        <div className="history-day-group" key={group.dateStr}>
          <div className="history-day-header">
            <span>{group.formattedDate}</span>
            <span className="history-day-summary">
              {Math.round(group.totalCalories)} cal
              {group.totalProtein > 0 && ` • P: ${Math.round(group.totalProtein)}g C: ${Math.round(group.totalCarbs)}g F: ${Math.round(group.totalFat)}g`}
            </span>
          </div>

          <div style={{ display: "flex", flexDirection: "column", gap: "12px" }}>
            {group.meals.map((meal) => (
              <div className="history-item-card" key={meal.id}>
                <div style={{ display: "flex", flexDirection: "column", flexGrow: 1, overflow: "hidden", paddingRight: "16px" }}>
                  <div className="history-item-title" style={{ whiteSpace: "nowrap", textOverflow: "ellipsis", overflow: "hidden" }}>
                    {meal.foodText}
                  </div>
                  <div className="history-item-meta">
                    <span className="history-item-type">{meal.mealType}</span>
                    <span style={{ display: "flex", alignItems: "center", gap: "4px" }}>
                      <Clock size={12} />
                      {parseMealTime(meal)}
                    </span>
                    {getMealMacrosSummary(meal) && (
                      <span style={{ color: "var(--green)", fontWeight: 700 }}>
                        {getMealMacrosSummary(meal)}
                      </span>
                    )}
                  </div>
                </div>

                <div className="history-item-right">
                  <div className="history-item-calories">
                    {Math.round(meal.totalCalories)}
                    <span>kcal</span>
                  </div>

                  <button
                    onClick={() => handleDeleteMeal(meal.id)}
                    className="delete-btn"
                    title="Delete Entry"
                    type="button"
                  >
                    <Trash2 size={16} />
                  </button>
                </div>
              </div>
            ))}
          </div>
        </div>
      ))}
    </div>
  );
}
