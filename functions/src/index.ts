import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

// Initialize Firebase Admin
admin.initializeApp();

// OpenAI API configuration
// API key is loaded from Firebase Secrets at runtime
const OPENAI_API_URL = "https://api.openai.com/v1/chat/completions";
const OPENAI_MODEL = "gpt-4o-2024-08-06";
const OPENAI_TEMPERATURE = 0.3;

// Rate limiting configuration
const MAX_REQUESTS_PER_DAY = 100; // Per user
const MAX_REQUESTS_PER_MINUTE = 10; // Per user

interface LogMealRequest {
  foodText: string;
  mealType: string;
  imageBase64?: string; // Optional base64-encoded image
  country?: string; // Optional country name (e.g., "India", "United States")
}

interface MealLogResponse {
  meal_type: string;
  total_calories: number;
  protein?: number;  // grams
  carbs?: number;    // grams
  fat?: number;      // grams
  items: Array<{
    name: string;
    quantity: string;
    calories: number;
    protein?: number;  // grams
    carbs?: number;    // grams
    fat?: number;      // grams
    assumptions?: string;
    confidence: number;
  }>;
  needs_clarification: boolean;
  clarifying_question: string;
}

/**
 * Track user usage for rate limiting
 * Returns { allowed: true } if Firestore is not available (graceful degradation)
 */
async function trackUsage(uid: string): Promise<{ allowed: boolean; reason?: string }> {
  try {
    const now = Date.now();
    const oneMinuteAgo = now - 60 * 1000;
    const oneDayAgo = now - 24 * 60 * 60 * 1000;

    const userRef = admin.firestore().collection("usage").doc(uid);
    const userDoc = await userRef.get();

    if (!userDoc.exists) {
      // First request - initialize
      await userRef.set({
        requests: [now],
        lastRequest: now,
      });
      return { allowed: true };
    }

    const data = userDoc.data()!;
    const requests = (data.requests as number[]) || [];

    // Filter requests within time windows
    const requestsLastMinute = requests.filter((t) => t > oneMinuteAgo);
    const requestsLastDay = requests.filter((t) => t > oneDayAgo);

    // Check rate limits
    if (requestsLastMinute.length >= MAX_REQUESTS_PER_MINUTE) {
      return {
        allowed: false,
        reason: "Rate limit exceeded. Please try again in a minute.",
      };
    }

    if (requestsLastDay.length >= MAX_REQUESTS_PER_DAY) {
      return {
        allowed: false,
        reason: "Daily limit exceeded. Please try again tomorrow.",
      };
    }

    // Update usage tracking
    requests.push(now);
    // Keep only last 24 hours of requests
    const recentRequests = requests.filter((t) => t > oneDayAgo);

    await userRef.update({
      requests: recentRequests,
      lastRequest: now,
    });

    return { allowed: true };
  } catch (error: any) {
    // If Firestore is not available, allow the request (graceful degradation)
    // Log the error but don't fail the function
    console.warn("WARNING: Firestore not available for rate limiting. Allowing request. Error:", error.message || error);
    return { allowed: true };
  }
}

/**
 * Call OpenAI API to log a meal
 */
async function callOpenAI(foodText: string, mealType: string, imageBase64?: string, country?: string): Promise<MealLogResponse> {
  console.log("DEBUG: callOpenAI function called");
  console.log("DEBUG: hasImage =", imageBase64 ? "yes" : "no");
  console.log("DEBUG: country =", country || "not provided");
  
  // Get API key from Firebase Secrets (set via functions:secrets:set)
  const apiKey = process.env.OPENAI_API_KEY;
  
  if (!apiKey) {
    console.error("ERROR: OPENAI_API_KEY is not set in environment variables");
    console.error("ERROR: process.env.OPENAI_API_KEY is:", process.env.OPENAI_API_KEY);
    console.error("ERROR: This usually means the function was deployed before the secret was set, or the secret name is incorrect");
    throw new functions.https.HttpsError(
      "internal",
      "OpenAI API key not configured. Please set OPENAI_API_KEY secret using: firebase functions:secrets:set OPENAI_API_KEY, then redeploy the function."
    );
  }
  
  console.log("DEBUG: API key is configured (length: " + apiKey.length + ", starts with: " + apiKey.substring(0, 7) + "...)");

  // Build system prompt based on country
  let systemPrompt: string;
  if (country && country.trim().length > 0) {
    systemPrompt = `You are a calorie logging assistant for ${country} food. When given a food description or image, estimate calories and macronutrients (protein, carbs, fat in grams) based on typical ${country} portion sizes and regional cuisine. Use the provided meal type. Never ask for clarifications - always set needs_clarification to false and clarifying_question to an empty string. Provide detailed breakdowns of items with quantities, calories, macronutrients, assumptions, and confidence scores.`;
  } else {
    systemPrompt = `You are a calorie logging assistant. When given a food description or image, estimate calories and macronutrients (protein, carbs, fat in grams) based on typical portion sizes. Use the provided meal type. Never ask for clarifications - always set needs_clarification to false and clarifying_question to an empty string. Provide detailed breakdowns of items with quantities, calories, macronutrients, assumptions, and confidence scores.`;
  }
  
  console.log("DEBUG: System prompt:", systemPrompt);

  // Build user message content array for Vision API
  const userContent: Array<{ type: string; text?: string; image_url?: { url: string } }> = [];
  
  // Add text if provided
  if (foodText && foodText.trim().length > 0) {
    userContent.push({
      type: "text",
      text: `Food description: ${foodText}\nMeal type: ${mealType}`
    });
  } else {
    // If no text, still include meal type
    userContent.push({
      type: "text",
      text: `Meal type: ${mealType}`
    });
  }
  
  // Add image if provided
  if (imageBase64) {
    // Ensure it has the data URI prefix
    const imageUrl = imageBase64.startsWith("data:") ? imageBase64 : `data:image/jpeg;base64,${imageBase64}`;
    userContent.push({
      type: "image_url",
      image_url: {
        url: imageUrl
      }
    });
    console.log("DEBUG: Image added to request, base64 length:", imageBase64.length);
  }

  const jsonSchema = {
    name: "meal_log",
    schema: {
      type: "object",
      additionalProperties: false,
      properties: {
        meal_type: {
          type: "string",
          enum: ["breakfast", "lunch", "dinner", "snack"],
        },
        total_calories: { type: "number" },
        protein: { type: "number" },
        carbs: { type: "number" },
        fat: { type: "number" },
        items: {
          type: "array",
          items: {
            type: "object",
            additionalProperties: false,
            properties: {
              name: { type: "string" },
              quantity: { type: "string" },
              calories: { type: "number" },
              protein: { type: "number" },
              carbs: { type: "number" },
              fat: { type: "number" },
              assumptions: { type: "string" },
              confidence: { type: "number" },
            },
            required: ["name", "quantity", "calories", "confidence"],
          },
        },
        needs_clarification: { type: "boolean" },
        clarifying_question: { type: "string" },
      },
      required: ["meal_type", "total_calories", "items", "needs_clarification"],
    },
  };

  const requestBody = {
    model: OPENAI_MODEL,
    temperature: OPENAI_TEMPERATURE,
    messages: [
      { role: "system", content: systemPrompt },
      { role: "user", content: userContent },
    ],
    response_format: {
      type: "json_schema",
      json_schema: jsonSchema,
    },
  };

  // Use global fetch (available in Node.js 18+)
  console.log("DEBUG: Sending request to OpenAI API...");
  let response;
  try {
    response = await fetch(OPENAI_API_URL, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(requestBody),
    });
    console.log("DEBUG: OpenAI API response status:", response.status);
  } catch (fetchError: any) {
    console.error("ERROR: Failed to fetch from OpenAI API:", fetchError);
    throw new functions.https.HttpsError(
      "internal",
      `Failed to connect to OpenAI API: ${fetchError.message || "Unknown network error"}`
    );
  }

  if (!response.ok) {
    const errorText = await response.text();
    console.error("ERROR: OpenAI API returned error status:", response.status);
    console.error("ERROR: OpenAI API error response:", errorText);
    throw new functions.https.HttpsError(
      "internal",
      `OpenAI API error: ${response.status} - ${errorText}`
    );
  }

  const data = await response.json();
  const content = data.choices?.[0]?.message?.content;

  if (!content) {
    throw new functions.https.HttpsError(
      "internal",
      "Invalid response from OpenAI API"
    );
  }

  return JSON.parse(content) as MealLogResponse;
}

/**
 * Firebase Function to log a meal
 * Requires authentication
 * 
 * To set the OpenAI API key:
 * firebase functions:secrets:set OPENAI_API_KEY
 */
export const logMeal = functions.runWith({
  secrets: ["OPENAI_API_KEY"],
}).https.onCall(
  async (data: LogMealRequest, context) => {
    console.log("DEBUG: logMeal function called");
    
    // Verify authentication
    if (!context.auth) {
      console.error("Unauthenticated call to logMeal function.");
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated"
      );
    }

    const uid = context.auth.uid;
    console.log("DEBUG: Authenticated user UID:", uid);
    const { foodText, mealType, imageBase64, country } = data;
    console.log("DEBUG: Request data - foodText:", foodText, "mealType:", mealType, "hasImage:", !!imageBase64, "country:", country || "not provided");

    // Validate input - either foodText or imageBase64 must be provided
    const hasText = foodText && typeof foodText === "string" && foodText.trim().length > 0;
    const hasImage = imageBase64 && typeof imageBase64 === "string" && imageBase64.length > 0;
    
    if (!hasText && !hasImage) {
      console.error("Invalid argument: Both foodText and imageBase64 are missing or empty for UID:", uid);
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Either foodText or imageBase64 must be provided"
      );
    }

    if (!mealType || typeof mealType !== "string") {
      console.error("Invalid argument: mealType is missing for UID:", uid);
      throw new functions.https.HttpsError(
        "invalid-argument",
        "mealType is required"
      );
    }

    // Check rate limits
    console.log("DEBUG: Checking rate limits for UID:", uid);
    const usageCheck = await trackUsage(uid);
    if (!usageCheck.allowed) {
      console.warn("Rate limit exceeded for UID:", uid, "Reason:", usageCheck.reason);
      throw new functions.https.HttpsError(
        "resource-exhausted",
        usageCheck.reason || "Rate limit exceeded"
      );
    }
    console.log("DEBUG: Rate limit check passed");

    try {
      // Call OpenAI API
      console.log("DEBUG: Calling OpenAI API...");
      const response = await callOpenAI(
        hasText ? foodText.trim() : "",
        mealType,
        hasImage ? imageBase64 : undefined,
        country
      );
      console.log("DEBUG: OpenAI API call successful, total calories:", response.total_calories);

      // Log successful request to Firestore (optional - for analytics)
      // Don't fail if Firestore write fails - just log it
      try {
        await admin.firestore().collection("mealLogs").add({
          uid,
          foodText: hasText ? foodText.trim() : "",
          mealType,
          totalCalories: response.total_calories,
          hasImage: hasImage,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });
        console.log("DEBUG: Successfully logged meal to Firestore");
      } catch (firestoreError: any) {
        // Firestore might not be initialized - that's okay, this is just for analytics
        console.warn("WARNING: Failed to write to Firestore (non-critical). Firestore may not be initialized. Error:", firestoreError.message || firestoreError);
        // Continue - this is just for analytics, not critical for the function
      }

      console.log("DEBUG: logMeal function completed successfully");
      return response;
    } catch (error: any) {
      console.error("ERROR: Error in logMeal function for UID:", uid);
      console.error("ERROR: Error type:", error?.constructor?.name || typeof error);
      console.error("ERROR: Error message:", error?.message || "No message");
      console.error("ERROR: Error stack:", error?.stack || "No stack");
      
      // Log full error details
      if (error instanceof Error) {
        console.error("ERROR: Full error:", JSON.stringify({
          name: error.name,
          message: error.message,
          stack: error.stack
        }, null, 2));
      } else {
        console.error("ERROR: Error object:", JSON.stringify(error, null, 2));
      }
      
      if (error instanceof functions.https.HttpsError) {
        console.error("ERROR: Re-throwing HttpsError:", error.message);
        throw error;
      }

      // Provide more detailed error message
      const errorMessage = error?.message || error?.toString() || "Unknown error occurred";
      console.error("ERROR: Throwing new HttpsError with message:", errorMessage);
      throw new functions.https.HttpsError(
        "internal",
        `Firebase Function error: ${errorMessage}. Check function logs for details.`
      );
    }
  }
);

/**
 * Health check function (no auth required)
 */
export const healthCheck = functions.https.onRequest((req, res) => {
  res.json({
    status: "ok",
    timestamp: new Date().toISOString(),
    service: "logcal-functions",
  });
});

