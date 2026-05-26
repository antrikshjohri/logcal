import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

// Initialize Firebase Admin
admin.initializeApp();

// OpenAI API configuration
// API key is loaded from Firebase Secrets at runtime
const OPENAI_API_URL = "https://api.openai.com/v1/chat/completions";
const OPENAI_MODEL = "gpt-4o-2024-08-06";
const OPENAI_TEMPERATURE = 0.3;
const FUNCTIONS_REGION = "asia-southeast1";

// Rate limiting configuration
const MAX_REQUESTS_PER_DAY = 100; // Per user (logMeal)
const MAX_REQUESTS_PER_MINUTE = 10; // Per user (logMeal)

const MAX_TRANSCRIBE_PER_DAY = 200; // Per user (speech-to-text / transcribeAudio)
const MAX_TRANSCRIBE_PER_MINUTE = 40; // Per user

// New app launch: disable custom Firestore-backed rate limits for now.
// Firebase/OpenAI quota and billing controls still apply. Re-enable with a faster
// counter-based limiter if usage or abuse risk increases.
const ENABLE_CUSTOM_RATE_LIMITS = false;

const MAX_TRANSCRIBE_AUDIO_BYTES = 4 * 1024 * 1024; // 4 MB — meal dictation clips
const WHISPER_TRANSCRIBE_MODEL = "gpt-4o-mini-transcribe";

/** Speech-to-text `prompt`: nudges vocabulary toward meal logging (works best when audio is English or mixed with English food terms). */
const WHISPER_MEAL_CONTEXT_PROMPT =
  "The speaker is logging a meal: what they ate or drank, ingredients, and portions. Typical terms: breakfast, lunch, dinner, snack, calories, protein, carbs, fat, rice, roti, bread, dal, curry, chicken, fish, eggs, salad, vegetables, fruit, yogurt, coffee, tea, juice, water.";

interface LogMealRequest {
  foodText: string;
  mealType: string;
  imageBase64?: string; // Optional base64-encoded image
  imageBase64s?: string[]; // Optional base64-encoded images
  country?: string; // Optional country name (e.g., "India", "United States")
}

interface TranscribeAudioRequest {
  audioBase64: string;
  mimeType?: string; // e.g. audio/m4a
  /** ISO 639-1 (e.g. en, hi). Omit or "auto" for Whisper auto-detect. */
  language?: string;
}

interface MealAnalyticsRequest {
  foodText?: string;
  mealType?: string;
  totalCalories?: number;
  hasImage?: boolean;
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

interface PerfMark {
  stage: string;
  deltaMs: number;
  totalMs: number;
  metadata?: Record<string, unknown>;
}

interface PerfSummary {
  label: string;
  totalMs: number;
  marks: PerfMark[];
}

class BackendPerf {
  private readonly startTime = Date.now();
  private lastMarkTime = this.startTime;
  private readonly marks: PerfMark[] = [];

  constructor(private readonly label: string) {
    console.log(`PERF [backend_${label}] start`);
  }

  mark(stage: string, metadata?: Record<string, unknown>): void {
    const now = Date.now();
    const mark: PerfMark = {
      stage,
      deltaMs: now - this.lastMarkTime,
      totalMs: now - this.startTime,
      ...(metadata ? { metadata } : {}),
    };
    this.lastMarkTime = now;
    this.marks.push(mark);
    console.log(
      `PERF [backend_${this.label}] ${stage} +${mark.deltaMs}ms total=${mark.totalMs}ms`,
      metadata || {}
    );
  }

  end(stage: string, metadata?: Record<string, unknown>): PerfSummary {
    this.mark(stage, metadata);
    const summary = {
      label: this.label,
      totalMs: Date.now() - this.startTime,
      marks: this.marks,
    };
    console.log(`PERF [backend_${this.label}] end total=${summary.totalMs}ms`);
    return summary;
  }
}

/** Shared JSON schema for meal_log responses (log + refine). */
const MEAL_LOG_JSON_SCHEMA = {
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

/**
 * Track user usage for rate limiting
 * Returns { allowed: true } if Firestore is not available (graceful degradation)
 */
async function trackUsage(uid: string, perf?: BackendPerf): Promise<{ allowed: boolean; reason?: string }> {
  try {
    const now = Date.now();
    const oneMinuteAgo = now - 60 * 1000;
    const oneDayAgo = now - 24 * 60 * 60 * 1000;

    const userRef = admin.firestore().collection("usage").doc(uid);
    const userDoc = await userRef.get();
    perf?.mark("rate_limit_doc_read");

    if (!userDoc.exists) {
      // First request - initialize
      await userRef.set({
        requests: [now],
        lastRequest: now,
      });
      perf?.mark("rate_limit_doc_created");
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
    perf?.mark("rate_limit_doc_updated", {
      requestsLastDay: requestsLastDay.length,
      requestsLastMinute: requestsLastMinute.length,
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
 * Rate limits for Whisper / transcribeAudio (separate from logMeal).
 */
async function trackTranscribeUsage(uid: string, perf?: BackendPerf): Promise<{ allowed: boolean; reason?: string }> {
  try {
    const now = Date.now();
    const oneMinuteAgo = now - 60 * 1000;
    const oneDayAgo = now - 24 * 60 * 60 * 1000;

    const userRef = admin.firestore().collection("usage").doc(uid);
    const userDoc = await userRef.get();
    perf?.mark("transcribe_rate_limit_doc_read");

    if (!userDoc.exists) {
      await userRef.set({
        requests: [],
        transcribeRequests: [now],
        lastTranscribeRequest: now,
      });
      perf?.mark("transcribe_rate_limit_doc_created");
      return { allowed: true };
    }

    const data = userDoc.data()!;
    const requests = (data.transcribeRequests as number[]) || [];

    const requestsLastMinute = requests.filter((t) => t > oneMinuteAgo);
    const requestsLastDay = requests.filter((t) => t > oneDayAgo);

    if (requestsLastMinute.length >= MAX_TRANSCRIBE_PER_MINUTE) {
      return {
        allowed: false,
        reason: "Transcription rate limit exceeded. Please try again in a minute.",
      };
    }

    if (requestsLastDay.length >= MAX_TRANSCRIBE_PER_DAY) {
      return {
        allowed: false,
        reason: "Daily transcription limit exceeded. Please try again tomorrow.",
      };
    }

    requests.push(now);
    const recentRequests = requests.filter((t) => t > oneDayAgo);

    await userRef.update({
      transcribeRequests: recentRequests,
      lastTranscribeRequest: now,
    });
    perf?.mark("transcribe_rate_limit_doc_updated", {
      requestsLastDay: requestsLastDay.length,
      requestsLastMinute: requestsLastMinute.length,
    });

    return { allowed: true };
  } catch (error: any) {
    console.warn(
      "WARNING: Firestore not available for transcribe rate limiting. Allowing request. Error:",
      error.message || error
    );
    return { allowed: true };
  }
}

/**
 * Call OpenAI Whisper API (multipart) — API key stays on server.
 */
/** Whisper `language` param: ISO 639-1 style; omit for auto-detect. */
function normalizeWhisperLanguage(code: unknown): string | undefined {
  if (typeof code !== "string") {
    return undefined;
  }
  let t = code.trim().toLowerCase();
  if (t === "" || t === "auto") {
    return undefined;
  }
  if (t.includes("-")) {
    t = t.split("-")[0] ?? t;
  }
  if (!/^[a-z]{2,3}$/.test(t)) {
    console.warn("DEBUG: Ignoring invalid whisper language code:", code);
    return undefined;
  }
  return t;
}

async function callOpenAIWhisperTranscription(
  audioBuffer: Buffer,
  filename: string,
  mimeType: string,
  language?: string,
  perf?: BackendPerf
): Promise<string> {
  const apiKey = process.env.OPENAI_API_KEY;

  if (!apiKey) {
    console.error("ERROR: OPENAI_API_KEY is not set for transcribeAudio");
    throw new functions.https.HttpsError(
      "internal",
      "OpenAI API key not configured."
    );
  }

  const formData = new FormData();
  const blob = new Blob([new Uint8Array(audioBuffer)], { type: mimeType });
  formData.append("file", blob, filename);
  formData.append("model", WHISPER_TRANSCRIBE_MODEL);
  if (language) {
    formData.append("language", language);
  }
  formData.append("prompt", WHISPER_MEAL_CONTEXT_PROMPT);

  console.log(
    "DEBUG: transcribeAudio calling OpenAI Whisper, bytes=",
    audioBuffer.length,
    "model=",
    WHISPER_TRANSCRIBE_MODEL,
    "language=",
    language || "(auto)",
    "mealContextPrompt=yes"
  );

  perf?.mark("openai_transcription_request_start", {
    bytes: audioBuffer.length,
    language: language || "auto",
    model: WHISPER_TRANSCRIBE_MODEL,
  });
  const response = await fetch("https://api.openai.com/v1/audio/transcriptions", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${apiKey}`,
    },
    body: formData,
  });
  perf?.mark("openai_transcription_response_headers", {
    status: response.status,
  });

  if (!response.ok) {
    const errorText = await response.text();
    console.error("ERROR: Whisper API status:", response.status, errorText);
    throw new functions.https.HttpsError(
      "internal",
      `Transcription service error: ${response.status}`
    );
  }

  const body = (await response.json()) as { text?: string };
  const text = (body.text || "").trim();
  perf?.mark("openai_transcription_body_parsed", {
    chars: text.length,
  });
  console.log("DEBUG: Whisper transcription length:", text.length);
  return text;
}

/**
 * Call OpenAI API to log a meal
 */
async function callOpenAI(
  foodText: string,
  mealType: string,
  imageBase64?: string,
  imageBase64s?: string[],
  country?: string,
  perf?: BackendPerf
): Promise<MealLogResponse> {
  console.log("DEBUG: callOpenAI function called");
  const images = imageBase64s && imageBase64s.length > 0 ? imageBase64s : imageBase64 ? [imageBase64] : [];
  console.log("DEBUG: imageCount =", images.length);
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
    systemPrompt = `You are a calorie logging assistant for ${country} food. When given a food description or image, estimate calories and macronutrients (protein, carbs, fat in grams) based on typical ${country} portion sizes and regional cuisine. Use the provided meal type. Never ask for clarifications - always set needs_clarification to false and clarifying_question to an empty string. Provide detailed breakdowns of items with quantities, calories, macronutrients, assumptions, and confidence scores. The top-level protein, carbs, and fat must equal the sum of the same fields across all items (in grams). When both a written description and a photo are provided, you must use both together: identify foods and portion sizes from the photo, use the text for context; if they disagree on something visible in the image, trust the image for that detail. Each item's assumptions field should mention what you inferred from the photo (e.g. visible portion, condiments, cooking style) when a photo is present, not only generic text-based guesses.`;
  } else {
    systemPrompt = `You are a calorie logging assistant. When given a food description or image, estimate calories and macronutrients (protein, carbs, fat in grams) based on typical portion sizes. Use the provided meal type. Never ask for clarifications - always set needs_clarification to false and clarifying_question to an empty string. Provide detailed breakdowns of items with quantities, calories, macronutrients, assumptions, and confidence scores. The top-level protein, carbs, and fat must equal the sum of the same fields across all items (in grams). When both a written description and a photo are provided, you must use both together: identify foods and portion sizes from the photo, use the text for context; if they disagree on something visible in the image, trust the image for that detail. Each item's assumptions field should mention what you inferred from the photo (e.g. visible portion, condiments, cooking style) when a photo is present, not only generic text-based guesses.`;
  }
  
  console.log("DEBUG: System prompt:", systemPrompt);

  // Build user message content array for Vision API
  const userContent: Array<{ type: string; text?: string; image_url?: { url: string } }> = [];
  
  // Add text if provided (same user message will also include image below when present — one multimodal request)
  if (foodText && foodText.trim().length > 0) {
    let text = `Food description: ${foodText}\nMeal type: ${mealType}`;
    if (images.length > 0) {
      text += `\n${images.length} photo(s) of this meal are attached in this message; combine them with the description above for estimates and assumptions.`;
    }
    userContent.push({
      type: "text",
      text,
    });
  } else {
    // If no text, still include meal type
    userContent.push({
      type: "text",
      text: `Meal type: ${mealType}`
    });
  }
  
  // Add images if provided
  for (const image of images) {
    // Ensure it has the data URI prefix
    const imageUrl = image.startsWith("data:") ? image : `data:image/jpeg;base64,${image}`;
    userContent.push({
      type: "image_url",
      image_url: {
        url: imageUrl
      }
    });
    console.log("DEBUG: Image added to request, base64 length:", image.length);
  }

  const requestBody = {
    model: OPENAI_MODEL,
    temperature: OPENAI_TEMPERATURE,
    messages: [
      { role: "system", content: systemPrompt },
      { role: "user", content: userContent },
    ],
    response_format: {
      type: "json_schema",
      json_schema: MEAL_LOG_JSON_SCHEMA,
    },
  };

  // Use global fetch (available in Node.js 18+)
  console.log("DEBUG: Sending request to OpenAI API...");
  let response;
  try {
    perf?.mark("openai_chat_request_start", {
      hasImage: !!imageBase64,
      imageCount: images.length,
      model: OPENAI_MODEL,
      textChars: foodText.length,
    });
    response = await fetch(OPENAI_API_URL, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(requestBody),
    });
    perf?.mark("openai_chat_response_headers", {
      status: response.status,
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
  perf?.mark("openai_chat_body_parsed");
  const content = data.choices?.[0]?.message?.content;

  if (!content) {
    throw new functions.https.HttpsError(
      "internal",
      "Invalid response from OpenAI API"
    );
  }

  const parsed = JSON.parse(content) as MealLogResponse;
  perf?.mark("openai_chat_content_decoded", {
    itemCount: parsed.items?.length || 0,
    totalCalories: parsed.total_calories,
  });
  return alignMealMacrosToItemSum(parsed);
}

/** Top-level P/C/F from the model can disagree with line items; when every item has macros, force totals to match the sum. */
function alignMealMacrosToItemSum(response: MealLogResponse): MealLogResponse {
  const items = response.items || [];
  if (items.length === 0) {
    return response;
  }
  const allComplete = items.every(
    (i) =>
      typeof i.protein === "number" &&
      !Number.isNaN(i.protein) &&
      typeof i.carbs === "number" &&
      !Number.isNaN(i.carbs) &&
      typeof i.fat === "number" &&
      !Number.isNaN(i.fat)
  );
  if (!allComplete) {
    console.log("DEBUG: alignMealMacrosToItemSum skipped — not all items have protein/carbs/fat");
    return response;
  }
  let p = 0;
  let c = 0;
  let f = 0;
  for (const i of items) {
    p += i.protein as number;
    c += i.carbs as number;
    f += i.fat as number;
  }
  console.log("DEBUG: alignMealMacrosToItemSum applied", { protein: p, carbs: c, fat: f, itemCount: items.length });
  return { ...response, protein: p, carbs: c, fat: f };
}

/**
 * Re-estimate a meal from the user's correction text (no image; uses prior JSON + description).
 */
async function callOpenAIRefineMeal(
  foodText: string,
  mealType: string,
  previousEstimate: MealLogResponse,
  correctionPrompt: string,
  country?: string
): Promise<MealLogResponse> {
  const apiKey = process.env.OPENAI_API_KEY;
  if (!apiKey) {
    throw new functions.https.HttpsError(
      "internal",
      "OpenAI API key not configured."
    );
  }

  let systemPrompt: string;
  if (country && country.trim().length > 0) {
    systemPrompt = `You are a calorie logging assistant for ${country} food. The user already has a structured meal estimate and wants to correct it. Apply their instructions: fix wrong foods, portions, cooking method, or macros. Output a complete new meal_log JSON. Set needs_clarification to false and clarifying_question to an empty string. Top-level protein, carbs, and fat must equal the sum of the same fields across all items (grams).`;
  } else {
    systemPrompt =
      "You are a calorie logging assistant. The user already has a structured meal estimate and wants to correct it. Apply their instructions: fix wrong foods, portions, cooking method, or macros. Output a complete new meal_log JSON. Set needs_clarification to false and clarifying_question to an empty string. Top-level protein, carbs, and fat must equal the sum of the same fields across all items (grams).";
  }

  const previousJson = JSON.stringify(previousEstimate);
  const userText = `Original user description (for context):\n${foodText.trim().length > 0 ? foodText.trim() : "(none or image-only log)"}\n\nMeal type: ${mealType}\n\nCurrent structured estimate (JSON):\n${previousJson}\n\nUser correction (apply these changes):\n${correctionPrompt.trim()}`;

  const requestBody = {
    model: OPENAI_MODEL,
    temperature: 0.25,
    messages: [
      { role: "system", content: systemPrompt },
      { role: "user", content: userText },
    ],
    response_format: {
      type: "json_schema",
      json_schema: MEAL_LOG_JSON_SCHEMA,
    },
  };

  console.log("DEBUG: callOpenAIRefineMeal request (chars):", userText.length);

  const response = await fetch(OPENAI_API_URL, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(requestBody),
  });

  if (!response.ok) {
    const errorText = await response.text();
    console.error("ERROR: refine OpenAI API status:", response.status, errorText);
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
      "Invalid response from OpenAI API (refine)"
    );
  }

  const parsed = JSON.parse(content) as MealLogResponse;
  console.log("DEBUG: callOpenAIRefineMeal done total_calories:", parsed.total_calories);
  return alignMealMacrosToItemSum(parsed);
}

/**
 * Firebase Function to log a meal
 * Requires authentication
 * 
 * To set the OpenAI API key:
 * firebase functions:secrets:set OPENAI_API_KEY
 */
export const logMeal = functions.region(FUNCTIONS_REGION).runWith({
  secrets: ["OPENAI_API_KEY"],
}).https.onCall(
  async (data: LogMealRequest, context) => {
    const perf = new BackendPerf("logMeal");
    console.log("DEBUG: logMeal function called");
    
    // Verify authentication
    if (!context.auth) {
      console.error("Unauthenticated call to logMeal function.");
      perf.end("unauthenticated");
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated"
      );
    }

    const uid = context.auth.uid;
    console.log("DEBUG: Authenticated user UID:", uid);
    const { foodText, mealType, imageBase64, imageBase64s, country } = data;
    const requestImages = Array.isArray(imageBase64s) && imageBase64s.length > 0
      ? imageBase64s.filter((image) => typeof image === "string" && image.length > 0).slice(0, 4)
      : (typeof imageBase64 === "string" && imageBase64.length > 0 ? [imageBase64] : []);
    console.log("DEBUG: Request data - foodText:", foodText, "mealType:", mealType, "imageCount:", requestImages.length, "country:", country || "not provided");

    // Validate input - either foodText or imageBase64 must be provided
    const hasText = typeof foodText === "string" && foodText.trim().length > 0;
    const hasImage = requestImages.length > 0;
    
    if (!hasText && !hasImage) {
      console.error("Invalid argument: Both foodText and imageBase64 are missing or empty for UID:", uid);
      perf.end("invalid_argument_empty_payload");
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Either foodText or imageBase64 must be provided"
      );
    }

    if (!mealType || typeof mealType !== "string") {
      console.error("Invalid argument: mealType is missing for UID:", uid);
      perf.end("invalid_argument_missing_meal_type");
      throw new functions.https.HttpsError(
        "invalid-argument",
        "mealType is required"
      );
    }
    perf.mark("input_validated", {
      hasImage: !!hasImage,
      textChars: hasText ? foodText.trim().length : 0,
    });

    // Check rate limits
    console.log("DEBUG: Checking rate limits for UID:", uid);
    if (ENABLE_CUSTOM_RATE_LIMITS) {
      const usageCheck = await trackUsage(uid, perf);
      if (!usageCheck.allowed) {
        console.warn("Rate limit exceeded for UID:", uid, "Reason:", usageCheck.reason);
        perf.end("rate_limited", {
          reason: usageCheck.reason || "Rate limit exceeded",
        });
        throw new functions.https.HttpsError(
          "resource-exhausted",
          usageCheck.reason || "Rate limit exceeded"
        );
      }
    } else {
      perf.mark("rate_limit_skipped");
    }
    console.log("DEBUG: Rate limit check passed");

    try {
      // Call OpenAI API
      console.log("DEBUG: Calling OpenAI API...");
      const response = await callOpenAI(
        hasText ? foodText.trim() : "",
        mealType,
        hasImage ? imageBase64 : undefined,
        hasImage ? requestImages : undefined,
        country,
        perf
      );
      console.log("DEBUG: OpenAI API call successful, total calories:", response.total_calories);

      console.log("DEBUG: logMeal function completed successfully");
      return {
        ...response,
        _perf: perf.end("success", {
          totalCalories: response.total_calories,
        }),
      };
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
        perf.end("failure_https_error", {
          message: error.message,
        });
        throw error;
      }

      // Provide more detailed error message
      const errorMessage = error?.message || error?.toString() || "Unknown error occurred";
      console.error("ERROR: Throwing new HttpsError with message:", errorMessage);
      perf.end("failure", {
        message: errorMessage,
      });
      throw new functions.https.HttpsError(
        "internal",
        `Firebase Function error: ${errorMessage}. Check function logs for details.`
      );
    }
  }
);

/**
 * Refine an existing meal estimate from a short user correction (counts toward same logMeal rate limits).
 */
export const refineMealLog = functions.region(FUNCTIONS_REGION).runWith({
  secrets: ["OPENAI_API_KEY"],
}).https.onCall(async (data: unknown, context) => {
  console.log("DEBUG: refineMealLog function called");

  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "User must be authenticated"
    );
  }

  const uid = context.auth.uid;
  const d = data as Record<string, unknown>;
  const foodText = typeof d.foodText === "string" ? d.foodText : "";
  const mealType = typeof d.mealType === "string" ? d.mealType : "";
  const correctionPrompt = typeof d.correctionPrompt === "string" ? d.correctionPrompt : "";
  const country = typeof d.country === "string" ? d.country : undefined;
  const previousEstimate = d.previousEstimate as MealLogResponse | undefined;

  if (!mealType.trim()) {
    throw new functions.https.HttpsError("invalid-argument", "mealType is required");
  }
  if (!correctionPrompt.trim()) {
    throw new functions.https.HttpsError("invalid-argument", "correctionPrompt is required");
  }
  if (!previousEstimate || !Array.isArray(previousEstimate.items)) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "previousEstimate with items is required"
    );
  }

  const usageCheck = await trackUsage(uid);
  if (!usageCheck.allowed) {
    throw new functions.https.HttpsError(
      "resource-exhausted",
      usageCheck.reason || "Rate limit exceeded"
    );
  }

  try {
    const response = await callOpenAIRefineMeal(
      foodText,
      mealType,
      previousEstimate,
      correctionPrompt.trim(),
      country
    );
    console.log("DEBUG: refineMealLog success total_calories:", response.total_calories);
    return response;
  } catch (error: any) {
    console.error("ERROR: refineMealLog:", error?.message || error);
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    throw new functions.https.HttpsError(
      "internal",
      error?.message || "Refine failed"
    );
  }
});

/**
 * Records non-critical meal logging analytics after the client has already shown
 * the meal result. Keep this off the `logMeal` hot path.
 */
export const recordMealLogAnalytics = functions.region(FUNCTIONS_REGION).https.onCall(
  async (data: MealAnalyticsRequest, context) => {
    const perf = new BackendPerf("recordMealLogAnalytics");
    console.log("DEBUG: recordMealLogAnalytics function called");

    if (!context.auth) {
      perf.end("unauthenticated");
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated"
      );
    }

    const uid = context.auth.uid;
    const foodText = typeof data?.foodText === "string" ? data.foodText.trim() : "";
    const mealType = typeof data?.mealType === "string" ? data.mealType : "";
    const totalCalories = typeof data?.totalCalories === "number" ? data.totalCalories : 0;
    const hasImage = data?.hasImage === true;

    if (!mealType) {
      perf.end("invalid_argument_missing_meal_type");
      throw new functions.https.HttpsError("invalid-argument", "mealType is required");
    }

    try {
      perf.mark("analytics_write_start", {
        hasImage,
        textChars: foodText.length,
        totalCalories,
      });
      await admin.firestore().collection("mealLogs").add({
        uid,
        foodText,
        mealType,
        totalCalories,
        hasImage,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });
      return {
        ok: true,
        _perf: perf.end("success"),
      };
    } catch (error: any) {
      console.warn("WARNING: recordMealLogAnalytics failed:", error?.message || error);
      perf.end("failure", {
        message: error?.message || "Unknown analytics write error",
      });
      throw new functions.https.HttpsError(
        "internal",
        error?.message || "Failed to record meal analytics"
      );
    }
  }
);

/**
 * Transcribe short meal dictation audio via OpenAI Whisper (server-side key).
 * Client sends base64-encoded audio (e.g. M4A). Auth required.
 */
export const transcribeAudio = functions.region(FUNCTIONS_REGION).runWith({
  secrets: ["OPENAI_API_KEY"],
  timeoutSeconds: 120,
  memory: "512MB",
}).https.onCall(
  async (data: TranscribeAudioRequest, context) => {
    const perf = new BackendPerf("transcribeAudio");
    console.log("DEBUG: transcribeAudio function called");

    if (!context.auth) {
      perf.end("unauthenticated");
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated"
      );
    }

    const uid = context.auth.uid;
    const audioBase64 = data?.audioBase64;
    const mimeType = typeof data?.mimeType === "string" && data.mimeType.length > 0
      ? data.mimeType
      : "audio/m4a";

    if (!audioBase64 || typeof audioBase64 !== "string" || audioBase64.length === 0) {
      perf.end("invalid_argument_missing_audio");
      throw new functions.https.HttpsError(
        "invalid-argument",
        "audioBase64 is required"
      );
    }

    let buffer: Buffer;
    try {
      buffer = Buffer.from(audioBase64, "base64");
      perf.mark("audio_base64_decoded", {
        base64Chars: audioBase64.length,
        bytes: buffer.length,
      });
    } catch (e) {
      perf.end("invalid_base64_audio");
      throw new functions.https.HttpsError("invalid-argument", "Invalid base64 audio");
    }

    if (buffer.length === 0) {
      perf.end("empty_audio_payload");
      throw new functions.https.HttpsError("invalid-argument", "Empty audio payload");
    }

    if (buffer.length > MAX_TRANSCRIBE_AUDIO_BYTES) {
      perf.end("audio_too_large", {
        bytes: buffer.length,
      });
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Audio too large. Please record a shorter clip."
      );
    }

    if (ENABLE_CUSTOM_RATE_LIMITS) {
      const usageCheck = await trackTranscribeUsage(uid, perf);
      if (!usageCheck.allowed) {
        perf.end("rate_limited", {
          reason: usageCheck.reason || "Rate limit exceeded",
        });
        throw new functions.https.HttpsError(
          "resource-exhausted",
          usageCheck.reason || "Rate limit exceeded"
        );
      }
    } else {
      perf.mark("transcribe_rate_limit_skipped");
    }

    const ext = mimeType.includes("wav") ? "wav" : mimeType.includes("webm") ? "webm" : "m4a";
    const filename = `dictation.${ext}`;
    const whisperLang = normalizeWhisperLanguage(data?.language);

    try {
      const text = await callOpenAIWhisperTranscription(buffer, filename, mimeType, whisperLang, perf);
      return {
        text,
        _perf: perf.end("success", {
          chars: text.length,
        }),
      };
    } catch (error: any) {
      if (error instanceof functions.https.HttpsError) {
        perf.end("failure_https_error", {
          message: error.message,
        });
        throw error;
      }
      console.error("ERROR: transcribeAudio failed:", error);
      perf.end("failure", {
        message: error?.message || "Transcription failed",
      });
      throw new functions.https.HttpsError(
        "internal",
        error?.message || "Transcription failed"
      );
    }
  }
);

/**
 * Health check function (no auth required)
 */
export const healthCheck = functions.region(FUNCTIONS_REGION).https.onRequest((req, res) => {
  res.json({
    status: "ok",
    timestamp: new Date().toISOString(),
    service: "logcal-functions",
  });
});
