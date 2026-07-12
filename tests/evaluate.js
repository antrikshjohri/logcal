const fs = require('fs');
const path = require('path');
const https = require('https');
const { execSync } = require('child_process');

const PROJECT_ID = 'logcal-ai';
const OPENAI_MODEL = 'gpt-4o-2024-08-06';

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
  console.log(`${YELLOW}No OPENAI_API_KEY found in environment. Attempting to fetch from Firebase Secrets Manager...${RESET}`);
  try {
    apiKey = execSync('npx -y firebase-tools@latest functions:secrets:access OPENAI_API_KEY', { encoding: 'utf8' }).trim();
    console.log(`${GREEN}Successfully retrieved API Key from Firebase!${RESET}\n`);
  } catch (e) {
    console.error(`${RED}ERROR: Could not retrieve OPENAI_API_KEY from environment or Firebase.${RESET}`);
    process.exit(1);
  }
}

// 2. Extract New System Prompt from functions/src/index.ts dynamically
function getNewSystemPrompt() {
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
  throw new Error("Could not extract new systemPrompt from functions/src/index.ts.");
}

// Old system prompt baseline
const OLD_SYSTEM_PROMPT = `You are a calorie logging assistant. When given a food description or image, estimate calories and macronutrients (protein, carbs, fat, fiber in grams) based on typical portion sizes. Use the provided meal type. Never ask for clarifications - always set needs_clarification to false and clarifying_question to an empty string. Provide detailed breakdowns of items with quantities, calories, macronutrients, assumptions, and confidence scores. The top-level protein, carbs, fat, and fiber must equal the sum of the same fields across all items (in grams). When both a written description and a photo are provided, you must use both together: identify foods and portion sizes from the photo, use the text for context; if they disagree on something visible in the image, trust the image for that detail. Each item's assumptions field should mention what you inferred from the photo (e.g. visible portion, condiments, cooking style) when a photo is present, not only generic text-based guesses.`;

// 3. Parse CSV file manually (robust line/quote parser)
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
function callOpenAI(systemPrompt, foodText, mealType) {
  return new Promise((resolve, reject) => {
    const postData = JSON.stringify({
      model: OPENAI_MODEL,
      temperature: 0.25,
      messages: [
        { role: "system", content: systemPrompt },
        { role: "user", content: `Food description: ${foodText}\nMeal type: ${mealType}` }
      ],
      response_format: {
        type: "json_schema",
        json_schema: MEAL_LOG_JSON_SCHEMA,
      },
    });

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

// Helper to pad strings for neat table output
function pad(str, length) {
  str = String(str);
  if (str.length > length) {
    return str.substring(0, length - 3) + '...';
  }
  return str.padEnd(length, ' ');
}

// 5. Main Execution
async function run() {
  const newSystemPrompt = getNewSystemPrompt();

  const csvPath = path.join(__dirname, 'LogCal Dataset test trimmed.csv');
  if (!fs.existsSync(csvPath)) {
    console.error(`${RED}ERROR: Trimmed CSV file not found at ${csvPath}${RESET}`);
    process.exit(1);
  }

  const csvContent = fs.readFileSync(csvPath, 'utf8');
  const csvData = parseCSV(csvContent);
  const items = csvData.slice(1);

  console.log(`${BOLD}${CYAN}=== STARTING SIDE-BY-SIDE PROMPT COMPARISON ===${RESET}`);
  console.log(`Evaluating ${items.length} cases on model: ${OPENAI_MODEL}\n`);

  let oldPasses = 0;
  let newPasses = 0;
  let oldTotalError = 0;
  let newTotalError = 0;

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

    let oldEst = null;
    let oldPass = false;
    let newEst = null;
    let newPass = false;

    // Run Old Prompt
    try {
      const res = await callOpenAI(OLD_SYSTEM_PROMPT, foodText, mealType);
      oldEst = res.total_calories;
      oldPass = oldEst >= minKcal && oldEst <= maxKcal;
      if (oldPass) oldPasses++;
      oldTotalError += Math.abs(oldEst - expectedKcal);
    } catch (e) {
      oldEst = 'ERR';
    }

    // Run New Prompt
    try {
      const res = await callOpenAI(newSystemPrompt, foodText, mealType);
      newEst = res.total_calories;
      newPass = newEst >= minKcal && newEst <= maxKcal;
      if (newPass) newPasses++;
      newTotalError += Math.abs(newEst - expectedKcal);
    } catch (e) {
      newEst = 'ERR';
    }

    // Compare results
    let comparison = 'Equal';
    if (oldPass && !newPass) {
      comparison = `${RED}Old Wins${RESET}`;
    } else if (!oldPass && newPass) {
      comparison = `${GREEN}New Wins${RESET}`;
    } else if (!oldPass && !newPass && oldEst !== 'ERR' && newEst !== 'ERR') {
      const oldDiff = Math.abs(oldEst - expectedKcal);
      const newDiff = Math.abs(newEst - expectedKcal);
      if (newDiff < oldDiff) {
        comparison = `${GREEN}New Closer${RESET}`;
      } else if (oldDiff < newDiff) {
        comparison = `${RED}Old Closer${RESET}`;
      }
    }

    const oldDisplay = oldEst === 'ERR' ? 'ERR' : `${oldEst} (${oldPass ? '✔' : '✘'})`;
    const newDisplay = newEst === 'ERR' ? 'ERR' : `${newEst} (${newPass ? '✔' : '✘'})`;

    tableRows.push({
      id: i + 1,
      text: foodText,
      target: `${expectedKcal} [${minKcal}-${maxKcal}]`,
      oldDisplay,
      newDisplay,
      comparison
    });

    process.stdout.write(`Done.\n`);
  }

  // Print Table
  console.log(`\n\n${BOLD}========================================================================================${RESET}`);
  console.log(`${BOLD}#   Food Description          Target range   Old Prompt Est   New Prompt Est   Outcome${RESET}`);
  console.log(`========================================================================================`);
  tableRows.forEach(r => {
    console.log(
      `${pad(r.id, 3)}` +
      `${pad(r.text, 25)} ` +
      `${pad(r.target, 14)} ` +
      `${pad(r.oldDisplay, 16)} ` +
      `${pad(r.newDisplay, 16)} ` +
      `${r.comparison}`
    );
  });
  console.log(`========================================================================================\n`);

  // Overall Statistics
  console.log(`${BOLD}=== COMPARISON METRICS SUMMARY ===${RESET}`);
  console.log(`-----------------------------------------------`);
  console.log(`Metric               Old Prompt      New Prompt`);
  console.log(`-----------------------------------------------`);
  console.log(`Pass Rate            ${((oldPasses / items.length) * 100).toFixed(1)}%           ${((newPasses / items.length) * 100).toFixed(1)}%`);
  console.log(`Mean Abs Error (MAE) ${(oldTotalError / items.length).toFixed(1)} kcal       ${(newTotalError / items.length).toFixed(1)} kcal`);
  console.log(`-----------------------------------------------\n`);
}

run();
