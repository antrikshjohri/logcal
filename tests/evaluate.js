const fs = require('fs');
const path = require('path');
const https = require('https');
const { execSync } = require('child_process');

const PROJECT_ID = 'logcal-ai';
const MODELS = {
  'gpt-4o': 'gpt-4o-2024-08-06',
  'gpt-5.6-luna': 'gpt-5.6-luna',
  'gpt-5-mini': 'gpt-5-mini',
  'o4-mini': 'o4-mini'
};

// Colors for terminal output
const RESET = '\x1b[0m';
const RED = '\x1b[31m';
const GREEN = '\x1b[32m';
const YELLOW = '\x1b[33m';
const CYAN = '\x1b[36m';
const BOLD = '\x1b[1m';

// JSON schema identical to production
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
    },
    required: ["meal_type", "total_calories", "protein", "carbs", "fat", "fiber", "items", "needs_clarification"],
  },
};

// 1. Load API Key
let apiKey = process.env.OPENAI_API_KEY;
if (!apiKey) {
  console.log(`${YELLOW}No OPENAI_API_KEY found in environment. Fetching from Secrets Manager...${RESET}`);
  try {
    apiKey = execSync('npx -y firebase-tools@latest functions:secrets:access OPENAI_API_KEY', { encoding: 'utf8' }).trim();
    console.log(`${GREEN}Successfully retrieved API Key!${RESET}\n`);
  } catch (e) {
    console.error(`${RED}ERROR: Could not retrieve API Key.${RESET}`);
    process.exit(1);
  }
}

// 2. Extract System Prompt from functions/src/index.ts dynamically
function getSystemPrompt() {
  const indexTsPath = path.join(__dirname, '../functions/src/index.ts');
  if (!fs.existsSync(indexTsPath)) {
    throw new Error(`Could not find functions/src/index.ts at ${indexTsPath}`);
  }
  const code = fs.readFileSync(indexTsPath, 'utf8');
  const regex = /systemPrompt\s*=\s*`You are a calorie logging assistant\.(?:[\s\S]*?)`;/g;
  const matches = [...code.matchAll(regex)];
  if (matches.length > 0) {
    const raw = matches[0][0];
    return raw.substring(raw.indexOf('`') + 1, raw.lastIndexOf('`'));
  }
  throw new Error("Could not extract systemPrompt from functions/src/index.ts.");
}

// 3. Parse CSV
function parseCSV(csvText) {
  const rows = [];
  let currentRow = [];
  let currentWord = '';
  let inQuotes = false;
  
  for (let i = 0; i < csvText.length; i++) {
    const char = csvText[i];
    
    if (char === '"') {
      inQuotes = !inQuotes;
    } else if (char === ',' && !inQuotes) {
      currentRow.push(currentWord.trim());
      currentWord = '';
    } else if ((char === '\r' || char === '\n') && !inQuotes) {
      if (currentWord || currentRow.length > 0) {
        currentRow.push(currentWord.trim());
        rows.push(currentRow);
        currentWord = '';
        currentRow = [];
      }
    } else {
      currentWord += char;
    }
  }
  if (currentWord || currentRow.length > 0) {
    currentRow.push(currentWord.trim());
    rows.push(currentRow);
  }
  return rows;
}

// 4. OpenAI Call API
function callOpenAI(model, systemPrompt, foodText, mealType) {
  return new Promise((resolve, reject) => {
    const requestPayload = {
      model: model,
      messages: [
        { role: "system", content: systemPrompt },
        { role: "user", content: `Food description: ${foodText}\nMeal type: ${mealType}` }
      ],
      response_format: {
        type: "json_schema",
        json_schema: MEAL_LOG_JSON_SCHEMA,
      },
    };

    // Omit temperature for models that only support the default 1.0 (GPT-5/Reasoning models)
    if (model === 'gpt-4o-2024-08-06') {
      requestPayload.temperature = 0.25;
    }

    const postData = JSON.stringify(requestPayload);

    const req = https.request({
      hostname: 'api.openai.com',
      path: '/v1/chat/completions',
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(postData)
      }
    }, (res) => {
      let body = '';
      res.on('data', (chunk) => body += chunk);
      res.on('end', () => {
        try {
          const response = JSON.parse(body);
          if (response.error) {
            reject(response.error);
          } else {
            resolve(JSON.parse(response.choices[0].message.content));
          }
        } catch (e) {
          reject(e);
        }
      });
    });

    req.on('error', (e) => reject(e));
    req.write(postData);
    req.end();
  });
}

function pad(str, length) {
  str = String(str);
  if (str.length > length) {
    return str.substring(0, length - 3) + '...';
  }
  return str.padEnd(length, ' ');
}

// 5. Main Execution
async function run() {
  const systemPrompt = getSystemPrompt();

  const csvPath = path.join(__dirname, 'LogCal Dataset test trimmed.csv');
  if (!fs.existsSync(csvPath)) {
    console.error(`${RED}ERROR: Trimmed CSV file not found at ${csvPath}${RESET}`);
    process.exit(1);
  }

  const csvContent = fs.readFileSync(csvPath, 'utf8');
  const csvData = parseCSV(csvContent);
  const items = csvData.slice(1);

  console.log(`${BOLD}${CYAN}=== STARTING 4-WAY MODEL & LATENCY COMPARISON ===${RESET}`);
  console.log(`Evaluating ${items.length} cases using the updated system prompt...\n`);

  // Performance metrics trackers
  const stats = {};
  Object.keys(MODELS).forEach(m => {
    stats[m] = { passes: 0, totalError: 0, totalLatency: 0, count: 0 };
  });

  const tableRows = [];

  for (let i = 0; i < items.length; i++) {
    const row = items[i];
    const foodText = row[0];
    const expectedKcal = parseFloat(row[2]);
    const minKcal = parseFloat(row[7]);
    const maxKcal = parseFloat(row[8]);

    process.stdout.write(`Evaluating case [${i + 1}/${items.length}]: "${foodText.substring(0, 25)}..." `);

    let mealType = 'breakfast';
    if (foodText.toLowerCase().includes('lunch')) mealType = 'lunch';
    if (foodText.toLowerCase().includes('dinner')) mealType = 'dinner';

    const rowResult = {
      id: i + 1,
      text: foodText,
      target: `${expectedKcal} [${minKcal}-${maxKcal}]`,
      displays: {}
    };

    // Evaluate each model sequentially
    for (const [modelKey, modelString] of Object.entries(MODELS)) {
      const startTime = Date.now();
      try {
        const res = await callOpenAI(modelString, systemPrompt, foodText, mealType);
        const latency = (Date.now() - startTime) / 1000; // in seconds
        
        const estKcal = res.total_calories;
        const isPass = estKcal >= minKcal && estKcal <= maxKcal;
        
        stats[modelKey].count++;
        stats[modelKey].totalLatency += latency;
        stats[modelKey].totalError += Math.abs(estKcal - expectedKcal);
        if (isPass) stats[modelKey].passes++;

        rowResult.displays[modelKey] = `${estKcal}(${isPass ? '✔' : '✘'}) ${latency.toFixed(1)}s`;
      } catch (e) {
        rowResult.displays[modelKey] = 'ERR';
      }
    }

    tableRows.push(rowResult);
    process.stdout.write(`Done.\n`);
  }

  // Print Table
  console.log(`\n\n=======================================================================================================`);
  console.log(`${BOLD}#   Food Description          Target range   gpt-4o         gpt-5.6-luna   gpt-5-mini     o4-mini${RESET}`);
  console.log(`=======================================================================================================`);
  tableRows.forEach(r => {
    console.log(
      `${pad(r.id, 3)}` +
      `${pad(r.text, 25)} ` +
      `${pad(r.target, 14)} ` +
      `${pad(r.displays['gpt-4o'], 14)} ` +
      `${pad(r.displays['gpt-5.6-luna'], 14)} ` +
      `${pad(r.displays['gpt-5-mini'], 14)} ` +
      `${pad(r.displays['o4-mini'], 14)}`
    );
  });
  console.log(`=======================================================================================================\n`);

  // Overall Statistics
  console.log(`${BOLD}=== MODEL PERFORMANCE & LATENCY METRICS ===${RESET}`);
  console.log(`-------------------------------------------------------------------------`);
  console.log("Model          Pass Rate     Mean Abs Error (MAE)    Average Latency");
  console.log(`-------------------------------------------------------------------------`);
  Object.keys(MODELS).forEach(m => {
    const s = stats[m];
    const passRate = s.count > 0 ? `${((s.passes / s.count) * 100).toFixed(1)}%` : '0%';
    const mae = s.count > 0 ? `${(s.totalError / s.count).toFixed(1)} kcal` : 'N/A';
    const avgLat = s.count > 0 ? `${(s.totalLatency / s.count).toFixed(2)}s` : 'N/A';
    
    console.log(
      `${pad(m, 14)} ` +
      `${pad(passRate, 13)} ` +
      `${pad(mae, 23)} ` +
      `${avgLat}`
    );
  });
  console.log(`-------------------------------------------------------------------------\n`);
}

run();
