import { createHash } from "crypto";

export class WhatsAppMediaError extends Error {}

const AUDIO_EXTENSIONS: Record<string, string> = {
  "audio/ogg": "ogg",
  "application/ogg": "ogg",
  "audio/mpeg": "mp3",
  "audio/mp3": "mp3",
  "audio/mp4": "m4a",
  "audio/m4a": "m4a",
  "audio/x-m4a": "m4a",
  "audio/wav": "wav",
  "audio/x-wav": "wav",
  "audio/webm": "webm",
  "audio/flac": "flac",
};

/** Stable UUID-shaped ID keeps webhook retries compatible with client meal IDs. */
export function whatsappMealId(uid: string, messageId: string): string {
  const bytes = createHash("sha256").update(JSON.stringify([uid, messageId])).digest().subarray(0, 16);
  bytes[6] = (bytes[6] & 0x0f) | 0x80; // UUID version 8 (custom deterministic ID)
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  const hex = bytes.toString("hex").toUpperCase();
  return `${hex.slice(0, 8)}-${hex.slice(8, 12)}-${hex.slice(12, 16)}-${hex.slice(16, 20)}-${hex.slice(20)}`;
}

async function downloadWhatsAppMedia(
  mediaId: string,
  phoneNumberId: string,
  accessToken: string,
  maxBytes: number,
  kind: "audio" | "image",
): Promise<{ buffer: Buffer; filename: string; mimeType: string }> {
  const label = kind === "image" ? "photo" : "voice note";
  if (!/^\d+$/.test(mediaId)) {
    throw new WhatsAppMediaError(`I couldn't read that ${label}. Please send it again.`);
  }
  const headers = { Authorization: `Bearer ${accessToken}` };
  const metadataResponse = await fetch(
    `https://graph.facebook.com/v23.0/${mediaId}?phone_number_id=${encodeURIComponent(phoneNumberId)}`,
    { headers, signal: AbortSignal.timeout(15000), redirect: "error" },
  );
  if (!metadataResponse.ok) throw new Error(`WhatsApp media lookup failed: ${metadataResponse.status}`);
  const metadata = await metadataResponse.json() as { url?: string; mime_type?: string; file_size?: number };
  const mimeType = (metadata.mime_type || "").split(";")[0].trim().toLowerCase();
  const extension = kind === "image"
    ? ({ "image/jpeg": "jpg", "image/png": "png" } as Record<string, string>)[mimeType]
    : AUDIO_EXTENSIONS[mimeType];
  if (!extension) {
    throw new WhatsAppMediaError(kind === "image"
      ? "That photo format isn't supported. Please send a JPEG or PNG photo."
      : "That audio format isn't supported. Please send a voice note recorded in WhatsApp.");
  }
  const tooLarge = () => new WhatsAppMediaError(kind === "image"
    ? "That photo is too large. Please send a smaller photo."
    : "That voice note is too large (maximum 4 MB). Please send a shorter recording.");
  if (Number(metadata.file_size) > maxBytes) throw tooLarge();
  const url = new URL(metadata.url || "");
  // Only send the bearer token to Meta's media hosts, without following redirects.
  if (url.protocol !== "https:" || url.username || url.password ||
      !(url.hostname.endsWith(".fbsbx.com") || url.hostname.endsWith(".facebook.com") || url.hostname.endsWith(".fbcdn.net"))) {
    throw new Error("Unexpected WhatsApp media download URL");
  }
  const response = await fetch(url, { headers, signal: AbortSignal.timeout(30000), redirect: "error" });
  if (!response.ok) throw new Error(`WhatsApp media download failed: ${response.status}`);
  if (Number(response.headers.get("content-length")) > maxBytes) {
    await response.body?.cancel();
    throw tooLarge();
  }
  if (!response.body) throw new Error("Missing WhatsApp media body");
  const reader = response.body.getReader();
  const chunks: Buffer[] = [];
  let size = 0;
  try {
    while (true) {
      const { done, value } = await reader.read();
      if (done) break;
      size += value.byteLength;
      if (size > maxBytes) {
        await reader.cancel();
        throw tooLarge();
      }
      chunks.push(Buffer.from(value));
    }
  } finally {
    reader.releaseLock();
  }
  if (size === 0) throw new WhatsAppMediaError(`That ${label} was empty. Please send it again.`);
  const buffer = Buffer.concat(chunks);
  if (kind === "image") {
    const valid = mimeType === "image/jpeg"
      ? buffer.length >= 3 && buffer[0] === 0xff && buffer[1] === 0xd8 && buffer[2] === 0xff
      : buffer.length >= 8 && buffer.subarray(0, 8).equals(Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]));
    if (!valid) throw new WhatsAppMediaError("I couldn't read that photo. Please send a JPEG or PNG photo again.");
  }
  return { buffer, filename: `${kind === "image" ? "meal-photo" : "voice-note"}.${extension}`, mimeType };
}

export function downloadWhatsAppAudio(mediaId: string, phoneNumberId: string, accessToken: string, maxBytes: number) {
  return downloadWhatsAppMedia(mediaId, phoneNumberId, accessToken, maxBytes, "audio");
}

export function downloadWhatsAppImage(mediaId: string, phoneNumberId: string, accessToken: string) {
  return downloadWhatsAppMedia(mediaId, phoneNumberId, accessToken, 5 * 1024 * 1024, "image");
}
