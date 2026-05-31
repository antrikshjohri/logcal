"use client";

import React, { useState, useEffect, useRef } from "react";
import { httpsCallable } from "firebase/functions";
import { doc, setDoc, getDoc, Timestamp } from "firebase/firestore";
import { auth, db, functions } from "../lib/firebase-client";
import { Mic, Check, X, Camera, Image as ImageIcon, Send, Sparkles, Bookmark, Trash2, ArrowRight, Star } from "lucide-react";

// Types matching Swift models
interface MealItem {
  name: string;
  quantity: string;
  calories: number;
  protein?: number;
  carbs?: number;
  fat?: number;
  assumptions?: string;
  confidence: number;
}

interface MealLogResponse {
  meal_type: string;
  total_calories: number;
  protein?: number;
  carbs?: number;
  fat?: number;
  items: MealItem[];
  needs_clarification: boolean;
  clarifying_question?: string;
}

export function LogView() {
  const [foodText, setFoodText] = useState("");
  const [mealType, setMealType] = useState("breakfast");
  const [selectedDate, setSelectedDate] = useState(() => {
    const today = new Date();
    return today.toISOString().split("T")[0];
  });
  
  // Images (as objects containing base64/status)
  const [images, setImages] = useState<{ id: string; src: string; loading: boolean }[]>([]);
  const [isDragging, setIsDragging] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);

  // Favorites List & Selection
  const [savedMeals, setSavedMeals] = useState<any[]>([]);
  const [activeFavorite, setActiveFavorite] = useState<any | null>(null);

  // Audio Recording State
  const [isRecording, setIsRecording] = useState(false);
  const [isTranscribing, setIsTranscribing] = useState(false);
  const mediaRecorderRef = useRef<MediaRecorder | null>(null);
  const audioChunksRef = useRef<Blob[]>([]);

  // Estimation Result State
  const [loading, setLoading] = useState(false);
  const [latestResult, setLatestResult] = useState<MealLogResponse | null>(null);
  const [correctionPrompt, setCorrectionPrompt] = useState("");
  const [refining, setRefining] = useState(false);
  const [isSaved, setIsSaved] = useState(false);
  const [statusMessage, setStatusMessage] = useState<string | null>(null);

  // Auto-detect meal type based on time of day
  useEffect(() => {
    const hour = new Date().getHours();
    if (hour >= 5 && hour < 11) setMealType("breakfast");
    else if (hour >= 11 && hour < 16) setMealType("lunch");
    else if (hour >= 16 && hour < 22) setMealType("dinner");
    else setMealType("snack");
  }, []);

  // Fetch favorites from Firestore on load/auth change
  useEffect(() => {
    const unsubscribe = auth.onAuthStateChanged((user) => {
      if (user) {
        const fetchFavorites = async () => {
          const userId = user.uid;
          try {
            const userDocRef = doc(db, "users", userId);
            const userDocSnap = await getDoc(userDocRef);
            if (userDocSnap.exists()) {
              const userData = userDocSnap.data();
              if (userData.savedMeals && Array.isArray(userData.savedMeals) && userData.savedMeals.length > 0) {
                setSavedMeals(userData.savedMeals);
                return;
              }
            }
            
            // Fallback defaults
            const DEFAULT_FAVORITES = [
              {
                id: "fav-1",
                title: "Double Egg Omelette",
                foodText: "Double Egg Omelette",
                mealType: "breakfast",
                totalCalories: 280,
                rawResponseJson: JSON.stringify({
                  meal_type: "breakfast",
                  total_calories: 280,
                  protein: 24,
                  carbs: 2,
                  fat: 20,
                  items: [{ name: "Egg Omelette", quantity: "2 large eggs", calories: 280, protein: 24, carbs: 2, fat: 20, confidence: 0.95 }]
                })
              },
              {
                id: "fav-2",
                title: "Chicken Breast & Rice",
                foodText: "Chicken Breast with Rice",
                mealType: "lunch",
                totalCalories: 550,
                rawResponseJson: JSON.stringify({
                  meal_type: "lunch",
                  total_calories: 550,
                  protein: 45,
                  carbs: 50,
                  fat: 10,
                  items: [
                    { name: "Chicken Breast", quantity: "150g", calories: 250, protein: 35, carbs: 0, fat: 4, confidence: 0.95 },
                    { name: "White Rice", quantity: "1.5 cups cooked", calories: 300, protein: 10, carbs: 50, fat: 6, confidence: 0.95 }
                  ]
                })
              },
              {
                id: "fav-3",
                title: "Protein Shake",
                foodText: "Protein Shake",
                mealType: "snack",
                totalCalories: 200,
                rawResponseJson: JSON.stringify({
                  meal_type: "snack",
                  total_calories: 200,
                  protein: 30,
                  carbs: 5,
                  fat: 3,
                  items: [{ name: "Protein Shake", quantity: "1 scoop protein powder", calories: 200, protein: 30, carbs: 5, fat: 3, confidence: 0.99 }]
                })
              }
            ];
            setSavedMeals(DEFAULT_FAVORITES);
          } catch (err) {
            console.error("Error loading favorites:", err);
          }
        };
        fetchFavorites();
      }
    });
    return () => unsubscribe();
  }, []);

  // Handle Date Navigation Chevrons
  const changeDateByDays = (days: number) => {
    const currentDate = new Date(selectedDate);
    currentDate.setDate(currentDate.getDate() + days);
    setSelectedDate(currentDate.toISOString().split("T")[0]);
  };

  // Image Upload Handling
  const handleImageClick = () => {
    fileInputRef.current?.click();
  };

  const processImageFiles = (files: File[]) => {
    if (images.length + files.length > 3) {
      alert("Maximum of 3 images can be uploaded.");
      return;
    }

    files.forEach((file) => {
      const imageId = crypto.randomUUID();
      // Add loading placeholder first
      setImages((prev) => [...prev, { id: imageId, src: "", loading: true }]);

      const reader = new FileReader();
      reader.onloadend = () => {
        const base64String = reader.result as string;
        setImages((prev) =>
          prev.map((img) =>
            img.id === imageId ? { ...img, src: base64String, loading: false } : img
          )
        );
      };
      reader.readAsDataURL(file);
    });
  };

  const handleImageChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (!e.target.files) return;
    processImageFiles(Array.from(e.target.files));
  };

  const removeImage = (id: string) => {
    setImages((prev) => prev.filter((img) => img.id !== id));
  };

  // Drag and Drop Event Handlers
  const handleDragOver = (e: React.DragEvent) => {
    e.preventDefault();
    e.stopPropagation();
  };

  const handleDragEnter = (e: React.DragEvent) => {
    e.preventDefault();
    e.stopPropagation();
    setIsDragging(true);
  };

  const handleDragLeave = (e: React.DragEvent) => {
    e.preventDefault();
    e.stopPropagation();
    setIsDragging(false);
  };

  const handleDrop = (e: React.DragEvent) => {
    e.preventDefault();
    e.stopPropagation();
    setIsDragging(false);

    if (e.dataTransfer.files && e.dataTransfer.files.length > 0) {
      const droppedFiles = Array.from(e.dataTransfer.files).filter((file) =>
        file.type.startsWith("image/")
      );
      if (droppedFiles.length > 0) {
        processImageFiles(droppedFiles);
      }
    }
  };

  // Voice recording logic
  const startRecording = async () => {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      const recorder = new MediaRecorder(stream, { mimeType: "audio/webm" });
      audioChunksRef.current = [];

      recorder.ondataavailable = (e) => {
        if (e.data.size > 0) {
          audioChunksRef.current.push(e.data);
        }
      };

      recorder.onstop = async () => {
        const audioBlob = new Blob(audioChunksRef.current, { type: "audio/webm" });
        setIsTranscribing(true);
        try {
          const reader = new FileReader();
          reader.readAsDataURL(audioBlob);
          reader.onloadend = async () => {
            const base64data = (reader.result as string).split(",")[1];
            await transcribeAudio(base64data);
          };
        } catch (err) {
          console.error("Failed to read audio blob:", err);
          setIsTranscribing(false);
        }
      };

      recorder.start();
      mediaRecorderRef.current = recorder;
      setIsRecording(true);
      setStatusMessage("Listening...");
    } catch (err) {
      console.error("Error accessing microphone:", err);
      alert("Please check your microphone permissions.");
    }
  };

  const stopRecording = () => {
    if (mediaRecorderRef.current && isRecording) {
      mediaRecorderRef.current.stop();
      mediaRecorderRef.current.stream.getTracks().forEach((track) => track.stop());
      setIsRecording(false);
      setStatusMessage("Transcribing...");
    }
  };

  const cancelRecording = () => {
    if (mediaRecorderRef.current && isRecording) {
      mediaRecorderRef.current.onstop = null;
      mediaRecorderRef.current.stop();
      mediaRecorderRef.current.stream.getTracks().forEach((track) => track.stop());
      setIsRecording(false);
      setStatusMessage(null);
    }
  };

  const transcribeAudio = async (base64Audio: string) => {
    try {
      const transcribeAudioFn = httpsCallable(functions, "transcribeAudio");
      const result = await transcribeAudioFn({
        audioBase64: base64Audio,
        mimeType: "audio/webm"
      });
      const data = result.data as { text: string };
      if (data.text) {
        setFoodText((prev) => (prev ? `${prev} ${data.text}` : data.text));
      }
    } catch (err: any) {
      console.error("Transcription error:", err);
      alert(err.message || "Transcription failed. Please try again.");
    } finally {
      setIsTranscribing(false);
      setStatusMessage(null);
    }
  };

  // Submit Meal for AI Estimation
  const handleEstimateMeal = async () => {
    const loadedImages = images.filter((img) => !img.loading);
    if (!foodText.trim() && loadedImages.length === 0) return;
    setLoading(true);
    setLatestResult(null);
    setIsSaved(false);
    setStatusMessage("Estimating calories...");

    const logMealFn = httpsCallable(functions, "logMeal");
    
    // Strip metadata prefixes from base64 if present
    const cleanedImages = loadedImages.map((img) => img.src.split(",")[1] || img.src);

    try {
      const result = await logMealFn({
        foodText: foodText.trim(),
        mealType: mealType,
        imageBase64s: cleanedImages,
        country: "India" // Matches regional default in user demographics
      });
      
      setLatestResult(result.data as MealLogResponse);
    } catch (err: any) {
      console.error("Estimation failed:", err);
      alert(err.message || "Failed to log meal. Please check your internet connection.");
    } finally {
      setLoading(false);
      setStatusMessage(null);
    }
  };

  // Refine / Correct AI Estimation
  const handleRefineMeal = async () => {
    if (!correctionPrompt.trim() || !latestResult) return;
    setRefining(true);
    setStatusMessage("Refining estimate...");

    const refineMealLogFn = httpsCallable(functions, "refineMealLog");

    try {
      const result = await refineMealLogFn({
        foodText: foodText.trim(),
        mealType: latestResult.meal_type,
        correctionPrompt: correctionPrompt.trim(),
        previousEstimate: latestResult,
        country: "India"
      });

      setLatestResult(result.data as MealLogResponse);
      setCorrectionPrompt("");
    } catch (err: any) {
      console.error("Refine failed:", err);
      alert(err.message || "Failed to update estimate.");
    } finally {
      setRefining(false);
      setStatusMessage(null);
    }
  };

  // Finalize and Save Meal to Firestore
  const handleSaveMeal = async () => {
    if (!latestResult || !auth.currentUser) return;
    setLoading(true);
    setStatusMessage("Saving meal...");

    const userId = auth.currentUser.uid;
    const mealId = crypto.randomUUID();
    const timestampDate = new Date(selectedDate);
    
    // Set time component to current time
    const now = new Date();
    timestampDate.setHours(now.getHours(), now.getMinutes(), now.getSeconds());

    const loadedImages = images.filter((img) => !img.loading);

    const mealData = {
      id: mealId,
      timestamp: Timestamp.fromDate(timestampDate),
      createdAt: Timestamp.fromDate(new Date()),
      foodText: foodText.trim() || latestResult.items.map((i) => i.name).join(", "),
      mealType: latestResult.meal_type,
      totalCalories: latestResult.total_calories,
      rawResponseJson: JSON.stringify(latestResult),
      hasImage: loadedImages.length > 0
    };

    try {
      // 1. Save to users/{userId}/meals/{mealId}
      await setDoc(doc(db, "users", userId, "meals", mealId), mealData);

      // 2. Log non-critical analytics (mealLogs collection)
      const recordMealLogAnalyticsFn = httpsCallable(functions, "recordMealLogAnalytics");
      await recordMealLogAnalyticsFn({
        foodText: mealData.foodText,
        mealType: mealData.mealType,
        totalCalories: mealData.totalCalories,
        hasImage: mealData.hasImage
      });

      setIsSaved(true);
      // Reset logging workspace on success
      setFoodText("");
      setImages([]);
    } catch (err: any) {
      console.error("Error saving meal:", err);
      alert(err.message || "Failed to save meal to database.");
    } finally {
      setLoading(false);
      setStatusMessage(null);
    }
  };

  // Log a favorite meal with a serving size multiplier
  const handleLogFavorite = async (fav: any, multiplier: number) => {
    if (!auth.currentUser) return;
    setLoading(true);
    setStatusMessage(`Logging ${fav.title} (${multiplier}x)...`);
    setIsSaved(false);
    
    const userId = auth.currentUser.uid;
    const mealId = crypto.randomUUID();
    const timestampDate = new Date(selectedDate);
    const now = new Date();
    timestampDate.setHours(now.getHours(), now.getMinutes(), now.getSeconds());

    let parsedJson;
    try {
      parsedJson = JSON.parse(fav.rawResponseJson);
    } catch (e) {
      parsedJson = { items: [] };
    }

    // Scale items
    const multipliedItems = (parsedJson.items || []).map((item: any) => ({
      ...item,
      calories: Math.round((item.calories || 0) * multiplier),
      protein: item.protein !== undefined ? Math.round((item.protein || 0) * multiplier) : undefined,
      carbs: item.carbs !== undefined ? Math.round((item.carbs || 0) * multiplier) : undefined,
      fat: item.fat !== undefined ? Math.round((item.fat || 0) * multiplier) : undefined,
      quantity: `${item.quantity} (x${multiplier})`
    }));

    const multipliedResult = {
      meal_type: fav.mealType,
      total_calories: Math.round((fav.totalCalories || 0) * multiplier),
      protein: parsedJson.protein !== undefined ? Math.round((parsedJson.protein || 0) * multiplier) : undefined,
      carbs: parsedJson.carbs !== undefined ? Math.round((parsedJson.carbs || 0) * multiplier) : undefined,
      fat: parsedJson.fat !== undefined ? Math.round((parsedJson.fat || 0) * multiplier) : undefined,
      items: multipliedItems,
      needs_clarification: false
    };

    const mealData = {
      id: mealId,
      timestamp: Timestamp.fromDate(timestampDate),
      createdAt: Timestamp.fromDate(new Date()),
      foodText: `${fav.title} (${multiplier}x serving)`,
      mealType: fav.mealType,
      totalCalories: multipliedResult.total_calories,
      rawResponseJson: JSON.stringify(multipliedResult),
      hasImage: false
    };

    try {
      // 1. Save to users/{userId}/meals/{mealId}
      await setDoc(doc(db, "users", userId, "meals", mealId), mealData);
      
      // 2. Log analytics
      const recordMealLogAnalyticsFn = httpsCallable(functions, "recordMealLogAnalytics");
      await recordMealLogAnalyticsFn({
        foodText: mealData.foodText,
        mealType: mealData.mealType,
        totalCalories: mealData.totalCalories,
        hasImage: false
      });

      setIsSaved(true);
      setActiveFavorite(null);
    } catch (err: any) {
      console.error("Error logging favorite:", err);
      alert(err.message || "Failed to log favorite meal.");
    } finally {
      setLoading(false);
      setStatusMessage(null);
    }
  };

  // Add currently estimated meal to favorites in settings doc
  const handleSaveToFavorites = async () => {
    if (!latestResult || !auth.currentUser) return;
    setLoading(true);
    setStatusMessage("Saving to Favorites...");

    const userId = auth.currentUser.uid;
    const trimmed = foodText.trim();
    let title = "";
    if (trimmed && trimmed !== "Image uploaded") {
      title = trimmed.substring(0, 140);
    } else {
      const itemNames = latestResult.items
        .slice(0, 3)
        .map((i) => i.name)
        .filter(Boolean)
        .join(", ");
      title = itemNames ? itemNames.substring(0, 140) : `${latestResult.meal_type} Meal`;
    }

    const newFavorite = {
      id: crypto.randomUUID(),
      title: title,
      foodText: trimmed || title,
      mealType: latestResult.meal_type,
      totalCalories: latestResult.total_calories,
      rawResponseJson: JSON.stringify(latestResult)
    };

    try {
      const userDocRef = doc(db, "users", userId);
      const updatedFavorites = [...savedMeals.filter((f) => f.title !== newFavorite.title), newFavorite];
      
      await setDoc(userDocRef, { savedMeals: updatedFavorites }, { merge: true });
      setSavedMeals(updatedFavorites);
      alert("Added to Favorites!");
    } catch (err: any) {
      console.error("Error saving favorite:", err);
      alert(err.message || "Failed to save to favorites.");
    } finally {
      setLoading(false);
      setStatusMessage(null);
    }
  };

  // Resolve macros for rendering
  const resolvedMacros = () => {
    if (!latestResult) return null;
    let protein = latestResult.protein || 0;
    let carbs = latestResult.carbs || 0;
    let fat = latestResult.fat || 0;

    // If top-level macros are missing, aggregate from individual items
    if (protein === 0 && carbs === 0 && fat === 0) {
      latestResult.items.forEach((item) => {
        protein += item.protein || 0;
        carbs += item.carbs || 0;
        fat += item.fat || 0;
      });
    }

    return { protein, carbs, fat };
  };

  return (
    <div style={{ maxWidth: "800px", width: "100%", margin: "0 auto" }}>
      {/* Date & Meal Type Selectors */}
      <div className="log-title-row" style={{ marginBottom: "20px" }}>
        <div className="date-meal-bar">
          <div style={{ display: "flex", alignItems: "center", border: "1px solid var(--line)", borderRadius: "var(--radius-card)", background: "var(--panel)" }}>
            <button
              onClick={() => changeDateByDays(-1)}
              style={{ background: "transparent", border: "none", cursor: "pointer", padding: "8px 12px", color: "var(--muted)" }}
              type="button"
            >
              &larr;
            </button>
            <input
              type="date"
              value={selectedDate}
              onChange={(e) => setSelectedDate(e.target.value)}
              style={{ border: "none", background: "transparent", fontWeight: 700, padding: "8px 4px", fontSize: "14px", outline: "none" }}
            />
            <button
              onClick={() => changeDateByDays(1)}
              style={{ background: "transparent", border: "none", cursor: "pointer", padding: "8px 12px", color: "var(--muted)" }}
              type="button"
            >
              &rarr;
            </button>
          </div>

          <select
            value={mealType}
            onChange={(e) => setMealType(e.target.value)}
            className="picker-select"
          >
            <option value="breakfast">Breakfast</option>
            <option value="lunch">Lunch</option>
            <option value="dinner">Dinner</option>
            <option value="snack">Snack</option>
          </select>
        </div>
      </div>

      {/* Favorites Tray */}
      {savedMeals.length > 0 && (
        <div className="favorites-container">
          <div className="favorites-label">
            <Star size={14} fill="var(--muted)" style={{ color: "var(--muted)" }} />
            <span>Quick Favorites</span>
          </div>
          <div className="favorites-tray">
            {savedMeals.map((fav) => {
              let displayCal = fav.totalCalories;
              return (
                <div
                  className="favorite-chip"
                  key={fav.id}
                  onClick={() => setActiveFavorite(fav)}
                >
                  <span className="favorite-chip-title">{fav.title}</span>
                  <span className="favorite-chip-cal">{Math.round(displayCal)} cal</span>
                </div>
              );
            })}
          </div>
        </div>
      )}

      {/* Main Composer Card */}
      <div className="glass-card composer-card">
        <div
          className={`composer-textarea-wrap ${isDragging ? "dragging" : ""}`}
          onDragOver={handleDragOver}
          onDragEnter={handleDragEnter}
          onDragLeave={handleDragLeave}
          onDrop={handleDrop}
        >
          <textarea
            value={foodText}
            onChange={(e) => setFoodText(e.target.value)}
            className="composer-textarea"
            placeholder="Write or speak naturally about what you ate... (or drag & drop images here)"
            disabled={isRecording || isTranscribing}
          />

          {images.length > 0 && (
            <div className="image-previews">
              {images.map((img) => (
                <div className={`image-preview-item ${img.loading ? "image-loading" : ""}`} key={img.id}>
                  {img.loading ? (
                    <div className="image-preview-spinner" />
                  ) : (
                    <img src={img.src} alt="meal attachment" />
                  )}
                  <button
                    onClick={() => removeImage(img.id)}
                    className="image-preview-remove"
                    type="button"
                  >
                    <X size={12} />
                  </button>
                </div>
              ))}
            </div>
          )}
        </div>

        {/* Hidden File Input */}
        <input
          type="file"
          accept="image/*"
          multiple
          ref={fileInputRef}
          onChange={handleImageChange}
          style={{ display: "none" }}
        />

        {/* Footer controls row */}
        <div className="composer-controls">
          <div className="composer-actions-left">
            {isRecording ? (
              <div className="recording-bar">
                <button
                  onClick={cancelRecording}
                  style={{ background: "transparent", border: "none", color: "#ff4d4d", cursor: "pointer", display: "flex", alignItems: "center" }}
                  title="Cancel Recording"
                  type="button"
                >
                  <X size={16} />
                </button>
                <div className="voice-wave-container">
                  <div className="voice-wave-bar" />
                  <div className="voice-wave-bar" />
                  <div className="voice-wave-bar" />
                  <div className="voice-wave-bar" />
                  <div className="voice-wave-bar" />
                </div>
                <span>Recording...</span>
                <button
                  onClick={stopRecording}
                  style={{ background: "transparent", border: "none", color: "var(--green)", cursor: "pointer", display: "flex", alignItems: "center", marginLeft: "8px" }}
                  title="Done Recording"
                  type="button"
                >
                  <Check size={16} />
                </button>
              </div>
            ) : (
              <>
                <button
                  onClick={handleImageClick}
                  className="icon-btn"
                  title="Attach Photo"
                  disabled={images.length >= 3 || isTranscribing}
                  type="button"
                >
                  <Camera size={20} />
                </button>
                <button
                  onClick={startRecording}
                  className="icon-btn"
                  style={{ background: "linear-gradient(135deg, #ff9f43, #ff793f)", color: "white", border: "none" }}
                  title="Voice Log"
                  disabled={isTranscribing}
                  type="button"
                >
                  <Mic size={20} />
                </button>
              </>
            )}
            
            {isTranscribing && (
              <span style={{ fontSize: "14px", color: "var(--muted)", display: "flex", alignItems: "center", fontWeight: 700 }}>
                Transcribing audio...
              </span>
            )}
          </div>

          <div className="composer-actions-right">
            <button
              onClick={handleEstimateMeal}
              disabled={loading || isRecording || isTranscribing || (!foodText.trim() && images.filter(img => !img.loading).length === 0)}
              className="primary-btn"
              type="button"
            >
              {loading ? "Analyzing..." : "Log Meal"}
            </button>
          </div>
        </div>
      </div>

      {statusMessage && (
        <div style={{ textAlign: "center", margin: "20px 0", color: "var(--green)", fontWeight: 800, display: "flex", alignItems: "center", justifyContent: "center", gap: "8px" }}>
          <Sparkles size={18} className="animate-pulse" />
          <span>{statusMessage}</span>
        </div>
      )}

      {/* Logging Results Card */}
      {latestResult && (
        <div className="glass-card result-card">
          <div className="result-header">
            <div>
              <span className="result-badge">{latestResult.meal_type}</span>
              <div className="result-calories">
                <div className="calories-val">{Math.round(latestResult.total_calories)}</div>
                <div className="calories-lbl">ESTIMATED CALORIES</div>
              </div>
            </div>
            
            <div className="result-actions" style={{ display: "flex", gap: "8px" }}>
              <button
                onClick={handleSaveToFavorites}
                className="icon-btn"
                style={{ background: "transparent", color: "#e0a800", borderColor: "#f3c022", display: "flex", alignItems: "center", justifyContent: "center" }}
                disabled={loading}
                title="Add to Favorites"
                type="button"
              >
                <Star size={18} fill="#f3c022" />
              </button>
              <button
                onClick={handleSaveMeal}
                className="primary-btn"
                style={{ display: "flex", alignItems: "center", gap: "8px", padding: "10px 24px" }}
                disabled={loading}
                type="button"
              >
                <Bookmark size={16} />
                <span>Save Entry</span>
              </button>
            </div>
          </div>

          {/* Macros */}
          {resolvedMacros() && (
            <div className="macros-grid">
              <div className="macro-pill macro-protein">
                <div className="macro-dot" />
                <span>{Math.round(resolvedMacros()!.protein)}g Protein</span>
              </div>
              <div className="macro-pill macro-carbs">
                <div className="macro-dot" />
                <span>{Math.round(resolvedMacros()!.carbs)}g Carbs</span>
              </div>
              <div className="macro-pill macro-fat">
                <div className="macro-dot" />
                <span>{Math.round(resolvedMacros()!.fat)}g Fat</span>
              </div>
            </div>
          )}

          <hr style={{ border: "none", borderTop: "1px solid var(--line)", margin: "24px 0" }} />

          {/* Ingredients Breakdown */}
          <div className="breakdown-title">Items Breakdown</div>
          <div className="breakdown-list">
            {latestResult.items.map((item, idx) => (
              <div className="breakdown-item" key={idx}>
                <div className="breakdown-item-main">
                  <span>{item.name}</span>
                  <span>{Math.round(item.calories)} cal</span>
                </div>
                <div className="breakdown-item-qty">{item.quantity}</div>
                <div className="breakdown-item-details">
                  {item.protein !== undefined && <span>P: {Math.round(item.protein)}g</span>}
                  {item.carbs !== undefined && <span>C: {Math.round(item.carbs)}g</span>}
                  {item.fat !== undefined && <span>F: {Math.round(item.fat)}g</span>}
                  {item.confidence !== undefined && <span>Confidence: {Math.round(item.confidence * 100)}%</span>}
                </div>
                {item.assumptions && (
                  <div className="breakdown-item-details breakdown-item-assumption">
                    &bull; {item.assumptions}
                  </div>
                )}
              </div>
            ))}
          </div>

          {/* Correction input box */}
          <div className="refine-card">
            <div className="refine-title">Make a correction</div>
            <div className="refine-input-row">
              <input
                type="text"
                value={correctionPrompt}
                onChange={(e) => setCorrectionPrompt(e.target.value)}
                placeholder="e.g. 'I actually had 2 eggs' or 'adjust the quantity to 200g'..."
                className="refine-input"
                disabled={refining}
                onKeyDown={(e) => e.key === "Enter" && handleRefineMeal()}
              />
              <button
                onClick={handleRefineMeal}
                className="icon-btn"
                style={{ background: "var(--green)", color: "white", borderColor: "var(--green)" }}
                disabled={refining || !correctionPrompt.trim()}
                type="button"
              >
                <Send size={18} />
              </button>
            </div>
          </div>
        </div>
      )}

      {isSaved && (
        <div className="glass-card" style={{ background: "var(--green-soft)", border: "1px solid var(--green-line)", display: "flex", alignItems: "center", gap: "16px", padding: "20px 24px" }}>
          <div style={{ width: "32px", height: "32px", borderRadius: "50%", background: "var(--green)", color: "white", display: "flex", alignItems: "center", justifyContent: "center" }}>
            <Check size={18} />
          </div>
          <div>
            <div style={{ fontWeight: 800, color: "var(--green)", fontSize: "16px" }}>Meal Saved Successfully!</div>
            <div style={{ fontSize: "14px", color: "var(--muted)", marginTop: "2px" }}>Your calories and macros have been recorded for today.</div>
          </div>
        </div>
      )}

      {/* Multiplier Selector Popover */}
      {activeFavorite && (
        <div className="multiplier-overlay" onClick={() => setActiveFavorite(null)}>
          <div className="multiplier-card" onClick={(e) => e.stopPropagation()}>
            <h4>Log Serving Size</h4>
            <p>Select portion multiplier for "{activeFavorite.title}"</p>
            
            <div className="multiplier-grid">
              {[0.5, 1.0, 1.5, 2.0].map((mult) => {
                const scaledCalories = Math.round(activeFavorite.totalCalories * mult);
                return (
                  <button
                    key={mult}
                    onClick={() => handleLogFavorite(activeFavorite, mult)}
                    className="multiplier-btn"
                    type="button"
                  >
                    <span>{mult === 1.0 ? "1.0x (Regular)" : `${mult}x`}</span>
                    <span className="multiplier-btn-cal">{scaledCalories} cal</span>
                  </button>
                );
              })}
            </div>
            
            <button
              onClick={() => setActiveFavorite(null)}
              className="multiplier-cancel-btn"
              type="button"
            >
              Cancel
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
