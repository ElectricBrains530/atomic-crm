This folder contains a small example to test OpenAI (Codex-style) code generation.

Quick steps

1. Get an OpenAI API key
   - Go to https://platform.openai.com/account/api-keys and create an API key.

2. Add your API key
   - Copy `.env.example` to `.env` and set `OPENAI_API_KEY`.
   - Or set the environment variable directly:

```powershell
$env:OPENAI_API_KEY = "sk-..."
```

3. Install dependencies

```bash
npm install openai dotenv
```

4. Run the example

```bash
node scripts/openai-codex/runCodex.js "Write a JavaScript function that reverses a string"
```

Notes

- The example uses the `openai` Node SDK. You can change `OPENAI_MODEL` in `.env` to a model you have access to.
- Do not commit your real API key to the repository.
- If you prefer a quick cURL test, replace `<KEY>` and run:

```bash
curl https://api.openai.com/v1/chat/completions \
  -H "Authorization: Bearer <KEY>" \
  -H "Content-Type: application/json" \
  -d '{"model":"gpt-4o-mini","messages":[{"role":"user","content":"Create a Python function to compute Fibonacci numbers."}]}'
```
