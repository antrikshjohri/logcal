#!/usr/bin/env node
// Operational controls use the operator's Firebase CLI login. No credentials are printed or persisted.
const fs = require('node:fs');
const path = require('node:path');
const os = require('node:os');
const crypto = require('node:crypto');
const { execFileSync } = require('node:child_process');
const project = 'logcal-ai';
const pilot = 'NIDRscOVhuQRpSEzrgk5gMo2i8m1';
const command = process.argv[2] || 'status';
const root = path.resolve(__dirname, '../..');
const baseline = require('../releases/whatsapp-prod-before-agent-2026-11-22.json');
(async () => {
 if (command === 'rollback-code') {
   const archive = path.join(root, 'deployments/whatsapp/whatsapp-prod-before-agent-2026-11-22.zip');
   if (crypto.createHash('sha256').update(fs.readFileSync(archive)).digest('hex') !== baseline.sourceZipSha256) throw Error('Baseline archive checksum mismatch');
   const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'logcal-whatsapp-rollback-'));
   fs.mkdirSync(path.join(dir, 'functions'));
   execFileSync('unzip', ['-q', archive, '-d', path.join(dir, 'functions')]);
   fs.writeFileSync(path.join(dir, 'firebase.json'), JSON.stringify({ functions: { source: 'functions' } }));
   execFileSync('npm', ['ci', '--ignore-scripts'], { cwd: path.join(dir, 'functions'), stdio: 'inherit' });
   execFileSync('firebase', ['deploy', '--only', 'functions:whatsappWebhook', '--project', project, '--non-interactive'], { cwd: dir, stdio: 'inherit' });
   console.log('Restored the verified pre-agent webhook. App-facing functions were not deployed.');
   return;
 }
 if (!['status', 'enable', 'disable'].includes(command)) throw Error('Use status, enable, disable, or rollback-code');
 const binary = fs.realpathSync(execFileSync('which', ['firebase'], { encoding: 'utf8' }).trim());
 const auth = require(path.resolve(path.dirname(binary), '../auth.js'));
 const account = auth.getGlobalDefaultAccount(); if (!account) throw Error('Run firebase login');
 const token = await auth.getAccessToken(account.tokens.refresh_token, ['https://www.googleapis.com/auth/cloud-platform']);
 const headers = { Authorization: `Bearer ${token.access_token}`, 'Content-Type': 'application/json' };
 const url = `https://firestore.googleapis.com/v1/projects/${project}/databases/(default)/documents/app/whatsappAgent`;
 if (command !== 'status') {
   if (command === 'enable') {
     const worker = await fetch(`https://cloudfunctions.googleapis.com/v1/projects/${project}/locations/asia-southeast1/functions/whatsappAgentWorker`, { headers });
     if (!worker.ok || (await worker.json()).status !== 'ACTIVE') throw Error('Deploy the agent worker before enabling the pilot');
   }
   const response = await fetch(url, { method: 'PATCH', headers, body: JSON.stringify({ fields: {
     enabled: { booleanValue: command === 'enable' }, allowedUids: { arrayValue: { values: [{ stringValue: pilot }] } },
     version: { stringValue: 'pilot-v1' }, generation: { stringValue: crypto.randomUUID() }, updatedAt: { timestampValue: new Date().toISOString() },
   } }) });
   if (!response.ok) throw Error(`Could not update pilot flag (${response.status})`);
 }
 const response = await fetch(url, { headers });
 if (response.status === 404) { console.log('Pilot flag absent: everyone uses the existing bot.'); return; }
 if (!response.ok) throw Error(`Could not read pilot flag (${response.status})`);
 const fields = (await response.json()).fields || {};
 console.log(JSON.stringify({ enabled: fields.enabled?.booleanValue === true,
   allowedUids: fields.allowedUids?.arrayValue?.values?.map(v => v.stringValue) || [], version: fields.version?.stringValue || null }));
})().catch(error => { console.error(error.message); process.exitCode = 1; });
