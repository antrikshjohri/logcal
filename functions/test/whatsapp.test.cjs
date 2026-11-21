const { test, beforeEach, afterEach } = require('node:test');
const assert = require('node:assert/strict');
const Module = require('node:module');
const { EventEmitter } = require('node:events');
const { downloadWhatsAppAudio } = require('../lib/whatsappAudio');

let records, replies, linked, calls, transcript, reactions, reactionFailure, confirmationFailure, mealItems, mediaMime, estimateCalories;
const realFetch = global.fetch;
const originalEnv = { ...process.env };
const snapshot = (path) => ({ exists: records.has(path), data: () => records.has(path) ? { ...records.get(path) } : undefined });
const doc = (path) => ({
  id: path.split('/').at(-1), path,
  get: async () => snapshot(path),
  collection: (name) => collection(`${path}/${name}`),
  update: async () => { throw new Error('Unexpected account mutation'); },
});
const collection = (path) => ({
  doc: (id) => doc(`${path}/${id}`),
  where: (field, operator, value) => path.endsWith('/meals') ? {
    filters: [[field, operator, value]],
    where(field, operator, value) { this.filters.push([field, operator, value]); return this; },
    async get() { return { forEach: (fn) => {
      for (const [key, data] of records) if (key.startsWith(`${path}/`) && this.filters.every(([field, op, value]) =>
        op === '>=' ? data[field] >= value : op === '<=' ? data[field] <= value : data[field] === value)) fn(snapshot(key));
    } }; },
  } : ({ get: async () => ({ empty: !linked, docs: linked ? [
    { id: 'test-user', data: () => ({ country: 'India' }), ref: doc('users/test-user') },
  ] : [] }) }),
});
function validateFirestoreData(value, path = 'data') {
  if (value === undefined) throw new Error(`Cannot use undefined as a Firestore value at ${path}`);
  if (value && typeof value === 'object' && !(value instanceof Date)) {
    for (const [key, child] of Object.entries(value)) validateFirestoreData(child, `${path}.${key}`);
  }
}
let transactionTail = Promise.resolve();
const firestore = () => ({
  collection,
  runTransaction: (fn) => {
    const next = transactionTail.then(() => fn({
      get: async (ref) => snapshot(ref.path),
      set: (ref, data) => { validateFirestoreData(data); records.set(ref.path, data); },
      delete: (ref) => records.delete(ref.path),
    }));
    transactionTail = next.catch(() => {});
    return next;
  },
});
firestore.Timestamp = { now: () => new Date(), fromDate: date => date };
const builder = { runWith: () => builder, https: { onCall: (fn) => fn, onRequest: (fn) => fn } };
const fakeHttps = {
  request: (_options, callback) => {
    const req = new EventEmitter();
    let body = '';
    req.write = (chunk) => { body += chunk; };
    req.end = () => {
      replies.push(JSON.parse(body));
      const res = new EventEmitter();
      res.statusCode = confirmationFailure && JSON.parse(body).type === 'interactive' ? 503 : 200;
      callback(res);
      res.emit('data', '{}');
      res.emit('end');
    };
    return req;
  },
};
const originalLoad = Module._load;
Module._load = function (name, ...args) {
  if (name === 'firebase-admin') return { initializeApp() {}, firestore };
  if (name === 'firebase-functions') return { region: () => builder, https: { HttpsError: Error } };
  if (name === 'https') return fakeHttps;
  return originalLoad.call(this, name, ...args);
};
const { transcribeAudio, whatsappWebhook } = require('../lib/index');
Module._load = originalLoad;

const metadata = (overrides = {}) => Response.json({
  url: 'https://lookaside.fbsbx.com/whatsapp_business/attachments/audio',
  mime_type: 'audio/ogg; codecs=opus', file_size: 3, ...overrides,
});
beforeEach(() => {
  records = new Map(); replies = []; calls = []; linked = true; transcript = 'two bananas';
  reactions = []; reactionFailure = false; confirmationFailure = false; mealItems = []; mediaMime = "audio/ogg; codecs=opus"; estimateCalories = 210;
  process.env.OPENAI_API_KEY = 'test-only-key';
  process.env.WHATSAPP_ACCESS_TOKEN = 'test-token';
  process.env.WHATSAPP_PHONE_NUMBER_ID = '123';
  global.fetch = async (input, options) => {
    const url = String(input);
    if (url.startsWith('https://graph.facebook.com/') && options?.method === 'POST') {
      const payload = JSON.parse(options.body);
      assert.equal(payload.type, 'reaction');
      assert.equal(payload.to, '919999999999');
      assert.equal(typeof payload.reaction.message_id, 'string');
      reactions.push({ emoji: payload.reaction.emoji, saved: meals().length > 0 });
      if (reactionFailure === 'network') throw new Error('Network failure');
      return Response.json({}, { status: reactionFailure ? 503 : 200 });
    }
    calls.push({ url, options });
    if (url.startsWith('https://graph.facebook.com/')) return metadata({ mime_type: mediaMime });
    if (url.startsWith('https://lookaside.fbsbx.com/')) return new Response(mediaMime === 'image/png' ? png : mediaMime === 'image/jpeg' ? jpeg : 'ogg');
    if (url.endsWith('/audio/transcriptions')) return Response.json({ text: transcript });
    if (url.endsWith('/responses')) return Response.json({ output_text: JSON.stringify({ meal_type: 'Lunch', total_calories: 360, items: mealItems }) });
    if (url.endsWith('/chat/completions')) return Response.json({ choices: [{ message: { content: JSON.stringify({
      meal_type: 'Snack', total_calories: estimateCalories, protein: 2, carbs: 54, fat: 1, fiber: 6, items: mealItems,
    }) } }] });
    throw new Error(`Unexpected fetch: ${url}`);
  };
});
afterEach(() => { global.fetch = realFetch; process.env = { ...originalEnv }; });

async function receive(message = {}) {
  const res = { status(code) { this.code = code; return this; }, send() {} };
  await whatsappWebhook({ method: 'POST', body: { entry: [{ changes: [{ value: { messages: [{
    from: '919999999999', id: 'wamid.test', type: 'audio', audio: { id: '456' }, ...message,
  }] } }] }] } }, res);
  assert.equal(res.code, 200);
}
const textReplies = () => replies.map((reply) => reply.text?.body || reply.interactive?.body?.text || '').join('\n');
const meals = () => [...records].filter(([key]) => key.startsWith('users/test-user/meals/'));

test('voice note downloads, transcribes OGG, logs both copies and replies with transcript', async () => {
  await receive();
  assert.equal(meals().length, 1);
  assert.equal(records.size, 2);
  assert.equal(meals()[0][1].foodText, 'two bananas');
  assert.match(textReplies(), /two bananas/);
  const request = calls.find(({ url }) => url.endsWith('/audio/transcriptions'));
  assert.equal(request.options.body.get('file').name, 'voice-note.ogg');
  assert.equal(request.options.body.get('file').type, 'audio/ogg');
  assert.equal(request.options.body.get('model'), 'gpt-transcribe');
  assert.deepEqual(request.options.body.getAll('languages[]'), []);
  assert.equal(calls[1].options.headers.Authorization, 'Bearer test-token');
});
test('mobile dictation adapts the existing language hint to the OpenAI request', async () => {
  const result = await transcribeAudio({
    audioBase64: Buffer.from('audio').toString('base64'),
    mimeType: 'audio/m4a',
    language: 'hi-IN',
  }, { auth: { uid: 'test-user' } });
  assert.equal(result.text, 'two bananas');
  const request = calls.find(({ url }) => url.endsWith('/audio/transcriptions'));
  assert.equal(request.options.body.get('file').name, 'dictation.m4a');
  assert.equal(request.options.body.get('model'), 'gpt-transcribe');
  assert.deepEqual(request.options.body.getAll('languages[]'), ['hi']);
  assert.equal(request.options.body.has('language'), false);
});
test('unlinked audio sender receives onboarding without download or transcription', async () => {
  linked = false;
  await receive();
  assert.equal(calls.length, 0);
  assert.match(textReplies(), /link your phone number/);
});
test('empty transcription replies with an actionable error without saving', async () => {
  transcript = ' ';
  await receive();
  assert.equal(records.size, 0);
  assert.match(textReplies(), /couldn't hear any words/);
});
test('transcription failure replies without logging a meal', async () => {
  const fetch = global.fetch;
  global.fetch = (url, opts) => String(url).endsWith('/audio/transcriptions')
    ? Promise.resolve(new Response('Unavailable', { status: 503 })) : fetch(url, opts);
  await receive();
  assert.equal(records.size, 0);
  assert.match(textReplies(), /couldn't transcribe/);
});
test('spoken unlink does not execute the account command', async () => {
  transcript = 'unlink';
  await receive();
  assert.equal(meals().length, 1);
});
test('sequential and concurrent webhook retries save only one meal', async () => {
  await Promise.all([receive(), receive()]);
  assert.equal(meals().length, 1);
  assert.equal(records.size, 2);
  assert.equal(replies.filter((reply) => reply.interactive).length, 1);
  const count = calls.length;
  await receive();
  assert.equal(calls.length, count);
});
test('text meal still logs without any transcription requests', async () => {
  await receive({ type: 'text', text: { body: 'one apple' } });
  assert.equal(meals()[0][1].foodText, 'one apple');
  assert.equal(calls.length, 1);
  assert.match(calls[0].url, /chat\/completions$/);
});
test('menu button still responds without calling OpenAI', async () => {
  await receive({ type: 'interactive', interactive: { button_reply: { id: 'menu' } } });
  assert.equal(calls.length, 0);
  assert.match(textReplies(), /voice note/);
});
test('oversized metadata is rejected before downloading', async () => {
  global.fetch = async () => metadata({ file_size: 5 * 1024 * 1024 });
  await receive();
  assert.equal(records.size, 0);
  assert.match(textReplies(), /maximum 4 MB/);
});
test('stream size limit holds even without content-length', async () => {
  let count = 0;
  global.fetch = async () => ++count === 1 ? metadata({ file_size: undefined }) : new Response('oversized');
  await assert.rejects(downloadWhatsAppAudio('456', '123', 'token', 3), /too large/);
});
test('unexpected media host never receives access token', async () => {
  let count = 0;
  global.fetch = async () => { count++; return metadata({ url: 'https://example.com/audio' }); };
  await assert.rejects(downloadWhatsAppAudio('456', '123', 'token', 1024), /Unexpected/);
  assert.equal(count, 1);
});
test('unsupported audio format gets a useful reply', async () => {
  global.fetch = async () => metadata({ mime_type: 'audio/aac' });
  await receive();
  assert.equal(records.size, 0);
  assert.match(textReplies(), /format isn't supported/);
});

test('voice and text reactions progress from pending to saved after the commit', async () => {
  await receive();
  assert.deepEqual(reactions, [{ emoji: '⏳', saved: false }, { emoji: '✅', saved: true }]);
  records.clear(); reactions = [];
  await receive({ type: 'text', text: { body: 'one apple' } });
  assert.deepEqual(reactions, [{ emoji: '⏳', saved: false }, { emoji: '✅', saved: true }]);
});
test('failed transcription replaces pending with warning', async () => {
  transcript = '';
  await receive();
  assert.deepEqual(reactions.map(r => r.emoji), ['⏳', '⚠️']);
  assert.equal(records.size, 0);
});
test('reaction HTTP and network failures never prevent saving or confirmation', async () => {
  for (const failure of ['http', 'network']) {
    records.clear(); replies = []; reactionFailure = failure;
    await receive();
    assert.equal(meals().length, 1);
    assert.match(textReplies(), /Logged/);
  }
});
test('confirmation failure keeps success reaction and reports the meal was saved', async () => {
  confirmationFailure = true;
  await receive();
  assert.equal(meals().length, 1);
  assert.ok(reactions.every(r => r.emoji !== '⚠️'));
  assert.match(textReplies(), /Your meal was saved/);
});
test('onboarding and menu do not receive meal progress reactions', async () => {
  linked = false;
  await receive();
  linked = true;
  await receive({ type: 'interactive', interactive: { button_reply: { id: 'menu' } } });
  assert.deepEqual(reactions, []);
});
test('completed retries restore success without showing pending again', async () => {
  await receive();
  reactions = [];
  await receive();
  assert.deepEqual(reactions, [{ emoji: '✅', saved: true }]);
});

test('text and voice confirmations show the same item breakdown saved in the app', async () => {
  mealItems = [
    { name: 'Bananas', quantity: '2 medium', calories: 210 },
    { name: 'Milk', quantity: '250 ml', calories: 150 },
  ];
  for (const message of [{}, { type: 'text', text: { body: 'bananas and milk' } }]) {
    records.clear(); replies = [];
    await receive(message);
    assert.match(textReplies(), /• \*Bananas\* \(2 medium\) — 210 kcal/);
    assert.match(textReplies(), /• \*Milk\* \(250 ml\) — 150 kcal/);
    const saved = JSON.parse(meals()[0][1].rawResponseJson);
    assert.deepEqual(saved.items, mealItems);
    assert.match(textReplies(), new RegExp(`Total: ${saved.total_calories} kcal`));
  }
});
test('long breakdown preserves all items and keeps the button message within its limit', async () => {
  mealItems = Array.from({ length: 80 }, (_, i) => ({
    name: `Item ${i + 1}`, quantity: '1 serving', calories: i + 1,
  }));
  await receive();
  const details = replies.filter(r => r.type === 'text').map(r => r.text.body).join('\n');
  for (const item of mealItems) {
    assert.ok(details.includes(`• *${item.name}* (${item.quantity}) — ${item.calories} kcal`));
  }
  const confirmation = replies.find(r => r.type === 'interactive');
  assert.ok(confirmation.interactive.body.text.length <= 1024);
  assert.match(confirmation.interactive.body.text, /Total:/);
  assert.equal(confirmation.interactive.action.buttons.length, 3);
});
test('missing item breakdown still returns totals without an empty list', async () => {
  mealItems = undefined;
  await receive();
  assert.match(textReplies(), /Total: 210 kcal/);
  assert.ok(!textReplies().includes('•'));
});

const png = Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aD1sAAAAASUVORK5CYII=', 'base64');
const jpeg = Buffer.from([0xff, 0xd8, 0xff, 0xe0, 0, 2, 0xff, 0xd9]);
const photo = (caption) => ({ type: 'image', image: { id: '456', ...(caption === undefined ? {} : { caption }) } });
function imageFixture() {
  mediaMime = 'image/png';
  mealItems = [{ name: 'Rice', quantity: '1 bowl', calories: 210 }];
}
test('captionless photo reaches vision and saves an item-based description with image flag', async () => {
  imageFixture();
  await receive(photo());
  const request = calls.find(c => c.url.endsWith('/chat/completions'));
  const body = JSON.parse(request.options.body);
  const image = body.messages[1].content.find(c => c.type === 'image_url');
  assert.equal(image.image_url.url, `data:image/png;base64,${png.toString('base64')}`);
  assert.equal(meals()[0][1].foodText, 'Rice');
  assert.equal(meals()[0][1].hasImage, true);
  assert.ok([...records.values()].every(r => r.hasImage));
  assert.match(textReplies(), /Rice/);
  assert.deepEqual(reactions.map(r => r.emoji), ['⏳', '✅']);
});
test('JPEG photo preserves format and caption as vision context', async () => {
  imageFixture(); mediaMime = 'image/jpeg';
  await receive(photo('Rice with one teaspoon of oil'));
  const body = JSON.parse(calls.find(c => c.url.endsWith('/chat/completions')).options.body);
  assert.match(body.messages[1].content[0].text, /one teaspoon of oil/);
  assert.equal(body.messages[1].content[1].image_url.url, `data:image/jpeg;base64,${jpeg.toString('base64')}`);
  assert.equal(meals()[0][1].foodText, 'Rice with one teaspoon of oil');
});
test('photo uses Responses vision route and account search entitlement when enabled', async () => {
  imageFixture();
  records.set('entitlements/test-user', { lunaEnabled: true, webSearchEnabled: true });
  await receive(photo());
  const body = JSON.parse(calls.find(c => c.url.endsWith('/responses')).options.body);
  assert.equal(body.input[0].content[1].type, 'input_image');
  assert.equal(body.input[0].content[1].image_url, `data:image/png;base64,${png.toString('base64')}`);
  assert.equal(body.tools[0].type, 'web_search');
  assert.equal(meals().length, 1);
});
test('photo captions never trigger menu or account commands', async () => {
  imageFixture();
  await receive(photo('unlink'));
  assert.equal(meals().length, 1);
  assert.equal(meals()[0][1].foodText, 'unlink');
});
test('unlinked photo receives onboarding without model calls', async () => {
  imageFixture(); linked = false;
  await receive(photo());
  assert.equal(calls.length, 0);
  assert.equal(records.size, 0);
});
test('photo retries do not log duplicate meals', async () => {
  imageFixture();
  await Promise.all([receive(photo()), receive(photo())]);
  assert.equal(meals().length, 1);
  const count = calls.length;
  await receive(photo());
  assert.equal(calls.length, count);
});
test('photo download failure warns without logging or calling vision', async () => {
  imageFixture(); const fetch = global.fetch;
  global.fetch = (url, opts) => String(url).startsWith('https://lookaside.fbsbx.com/')
    ? Promise.resolve(new Response('Expired', { status: 401 })) : fetch(url, opts);
  await receive(photo());
  assert.equal(records.size, 0);
  assert.ok(!calls.some(c => c.url.endsWith('/chat/completions')));
  assert.match(textReplies(), /couldn't download that photo/);
  assert.deepEqual(reactions.map(r => r.emoji), ['⏳', '⚠️']);
});
test('oversized photo is rejected before download', async () => {
  imageFixture(); const fetch = global.fetch;
  global.fetch = (url, opts) => String(url).includes('/456?')
    ? Promise.resolve(metadata({ mime_type: 'image/png', file_size: 6 * 1024 * 1024 })) : fetch(url, opts);
  await receive(photo());
  assert.equal(records.size, 0);
  assert.match(textReplies(), /photo is too large/);
});
test('invalid image bytes and unsupported format never reach vision', async () => {
  imageFixture(); const fetch = global.fetch;
  global.fetch = (url, opts) => String(url).startsWith('https://lookaside.fbsbx.com/')
    ? Promise.resolve(new Response('invalid-image')) : fetch(url, opts);
  await receive(photo());
  assert.equal(records.size, 0);
  assert.match(textReplies(), /couldn't read that photo/);
  mediaMime = 'image/heic'; replies = [];
  await receive(photo());
  assert.equal(records.size, 0);
  assert.match(textReplies(), /format isn't supported/);
});

function action(id, eventId = 'wamid.action') {
  return { id: eventId, type: 'interactive', interactive: { button_reply: { id } } };
}
function mealActionId(kind) { return `meal:${kind}:${meals()[0][1].id}`; }
const sessionPath = 'users/test-user/whatsappState/edit';
const correctedText = (body = 'Make it one banana', id = 'wamid.correction') => ({ id, type: 'text', text: { body } });
async function startEdit() {
  await receive({ type: 'text', text: { body: 'two bananas' } });
  await receive(action(mealActionId('edit')));
}
test('meal confirmation buttons identify the exact meal', async () => {
  await receive();
  const buttons = replies.find(r => r.type === 'interactive').interactive.action.buttons.map(b => b.reply);
  assert.equal(buttons[0].id, mealActionId('edit'));
  assert.equal(buttons[1].id, mealActionId('delete'));
  assert.equal(buttons[1].title, 'Delete meal');
});
test('delete soft-deletes both copies and repeated button delivery is harmless', async () => {
  await receive();
  const event = action(mealActionId('delete'));
  const modelCount = calls.length;
  await receive(event); await receive(event);
  assert.equal(meals().length, 1);
  assert.equal(meals()[0][1].deleted, true);
  assert.equal(records.get(`mealLogs/${meals()[0][1].id}`).deleted, true);
  assert.equal(calls.length, modelCount);
  assert.match(textReplies(), /Meal deleted/);
});
test('edit targets original meal, preserves timestamp/photo and updates both copies', async () => {
  imageFixture(); await receive(photo());
  const id = meals()[0][1].id;
  const original = { ...meals()[0][1] };
  await receive(action(mealActionId('edit')));
  assert.equal(records.get(sessionPath).mealId, id);
  assert.match(textReplies(), /What would you like to change/);
  mealItems = [{ name: 'Rice', quantity: 'half a bowl', calories: 100 }]; estimateCalories = 100;
  await receive(correctedText('Make the rice half a bowl'));
  const updated = meals()[0][1];
  assert.equal(meals().length, 1);
  assert.equal(updated.id, id);
  assert.equal(updated.timestamp, original.timestamp);
  assert.equal(updated.createdAt, original.createdAt);
  assert.equal(updated.hasImage, true);
  assert.equal(updated.totalCalories, 100);
  assert.match(updated.foodText, /half a bowl Rice/);
  assert.equal(records.get(`mealLogs/${id}`).totalCalories, 100);
  assert.equal(records.has(sessionPath), false);
  assert.match(textReplies(), /Updated/);
  const request = calls.findLast(c => c.url.endsWith('/chat/completions'));
  assert.match(JSON.parse(request.options.body).messages[1].content, /Make the rice half a bowl/);
  const count = calls.length;
  await receive(correctedText('Make the rice half a bowl'));
  assert.equal(calls.length, count);
  assert.equal(meals().length, 1);
});
test('cancel ends the edit and allows a new meal to be logged', async () => {
  await startEdit();
  await receive(action('meal:cancel', 'wamid.cancel'));
  assert.equal(records.has(sessionPath), false);
  await receive(correctedText('one apple', 'wamid.new-meal'));
  assert.equal(meals().length, 2);
});
test('expired edits do not turn corrections into new meals', async () => {
  await startEdit(); records.get(sessionPath).expiresAt = 0;
  await receive(correctedText());
  assert.equal(meals().length, 1);
  assert.match(textReplies(), /edit expired/);
});
test('cannot edit or delete a meal belonging to another account', async () => {
  await receive();
  const foreignId = '11111111-1111-4111-8111-111111111111';
  records.set(`users/other-user/meals/${foreignId}`, { deleted: false });
  for (const kind of ['edit', 'delete']) await receive(action(`meal:${kind}:${foreignId}`, `wamid.${kind}`));
  assert.equal(records.get(`users/other-user/meals/${foreignId}`).deleted, false);
  assert.equal(records.has(sessionPath), false);
  assert.match(textReplies(), /find that meal in your account/);
});
test('deleted meals cannot be edited or resurrected by old buttons', async () => {
  await receive();
  const edit = mealActionId('edit');
  await receive(action(mealActionId('delete'), 'wamid.delete'));
  await receive(action(edit, 'wamid.edit'));
  assert.equal(meals()[0][1].deleted, true);
  assert.equal(records.has(sessionPath), false);
});
test('photos/voice during edit ask for text without logging an extra meal', async () => {
  await startEdit();
  const count = calls.length;
  await receive({ id: 'wamid.photo', ...photo() });
  await receive({ id: 'wamid.voice' });
  assert.equal(calls.length, count);
  assert.equal(meals().length, 1);
  assert.match(textReplies(), /type your correction/);
});
test('model failure preserves edit session so the user can retry', async () => {
  await startEdit();
  const fetch = global.fetch;
  global.fetch = (url, opts) => String(url).endsWith('/chat/completions')
    ? Promise.resolve(new Response('Unavailable', { status: 503 })) : fetch(url, opts);
  await receive(correctedText());
  assert.ok(records.has(sessionPath));
  assert.equal(meals().length, 1);
  assert.match(textReplies(), /couldn't complete that meal action/);
});
test('deleting while a correction is in flight cannot resurrect the meal', async () => {
  await startEdit();
  const fetch = global.fetch;
  let release;
  let entered;
  const ready = new Promise(resolve => { entered = resolve; });
  global.fetch = async (url, opts) => {
    if (String(url).endsWith('/chat/completions')) {
      entered(); await new Promise(resolve => { release = resolve; });
    }
    return fetch(url, opts);
  };
  const correction = receive(correctedText()); await ready;
  await receive(action(mealActionId('delete'), 'wamid.delete'));
  release(); await correction;
  assert.equal(meals()[0][1].deleted, true);
  assert.match(textReplies(), /deleted while editing/);
});
test('a concurrent app edit is not overwritten by a stale correction', async () => {
  await startEdit();
  const fetch = global.fetch;
  global.fetch = async (url, opts) => {
    if (String(url).endsWith('/chat/completions')) meals()[0][1].rawResponseJson = '{"changed":true}';
    return fetch(url, opts);
  };
  await receive(correctedText());
  assert.equal(meals()[0][1].rawResponseJson, '{"changed":true}');
  assert.match(textReplies(), /changed while editing/);
});

test('summary excludes deleted meals', async () => {
  await receive();
  await receive(action(mealActionId('delete')));
  await receive(correctedText('summary', 'wamid.summary'));
  assert.match(textReplies(), /Calories: \*0 \/ 2000 kcal/);
});
test('summary button cancels pending edit and returns the summary', async () => {
  await startEdit();
  await receive(action('summary', 'wamid.summary'));
  assert.equal(records.has(sessionPath), false);
  assert.match(textReplies(), /Today's Progress/);
});
test('old edit button replay after a completed correction does not restart the session', async () => {
  await startEdit(); const edit = action(mealActionId('edit'));
  await receive(correctedText());
  await receive(edit);
  assert.equal(records.has(sessionPath), false);
});
test('overlapping corrections only commit once for the edit session', async () => {
  await startEdit();
  const fetch = global.fetch;
  const release = [];
  let entered = 0;
  let allReady;
  const ready = new Promise(resolve => { allReady = resolve; });
  global.fetch = async (url, opts) => {
    if (String(url).endsWith('/chat/completions')) {
      entered++;
      if (entered === 2) allReady();
      await new Promise(resolve => { release.push(resolve); });
    }
    return fetch(url, opts);
  };
  const one = receive(correctedText('one banana', 'wamid.one'));
  const two = receive(correctedText('half a banana', 'wamid.two'));
  await ready; release.forEach(resolve => resolve()); await Promise.all([one, two]);
  const receipts = [...records.values()].filter(data => data.action === 'corrected');
  assert.equal(receipts.length, 1);
  assert.equal(meals().length, 1);
});

test('failed correction replay after cancellation cannot log a new meal', async () => {
  await startEdit();
  const fetch = global.fetch;
  global.fetch = (url, opts) => String(url).endsWith('/chat/completions')
    ? Promise.resolve(new Response('Unavailable', { status: 503 })) : fetch(url, opts);
  await receive(correctedText());
  await receive(action('meal:cancel', 'wamid.cancel'));
  global.fetch = fetch;
  await receive(correctedText());
  assert.equal(meals().length, 1);
});
test('media received during edit cannot become a new meal on delayed retry', async () => {
  await startEdit();
  const event = { id: 'wamid.pending-photo', ...photo() };
  await receive(event);
  await receive(action('meal:cancel', 'wamid.cancel'));
  const count = calls.length;
  await receive(event);
  assert.equal(meals().length, 1);
  assert.equal(calls.length, count);
});

const { istDateKey, yesterdayIST, parseMealDate, mealDateLabel, moveMealDate } = require('../lib/whatsappDates');
async function startDate() { await receive(action('date:start', 'wamid.date-start')); }
async function chooseDate(choice = 'yesterday', id = 'wamid.date-choice') {
  const token = records.get(sessionPath).token;
  await receive(action(`date:${choice}:${token}`, id));
}
async function selectYesterday() { await startDate(); await chooseDate(); }
test('date parser validates calendar dates, leap years, unambiguous formats and future dates', () => {
  const now = new Date('2026-10-18T10:00:00Z');
  assert.equal(parseMealDate('15 Oct 2026', now), '2026-10-15');
  assert.equal(parseMealDate('15 October 2026', now), '2026-10-15');
  assert.equal(parseMealDate('2024-02-29', now), '2024-02-29');
  assert.equal(parseMealDate('today', now), '2026-10-18');
  assert.equal(parseMealDate('yesterday', now), '2026-10-17');
  for (const invalid of ['2026-02-29', '2026-04-31', '10/11/2026', '15 Oct', '2026-10-19']) {
    assert.equal(parseMealDate(invalid, now), undefined);
  }
  assert.equal(istDateKey(new Date('2026-10-17T19:00:00Z')), '2026-10-18');
  assert.equal(moveMealDate('2026-10-15', new Date('2026-10-17T19:12:34.567Z')).toISOString(), '2026-10-14T19:12:34.567Z');
});
test('main menu exposes logging for another day within the three-button limit', async () => {
  await receive(correctedText('menu', 'wamid.menu'));
  const buttons = replies.findLast(r => r.type === 'interactive').interactive.action.buttons;
  assert.equal(buttons.length, 3);
  assert.ok(buttons.some(b => b.reply.id === 'date:start'));
});
test('yesterday applies to one text meal, shows date and resets to today after saving', async () => {
  await selectYesterday();
  assert.match(textReplies(), /Your next meal will be logged for/);
  await receive(correctedText('rice and dal', 'wamid.backdated'));
  const meal = meals()[0][1];
  assert.equal(istDateKey(meal.timestamp), yesterdayIST());
  assert.equal(istDateKey(records.get(`mealLogs/${meal.id}`).timestamp), yesterdayIST());
  assert.equal(meal.mealType, 'Meal');
  assert.match(textReplies(), new RegExp(mealDateLabel(yesterdayIST())));
  assert.equal(records.has(sessionPath), false);
  await receive(correctedText('one apple', 'wamid.today'));
  assert.equal(istDateKey(meals()[1][1].timestamp), istDateKey());
});
test('custom date selection works before a captionless photo', async () => {
  await startDate(); await chooseDate('other');
  await receive(correctedText('2024-02-29', 'wamid.custom-date'));
  imageFixture(); await receive({ ...photo(), id: 'wamid.backdated-photo' });
  assert.equal(istDateKey(meals()[0][1].timestamp), '2024-02-29');
  assert.equal(meals()[0][1].hasImage, true);
});
test('backdated voice meal uses a spoken meal type rather than the current hour', async () => {
  await selectYesterday(); transcript = 'For dinner I had two bananas';
  await receive({ id: 'wamid.backdated-voice' });
  assert.equal(meals()[0][1].mealType, 'Dinner');
  assert.equal(istDateKey(meals()[0][1].timestamp), yesterdayIST());
});
test('processing failure retains selected date for a new attempt', async () => {
  await selectYesterday(); const fetch = global.fetch;
  global.fetch = (url, opts) => String(url).endsWith('/chat/completions')
    ? Promise.resolve(new Response('Unavailable', { status: 503 })) : fetch(url, opts);
  await receive(correctedText('two bananas', 'wamid.failed'));
  assert.equal(records.get(sessionPath).stage, 'ready');
  assert.equal(meals().length, 0);
  global.fetch = fetch;
  await receive(correctedText('two bananas', 'wamid.retry'));
  assert.equal(istDateKey(meals()[0][1].timestamp), yesterdayIST());
});
test('cancel clears selected date and logs subsequent meals for today', async () => {
  await selectYesterday(); await receive(action('meal:cancel', 'wamid.cancel-date'));
  await receive(correctedText('two bananas', 'wamid.today'));
  assert.equal(istDateKey(meals()[0][1].timestamp), istDateKey());
});
test('expired date selections clear automatically and a fresh text meal logs for today', async () => {
  await selectYesterday(); records.get(sessionPath).expiresAt = 0;
  await receive(correctedText('two bananas', 'wamid.expired'));
  assert.equal(meals().length, 1);
  assert.equal(istDateKey(meals()[0][1].timestamp), istDateKey());
  assert.equal(records.has(sessionPath), false);
  assert.match(textReplies(), new RegExp(mealDateLabel(istDateKey())));
  assert.ok(!textReplies().includes('date selection expired'));
});
test('old date buttons cannot change a replacement selection', async () => {
  await startDate(); const old = records.get(sessionPath).token;
  await receive(action('date:start', 'wamid.replacement'));
  await receive(action(`date:yesterday:${old}`, 'wamid.stale-date'));
  assert.equal(records.get(sessionPath).stage, 'dateChoice');
  assert.match(textReplies(), /no longer active/);
});
test('change date updates both copies without an AI call or calorie changes', async () => {
  await receive();
  const original = { ...meals()[0][1] }; const count = calls.length;
  await receive(action(mealActionId('edit'), 'wamid.edit-menu'));
  const choices = replies.findLast(r => r.type === 'interactive').interactive.action.buttons;
  assert.ok(choices.some(b => b.reply.title === 'Change date'));
  await receive(action(mealActionId('date'), 'wamid.edit-date'));
  await chooseDate();
  const updated = meals()[0][1];
  assert.equal(calls.length, count);
  assert.equal(istDateKey(updated.timestamp), yesterdayIST());
  assert.equal(updated.totalCalories, original.totalCalories);
  assert.equal(updated.rawResponseJson, original.rawResponseJson);
  assert.equal(updated.createdAt, original.createdAt);
  assert.equal(istDateKey(records.get(`mealLogs/${updated.id}`).timestamp), yesterdayIST());
  await receive(correctedText('summary', 'wamid.summary-after-move'));
  assert.match(textReplies(), /Calories: \*0 \/ 2000 kcal/);
});
test('invalid edit dates keep the meal unchanged and allow a new valid date', async () => {
  await receive(); const original = meals()[0][1].timestamp;
  await receive(action(mealActionId('date'), 'wamid.edit-date'));
  await chooseDate('other');
  await receive(correctedText('31 Feb 2026', 'wamid.invalid-date'));
  assert.equal(meals()[0][1].timestamp, original);
  await receive(correctedText('2024-02-29', 'wamid.valid-date'));
  assert.equal(istDateKey(meals()[0][1].timestamp), '2024-02-29');
});
test('replayed date choice after a consumed selection cannot start a new meal', async () => {
  await startDate(); const token = records.get(sessionPath).token;
  const event = action(`date:yesterday:${token}`, 'wamid.select-yesterday');
  await receive(event); await receive(correctedText('rice', 'wamid.rice')); await receive(event);
  assert.equal(meals().length, 1);
  assert.equal(records.has(sessionPath), false);
});
test('date selection is not cleared if changed while a meal is processing', async () => {
  await selectYesterday(); const fetch = global.fetch;
  global.fetch = async (url, opts) => {
    if (String(url).endsWith('/chat/completions')) records.get(sessionPath).token = 'new-token';
    return fetch(url, opts);
  };
  await receive(correctedText('rice', 'wamid.rice'));
  assert.equal(meals().length, 0);
  assert.equal(records.get(sessionPath).token, 'new-token');
  assert.match(textReplies(), /selected date changed/);
});
test('competing meals cannot both consume a one-meal date selection', async () => {
  await selectYesterday(); const fetch = global.fetch;
  let entered = 0; let ready; const pending = new Promise(resolve => { ready = resolve; }); const releases = [];
  global.fetch = async (url, opts) => {
    if (String(url).endsWith('/chat/completions')) {
      entered++; if (entered === 2) ready();
      await new Promise(resolve => releases.push(resolve));
    }
    return fetch(url, opts);
  };
  const a = receive(correctedText('rice', 'wamid.one'));
  const b = receive(correctedText('dal', 'wamid.two'));
  await pending; releases.forEach(resolve => resolve()); await Promise.all([a, b]);
  assert.equal(meals().length, 1);
  assert.equal(istDateKey(meals()[0][1].timestamp), yesterdayIST());
});

test('moving an older meal to today includes it in today summary', async () => {
  await selectYesterday(); await receive(correctedText('rice', 'wamid.rice'));
  await receive(action(mealActionId('date'), 'wamid.move-date')); await chooseDate('today', 'wamid.move-today');
  await receive(correctedText('summary', 'wamid.summary'));
  assert.match(textReplies(), /Calories: \*210 \/ 2000 kcal/);
});
test('food edit confirmation shows the latest timestamp if another device moved the meal', async () => {
  await startEdit(); const fetch = global.fetch;
  const target = new Date('2024-02-29T06:30:00Z');
  global.fetch = async (url, opts) => {
    if (String(url).endsWith('/chat/completions')) meals()[0][1].timestamp = target;
    return fetch(url, opts);
  };
  await receive(correctedText());
  assert.equal(meals()[0][1].timestamp, target);
  assert.match(textReplies(), /29 February 2024/);
});
test('change food submenu still accepts a portion correction', async () => {
  await startEdit(); await receive(action(mealActionId('food'), 'wamid.change-food'));
  await receive(correctedText()); assert.equal(meals().length, 1);
  assert.equal(records.has(sessionPath), false);
  assert.match(textReplies(), /Updated/);
});

test('logged and edited meal replies round floating point artifacts without changing saved nutrition', async () => {
  mealItems = [
    { name: 'Coffee', quantity: '12 g', calories: 2.4, protein: 0.1, carbs: 0.1, fat: 0, fiber: 0 },
    { name: 'Milk', quantity: '120 ml', calories: 73.2, protein: 3.6, carbs: 5.5, fat: 3.9, fiber: 0 },
    { name: 'Sugar', quantity: '1 tsp', calories: 14.6, protein: 0.1, carbs: 4.2, fat: 0, fiber: 0 },
  ];
  estimateCalories = 90.00000000000001;
  await receive(correctedText('cappuccino', 'wamid.coffee'));
  function verifyReply() {
    const reply = replies.findLast(r => r.type === 'interactive').interactive.body.text;
    assert.match(reply, /Protein: \*3\.8g\*/);
    assert.match(reply, /Carbs: \*9\.8g\*/);
    assert.match(reply, /Fat: \*3\.9g\*/);
    assert.match(reply, /Fiber: \*0g\*/);
    assert.match(reply, /Total: 90 kcal/);
    assert.match(reply, /Coffee\* \(12 g\) — 2 kcal/);
    assert.match(reply, /Sugar\* \(1 tsp\) — 15 kcal/);
    assert.ok(!reply.includes('000000000'));
    const saved = JSON.parse(meals()[0][1].rawResponseJson);
    assert.equal(saved.protein, 0.1 + 3.6 + 0.1);
    assert.equal(saved.items[0].calories, 2.4);
    assert.equal(meals()[0][1].totalCalories, estimateCalories);
  }
  verifyReply();
  await receive(action(mealActionId('edit'), 'wamid.edit-coffee'));
  await receive(correctedText('keep the same ingredients', 'wamid.correct-coffee'));
  verifyReply();
});

test('Today, Yesterday and Other date work before a meal ID exists with strict Firestore validation', async () => {
  for (const choice of ['today', 'yesterday', 'other']) {
    records.clear(); replies = [];
    await startDate();
    assert.equal(Object.hasOwn(records.get(sessionPath), 'mealId'), false);
    await chooseDate(choice);
    if (choice === 'other') {
      assert.equal(records.get(sessionPath).stage, 'customDate');
      const receipt = [...records.values()].find(r => r.action === 'correction');
      assert.equal(Object.hasOwn(receipt, 'mealId'), false);
      await receive(correctedText('2024-02-29', 'wamid.typed-date'));
    }
    assert.equal(records.get(sessionPath).stage, 'ready');
    assert.match(textReplies(), /Your next meal will be logged for/);
    assert.ok(!textReplies().includes("couldn't complete that meal action"));
    assert.equal(calls.length, 0);
  }
});

test('fresh voice notes after an abandoned date picker always reach transcription and log for today', async () => {
  for (const stage of ['dateChoice', 'customDate', 'ready']) {
    records.clear(); replies = []; calls = []; reactions = [];
    await startDate();
    Object.assign(records.get(sessionPath), { stage, date: yesterdayIST(), expiresAt: 0 });
    transcript = 'A chicken sandwich and grilled chicken';
    const event = { id: `wamid.fresh-voice-${stage}` };
    await receive(event);
    assert.ok(calls.some(c => c.url.endsWith('/audio/transcriptions')));
    assert.equal(meals().length, 1);
    assert.equal(meals()[0][1].foodText, transcript);
    assert.equal(istDateKey(meals()[0][1].timestamp), istDateKey());
    assert.equal(records.has(sessionPath), false);
    assert.ok(!textReplies().includes('expired'));
    const count = calls.length;
    await receive(event);
    assert.equal(calls.length, count);
    assert.equal(meals().length, 1);
  }
});
test('expired food and date edits do not intercept a fresh photo or voice meal', async () => {
  for (const mode of ['chooseEdit', 'editFood', 'editDate']) {
    for (const type of ['audio', 'image']) {
      records.clear(); replies = []; calls = []; mediaMime = 'audio/ogg; codecs=opus';
      await startEdit();
      Object.assign(records.get(sessionPath), { mode, expiresAt: 0 });
      if (type === 'image') imageFixture();
      await receive({ id: `wamid.new-${mode}-${type}`, ...(type === 'image' ? photo() : {}) });
      assert.equal(meals().length, 2);
      assert.equal(istDateKey(meals()[1][1].timestamp), istDateKey());
      assert.equal(records.has(sessionPath), false);
      assert.ok(!textReplies().includes('expired'));
    }
  }
});
test('a new text meal after a stale edit logs normally rather than asking to edit again', async () => {
  await startEdit(); records.get(sessionPath).expiresAt = 0;
  await receive(correctedText('Two rotis and dal', 'wamid.new-text'));
  assert.equal(meals().length, 2);
  assert.equal(records.has(sessionPath), false);
});
test('explicit date replies and stale date buttons still cannot become meals', async () => {
  for (const type of ['text', 'button']) {
    records.clear(); replies = [];
    await startDate();
    const token = records.get(sessionPath).token;
    records.get(sessionPath).expiresAt = 0;
    const event = type === 'text' ? correctedText('2024-02-29', 'wamid.old-date')
      : action(`date:yesterday:${token}`, 'wamid.old-date');
    await receive(event); await receive(event);
    assert.equal(meals().length, 0);
    assert.equal(records.has(sessionPath), false);
    assert.match(textReplies(), /date selection expired/);
  }
});
test('active date and edit sessions continue to require their expected input', async () => {
  await startDate(); await receive({ id: 'wamid.active-picker-voice' });
  assert.equal(meals().length, 0);
  assert.ok(records.has(sessionPath));
  assert.match(textReplies(), /valid date/);
  records.clear(); replies = [];
  await startEdit(); await receive({ id: 'wamid.active-edit-voice' });
  assert.equal(meals().length, 1);
  assert.ok(records.has(sessionPath));
  assert.match(textReplies(), /type your correction/);
});
