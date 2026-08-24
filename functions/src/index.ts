import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import * as https from "https";
import * as crypto from "crypto";

// Initialize Firebase Admin
admin.initializeApp();

// OpenAI API configuration
// API key is loaded from Firebase Secrets at runtime
const OPENAI_CHAT_COMPLETIONS_URL = "https://api.openai.com/v1/chat/completions";
const OPENAI_RESPONSES_URL = "https://api.openai.com/v1/responses";
const OPENAI_LEGACY_MODEL = "gpt-4o-2024-08-06";
const OPENAI_LUNA_MODEL = "gpt-5.6-luna";
const OPENAI_TEMPERATURE = 0.3;
const FUNCTIONS_REGION = "asia-southeast1";
const FALLBACK_LUNA_ALLOWLIST_UIDS = new Set([
  "NIDRscOVhuQRpSEzrgk5gMo2i8m1",
]);
const FALLBACK_WEB_SEARCH_ALLOWLIST_UIDS = new Set([
  "NIDRscOVhuQRpSEzrgk5gMo2i8m1",
]);
const OPENAI_PRICING_SNAPSHOT = "2026-07-19";
const OPENAI_WEB_SEARCH_COST_USD = 0.01;
const OPENAI_MODEL_PRICING_USD_PER_1M: Record<string, {
  input: number;
  cachedInput: number;
  output: number;
}> = {
  [OPENAI_LEGACY_MODEL]: {
    input: 2.5,
    cachedInput: 1.25,
    output: 10,
  },
  [OPENAI_LUNA_MODEL]: {
    input: 1,
    cachedInput: 0.1,
    output: 6,
  },
};

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

const CONCISE_ASSUMPTIONS_RULE =
  "Keep each item's assumptions short and user-friendly: one sentence, maximum 25 words. Mention only portion/cooking assumption, not nutrition math.";
const WEB_SEARCH_RULE =
  "Use web search only for specific branded packaged foods, exact restaurant/menu items, barcode/label-like product names, or exact product variants. Do not search for vague or generic foods. If web search is used, include clickable source URLs in the top-level sources array; otherwise use an empty sources array.";

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
  fiber?: number;    // grams
  items: Array<{
    name: string;
    quantity: string;
    calories: number;
    protein?: number;  // grams
    carbs?: number;    // grams
    fat?: number;      // grams
    fiber?: number;    // grams
    assumptions?: string;
    confidence: number;
  }>;
  needs_clarification: boolean;
  clarifying_question: string;
  sources?: Array<{
    title: string;
    url: string;
  }>;
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

interface OpenAIMealRoute {
  api: "chat_completions" | "responses";
  model: string;
  url: string;
  reason: "default" | "luna_entitlement" | "luna_global" | "luna_fallback_allowlist";
}

interface MealEntitlements {
  lunaEnabled: boolean;
  webSearchEnabled: boolean;
  source: "entitlement" | "global_config" | "fallback_allowlist" | "default" | "firestore_error";
}

interface GlobalMealModelConfig {
  lunaEnabledForAll: boolean;
  webSearchEnabledForAll: boolean;
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
      fiber: { type: "number" },
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
            fiber: { type: "number" },
            assumptions: { type: "string" },
            confidence: { type: "number" },
          },
          required: ["name", "quantity", "calories", "protein", "carbs", "fat", "fiber", "assumptions", "confidence"],
        },
      },
      needs_clarification: { type: "boolean" },
      clarifying_question: { type: "string" },
      sources: {
        type: "array",
        items: {
          type: "object",
          additionalProperties: false,
          properties: {
            title: { type: "string" },
            url: { type: "string" },
          },
          required: ["title", "url"],
        },
      },
    },
    required: ["meal_type", "total_calories", "protein", "carbs", "fat", "fiber", "items", "needs_clarification", "clarifying_question", "sources"],
  },
};

function booleanFromEntitlement(value: unknown): boolean | undefined {
  return typeof value === "boolean" ? value : undefined;
}

async function getGlobalMealModelConfig(): Promise<GlobalMealModelConfig> {
  try {
    const snapshot = await admin.firestore().collection("app").doc("modelConfig").get();
    const data = snapshot.exists ? snapshot.data() || {} : {};
    return {
      lunaEnabledForAll: booleanFromEntitlement(data.lunaEnabledForAll) ?? false,
      webSearchEnabledForAll: booleanFromEntitlement(data.webSearchEnabledForAll) ?? false,
    };
  } catch (error) {
    console.error("ERROR: Failed to read global meal model config:", { error });
    return {
      lunaEnabledForAll: false,
      webSearchEnabledForAll: false,
    };
  }
}

async function getMealEntitlements(uid: string): Promise<MealEntitlements> {
  const globalConfig = await getGlobalMealModelConfig();

  try {
    const snapshot = await admin.firestore().collection("entitlements").doc(uid).get();
    if (snapshot.exists) {
      const data = snapshot.data() || {};
      const features = typeof data.features === "object" && data.features !== null
        ? data.features as Record<string, unknown>
        : {};
      const lunaOverride = booleanFromEntitlement(data.lunaEnabled) ??
        booleanFromEntitlement(features.luna) ??
        booleanFromEntitlement(features.lunaEnabled);
      const webSearchOverride = booleanFromEntitlement(data.webSearchEnabled) ??
        booleanFromEntitlement(features.webSearch) ??
        booleanFromEntitlement(features.webSearchEnabled);

      return {
        lunaEnabled: lunaOverride ?? globalConfig.lunaEnabledForAll,
        webSearchEnabled: webSearchOverride ?? globalConfig.webSearchEnabledForAll,
        source: "entitlement",
      };
    }
  } catch (error) {
    console.error("ERROR: Failed to read meal entitlements:", {
      uid,
      error,
    });
    return {
      lunaEnabled: FALLBACK_LUNA_ALLOWLIST_UIDS.has(uid),
      webSearchEnabled: FALLBACK_WEB_SEARCH_ALLOWLIST_UIDS.has(uid),
      source: "firestore_error",
    };
  }

  if (globalConfig.lunaEnabledForAll || globalConfig.webSearchEnabledForAll) {
    return {
      lunaEnabled: globalConfig.lunaEnabledForAll,
      webSearchEnabled: globalConfig.webSearchEnabledForAll,
      source: "global_config",
    };
  }

  if (FALLBACK_LUNA_ALLOWLIST_UIDS.has(uid) || FALLBACK_WEB_SEARCH_ALLOWLIST_UIDS.has(uid)) {
    return {
      lunaEnabled: FALLBACK_LUNA_ALLOWLIST_UIDS.has(uid),
      webSearchEnabled: FALLBACK_WEB_SEARCH_ALLOWLIST_UIDS.has(uid),
      source: "fallback_allowlist",
    };
  }

  return {
    lunaEnabled: false,
    webSearchEnabled: false,
    source: "default",
  };
}

function getOpenAIMealRoute(entitlements: MealEntitlements): OpenAIMealRoute {
  if (entitlements.lunaEnabled) {
    return {
      api: "responses",
      model: OPENAI_LUNA_MODEL,
      url: OPENAI_RESPONSES_URL,
      reason: entitlements.source === "fallback_allowlist" || entitlements.source === "firestore_error"
        ? "luna_fallback_allowlist"
        : entitlements.source === "global_config"
          ? "luna_global"
        : "luna_entitlement",
    };
  }

  return {
    api: "chat_completions",
    model: OPENAI_LEGACY_MODEL,
    url: OPENAI_CHAT_COMPLETIONS_URL,
    reason: "default",
  };
}

function logOpenAIMealRoute(
  action: "logMeal" | "refineMealLog",
  uid: string,
  route: OpenAIMealRoute,
  metadata?: Record<string, unknown>
): void {
  console.log("OPENAI_MEAL_ROUTE", {
    action,
    uid,
    api: route.api,
    model: route.model,
    reason: route.reason,
    ...(metadata ? { metadata } : {}),
  });
}

function extractResponsesOutputText(data: any): string | undefined {
  if (typeof data?.output_text === "string") {
    return data.output_text;
  }

  const output = Array.isArray(data?.output) ? data.output : [];
  for (const item of output) {
    if (item?.type !== "message" || !Array.isArray(item?.content)) {
      continue;
    }
    for (const content of item.content) {
      if (typeof content?.text === "string") {
        return content.text;
      }
      if (typeof content?.output_text === "string") {
        return content.output_text;
      }
    }
  }

  return undefined;
}

function isWebSearchEnabled(route: OpenAIMealRoute, entitlements: MealEntitlements): boolean {
  return route.api === "responses" && entitlements.webSearchEnabled;
}

function buildWebSearchTool(country?: string): Record<string, unknown> {
  const tool: Record<string, unknown> = {
    type: "web_search",
    search_context_size: "low",
  };

  const normalizedCountry = country?.trim().toLowerCase();
  if (normalizedCountry === "india") {
    tool.user_location = {
      type: "approximate",
      country: "IN",
    };
  } else if (normalizedCountry === "united states" || normalizedCountry === "usa" || normalizedCountry === "us") {
    tool.user_location = {
      type: "approximate",
      country: "US",
    };
  }

  return tool;
}

function extractWebSearchMetadata(data: any): {
  used: boolean;
  callCount: number;
  queries: string[];
  sources: Array<{ title: string; url: string }>;
} {
  const output = Array.isArray(data?.output) ? data.output : [];
  const querySet = new Set<string>();
  const sourceMap = new Map<string, { title: string; url: string }>();
  let used = false;
  let callCount = 0;

  const addSource = (source: any): void => {
    const citation = source?.url_citation || source;
    const url = citation?.url || citation?.source_url || citation?.source_website_url;
    if (typeof url !== "string" || url.trim().length === 0) {
      return;
    }
    const title = typeof citation?.title === "string" && citation.title.trim().length > 0
      ? citation.title.trim()
      : url;
    sourceMap.set(url, { title, url });
  };

  for (const item of output) {
    if (item?.type === "web_search_call") {
      used = true;
      callCount += 1;
      const action = item.action || {};
      if (typeof action.query === "string") {
        querySet.add(action.query);
      }
      if (Array.isArray(action.queries)) {
        for (const query of action.queries) {
          if (typeof query === "string") {
            querySet.add(query);
          } else if (typeof query?.query === "string") {
            querySet.add(query.query);
          }
        }
      }
      if (Array.isArray(action.sources)) {
        for (const source of action.sources) {
          addSource(source);
        }
      }
    }

    if (item?.type === "message" && Array.isArray(item.content)) {
      for (const content of item.content) {
        if (Array.isArray(content?.annotations)) {
          for (const annotation of content.annotations) {
            addSource(annotation);
          }
        }
      }
    }
  }

  return {
    used,
    callCount,
    queries: Array.from(querySet),
    sources: Array.from(sourceMap.values()),
  };
}

function roundUsd(value: number): number {
  return Math.round(value * 1_000_000_000) / 1_000_000_000;
}

function extractOpenAITokenUsage(data: any): {
  inputTokens: number;
  cachedInputTokens: number;
  uncachedInputTokens: number;
  outputTokens: number;
  totalTokens: number;
} {
  const usage = data?.usage || {};
  const inputTokens = Number(usage.input_tokens ?? usage.prompt_tokens ?? 0) || 0;
  const outputTokens = Number(usage.output_tokens ?? usage.completion_tokens ?? 0) || 0;
  const totalTokens = Number(usage.total_tokens ?? inputTokens + outputTokens) || 0;
  const cachedInputTokens = Number(
    usage.input_tokens_details?.cached_tokens ??
    usage.prompt_tokens_details?.cached_tokens ??
    0
  ) || 0;
  const uncachedInputTokens = Math.max(inputTokens - cachedInputTokens, 0);

  return {
    inputTokens,
    cachedInputTokens,
    uncachedInputTokens,
    outputTokens,
    totalTokens,
  };
}

function logOpenAIMealUsage(
  action: "logMeal" | "refineMealLog",
  uid: string,
  route: OpenAIMealRoute,
  data: any,
  webSearchMetadata: { used: boolean; callCount: number }
): void {
  const tokenUsage = extractOpenAITokenUsage(data);
  const pricing = OPENAI_MODEL_PRICING_USD_PER_1M[route.model];
  const estimatedModelCostUsd = pricing
    ? (
      (tokenUsage.uncachedInputTokens * pricing.input) +
      (tokenUsage.cachedInputTokens * pricing.cachedInput) +
      (tokenUsage.outputTokens * pricing.output)
    ) / 1_000_000
    : undefined;
  const estimatedWebSearchCostUsd = webSearchMetadata.callCount * OPENAI_WEB_SEARCH_COST_USD;
  const estimatedCostUsd = typeof estimatedModelCostUsd === "number"
    ? estimatedModelCostUsd + estimatedWebSearchCostUsd
    : undefined;

  console.log("OPENAI_MEAL_USAGE", {
    action,
    uid,
    api: route.api,
    model: route.model,
    pricingSnapshot: OPENAI_PRICING_SNAPSHOT,
    inputTokens: tokenUsage.inputTokens,
    cachedInputTokens: tokenUsage.cachedInputTokens,
    uncachedInputTokens: tokenUsage.uncachedInputTokens,
    outputTokens: tokenUsage.outputTokens,
    totalTokens: tokenUsage.totalTokens,
    webSearchUsed: webSearchMetadata.used,
    webSearchCallCount: webSearchMetadata.callCount,
    estimatedModelCostUsd: typeof estimatedModelCostUsd === "number" ? roundUsd(estimatedModelCostUsd) : null,
    estimatedWebSearchCostUsd: roundUsd(estimatedWebSearchCostUsd),
    estimatedCostUsd: typeof estimatedCostUsd === "number" ? roundUsd(estimatedCostUsd) : null,
  });
}

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
  perf?: BackendPerf,
  uid = ""
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
  const entitlements = await getMealEntitlements(uid);
  const route = getOpenAIMealRoute(entitlements);
  const webSearchEnabled = isWebSearchEnabled(route, entitlements);
  logOpenAIMealRoute("logMeal", uid, route, {
    imageCount: images.length,
    textChars: foodText.length,
    webSearchEnabled,
    entitlementSource: entitlements.source,
    lunaEnabled: entitlements.lunaEnabled,
  });

  // Build system prompt based on country
  let systemPrompt: string;
  if (country && country.trim().length > 0) {
    systemPrompt = `You are a calorie logging assistant for ${country} food. When given a food description or image, estimate calories and macronutrients (protein, carbs, fat, fiber in grams) based on typical ${country} portion sizes and regional cuisine. Use the provided meal type. Never ask for clarifications - always set needs_clarification to false and clarifying_question to an empty string. Provide detailed breakdowns of items with quantities, calories, macronutrients, assumptions, and confidence scores. 

CRITICAL RULES FOR ACCURACY:
1. For each item in the breakdown, calculate its calories and macronutrients strictly based on the exact quantity specified for that specific item. Do not let other numbers or totals in the user's description influence the calculations of a single item's portion.
2. The numerical values for calories, protein, carbs, fat, and fiber in the JSON fields must align perfectly with the values and math you describe in the item's 'assumptions' text.
3. The top-level protein, carbs, fat, and fiber must equal the sum of the same fields across all items (in grams).
4. ${CONCISE_ASSUMPTIONS_RULE}
5. ${WEB_SEARCH_RULE}

When both a written description and a photo are provided, you must use both together: identify foods and portion sizes from the photo, use the text for context; if they disagree on something visible in the image, trust the image for that detail. Each item's assumptions field should mention what you inferred from the photo (e.g. visible portion, condiments, cooking style) when a photo is present, not only generic text-based guesses.`;
  } else {
    systemPrompt = `You are a calorie logging assistant. When given a food description or image, estimate calories and macronutrients (protein, carbs, fat, fiber in grams) based on typical portion sizes. Use the provided meal type. Never ask for clarifications - always set needs_clarification to false and clarifying_question to an empty string. Provide detailed breakdowns of items with quantities, calories, macronutrients, assumptions, and confidence scores. 

CRITICAL RULES FOR ACCURACY:
1. For each item in the breakdown, calculate its calories and macronutrients strictly based on the exact quantity specified for that specific item. Do not let other numbers or totals in the user's description influence the calculations of a single item's portion.
2. The numerical values for calories, protein, carbs, fat, and fiber in the JSON fields must align perfectly with the values and math you describe in the item's 'assumptions' text.
3. The top-level protein, carbs, fat, and fiber must equal the sum of the same fields across all items (in grams).
4. ${CONCISE_ASSUMPTIONS_RULE}
5. ${WEB_SEARCH_RULE}

When both a written description and a photo are provided, you must use both together: identify foods and portion sizes from the photo, use the text for context; if they disagree on something visible in the image, trust the image for that detail. Each item's assumptions field should mention what you inferred from the photo (e.g. visible portion, condiments, cooking style) when a photo is present, not only generic text-based guesses.`;
  }
  
  console.log("DEBUG: System prompt:", systemPrompt);

  const userTextParts: string[] = [];
  if (foodText && foodText.trim().length > 0) {
    userTextParts.push(`Food description: ${foodText}`);
  } else {
    userTextParts.push("Food description: (none)");
  }
  userTextParts.push(`Meal type: ${mealType}`);
  if (images.length > 0) {
    userTextParts.push(`${images.length} photo(s) of this meal are attached in this message; combine them with the description above for estimates and assumptions.`);
  }
  const userText = userTextParts.join("\n");

  const chatUserContent: Array<{ type: "text"; text: string } | { type: "image_url"; image_url: { url: string } }> = [
    {
      type: "text",
      text: userText,
    },
  ];
  const responsesUserContent: Array<{ type: "input_text"; text: string } | { type: "input_image"; image_url: string; detail: "low" }> = [
    {
      type: "input_text",
      text: userText,
    },
  ];

  for (const image of images) {
    const imageUrl = image.startsWith("data:") ? image : `data:image/jpeg;base64,${image}`;
    chatUserContent.push({
      type: "image_url",
      image_url: {
        url: imageUrl,
      },
    });
    responsesUserContent.push({
      type: "input_image",
      image_url: imageUrl,
      detail: "low",
    });
    console.log("DEBUG: Image added to request, base64 length:", image.length);
  }

  const requestBody = route.api === "responses"
    ? {
      model: route.model,
      store: false,
      instructions: systemPrompt,
      input: [
        {
          role: "user",
          content: responsesUserContent,
        },
      ],
      ...(webSearchEnabled ? {
        tools: [buildWebSearchTool(country)],
        tool_choice: "auto",
        include: ["web_search_call.action.sources"],
      } : {}),
      text: {
        format: {
          type: "json_schema",
          name: MEAL_LOG_JSON_SCHEMA.name,
          strict: true,
          schema: MEAL_LOG_JSON_SCHEMA.schema,
        },
      },
    }
    : {
      model: route.model,
      temperature: OPENAI_TEMPERATURE,
      messages: [
        { role: "system", content: systemPrompt },
        { role: "user", content: chatUserContent },
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
      model: route.model,
      api: route.api,
      routeReason: route.reason,
      textChars: foodText.length,
    });
    response = await fetch(route.url, {
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
  const webSearchMetadata = route.api === "responses" ? extractWebSearchMetadata(data) : { used: false, callCount: 0, queries: [], sources: [] };
  logOpenAIMealUsage("logMeal", uid, route, data, webSearchMetadata);
  const content = route.api === "responses"
    ? extractResponsesOutputText(data)
    : data.choices?.[0]?.message?.content;

  if (!content) {
    throw new functions.https.HttpsError(
      "internal",
      "Invalid response from OpenAI API"
    );
  }

  const parsed = JSON.parse(content) as MealLogResponse;
  if (!Array.isArray(parsed.sources)) {
    parsed.sources = [];
  }
  if (parsed.sources.length === 0 && webSearchMetadata.sources.length > 0) {
    parsed.sources = webSearchMetadata.sources;
  }
  if (webSearchEnabled) {
    console.log("OPENAI_WEB_SEARCH_USAGE", {
      action: "logMeal",
      uid,
      used: webSearchMetadata.used,
      callCount: webSearchMetadata.callCount,
      queries: webSearchMetadata.queries,
      sourceCount: parsed.sources.length,
    });
  }
  perf?.mark("openai_chat_content_decoded", {
    itemCount: parsed.items?.length || 0,
    totalCalories: parsed.total_calories,
    webSearchUsed: webSearchMetadata.used,
    webSearchCallCount: webSearchMetadata.callCount,
    sourceCount: parsed.sources.length,
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
  
  const allFiberComplete = items.every(
    (i) => typeof i.fiber === "number" && !Number.isNaN(i.fiber)
  );
  let fib = undefined;
  if (allFiberComplete) {
    fib = 0;
    for (const i of items) {
      fib += i.fiber as number;
    }
  }

  console.log("DEBUG: alignMealMacrosToItemSum applied", { protein: p, carbs: c, fat: f, fiber: fib, itemCount: items.length });
  return { ...response, protein: p, carbs: c, fat: f, fiber: fib !== undefined ? fib : response.fiber };
}

/**
 * Re-estimate a meal from the user's correction text (no image; uses prior JSON + description).
 */
async function callOpenAIRefineMeal(
  foodText: string,
  mealType: string,
  previousEstimate: MealLogResponse,
  correctionPrompt: string,
  country?: string,
  uid = ""
): Promise<MealLogResponse> {
  const apiKey = process.env.OPENAI_API_KEY;
  if (!apiKey) {
    throw new functions.https.HttpsError(
      "internal",
      "OpenAI API key not configured."
    );
  }
  const entitlements = await getMealEntitlements(uid);
  const route = getOpenAIMealRoute(entitlements);
  const webSearchEnabled = isWebSearchEnabled(route, entitlements);
  logOpenAIMealRoute("refineMealLog", uid, route, {
    correctionChars: correctionPrompt.length,
    previousItems: previousEstimate.items?.length || 0,
    webSearchEnabled,
    entitlementSource: entitlements.source,
    lunaEnabled: entitlements.lunaEnabled,
  });

  let systemPrompt: string;
  if (country && country.trim().length > 0) {
    systemPrompt = `You are a calorie logging assistant for ${country} food. The user already has a structured meal estimate and wants to correct it. Apply their instructions: fix wrong foods, portions, cooking method, or macros. Output a complete new meal_log JSON. Set needs_clarification to false and clarifying_question to an empty string.

CRITICAL RULES FOR ACCURACY:
1. For each item in the breakdown, calculate its calories and macronutrients strictly based on the exact quantity specified for that specific item. Do not let other numbers or totals in the user's description influence the calculations of a single item's portion.
2. The numerical values for calories, protein, carbs, fat, and fiber in the JSON fields must align perfectly with the values and math you describe in the item's 'assumptions' text.
3. The top-level protein, carbs, fat, and fiber must equal the sum of the same fields across all items (in grams).
4. ${CONCISE_ASSUMPTIONS_RULE}
5. ${WEB_SEARCH_RULE}`;
  } else {
    systemPrompt = `You are a calorie logging assistant. The user already has a structured meal estimate and wants to correct it. Apply their instructions: fix wrong foods, portions, cooking method, or macros. Output a complete new meal_log JSON. Set needs_clarification to false and clarifying_question to an empty string.

CRITICAL RULES FOR ACCURACY:
1. For each item in the breakdown, calculate its calories and macronutrients strictly based on the exact quantity specified for that specific item. Do not let other numbers or totals in the user's description influence the calculations of a single item's portion.
2. The numerical values for calories, protein, carbs, fat, and fiber in the JSON fields must align perfectly with the values and math you describe in the item's 'assumptions' text.
3. The top-level protein, carbs, fat, and fiber must equal the sum of the same fields across all items (in grams).
4. ${CONCISE_ASSUMPTIONS_RULE}
5. ${WEB_SEARCH_RULE}`;
  }

  const previousJson = JSON.stringify(previousEstimate);
  const userText = `Original user description (for context):\n${foodText.trim().length > 0 ? foodText.trim() : "(none or image-only log)"}\n\nMeal type: ${mealType}\n\nCurrent structured estimate (JSON):\n${previousJson}\n\nUser correction (apply these changes):\n${correctionPrompt.trim()}`;

  const requestBody = route.api === "responses"
    ? {
      model: route.model,
      store: false,
      instructions: systemPrompt,
      input: userText,
      ...(webSearchEnabled ? {
        tools: [buildWebSearchTool(country)],
        tool_choice: "auto",
        include: ["web_search_call.action.sources"],
      } : {}),
      text: {
        format: {
          type: "json_schema",
          name: MEAL_LOG_JSON_SCHEMA.name,
          strict: true,
          schema: MEAL_LOG_JSON_SCHEMA.schema,
        },
      },
    }
    : {
      model: route.model,
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

  const response = await fetch(route.url, {
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
  const webSearchMetadata = route.api === "responses" ? extractWebSearchMetadata(data) : { used: false, callCount: 0, queries: [], sources: [] };
  logOpenAIMealUsage("refineMealLog", uid, route, data, webSearchMetadata);
  const content = route.api === "responses"
    ? extractResponsesOutputText(data)
    : data.choices?.[0]?.message?.content;
  if (!content) {
    throw new functions.https.HttpsError(
      "internal",
      "Invalid response from OpenAI API (refine)"
    );
  }

  const parsed = JSON.parse(content) as MealLogResponse;
  if (!Array.isArray(parsed.sources)) {
    parsed.sources = [];
  }
  if (parsed.sources.length === 0 && webSearchMetadata.sources.length > 0) {
    parsed.sources = webSearchMetadata.sources;
  }
  if (webSearchEnabled) {
    console.log("OPENAI_WEB_SEARCH_USAGE", {
      action: "refineMealLog",
      uid,
      used: webSearchMetadata.used,
      callCount: webSearchMetadata.callCount,
      queries: webSearchMetadata.queries,
      sourceCount: parsed.sources.length,
    });
  }
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
        perf,
        uid
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
      country,
      uid
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

function sendWhatsAppMessage(to: string, text: string, phoneNumberId: string, accessToken: string): Promise<void> {
  return new Promise((resolve, reject) => {
    const data = JSON.stringify({
      messaging_product: "whatsapp",
      recipient_type: "individual",
      to: to,
      type: "text",
      text: {
        body: text
      }
    });

    const options = {
      hostname: "graph.facebook.com",
      port: 443,
      path: `/v17.0/${phoneNumberId}/messages`,
      method: "POST",
      headers: {
        "Authorization": `Bearer ${accessToken}`,
        "Content-Type": "application/json",
        "Content-Length": Buffer.byteLength(data)
      }
    };

    const req = https.request(options, (res) => {
      let body = "";
      res.on("data", (chunk) => body += chunk);
      res.on("end", () => {
        if (res.statusCode && res.statusCode >= 200 && res.statusCode < 300) {
          console.log("DEBUG: WhatsApp message sent successfully:", body);
          resolve();
        } else {
          console.error("ERROR: WhatsApp message failed with status", res.statusCode, body);
          reject(new Error(`WhatsApp API error status ${res.statusCode}: ${body}`));
        }
      });
    });

    req.on("error", (e) => {
      console.error("ERROR: WhatsApp request network error:", e);
      reject(e);
    });

    req.write(data);
    req.end();
  });
}

function sendWhatsAppTypingIndicator(messageId: string, phoneNumberId: string, accessToken: string): Promise<void> {
  return new Promise((resolve) => {
    const data = JSON.stringify({
      messaging_product: "whatsapp",
      status: "read",
      message_id: messageId,
      typing_indicator: {
        type: "text"
      }
    });

    const options = {
      hostname: "graph.facebook.com",
      port: 443,
      path: `/v17.0/${phoneNumberId}/messages`,
      method: "POST",
      headers: {
        "Authorization": `Bearer ${accessToken}`,
        "Content-Type": "application/json",
        "Content-Length": Buffer.byteLength(data)
      }
    };

    const req = https.request(options, (res) => {
      let body = "";
      res.on("data", (chunk) => body += chunk);
      res.on("end", () => {
        if (res.statusCode && res.statusCode >= 200 && res.statusCode < 300) {
          console.log("DEBUG: WhatsApp typing indicator sent successfully:", body);
        } else {
          console.warn("WARN: WhatsApp typing indicator failed with status", res.statusCode, body);
        }
        resolve();
      });
    });

    req.on("error", (e) => {
      console.warn("WARN: WhatsApp typing indicator network error:", e);
      resolve();
    });

    req.write(data);
    req.end();
  });
}

function sendWhatsAppButtons(
  to: string, 
  bodyText: string, 
  buttons: { id: string; title: string }[], 
  phoneNumberId: string, 
  accessToken: string,
  headerText?: string,
  footerText?: string
): Promise<void> {
  return new Promise((resolve, reject) => {
    const data = JSON.stringify({
      messaging_product: "whatsapp",
      recipient_type: "individual",
      to: to,
      type: "interactive",
      interactive: {
        type: "button",
        ...(headerText ? { header: { type: "text", text: headerText } } : {}),
        body: {
          text: bodyText
        },
        ...(footerText ? { footer: { text: footerText } } : {}),
        action: {
          buttons: buttons.map(btn => ({
            type: "reply",
            reply: {
              id: btn.id,
              title: btn.title.substring(0, 20) // Ensure max 20 chars limit is strictly respected
            }
          }))
        }
      }
    });

    const options = {
      hostname: "graph.facebook.com",
      port: 443,
      path: `/v17.0/${phoneNumberId}/messages`,
      method: "POST",
      headers: {
        "Authorization": `Bearer ${accessToken}`,
        "Content-Type": "application/json",
        "Content-Length": Buffer.byteLength(data)
      }
    };

    const req = https.request(options, (res) => {
      let body = "";
      res.on("data", (chunk) => body += chunk);
      res.on("end", () => {
        if (res.statusCode && res.statusCode >= 200 && res.statusCode < 300) {
          console.log("DEBUG: WhatsApp buttons sent successfully:", body);
          resolve();
        } else {
          console.error("ERROR: WhatsApp buttons failed with status", res.statusCode, body);
          reject(new Error(`WhatsApp API error status ${res.statusCode}: ${body}`));
        }
      });
    });

    req.on("error", (e) => {
      console.error("ERROR: WhatsApp request network error:", e);
      reject(e);
    });

    req.write(data);
    req.end();
  });
}

function getISTDayBounds(): { start: Date; end: Date } {
  const nowSystem = new Date();
  const nowKolkata = new Date(nowSystem.toLocaleString("en-US", { timeZone: "Asia/Kolkata" }));
  
  const start = new Date(nowKolkata);
  start.setHours(0, 0, 0, 0);
  
  const end = new Date(nowKolkata);
  end.setHours(23, 59, 59, 999);
  
  const diffMs = nowKolkata.getTime() - nowSystem.getTime();
  
  return {
    start: new Date(start.getTime() - diffMs),
    end: new Date(end.getTime() - diffMs)
  };
}

/**
 * WhatsApp chatbot webhook to log meals directly via text message.
 */
export const whatsappWebhook = functions.region(FUNCTIONS_REGION).runWith({
  secrets: ["OPENAI_API_KEY", "WHATSAPP_ACCESS_TOKEN", "WHATSAPP_VERIFY_TOKEN", "WHATSAPP_PHONE_NUMBER_ID"],
}).https.onRequest(async (req, res) => {
  const method = req.method;

  if (method === "GET") {
    // Webhook verification from Meta
    const mode = req.query["hub.mode"];
    const token = req.query["hub.verify_token"];
    const challenge = req.query["hub.challenge"];
    const configuredVerifyToken = process.env.WHATSAPP_VERIFY_TOKEN ? process.env.WHATSAPP_VERIFY_TOKEN.trim() : undefined;

    if (mode === "subscribe" && token === configuredVerifyToken) {
      console.log("DEBUG: Webhook verified successfully!");
      res.status(200).send(challenge);
    } else {
      console.error("ERROR: Webhook verification failed. Tokens mismatch. Configured:", configuredVerifyToken, "Received:", token);
      res.status(403).send("Forbidden");
    }
    return;
  }

  if (method === "POST") {
    const accessToken = process.env.WHATSAPP_ACCESS_TOKEN ? process.env.WHATSAPP_ACCESS_TOKEN.trim() : undefined;
    const phoneNumberId = process.env.WHATSAPP_PHONE_NUMBER_ID ? process.env.WHATSAPP_PHONE_NUMBER_ID.trim() : undefined;

    if (!accessToken || !phoneNumberId) {
      console.error("ERROR: WhatsApp configuration secrets missing.");
      res.status(500).send("Internal Server Error");
      return;
    }

    const body = req.body;
    console.log("DEBUG: Received WhatsApp webhook payload:", JSON.stringify(body));

    const entry = body.entry?.[0];
    const changes = entry?.changes?.[0];
    const value = changes?.value;
    const message = value?.messages?.[0];

    if (!message) {
      // Not a message event (likely a status update or delivery receipt)
      res.status(200).send("EVENT_RECEIVED");
      return;
    }

    const from = message.from; // Sender's phone number
    
    // Parse message text from either direct text message or interactive button reply
    let text = "";
    if (message.type === "text") {
      text = message.text?.body;
    } else if (message.type === "interactive") {
      text = message.interactive?.button_reply?.id || message.interactive?.button_reply?.title;
    }

    if (!from || !text) {
      res.status(200).send("EVENT_RECEIVED");
      return;
    }

    console.log(`DEBUG: Received message from ${from}: "${text}"`);

    // Fire typing indicator in background (non-blocking)
    const messageId = message.id;
    if (messageId) {
      sendWhatsAppTypingIndicator(messageId, phoneNumberId, accessToken).catch((err) => {
        console.warn("WARN: Failed to send typing indicator:", err);
      });
    }

    try {
      // 1. Account linking check (handles custom sentence like "Please link my LogCal account with code: A1B2C3" or "link A1B2C3" or code in quotes)
      const linkRegex = /(?:(?:link|\/link|code)\s+|code\s*:\s*)"?([a-zA-Z0-9]{6})"?\b/i;
      const match = text.trim().match(linkRegex);

      if (match) {
        const code = match[1].toUpperCase();
        console.log(`DEBUG: Attempting to link code "${code}" for phone "${from}"`);

        const usersRef = admin.firestore().collection("users");
        const snapshot = await usersRef.where("whatsappLinkageCode", "==", code).get();

        if (snapshot.empty) {
          await sendWhatsAppMessage(from, "❌ Invalid or expired linking code. Please check the code in the LogCal app settings and try again.", phoneNumberId, accessToken);
          res.status(200).send("EVENT_RECEIVED");
          return;
        }

        const userDoc = snapshot.docs[0];
        const userData = userDoc.data();
        const expiry = userData.whatsappLinkageExpiry?.toDate();

        if (expiry && expiry < new Date()) {
          await sendWhatsAppMessage(from, "❌ That linking code has expired. Please generate a new one in the app and try again.", phoneNumberId, accessToken);
          res.status(200).send("EVENT_RECEIVED");
          return;
        }

        // Code matches and is valid! Update the user doc to link WhatsApp number
        await userDoc.ref.update({
          whatsappPhoneNumber: from,
          whatsappLinkageCode: admin.firestore.FieldValue.delete(),
          whatsappLinkageExpiry: admin.firestore.FieldValue.delete()
        });

        await sendWhatsAppButtons(
          from,
          "✅ *LogCal Account Linked!*\n\nYou can now log meals simply by typing them here (e.g. \"2 bananas\").",
          [
            { id: "summary", title: "Today's Progress" },
            { id: "menu", title: "Main Menu" }
          ],
          phoneNumberId,
          accessToken
        );
        res.status(200).send("EVENT_RECEIVED");
        return;
      }

      // 2. Fetch linked user
      const usersRef = admin.firestore().collection("users");
      const snapshot = await usersRef.where("whatsappPhoneNumber", "==", from).get();

      if (snapshot.empty) {
        // WhatsApp number is not linked to any user
        const onboardText = `👋 *Welcome to LogCal!*\n\n` +
          `To log your meals directly through WhatsApp, please link your phone number.\n\n` +
          `*How to link:*\n` +
          `1. Open the *LogCal* app.\n` +
          `2. Go to *Profile* > *WhatsApp Logging*.\n` +
          `3. Tap *Link with WhatsApp* to open this chat automatically with your secure link message.\n` +
          `4. Send the pre-filled message (or reply here with *link CODE* if you have one).\n\n` +
          `_Don't have the app yet? Download it on the App Store:_\n` +
          `https://apps.apple.com/us/app/logcal-ai-calorie-tracker/id6757228315`;
        await sendWhatsAppMessage(from, onboardText, phoneNumberId, accessToken);
        res.status(200).send("EVENT_RECEIVED");
        return;
      }

      const userDoc = snapshot.docs[0];
      const uid = userDoc.id;
      const lowerText = text.trim().toLowerCase();

      // ==========================================
      // COMMAND ROUTING
      // ==========================================

      // A. HELP / MENU FLOW
      if (lowerText === "help" || lowerText === "menu" || lowerText === "hi") {
        const welcomeText = `🤖 *LogCal Assistant*\n\n` +
          `• *Direct Log:* Type what you ate to log it instantly.\n` +
          `• *Summary:* View your progress/goals for today.\n` +
          `• *Unlink:* Disconnect this WhatsApp number.`;
        await sendWhatsAppButtons(
          from,
          welcomeText,
          [
            { id: "summary", title: "Today's Progress" },
            { id: "unlink", title: "Unlink Account" }
          ],
          phoneNumberId,
          accessToken
        );
        res.status(200).send("EVENT_RECEIVED");
        return;
      }

      // B. UNLINK FLOW
      if (lowerText === "unlink" || lowerText === "/unlink") {
        await userDoc.ref.update({
          whatsappPhoneNumber: admin.firestore.FieldValue.delete()
        });
        await sendWhatsAppMessage(from, "🔌 Your WhatsApp number has been successfully unlinked from LogCal.", phoneNumberId, accessToken);
        res.status(200).send("EVENT_RECEIVED");
        return;
      }

      // C. TODAY'S SUMMARY FLOW
      if (lowerText === "summary" || lowerText === "today" || lowerText === "progress") {
        console.log(`DEBUG: Calculating today's summary for user ${uid}`);
        try {
          const bounds = getISTDayBounds();
          const mealsSnapshot = await admin.firestore().collection("users").doc(uid).collection("meals")
            .where("timestamp", ">=", admin.firestore.Timestamp.fromDate(bounds.start))
            .where("timestamp", "<=", admin.firestore.Timestamp.fromDate(bounds.end))
            .get();
            
          let totalCalories = 0;
          let totalProtein = 0;
          let totalCarbs = 0;
          let totalFat = 0;
          let totalFiber = 0;
          
          mealsSnapshot.forEach((doc: any) => {
            const data = doc.data();
            if (data.deleted === true) return;
            totalCalories += data.totalCalories || 0;
            
            if (data.rawResponseJson) {
              try {
                const resJson = JSON.parse(data.rawResponseJson);
                totalProtein += resJson.protein || 0;
                totalCarbs += resJson.carbs || 0;
                totalFat += resJson.fat || 0;
                totalFiber += resJson.fiber || 0;
              } catch (e) {
                // Ignore
              }
            }
          });
          
          const userData = userDoc.data() || {};
          const dailyGoal = userData.dailyGoal || 2000;
          const proteinGoal = userData.proteinGoal || 150;
          const carbsGoal = userData.carbsGoal || 200;
          const fatGoal = userData.fatGoal || 65;
          const fiberGoal = (dailyGoal / 1000) * 14;
          
          const summaryText = `📊 *Today's Progress (IST)*\n\n` +
            `🔥 Calories: *${totalCalories.toFixed(0)} / ${dailyGoal.toFixed(0)} kcal*\n` +
            `💪 Protein: *${totalProtein.toFixed(0)}g / ${proteinGoal.toFixed(0)}g*\n` +
            `🍞 Carbs: *${totalCarbs.toFixed(0)}g / ${carbsGoal.toFixed(0)}g*\n` +
            `🥑 Fat: *${totalFat.toFixed(0)}g / ${fatGoal.toFixed(0)}g*\n` +
            `🌿 Fiber: *${totalFiber.toFixed(0)}g / ${fiberGoal.toFixed(0)}g*`;
            
          await sendWhatsAppButtons(
            from, 
            summaryText, 
            [{ id: "menu", title: "Main Menu" }], 
            phoneNumberId, 
            accessToken
          );
        } catch (err) {
          console.error("ERROR: Failed to generate today's summary:", err);
          await sendWhatsAppMessage(from, "⚠️ Failed to fetch today's summary. Please try again later.", phoneNumberId, accessToken);
        }
        res.status(200).send("EVENT_RECEIVED");
        return;
      }

      // D. MEAL LOGGING FLOW (DEFAULT)
      // Infer the meal type based on current hour in IST (Asia/Kolkata timezone)
      const dateInKolkata = new Date(new Date().toLocaleString("en-US", { timeZone: "Asia/Kolkata" }));
      const hour = dateInKolkata.getHours();
      
      let inferredMealType = "Snack";
      if (hour >= 5 && hour < 11) {
        inferredMealType = "Breakfast";
      } else if (hour >= 11 && hour < 16) {
        inferredMealType = "Lunch";
      } else if (hour >= 16 && hour < 19) {
        inferredMealType = "Snack";
      } else if (hour >= 19 && hour < 24) {
        inferredMealType = "Dinner";
      }

      // Call OpenAI to parse meal using the linked user's UID and entitlements (Luna / Web Search / country)
      const userData = userDoc.data() || {};
      const userCountry = userData.country || "India";
      const openaiResponse = await callOpenAI(
        text.trim(),
        inferredMealType,
        undefined,
        undefined,
        userCountry,
        undefined,
        uid
      );
      
      // Save meal to user's collection in Firestore (UUID v4 format for client-side SwiftData UUID compatibility)
      const mealId = crypto.randomUUID().toUpperCase(); 
      
      const mealData = {
        id: mealId,
        timestamp: admin.firestore.Timestamp.now(),
        createdAt: admin.firestore.Timestamp.now(),
        foodText: text.trim(),
        mealType: openaiResponse.meal_type || inferredMealType,
        totalCalories: openaiResponse.total_calories || 0,
        rawResponseJson: JSON.stringify(openaiResponse),
        hasImage: false,
        deleted: false
      };

      await userDoc.ref.collection("meals").doc(mealId).set(mealData);

      // Save to mealLogs collection (for sync)
      await admin.firestore().collection("mealLogs").doc(mealId).set({
        uid: uid,
        foodText: text.trim(),
        mealType: openaiResponse.meal_type || inferredMealType,
        totalCalories: openaiResponse.total_calories || 0,
        hasImage: false,
        timestamp: admin.firestore.Timestamp.now(),
        deleted: false
      });

      // Construct a confirmation reply showing the logged macros
      const mealName = openaiResponse.meal_type || inferredMealType;
      const calories = openaiResponse.total_calories || 0;
      const protein = openaiResponse.protein || 0;
      const carbs = openaiResponse.carbs || 0;
      const fat = openaiResponse.fat || 0;
      const fiber = openaiResponse.fiber || 0;

      const replyMessage = `🍳 Logged *${mealName}*:\n"${text.trim()}"\n\n🔥 *${calories} kcal*\n💪 Protein: *${protein}g*\n🍞 Carbs: *${carbs}g*\n🥑 Fat: *${fat}g*\n🌿 Fiber: *${fiber}g*`;
      
      await sendWhatsAppButtons(
        from,
        replyMessage,
        [
          { id: "summary", title: "Today's Progress" },
          { id: "menu", title: "Main Menu" }
        ],
        phoneNumberId,
        accessToken
      );
      
    } catch (err: any) {
      console.error("ERROR: Error processing WhatsApp message:", err);
      try {
        await sendWhatsAppMessage(from, "⚠️ Sorry, I had trouble processing that meal description. Please try describing it differently.", phoneNumberId, accessToken);
      } catch (sendErr) {
        console.error("ERROR: Failed to send error message back:", sendErr);
      }
    }

    res.status(200).send("EVENT_RECEIVED");
    return;
  }

  res.status(405).send("Method Not Allowed");
});
