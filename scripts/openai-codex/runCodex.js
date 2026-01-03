#!/usr/bin/env node
// Simple example to call OpenAI from Node.js.
// Usage: set OPENAI_API_KEY in env or create a .env file, then:
//   npm install openai dotenv
//   node scripts/openai-codex/runCodex.js "Write a JS function that reverses a string"

const OpenAI = require('openai');
require('dotenv').config();

const apiKey = process.env.OPENAI_API_KEY;
if (!apiKey) {
  console.error('Missing OPENAI_API_KEY. See scripts/openai-codex/README.md');
  process.exit(1);
}

const client = new OpenAI({ apiKey });

async function main() {
  const prompt = process.argv.slice(2).join(' ') || 'Write a JavaScript function that reverses a string.';
  const model = process.env.OPENAI_MODEL || 'gpt-4o-mini';

  // Use the Chat Completions endpoint for a robust code-generation flow.
  const res = await client.chat.completions.create({
    model,
    messages: [{ role: 'user', content: prompt }],
    max_tokens: 512,
  });

  const output = res?.choices?.[0]?.message?.content;
  if (output) console.log(output.trim());
  else console.log(JSON.stringify(res, null, 2));
}

main().catch(err => { console.error(err); process.exit(1); });
