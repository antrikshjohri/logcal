const { test, beforeEach, afterEach } = require('node:test');
const assert = require('node:assert/strict');
const Module = require('node:module');
const { WHATSAPP_AGENT_PILOT_UID: uid, agentAllowed, allowsMealWrite, runAgentTurn } = require('../lib/whatsappAgentCore');
let docs, sent, estimates, modelResponses, networkCalls;
const realFetch = global.fetch;
const phone = '919900000001';
class Stamp {
  constructor(ms) { this.ms = ms; }
  toDate() { return new Date(this.ms); }
  toMillis() { return this.ms; }
  static now() { return new Stamp(Date.now()); }
  static fromDate(d) { return new Stamp(d.getTime()); }
}
function valid(v) {
  assert.notEqual(v, undefined, 'Firestore rejects undefined');
  if (v && typeof v === 'object' && !(v instanceof Stamp)) Object.values(v).forEach(valid);
}
const snap = path => ({ id: path.split('/').at(-1), exists: docs.has(path), data: () => docs.has(path) ? { ...docs.get(path) } : undefined });
const ref = path => ({ path, id: path.split('/').at(-1), get: async () => snap(path),
  set: async data => { valid(data); docs.set(path, data); },
  update: async patch => { valid(patch); assert.ok(docs.has(path)); docs.set(path, { ...docs.get(path), ...patch }); },
  collection: name => collection(`${path}/${name}`) });
function collection(path) {
  const filters = []; let max = Infinity;
  return {
    doc: id => ref(`${path}/${id}`),
    where(key, op, val) { filters.push([key, op, val]); return this; },
    orderBy() { return this; }, limit(n) { max = n; return this; },
    async get() {
      const rows = [...docs].filter(([p,v]) => p.startsWith(`${path}/`) && !p.slice(path.length+1).includes('/') && filters.every(([k,op,val]) => {
        const a = v[k] instanceof Stamp ? v[k].ms : v[k], b = val instanceof Stamp ? val.ms : val;
        return op === '>=' ? a >= b : op === '<' ? a < b : a === b;
      })).slice(0,max).map(([p])=>snap(p));
      return { docs: rows, size: rows.length };
    },
  };
}
const db = { doc: ref, collection,
  async runTransaction(fn) {
    const writes=[];
    const result = await fn({
      async get(r) { assert.equal(writes.length, 0, 'Firestore reads must precede writes'); return snap(r.path); },
      set(r,data) { valid(data); writes.push(()=>docs.set(r.path,data)); },
      update(r,patch) { valid(patch); writes.push(()=>docs.set(r.path,{...docs.get(r.path),...patch})); },
      delete(r) { writes.push(()=>docs.delete(r.path)); },
    });
    writes.forEach(write=>write()); return result;
  },
};
const firestore = () => db; firestore.Timestamp = Stamp;
const load = Module._load;
Module._load = function(name,...rest) { return name === 'firebase-admin' ? { firestore } : load.call(this,name,...rest); };
const { routeWhatsAppAgent, processWhatsAppAgentJob, nutritionData } = require('../lib/whatsappAgent');
Module._load = load;
const estimate = { meal_type:'Snack', total_calories:210, protein:2, carbs:54, fat:1, fiber:6,
  items:[{name:'Bananas',quantity:'2',calories:210,protein:2,carbs:54,fat:1,fiber:6,confidence:0.8}], needs_clarification:false,clarifying_question:'',sources:[] };
const svc = { model:'test-model',
  transcribe: async()=> 'How much protein did I log yesterday?',
  estimate: async()=> { estimates++; return estimate; },
  send: async(to,text)=>sent.push({type:'text',to,text}),
  buttons: async(to,text,buttons)=>sent.push({type:'buttons',to,text,buttons}),
  react: async(to,id,emoji)=>sent.push({type:'reaction',to,id,emoji}),
  confirm: async(to,id,text,response,timestamp)=>sent.push({type:'confirmation',to,id,text,response,timestamp}),
};
const message = (text,id='message-1') => ({id,from:phone,type:'text',text:{body:text}});
const call = (name,args) => ({output:[{type:'function_call',name,arguments:JSON.stringify(args),call_id:`call-${name}`} ]});
const reply = text => ({output:[{type:'message',content:[{type:'output_text',text}]}]});
const recordArgs = {food_text:'two bananas',meal_type:'Snack',date:null,source_quote:'two bananas'};
const today = ()=>new Date(Date.now()+330*60000).toISOString().slice(0,10);
function seedMeal(id='meal-existing',extra={}) {
  docs.set(`users/${uid}/meals/${id}`, {id, timestamp:Stamp.fromDate(new Date(`${today()}T12:00:00+05:30`)),
    foodText:'two bananas',mealType:'Snack',totalCalories:210,rawResponseJson:JSON.stringify(estimate),deleted:false,...extra});
}
async function enqueue(text='two bananas',id='message-1') {
  assert.equal(await routeWhatsAppAgent(uid,phone,message(text,id),svc),true);
  return [...docs.keys()].find(p=>p.startsWith('whatsappAgentInbox/')&&docs.get(p).message.id===id).split('/').at(-1);
}
function meals() { return [...docs].filter(([p])=>p.startsWith(`users/${uid}/meals/`)); }
beforeEach(()=> {
  docs=new Map(); sent=[];estimates=0;modelResponses=[];networkCalls=[];
  docs.set('app/whatsappAgent',{enabled:true,allowedUids:[uid]});
  docs.set(`users/${uid}`,{whatsappPhoneNumber:phone,country:'India',dailyGoal:2000,proteinGoal:150});
  process.env.OPENAI_API_KEY='test-only';process.env.WHATSAPP_ACCESS_TOKEN='test-only';process.env.WHATSAPP_PHONE_NUMBER_ID='123';
  global.fetch=async(url,options)=>{
    networkCalls.push({url:String(url),options});
    if(String(url).startsWith('https://graph.facebook.com/')) return Response.json({url:'https://lookaside.fbsbx.com/audio',mime_type:'audio/ogg',file_size:3});
    if(String(url).startsWith('https://lookaside.fbsbx.com/')) return new Response('ogg');
    assert.equal(String(url),'https://api.openai.com/v1/responses');
    assert.ok(modelResponses.length,'Unexpected model call');
    const value=modelResponses.shift();if(value instanceof Error) throw value;
    return Response.json(value);
  };
});
afterEach(()=>{global.fetch=realFetch;});

test('gate defaults off and cannot enroll another account even through allowlist misconfiguration',()=>{
  assert.equal(agentAllowed(undefined,uid),false);
  assert.equal(agentAllowed({enabled:true,allowedUids:[uid]},uid),true);
  assert.equal(agentAllowed({enabled:true,allowedUids:['someone-else']},'someone-else'),false);
});
test('nonpilot uses legacy route without config reads, writes, messages or model calls',async()=>{
  docs.clear();assert.equal(await routeWhatsAppAgent('someone-else',phone,message('How much protein?'),svc),false);
  assert.equal(docs.size,0);assert.equal(sent.length,0);assert.equal(networkCalls.length,0);
});
test('disabled pilot uses legacy; /legacy blocks queued work; /agent opts back in',async()=>{
  const id=await enqueue();
  await routeWhatsAppAgent(uid,phone,message('/legacy'),svc);
  await processWhatsAppAgentJob(id,svc);
  assert.equal(docs.get(`whatsappAgentInbox/${id}`).status,'cancelled');assert.equal(meals().length,0);
  assert.equal(await routeWhatsAppAgent(uid,phone,message('rice'),svc),false);
  await routeWhatsAppAgent(uid,phone,message('/agent'),svc);
  assert.equal(docs.get(`whatsappAgentPreferences/${uid}`).legacy,false);
  docs.get('app/whatsappAgent').enabled=false;
  assert.equal(await routeWhatsAppAgent(uid,phone,message('rice'),svc),false);
});
test('webhook queues duplicate event once and preserves arrival order',async()=>{
  const id=await enqueue();await enqueue();
  assert.equal([...docs.keys()].filter(p=>p.startsWith('whatsappAgentInbox/')).length,1);
  const second=await enqueue('rice','message-2');
  await assert.rejects(processWhatsAppAgentJob(second,svc),/earlier chat turn/);
  modelResponses=[reply('Hello')];await processWhatsAppAgentJob(id,svc);
  assert.deepEqual(docs.get(`whatsappAgentQueues/${uid}`).ids,[second]);
});
test('questions, hypotheticals, explicit no-save and workout advice do not authorize meal writes',()=>{
  for(const text of ['How much protein did I log?','What if I had two bananas?','Suggest a workout','Should I eat eggs?','Do not log this meal','Can you recommend dinner?']) assert.equal(allowsMealWrite(text,false),false,text);
  for(const text of ['two bananas','I had two eggs. How much protein do I have left?','Can you log two eggs?','Log this sandwich']) assert.equal(allowsMealWrite(text,false),true,text);
});
test('even a wrong model tool choice cannot save a question as a meal',async()=>{
  const id=await enqueue('How much protein is in two bananas?');
  modelResponses=[call('record_meal',{...recordArgs,source_quote:'two bananas'}),reply('Two bananas contain approximately 2 g protein; nothing was logged.')];
  await processWhatsAppAgentJob(id,svc);assert.equal(meals().length,0);assert.equal(estimates,0);
  const inputs=JSON.parse(networkCalls[1].options.body).input;
  assert.match(inputs.find(x=>x.type==='function_call_output').output,/does not authorize logging/);
});
test('mixed log-and-query saves both existing-format copies once and answers using updated records',async()=>{
  const id=await enqueue('I had two bananas. How much protein today?');
  modelResponses=[call('record_meal',recordArgs),call('get_nutrition_data',{start_date:today(),end_date:today(),food_filter:null}),reply('Logged. Your logged protein total today is 2 g.')];
  await processWhatsAppAgentJob(id,svc);
  assert.equal(meals().length,1);assert.equal(estimates,1);
  const [p,meal]=meals()[0];const sync=docs.get(`mealLogs/${meal.id}`);
  assert.equal(sync.uid,uid);assert.equal(meal.totalCalories,210);assert.equal(sync.totalCalories,210);
  assert.deepEqual(Object.keys(meal).sort(),['id','timestamp','createdAt','foodText','mealType','totalCalories','rawResponseJson','hasImage','deleted'].sort());
  assert.ok(sent.some(s=>s.type==='confirmation'));assert.equal(docs.get(`whatsappAgentInbox/${id}`).status,'done');
  await processWhatsAppAgentJob(id,svc);assert.equal(meals().length,1);assert.equal(estimates,1);
  assert.ok(p.startsWith(`users/${uid}/`));
});
test('read tool uses deterministic totals, excludes deletion, separates missing macros and filters food',async()=>{
  seedMeal();seedMeal('deleted',{deleted:true,totalCalories:999});seedMeal('unknown',{foodText:'rice',totalCalories:100,rawResponseJson:'{}'});
  docs.set('users/other/meals/private',{totalCalories:9999});
  const result=await nutritionData(uid,{start_date:today(),end_date:today(),food_filter:null});
  assert.equal(result.totals.calories,310);assert.equal(result.totals.protein,2);assert.equal(result.totals.missingMacros,1);
  assert.equal(result.daysWithMatchingLogs,1);assert.equal(result.meals.length,2);
  const filtered=await nutritionData(uid,{start_date:today(),end_date:today(),food_filter:'rice'});
  assert.equal(filtered.totals.calories,100);
  await assert.rejects(nutritionData(uid,{start_date:'2026-02-30',end_date:today(),food_filter:null}),/valid date/);
});
test('nutrition query caps records and reports incomplete results',async()=>{
  for(let i=0;i<501;i++)seedMeal(`many-${i}`);
  const result=await nutritionData(uid,{start_date:today(),end_date:today(),food_filter:null});
  assert.equal(result.queryTruncated,true);assert.equal(result.mealRowsTruncated,true);assert.equal(result.meals.length,80);assert.equal(result.matchingMeals,500);
});
test('estimate-only tool never writes and workout coaching has no write capability',async()=>{
  const id=await enqueue('What if I had two bananas before a workout?');
  modelResponses=[call('estimate_meal',{food_text:'two bananas',meal_type:'Snack'}),reply('That is approximately 210 kcal. Tell me your training goals and equipment.')];
  await processWhatsAppAgentJob(id,svc);assert.equal(meals().length,0);assert.equal(estimates,1);
});
test('voice question is transcribed and answered without falling through to meal logging',async()=>{
  const msg={id:'voice-1',type:'audio',audio:{id:'456'}};
  await routeWhatsAppAgent(uid,phone,msg,svc);
  const id=[...docs.keys()].find(p=>p.startsWith('whatsappAgentInbox/')).split('/').at(-1);
  modelResponses=[reply('No meals were logged for that day.')];await processWhatsAppAgentJob(id,svc);
  assert.equal(meals().length,0);assert.equal(estimates,0);
});
test('kill switch changed during estimation prevents committing a meal',async()=>{
  const id=await enqueue();modelResponses=[call('record_meal',recordArgs),reply('The pilot was paused; no meal was saved.')];
  await processWhatsAppAgentJob(id,{...svc,estimate:async()=>{docs.get('app/whatsappAgent').enabled=false;return estimate;}});
  assert.equal(meals().length,0);assert.equal(docs.get(`whatsappAgentInbox/${id}`).status,'cancelled');
  assert.ok(!sent.some(s=>s.type==='confirmation'));
});
test('model failure never falls back to logging; bounded retries release the queue',async()=>{
  const id=await enqueue('How much protein today?');
  for(let i=0;i<3;i++){
    modelResponses=[new Error('Model unavailable')];
    if(i<2)await assert.rejects(processWhatsAppAgentJob(id,svc),/Model unavailable/);
    else await processWhatsAppAgentJob(id,svc);
  }
  assert.equal(meals().length,0);assert.equal(docs.get(`whatsappAgentInbox/${id}`).status,'terminal_failed');
  assert.deepEqual(docs.get(`whatsappAgentQueues/${uid}`).ids,[]);
});
test('a successful meal is not duplicated when the model fails before the answer',async()=>{
  const id=await enqueue();
  modelResponses=[call('record_meal',recordArgs),new Error('Model unavailable')];
  await assert.rejects(processWhatsAppAgentJob(id,svc),/Model unavailable/);
  assert.equal(meals().length,1);
  modelResponses=[call('record_meal',recordArgs),reply('Your meal was saved.')];
  await processWhatsAppAgentJob(id,svc);
  assert.equal(meals().length,1);assert.equal(estimates,1);
});
test('active lease retries instead of abandoning a turn after a worker crash',async()=>{
  const id=await enqueue();docs.set(`whatsappAgentLocks/${uid}`,{jobId:id,expiresAt:Date.now()+1000});
  await assert.rejects(processWhatsAppAgentJob(id,svc),/processing/);
  docs.get(`whatsappAgentLocks/${uid}`).expiresAt=0;
  modelResponses=[reply('Hello')];await processWhatsAppAgentJob(id,svc);
  assert.equal(docs.get(`whatsappAgentInbox/${id}`).status,'done');
});
test('fresh questions bypass abandoned legacy state and legacy buttons retain their path',async()=>{
  docs.set(`users/${uid}/whatsappState/edit`,{from:phone,mode:'editFood',expiresAt:Date.now()+60000});
  await enqueue('How much protein today?');assert.equal([...docs.keys()].filter(p=>p.startsWith('whatsappAgentInbox/')).length,1);
  assert.equal(await routeWhatsAppAgent(uid,phone,{id:'button-1',type:'interactive',interactive:{button_reply:{id:'meal:edit:existing'}}},svc),false);
});
test('tool limits terminate runaway agent loops and history is bounded',async()=>{
  modelResponses=Array.from({length:5},()=>call('estimate_meal',{food_text:'eggs',meal_type:'Meal'}));
  await assert.rejects(runAgentTurn({text:'what is in eggs?',history:Array.from({length:40},()=>({role:'user',text:'old history'})),profile:{},apiKey:'test',model:'test',execute:async()=>({calories:1})}),/round limit/);
  assert.equal(JSON.parse(networkCalls[0].options.body).input.length,13);
});

test('workout reports and logging requests cannot authorize the meal write tool',()=>{
  for(const text of ['Log my workout: 30 minutes cycling','I had a workout','I completed a run','Add a walk for today']) assert.equal(allowsMealWrite(text,false),false,text);
});
test('completed turns clean up a queue head left behind by a terminated worker',async()=>{
  const id=await enqueue();docs.get(`whatsappAgentInbox/${id}`).status='done';
  await processWhatsAppAgentJob(id,svc);assert.deepEqual(docs.get(`whatsappAgentQueues/${uid}`).ids,[]);
});
test('the model cannot invent a past logging date that the user never specified',async()=>{
  const id=await enqueue();modelResponses=[call('record_meal',{...recordArgs,date:'2024-02-29'}),reply('Please specify the intended date.')];
  await processWhatsAppAgentJob(id,svc);assert.equal(meals().length,0);assert.equal(estimates,0);
});

test('calendar-day and logged-day averages remain distinct across missing days',async()=>{
  seedMeal();
  const earlier=new Date(Date.now()-2*86400000);const key=new Date(earlier.getTime()+330*60000).toISOString().slice(0,10);
  seedMeal('earlier',{timestamp:Stamp.fromDate(new Date(`${key}T12:00:00+05:30`))});
  const result=await nutritionData(uid,{start_date:key,end_date:today(),food_filter:null});
  assert.equal(result.daysRequested,3);assert.equal(result.daysWithMatchingLogs,2);
  assert.equal(result.averagesPerRequestedDay.calories,140);assert.equal(result.averagesPerLoggedDay.calories,210);
});
test('existing app callables, shared helpers and constants match the verified production baseline',()=>{
  const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto'),ts=require('typescript');
  const baseline=require('../releases/whatsapp-prod-before-agent-2026-11-22.json');
  const file=ts.createSourceFile('current',fs.readFileSync(path.resolve(__dirname,'../src/index.ts'),'utf8'),ts.ScriptTarget.Latest,true);
  const definitions=new Map(file.statements.flatMap(n=>ts.isFunctionDeclaration(n)?[[n.name?.text,n.getText(file)]]:ts.isVariableStatement(n)?n.declarationList.declarations.map(d=>[d.name.getText(file),d.getText(file)]):[]));
  for(const [name,hash] of Object.entries(baseline.existingDefinitions)) assert.equal(crypto.createHash('sha256').update(definitions.get(name)||'').digest('hex'),hash,name);
  const archive=fs.readFileSync(path.resolve(__dirname,'../../deployments/whatsapp/whatsapp-prod-before-agent-2026-11-22.zip'));
  assert.equal(crypto.createHash('sha256').update(archive).digest('hex'),baseline.sourceZipSha256);
});

test('pilot Main Menu buttons show agent help while meal actions keep their legacy route',async()=>{
  assert.equal(await routeWhatsAppAgent(uid,phone,{id:'main-menu',type:'interactive',interactive:{button_reply:{id:'menu'}}},svc),true);
  assert.ok(sent.some(s=>s.type==='buttons'&&s.text.includes('Your LogCal agent')));
  assert.equal([...docs.keys()].filter(p=>p.startsWith('whatsappAgentInbox/')).length,0);
});

test('turning the rollout off and on cannot revive older queued actions',async()=>{
  const id=await enqueue();
  docs.get('app/whatsappAgent').generation='new-rollout';
  await processWhatsAppAgentJob(id,svc);
  assert.equal(docs.get(`whatsappAgentInbox/${id}`).status,'cancelled');assert.equal(networkCalls.length,0);
});
test('leaving and rejoining the pilot cannot revive old queued actions',async()=>{
  const id=await enqueue();
  await routeWhatsAppAgent(uid,phone,message('/legacy'),svc);
  await routeWhatsAppAgent(uid,phone,message('/agent'),svc);
  await processWhatsAppAgentJob(id,svc);
  assert.equal(docs.get(`whatsappAgentInbox/${id}`).status,'cancelled');assert.equal(meals().length,0);
});

test('agent transcription preserves general questions and workout vocabulary separately from app dictation',async()=>{
  const {transcribeWhatsAppAgentAudio}=require('../lib/whatsappAgentCore');
  let request;
  global.fetch=async(url,options)=>{request={url,options};return Response.json({text:'Suggest a shoulder workout'});};
  const text=await transcribeWhatsAppAgentAudio(Buffer.from('audio'),'voice.ogg','audio/ogg','test-speech-model');
  assert.equal(text,'Suggest a shoulder workout');
  assert.equal(request.options.body.get('file').name,'voice.ogg');
  assert.match(request.options.body.get('prompt'),/exercise names/);
  assert.equal(request.options.body.get('model'),'test-speech-model');
});
