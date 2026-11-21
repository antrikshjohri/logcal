import * as admin from "firebase-admin";
import type { MealLogResponse } from "./index";
import { istDateKey, yesterdayIST, parseMealDate, mealDateLabel, timestampDate, moveMealDate, LogDateSelection } from "./whatsappDates";
import { whatsappMealId } from "./whatsappMedia";

interface ActionContext {
  uid: string;
  from: string;
  messageId: string;
  messageType: string;
  text: string;
  buttonId?: string;
  send: (text: string) => Promise<void>;
  buttons: (text: string, buttons: { id: string; title: string }[]) => Promise<void>;
  react: (emoji: string) => Promise<void>;
  refine: (meal: admin.firestore.DocumentData, correction: string) => Promise<MealLogResponse>;
  confirm: (mealId: string, description: string, estimate: MealLogResponse, timestamp?: admin.firestore.Timestamp) => Promise<void>;
  onLogDate: (selection: LogDateSelection) => void;
}

class MealActionError extends Error {}
const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const commands = new Set(["help", "menu", "hi", "summary", "today", "progress", "unlink", "/unlink"]);

/** Returns true when this event belongs to an edit/delete conversation. */
export async function handleWhatsAppMealActions(ctx: ActionContext): Promise<boolean> {
  const db = admin.firestore();
  const user = db.collection("users").doc(ctx.uid);
  const stateRef = user.collection("whatsappState").doc("edit");
  const receiptRef = ctx.messageId
    ? user.collection("whatsappActions").doc(whatsappMealId(ctx.uid, ctx.messageId)) : undefined;
  const action = ctx.buttonId?.match(/^meal:(edit|delete|food|date):(.+)$/);
  let committed = false;
  let started = false;
  try {
    // Receipts ensure a retried correction cannot become a new meal after the
    // edit session is consumed. Button IDs are accepted only from button events.
    if (receiptRef && (await receiptRef.get()).exists) return true;
    const state = (await stateRef.get()).data();
    const ownState = state?.from === ctx.from ? state : undefined;
    const cancel = ctx.buttonId === "meal:cancel" ||
      (ctx.messageType === "text" && ctx.text.trim().toLowerCase() === "cancel");

    const dateStart = ctx.buttonId === "date:start";
    const dateButton = ctx.buttonId?.match(/^date:(today|yesterday|other):(.+)$/);
    if (!action && !cancel && !ownState && !dateStart && !dateButton) return false;
    if (!receiptRef) throw new MealActionError("Please send that action again.");

    const choosingDate = (ownState?.mode === "logDate" || ownState?.mode === "editDate") && ownState.stage !== "ready";
    const navigation = commands.has(ctx.text.trim().toLowerCase()) && !(choosingDate && ctx.text.trim().toLowerCase() === "today");
    if (cancel || (!action && !dateStart && !dateButton && (ctx.messageType === "text" || ctx.messageType === "interactive") && navigation)) {
      await db.runTransaction(async tx => {
        const current = (await tx.get(stateRef)).data();
        if (current?.from === ctx.from && current.requestId === ownState?.requestId) tx.delete(stateRef);
        tx.set(receiptRef, { action: "cancel", createdAt: admin.firestore.Timestamp.now() });
      });
      if (!cancel) return false;
      await ctx.send(ownState?.mode === "logDate"
        ? "Date selection cancelled. Your next meal will be logged for Today."
        : "Edit cancelled. Send your next meal whenever you're ready.");
      return true;
    }

    if (dateStart) {
      const token = whatsappMealId(ctx.uid, ctx.messageId);
      await db.runTransaction(async tx => {
        if ((await tx.get(receiptRef)).exists) return;
        tx.set(stateRef, { mode: "logDate", stage: "dateChoice", from: ctx.from,
          requestId: ctx.messageId, token, expiresAt: Date.now() + 15 * 60000 });
        tx.set(receiptRef, { action: "dateStart", createdAt: admin.firestore.Timestamp.now() });
      });
      await dateChoices(ctx, token, "Which date should your next meal be logged for?");
      return true;
    }
    if (dateButton && (!ownState || dateButton[2] !== ownState.token)) {
      await ctx.send("That date selection is no longer active. Open the menu or Edit meal to choose again.");
      return true;
    }
    if (ownState?.mode === "logDate" && ownState.stage === "ready" && !action && !dateButton && ownState.expiresAt > Date.now()) {
      ctx.onLogDate({ date: ownState.date, requestId: ownState.requestId, token: ownState.token });
      return false;
    }
    if (action) {
      const [, kind, mealId] = action;
      if (!UUID.test(mealId)) throw new MealActionError("That meal action isn't valid. Use the buttons on a meal confirmation.");
      const mealRef = user.collection("meals").doc(mealId);
      const syncRef = db.collection("mealLogs").doc(mealId);
      await db.runTransaction(async tx => {
        if ((await tx.get(receiptRef)).exists) return;
        const meal = (await tx.get(mealRef)).data();
        const sync = (await tx.get(syncRef)).data();
        const currentState = (await tx.get(stateRef)).data();
        if (!meal) throw new MealActionError("I couldn't find that meal in your account.");
        if (sync && sync.uid !== ctx.uid) throw new MealActionError("I couldn't verify that meal belongs to your account.");
        if (kind !== "delete") {
          if (meal.deleted) throw new MealActionError("That meal has been deleted and can't be edited.");
          tx.set(stateRef, {
            mealId, from: ctx.from, requestId: ctx.messageId,
            mode: kind === "date" ? "editDate" : kind === "food" ? "editFood" : "chooseEdit",
            stage: "dateChoice", token: whatsappMealId(ctx.uid, ctx.messageId),
            expiresAt: Date.now() + 15 * 60 * 1000,
          });
        } else {
          // Keep tombstones so the apps remove the meal on their next sync.
          tx.set(mealRef, { ...meal, deleted: true, updatedAt: admin.firestore.Timestamp.now() });
          tx.set(syncRef, {
            ...(sync || {}), uid: ctx.uid, foodText: meal.foodText,
            mealType: meal.mealType, totalCalories: meal.totalCalories,
            timestamp: meal.timestamp, hasImage: meal.hasImage || false, deleted: true,
          });
          if (currentState?.mealId === mealId) tx.delete(stateRef);
        }
        tx.set(receiptRef, { action: kind, mealId, createdAt: admin.firestore.Timestamp.now() });
      });
      committed = true;
      if (kind === "delete") {
        await ctx.react("✅");
        await ctx.send("🗑️ Meal deleted. It has been removed from your totals.");
      } else {
        const meal = (await mealRef.get()).data();
        const description = String(meal?.foodText || "this meal").slice(0, 250);
        if (kind === "date") {
          await dateChoices(ctx, whatsappMealId(ctx.uid, ctx.messageId), `Change date for "${description}"`);
        } else if (kind === "edit") {
          await ctx.buttons(`✏️ Editing: "${description}"\n\nWhat would you like to change? You can also type a food correction directly.`, [
            { id: `meal:food:${mealId}`, title: "Change food" },
            { id: `meal:date:${mealId}`, title: "Change date" },
            { id: "meal:cancel", title: "Cancel" },
          ]);
        } else await ctx.buttons(
          `✏️ Editing: "${description}"\n\nType what to change, for example: "Make the rice half a bowl" or "Remove the milk".\n\nYour next text message will update this meal. This edit expires in 15 minutes.`,
          [{ id: "meal:cancel", title: "Cancel" }],
        );
      }
      return true;
    }

    if (!ownState) return false;
    if (ownState.expiresAt <= Date.now()) {
      // An abandoned date/edit conversation must not eat a fresh meal hours
      // later. Media and ordinary meal text start fresh; explicit corrections
      // and date-picker replies still need their intended action selected again.
      const dateReply = ctx.messageType === "text" &&
        (Boolean(parseMealDate(ctx.text)) ||
          /^(?:\d{4}-\d{1,2}-\d{1,2}|\d{1,2}[/-]\d{1,2}[/-]\d{2,4}|\d{1,2}\s+[a-z]+\s+\d{4})$/i.test(ctx.text.trim()));
      const correctionReply = ownState.mode !== "logDate" && ctx.messageType === "text" &&
        /^(?:actually\b|(?:please\s+)?(?:change|make|remove|replace|correct|update|reduce|increase|decrease|adjust|keep)\b|(?:it|that)\s+(?:was|is|should)\b)/i.test(ctx.text.trim());
      const freshMeal = !dateButton && (ctx.messageType === "audio" || ctx.messageType === "image" ||
        (ctx.messageType === "text" && !dateReply && !correctionReply));
      const result = await db.runTransaction(async tx => {
        if ((await tx.get(receiptRef)).exists) return "handled";
        const current = (await tx.get(stateRef)).data();
        if (current && (current.requestId !== ownState.requestId || current.from !== ctx.from)) return "changed";
        if (current) tx.delete(stateRef);
        if (!freshMeal) tx.set(receiptRef, { action: "expired", createdAt: admin.firestore.Timestamp.now() });
        return "cleared";
      });
      if (result === "handled") return true;
      if (result === "changed") {
        await ctx.send("Your selection changed. Please resend your meal or use the current buttons.");
        return true;
      }
      if (freshMeal) return false;
      await ctx.send(ownState.mode === "logDate"
        ? "That date selection expired. Open Menu → Log for another day to choose again."
        : "That edit expired. Tap Edit meal again, then send your correction.");
      return true;
    }
    // Reserve every message received during an edit, including failed corrections
    // and media prompts. A delayed webhook retry must never become a new meal
    // after this session has ended.
    const claimed = await db.runTransaction(async tx => {
      if ((await tx.get(receiptRef)).exists) return false;
      tx.set(receiptRef, {
        action: "correction",
        ...(typeof ownState.mealId === "string" ? { mealId: ownState.mealId } : {}),
        createdAt: admin.firestore.Timestamp.now(),
      });
      return true;
    });
    if (!claimed) return true;
    if (ownState.mode === "editDate" || ownState.mode === "logDate") {
      if (dateButton?.[1] === "other") {
        await db.runTransaction(async tx => {
          const current = (await tx.get(stateRef)).data();
          if (current?.requestId !== ownState.requestId) throw new MealActionError("This date selection changed. Choose again from the menu.");
          tx.set(stateRef, { ...current, stage: "customDate" });
        });
        await ctx.buttons("Type a date such as 15 Oct 2026 or 2026-10-15 (IST). Please include the year.", [{ id: "meal:cancel", title: "Cancel" }]);
        return true;
      }
      const date = dateButton?.[1] === "today" ? istDateKey()
        : dateButton?.[1] === "yesterday" ? yesterdayIST()
        : ctx.messageType === "text" ? parseMealDate(ctx.text) : undefined;
      if (!date) {
        await ctx.buttons("Please enter a valid date such as 15 Oct 2026 or 2026-10-15. Future dates and ambiguous formats aren't supported.", [{ id: "meal:cancel", title: "Cancel" }]);
        return true;
      }
      let moved: admin.firestore.DocumentData | undefined;
      await db.runTransaction(async tx => {
        const session = (await tx.get(stateRef)).data();
        if (session?.requestId !== ownState.requestId || session?.expiresAt <= Date.now()) throw new MealActionError("This date selection changed or expired. Please choose again.");
        if (ownState.mode === "logDate") {
          tx.set(stateRef, { ...session, stage: "ready", date });
        } else {
          if (!UUID.test(ownState.mealId)) throw new MealActionError("Please select the meal again.");
          const mealRef = user.collection("meals").doc(ownState.mealId);
          const syncRef = db.collection("mealLogs").doc(ownState.mealId);
          const meal = (await tx.get(mealRef)).data();
          const sync = (await tx.get(syncRef)).data();
          if (!meal || meal.deleted) throw new MealActionError("That meal no longer exists or has been deleted.");
          if (sync && sync.uid !== ctx.uid) throw new MealActionError("I couldn't verify that meal belongs to your account.");
          const timestamp = admin.firestore.Timestamp.fromDate(moveMealDate(date, timestampDate(meal.timestamp)));
          moved = { ...meal, timestamp, updatedAt: admin.firestore.Timestamp.now() };
          tx.set(mealRef, moved);
          tx.set(syncRef, { ...(sync || {}), uid: ctx.uid, foodText: meal.foodText, mealType: meal.mealType,
            totalCalories: meal.totalCalories, hasImage: meal.hasImage || false, timestamp, deleted: false });
          tx.delete(stateRef);
        }
        tx.set(receiptRef, { action: "dateSelected", date, createdAt: admin.firestore.Timestamp.now() });
      });
      committed = true;
      if (moved) {
        await ctx.react("✅");
        await ctx.confirm(ownState.mealId, moved.foodText, JSON.parse(moved.rawResponseJson), moved.timestamp);
      } else {
        await ctx.buttons(`📅 Your next meal will be logged for *${mealDateLabel(date)}* (IST).\n\nSend text, a voice note, or a photo. This selection expires in 15 minutes. After saving, I'll return to Today.`, [{ id: "meal:cancel", title: "Cancel" }]);
      }
      return true;
    }
    if (ctx.messageType !== "text") {
      await ctx.buttons("Please type your correction for the selected meal, or cancel the edit to log a new meal.",
        [{ id: "meal:cancel", title: "Cancel" }]);
      return true;
    }
    const correction = ctx.text.trim();
    if (!correction || correction.length > 2000) throw new MealActionError("Please describe your correction in a shorter text message.");
    if (typeof ownState.mealId !== "string" || !UUID.test(ownState.mealId)) throw new MealActionError("Please cancel this edit and select the meal again.");
    const mealRef = user.collection("meals").doc(ownState.mealId);
    const syncRef = db.collection("mealLogs").doc(ownState.mealId);
    const base = (await mealRef.get()).data();
    if (!base || base.deleted) throw new MealActionError("That meal no longer exists. Cancel this edit to log a new meal.");
    started = true;
    await ctx.react("⏳");
    const estimate = await ctx.refine(base, correction);
    const description = estimate.items.map(item => `${item.quantity ? `${item.quantity} ` : ""}${item.name}`).join(", ") || base.foodText;
    let confirmedTimestamp = base.timestamp;
    const saved = await db.runTransaction(async tx => {
      if ((await tx.get(receiptRef)).data()?.action === "corrected") return false;
      const current = (await tx.get(mealRef)).data();
      const session = (await tx.get(stateRef)).data();
      const sync = (await tx.get(syncRef)).data();
      if (sync && sync.uid !== ctx.uid) throw new MealActionError("I couldn't verify that meal belongs to your account.");
      if (!current || current.deleted) throw new MealActionError("That meal was deleted while editing. Your correction wasn't saved.");
      if (session?.requestId !== ownState.requestId || session?.from !== ctx.from || session.expiresAt <= Date.now()) {
        throw new MealActionError("This edit was cancelled, replaced, or expired. Tap Edit meal again to retry.");
      }
      if (current.rawResponseJson !== base.rawResponseJson || current.foodText !== base.foodText || current.mealType !== base.mealType || current.totalCalories !== base.totalCalories) {
        throw new MealActionError("That meal changed while editing. Please send your correction again to use its latest values.");
      }
      const changes = {
        foodText: description, mealType: estimate.meal_type || current.mealType,
        totalCalories: estimate.total_calories, rawResponseJson: JSON.stringify(estimate),
        updatedAt: admin.firestore.Timestamp.now(),
      };
      confirmedTimestamp = current.timestamp;
      tx.set(mealRef, { ...current, ...changes });
      tx.set(syncRef, {
        ...(sync || {}), uid: ctx.uid, foodText: description,
        mealType: changes.mealType, totalCalories: changes.totalCalories,
        timestamp: current.timestamp, hasImage: current.hasImage || false, deleted: false,
      });
      tx.delete(stateRef);
      tx.set(receiptRef, { action: "corrected", mealId: ownState.mealId, createdAt: admin.firestore.Timestamp.now() });
      return true;
    });
    committed = true;
    await ctx.react("✅");
    if (saved) await ctx.confirm(ownState.mealId, description, estimate, confirmedTimestamp);
    return true;
  } catch (error) {
    console.error("ERROR: WhatsApp meal action failed:", error);
    if (started) await ctx.react(committed ? "✅" : "⚠️");
    await ctx.send(committed
      ? "Your meal action was saved, but I couldn't send its confirmation. Check LogCal to see the result."
      : error instanceof MealActionError ? error.message
      : "I couldn't complete that meal action. Please try again. If editing, send your correction again or tap Cancel.");
    return true;
  }
}

async function dateChoices(ctx: ActionContext, token: string, message: string): Promise<void> {
  await ctx.buttons(`📅 ${message} (IST)\nType Cancel to leave date selection.`, [
    { id: `date:today:${token}`, title: "Today" },
    { id: `date:yesterday:${token}`, title: "Yesterday" },
    { id: `date:other:${token}`, title: "Other date" },
  ]);
}
