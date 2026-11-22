import * as admin from "firebase-admin";
import { randomUUID } from "crypto";
import type { MealLogResponse } from "./index";
import { agentAllowed, checkedDate, runAgentTurn, WHATSAPP_AGENT_PILOT_UID, WHATSAPP_AGENT_VERSION, AgentMessage } from "./whatsappAgentCore";
import { istDateKey, yesterdayIST, parseMealDate, LogDateSelection } from "./whatsappDates";
import { downloadWhatsAppAudio, downloadWhatsAppImage, whatsappMealId } from "./whatsappMedia";

const configPath = "app/whatsappAgent";
const inboxPath = "whatsappAgentInbox";
export interface AgentServices {
  model: string;
  transcribe: (buffer: Buffer, filename: string, mimeType: string) => Promise<string>;
  estimate: (uid: string, text: string, type: string, country: string, image?: string) => Promise<MealLogResponse>;
  send: (to: string, text: string) => Promise<void>;
  buttons: (to: string, text: string, buttons: { id: string; title: string }[]) => Promise<void>;
  react: (to: string, messageId: string, emoji: string) => Promise<void>;
  confirm: (to: string, id: string, text: string, estimate: MealLogResponse, timestamp: admin.firestore.Timestamp) => Promise<void>;
}
async function enabled(uid: string, job?: admin.firestore.DocumentData): Promise<boolean> {
  if (uid !== WHATSAPP_AGENT_PILOT_UID) return false;
  const db = admin.firestore();
  const [flag, pref] = await Promise.all([db.doc(configPath).get(), db.doc(`whatsappAgentPreferences/${uid}`).get()]);
  return agentAllowed(flag.data(), uid) && pref.data()?.legacy !== true && (!job ||
    (job.generation === (flag.data()?.generation || "") && job.preferenceEpoch === (pref.data()?.epoch || "")));
}

/** Only the pilot's free-form messages enter the new queue. All other users retain the existing path. */
export async function routeWhatsAppAgent(uid: string, from: string, message: any, svc: AgentServices): Promise<boolean> {
  if (uid !== WHATSAPP_AGENT_PILOT_UID) return false;
  const db = admin.firestore();
  const text = message.type === "text" ? String(message.text?.body || "").trim()
    : message.interactive?.button_reply?.id === "menu" ? "menu" : "";
  try {
    if (text === "/legacy" || text === "/agent") {
      if (text === "/agent" && !agentAllowed((await db.doc(configPath).get()).data(), uid)) {
        await svc.send(from, "The private agent pilot is paused. Your existing meal bot is still available.");
      } else {
        await db.doc(`whatsappAgentPreferences/${uid}`).set({ legacy: text === "/legacy", epoch: randomUUID() });
        await svc.send(from, text === "/legacy" ? "Switched back to your existing meal bot. Send /agent to return to the private pilot." : "Your private LogCal agent is on. Ask about your meals, nutrition, or workouts, or send a meal to log.");
      }
      return true;
    }
    // A redelivered agent message must not become a legacy meal after rollback.
    if (message.id && (await db.collection(inboxPath).doc(whatsappMealId(uid, message.id)).get()).exists) return true;
    if (!await enabled(uid)) return false;
  } catch (error) {
    console.warn("WHATSAPP_AGENT_GATE_UNAVAILABLE", { error });
    // Once the configured pilot is being routed, uncertainty must never turn a
    // question into a legacy meal. Non-pilot accounts never read this gate.
    await svc.send(from, "I couldn't check your chat mode. Please try again shortly; nothing was logged.");
    return true;
  }
  const button = message.interactive?.button_reply?.id;
  if (message.type === "interactive" && button !== "menu") return false;
  if (["summary", "today", "progress", "unlink", "/unlink", "cancel"].includes(text.toLowerCase())) return false;
  if (["menu", "help", "hi", "hello"].includes(text.toLowerCase())) {
    await svc.buttons(from, "👋 *Your LogCal agent*\n\nSend a meal to log, ask about your logged nutrition, or ask for nutrition/workout advice. Text, voice and photos work.\n\nExamples:\n• How much protein did I log yesterday?\n• What could I eat tonight to meet my goal?\n• Suggest a beginner dumbbell workout.\n\nWorkout tracking isn't connected yet. Send /legacy to return to the existing bot.", [
      { id: "summary", title: "Today's Progress" }, { id: "date:start", title: "Log for another day" }, { id: "menu", title: "Main Menu" },
    ]);
    return true;
  }
  const state = (await db.doc(`users/${uid}/whatsappState/edit`).get()).data();
  if (state?.from === from && state.expiresAt > Date.now() && message.type === "text") {
    const dateReply = (state.mode === "editDate" || state.mode === "logDate" && state.stage !== "ready") && Boolean(parseMealDate(text));
    const correction = state.mode !== "logDate" && /^(?:actually\b|(?:please\s+)?(?:change|make|remove|replace|correct|reduce|increase|adjust|keep)\b)/i.test(text);
    if (dateReply || correction) return false;
  }
  if (button) return false;
  if (!message.id) { await svc.send(from, "I couldn't identify that message. Please send it again."); return true; }
  const ref = db.collection(inboxPath).doc(whatsappMealId(uid, message.id));
  await db.runTransaction(async tx => {
    if ((await tx.get(ref)).exists) return;
    const flag = (await tx.get(db.doc(configPath))).data();
    const pref = (await tx.get(db.doc(`whatsappAgentPreferences/${uid}`))).data();
    if (!agentAllowed(flag, uid) || pref?.legacy === true) throw new Error("The pilot changed while queuing. Please retry.");
    const queueRef = db.doc(`whatsappAgentQueues/${uid}`);
    const queue = (await tx.get(queueRef)).data()?.ids || [];
    if (queue.length >= 30) throw new Error("Your agent queue is full; please retry shortly");
    tx.set(queueRef, { ids: [...queue, ref.id] });
    tx.set(ref, { uid, from, message, generation: flag?.generation || "", preferenceEpoch: pref?.epoch || "", version: WHATSAPP_AGENT_VERSION, status: "queued", attempts: 0,
      createdAt: admin.firestore.Timestamp.now() });
  });
  return true;
}

function profile(data: admin.firestore.DocumentData): Record<string, unknown> {
  const result: Record<string, unknown> = {};
  for (const key of ["country", "dailyGoal", "proteinGoal", "carbsGoal", "fatGoal", "dietStyle"]) {
    if (typeof data[key] === "string" || typeof data[key] === "number") result[key] = data[key];
  }
  return result;
}
function round(n: number) { return Math.round(n * 10) / 10; }

/** Queries structured records; sums and averages are calculated here, never by the model. */
export async function nutritionData(uid: string, args: Record<string, unknown>): Promise<unknown> {
  const start = checkedDate(args.start_date), end = checkedDate(args.end_date);
  const count = Math.round((Date.parse(end) - Date.parse(start)) / 86400000) + 1;
  if (count < 1 || count > 92) throw new Error("Choose a date range of 1–92 days.");
  if (args.food_filter !== null && (typeof args.food_filter !== "string" || args.food_filter.length > 100)) throw new Error("Invalid food filter");
  const filter = typeof args.food_filter === "string" ? args.food_filter.trim().toLowerCase() : "";
  const query = await admin.firestore().collection("users").doc(uid).collection("meals")
    .where("timestamp", ">=", admin.firestore.Timestamp.fromDate(new Date(`${start}T00:00:00+05:30`)))
    .where("timestamp", "<", admin.firestore.Timestamp.fromDate(new Date(new Date(`${end}T00:00:00+05:30`).getTime() + 86400000)))
    .orderBy("timestamp").limit(501).get();
  const days: Record<string, { calories: number; protein: number; carbs: number; fat: number; fiber: number; mealCount: number; missingMacros: number }> = {};
  const rows: unknown[] = [];
  let matches = 0;
  for (const doc of query.docs.slice(0, 500)) {
    const meal = doc.data(); if (meal.deleted) continue;
    let estimate: any = {}; try { estimate = JSON.parse(meal.rawResponseJson || "{}"); } catch { /* Missing nutrition is reported. */ }
    const names = `${meal.foodText || ""} ${(estimate.items || []).map((item: any) => item.name).join(" ")}`;
    if (filter && !names.toLowerCase().includes(filter)) continue;
    matches++;
    const day = istDateKey(meal.timestamp.toDate());
    const aggregate = days[day] ||= { calories: 0, protein: 0, carbs: 0, fat: 0, fiber: 0, mealCount: 0, missingMacros: 0 };
    aggregate.mealCount++; aggregate.calories += Number.isFinite(meal.totalCalories) ? meal.totalCalories : 0;
    const macros: Record<string, number | null> = {};
    for (const key of ["protein", "carbs", "fat", "fiber"] as const) {
      macros[key] = Number.isFinite(estimate[key]) ? estimate[key] : null;
      if (macros[key] !== null) aggregate[key] += macros[key]!;
    }
    if (Object.values(macros).some(v => v === null)) aggregate.missingMacros++;
    if (rows.length < 80) rows.push({ id: doc.id, date: day, food: String(meal.foodText || "").slice(0, 200),
      mealType: meal.mealType || "Meal", calories: meal.totalCalories || 0, ...macros });
  }
  const total = { calories: 0, protein: 0, carbs: 0, fat: 0, fiber: 0, mealCount: 0, missingMacros: 0 };
  for (const day of Object.values(days)) for (const key of Object.keys(total) as (keyof typeof total)[]) total[key] += day[key];
  const loggedDays = Object.keys(days).length;
  return { start, end, timezone: "Asia/Kolkata", foodFilter: filter || null,
    totalsScope: filter ? "Totals include whole meals matching this food, not only the matching ingredient. Ingredient-only nutrient totals are not available from this query." : "Whole logged meals", daysRequested: count, daysWithMatchingLogs: loggedDays,
    totals: Object.fromEntries(Object.entries(total).map(([k,v]) => [k, round(v)])),
    averagesPerRequestedDay: { calories: round(total.calories / count), protein: round(total.protein / count) },
    averagesPerLoggedDay: loggedDays ? { calories: round(total.calories / loggedDays), protein: round(total.protein / loggedDays) } : null,
    days, meals: rows, matchingMeals: matches, mealRowsTruncated: matches > rows.length,
    queryTruncated: query.docs.length > 500, note: "Missing logs do not mean no food was eaten. Macros missing from records are not known zeros. All nutrition is estimated." };
}

export async function processWhatsAppAgentJob(id: string, svc: AgentServices): Promise<void> {
  const db = admin.firestore(), jobRef = db.collection(inboxPath).doc(id);
  const first = (await jobRef.get()).data();
  if (!first) return;
  if (["done", "cancelled", "terminal_failed"].includes(first.status)) { await removeFromQueue(first.uid, id); return; }
  if (!await enabled(first.uid, first)) {
    await jobRef.update({ status: "cancelled" }); await removeFromQueue(first.uid, id); return;
  }
  const lock = db.doc(`whatsappAgentLocks/${first.uid}`), lease = Date.now() + 6 * 60000;
  const acquired = await db.runTransaction(async tx => {
    const job = (await tx.get(jobRef)).data(); const held = (await tx.get(lock)).data();
    const queue = (await tx.get(db.doc(`whatsappAgentQueues/${first.uid}`))).data()?.ids || [];
    if (queue.length && queue[0] !== id) throw new Error("An earlier chat turn is queued; retry later");
    if (!job || ["done", "cancelled", "terminal_failed"].includes(job.status)) return false;
    if (held?.expiresAt > Date.now()) {
      throw new Error("Another agent turn is processing; retry in order");
    }
    tx.set(lock, { jobId: id, expiresAt: lease });
    tx.update(jobRef, { status: "processing", attempts: (job.attempts || 0) + 1 }); return true;
  });
  if (!acquired) return;
  const sessionRef = db.doc(`whatsappAgentSessions/${first.uid}`);
  try {
    const job = (await jobRef.get()).data()!;
    if (job.attempts > 3) throw new Error("Agent retry limit reached");
    const userRef = db.doc(`users/${job.uid}`), user = (await userRef.get()).data();
    if (!user || user.whatsappPhoneNumber !== job.from) throw new Error("Linked account changed");
    const session = (await sessionRef.get()).data();
    const history: AgentMessage[] = session?.updatedAt?.toMillis() > Date.now() - 86400000 ? session?.messages || [] : [];
    let text = job.message.type === "text" ? job.message.text.body : job.message.image?.caption || "";
    let image: string | undefined;
    await svc.react(job.from, job.message.id, "⏳");
    const token = process.env.WHATSAPP_ACCESS_TOKEN?.trim(), phone = process.env.WHATSAPP_PHONE_NUMBER_ID?.trim();
    if (!token || !phone) throw new Error("WhatsApp credentials unavailable");
    if (job.message.type === "audio") {
      const audio = await downloadWhatsAppAudio(job.message.audio.id, phone, token, 4 * 1024 * 1024);
      text = await svc.transcribe(audio.buffer, audio.filename, audio.mimeType);
      if (!text.trim()) throw new Error("No speech was detected");
    }
    if (job.message.type === "image") {
      const photo = await downloadWhatsAppImage(job.message.image.id, phone, token);
      image = `data:${photo.mimeType};base64,${photo.buffer.toString("base64")}`;
    }
    const dateRef = userRef.collection("whatsappState").doc("edit");
    const dateState = (await dateRef.get()).data();
    const selected: LogDateSelection | undefined = dateState?.mode === "logDate" && dateState?.stage === "ready" && dateState.from === job.from && dateState.expiresAt > Date.now()
      ? { date: dateState.date, requestId: dateState.requestId, token: dateState.token } : undefined;
    const execute = async (name: string, args: Record<string, unknown>): Promise<unknown> => {
      if (!await enabled(job.uid, job)) throw new Error("Agent pilot is disabled");
      if (name === "get_nutrition_data") return nutritionData(job.uid, args);
      if (!["estimate_meal", "record_meal"].includes(name)) throw new Error("Unsupported tool");
      if (typeof args.food_text !== "string" || (!args.food_text.trim() && !image) || args.food_text.length > 4000 || !["Breakfast", "Lunch", "Dinner", "Snack", "Meal"].includes(String(args.meal_type))) throw new Error("Invalid meal arguments");
      if (name === "record_meal" && job.mealResult) return { saved: !job.mealResult.deleted, ...job.mealResult };
      const date = name === "record_meal" ? args.date === null ? selected?.date || istDateKey() : checkedDate(args.date) : istDateKey();
      if (name === "record_meal" && date !== istDateKey() && date !== selected?.date) {
        const candidates = text.match(/\b\d{4}-\d{2}-\d{2}\b|\b\d{1,2}\s+[a-z]+\s+\d{4}\b/gi) || [];
        const dates = candidates.map((value: string) => parseMealDate(value));
        if (/\byesterday\b/i.test(text)) dates.push(yesterdayIST());
        if (!dates.includes(date)) throw new Error("The date must be specified by this user or selected through the menu. Ask for an explicit date.");
      }
      const type = String(args.meal_type);
      const estimate = await svc.estimate(job.uid, args.food_text, type, user.country || "India", image);
      if (name === "estimate_meal") return { saved: false, estimate };
      const mealId = whatsappMealId(job.uid, job.message.id), mealRef = userRef.collection("meals").doc(mealId);
      const timestamp = date === istDateKey() ? admin.firestore.Timestamp.now() : admin.firestore.Timestamp.fromDate(new Date(`${date}T12:00:00+05:30`));
      const description = args.food_text.trim() || estimate.items.map(item => item.name).join(", ") || "Meal photo";
      const result = { id: mealId, foodText: description, date, calories: estimate.total_calories };
      await db.runTransaction(async tx => {
        const flag = (await tx.get(db.doc(configPath))).data();
        const pref = (await tx.get(db.doc(`whatsappAgentPreferences/${job.uid}`))).data();
        const latest = (await tx.get(jobRef)).data();
        const account = (await tx.get(userRef)).data();
        const meal = await tx.get(mealRef);
        const state = selected ? (await tx.get(dateRef)).data() : undefined;
        if (!agentAllowed(flag, job.uid) || pref?.legacy === true || account?.whatsappPhoneNumber !== job.from ||
            (flag?.generation || "") !== job.generation || (pref?.epoch || "") !== job.preferenceEpoch || latest?.status !== "processing") throw new Error("Agent pilot was disabled or account changed; nothing new saved");
        if (latest?.mealResult) return;
        if (meal.exists) {
          const existing = meal.data()!;
          tx.update(jobRef, { mealResult: { id: mealId, foodText: existing.foodText, calories: existing.totalCalories,
            date: istDateKey(existing.timestamp.toDate()), deleted: existing.deleted === true } });
          return;
        }
        if (selected && (state?.requestId !== selected.requestId || state?.token !== selected.token || state?.date !== selected.date || state?.expiresAt <= Date.now())) throw new Error("Date selection changed; choose a date again before logging");
        const data = { id: mealId, timestamp, createdAt: admin.firestore.Timestamp.now(), foodText: description,
          mealType: estimate.meal_type || type, totalCalories: estimate.total_calories || 0,
          rawResponseJson: JSON.stringify(estimate), hasImage: Boolean(image), deleted: false };
        tx.set(mealRef, data);
        tx.set(db.collection("mealLogs").doc(mealId), { uid: job.uid, foodText: description, mealType: data.mealType,
          totalCalories: data.totalCalories, hasImage: data.hasImage, timestamp, deleted: false });
        tx.update(jobRef, { mealResult: result });
        if (selected) tx.delete(dateRef);
      });
      job.mealResult = (await jobRef.get()).data()?.mealResult;
      return { saved: Boolean(job.mealResult) && !job.mealResult.deleted, ...job.mealResult };
    };
    const reply = job.reply || await runAgentTurn({ text, imageDataUrl: image, history, profile: profile(user), selectedDate: selected?.date,
      alreadyLogged: job.mealResult, model: svc.model, apiKey: process.env.OPENAI_API_KEY || "", execute });
    await jobRef.update({ reply });
    if (!await enabled(job.uid, job)) { await jobRef.update({ status: "cancelled" }); return; }
    if (job.mealResult && !job.mealResult.deleted && !job.confirmationSent) {
      const meal = (await userRef.collection("meals").doc(job.mealResult.id).get()).data()!;
      await svc.confirm(job.from, job.mealResult.id, meal.foodText, JSON.parse(meal.rawResponseJson), meal.timestamp);
      await jobRef.update({ confirmationSent: true });
    }
    for (const chunk of splitReply(reply)) await svc.send(job.from, chunk);
    await svc.react(job.from, job.message.id, "✅");
    await sessionRef.set({ messages: [...history, { role: "user", text: text.slice(0, 2500) || "[Meal photo]" }, { role: "assistant", text: reply.slice(0, 2500) }].slice(-12),
      updatedAt: admin.firestore.Timestamp.now(), version: WHATSAPP_AGENT_VERSION });
    await jobRef.update({ status: "done", completedAt: admin.firestore.Timestamp.now() });
  } catch (error) {
    const latest = (await jobRef.get()).data()!;
    console.error("WHATSAPP_AGENT_TURN_FAILED", { id, attempts: latest.attempts, error });
    if (latest.attempts >= 3) {
      await jobRef.update({ status: "terminal_failed" });
      if (await enabled(first.uid, first)) {
        await svc.react(first.from, first.message.id, "⚠️");
        await svc.send(first.from, latest.mealResult ? "Your meal was saved, but I couldn't finish the answer. Check the meal confirmation or LogCal. Send /legacy to use the existing bot."
          : "I couldn't finish that request. No meal was saved. Please try again, or send /legacy to switch to the existing bot.");
      }
    } else { await jobRef.update({ status: "retrying" }); throw error; }
  } finally {
    await db.runTransaction(async tx => {
      const held = (await tx.get(lock)).data(); if (held?.jobId === id && held.expiresAt === lease) tx.delete(lock);
    });
    const status = (await jobRef.get()).data()?.status;
    if (["done", "cancelled", "terminal_failed"].includes(status)) await removeFromQueue(first.uid, id);
  }
}
function splitReply(text: string): string[] {
  const result: string[] = [];
  while (text.length > 3500) {
    let at = text.lastIndexOf("\n", 3500); if (at < 1500) at = 3500;
    const code = text.charCodeAt(at - 1); if (code >= 0xd800 && code <= 0xdbff) at--;
    result.push(text.slice(0, at)); text = text.slice(at).trimStart();
  }
  if (text) result.push(text); return result;
}

async function removeFromQueue(uid: string, id: string): Promise<void> {
  const db = admin.firestore(), ref = db.doc(`whatsappAgentQueues/${uid}`);
  await db.runTransaction(async tx => {
    const queue = (await tx.get(ref)).data()?.ids || [];
    tx.set(ref, { ids: queue.filter((value: string) => value !== id) });
  });
}
