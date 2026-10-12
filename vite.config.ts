import tailwindcss from '@tailwindcss/vite';
import react from '@vitejs/plugin-react';
import path from 'path';
import dotenv from 'dotenv';
import {defineConfig, Plugin} from 'vite';

dotenv.config();

function nexAiPlugin(): Plugin {
  return {
    name: 'nex-ai-api',
    configureServer(server) {
      server.middlewares.use('/api/chat', async (req, res) => {
        if (req.method !== 'POST') {
          res.statusCode = 405;
          res.setHeader('Content-Type', 'application/json');
          res.end(JSON.stringify({ error: 'Method not allowed' }));
          return;
        }

        let body = '';
        req.on('data', chunk => {
          body += chunk;
        });
        req.on('end', async () => {
          try {
            const { message, context, language } = JSON.parse(body || '{}');
            const apiKey = process.env.GEMINI_API_KEY;

            if (!apiKey || apiKey === 'MY_GEMINI_API_KEY') {
              res.statusCode = 503;
              res.setHeader('Content-Type', 'application/json');
              res.end(JSON.stringify({
                error: 'GEMINI_API_KEY_NOT_CONFIGURED',
                message: 'No active Gemini API key configured in environment secrets.'
              }));
              return;
            }

            const { GoogleGenAI } = await import('@google/genai');
            const ai = new GoogleGenAI({ apiKey });

            const systemPrompt = `You are NEX, a friendly, intelligent scientific research assistant companion robot in the Research Nexus AI platform.
You have a warm white chassis with deep navy trims and calm teal ocular accents.
You are calm, charming, helpful, and scientifically rigorous.
You never hallucinate citations, invented findings, or fake certainty.
Language requested: ${language === 'th' ? 'Thai' : 'English'}.
Keep your advice clear, encouraging, and structured (under 250 words).`;

            const fullPrompt = `${context ? `[CURRENT WORKSPACE CONTEXT]\n${context}\n\n` : ''}[RESEARCHER QUESTION]\n${message}`;

            const response = await ai.models.generateContent({
              model: 'gemini-3.8-flash',
              contents: fullPrompt,
              config: {
                systemInstruction: systemPrompt,
                temperature: 0.3,
              }
            });

            res.statusCode = 200;
            res.setHeader('Content-Type', 'application/json');
            res.end(JSON.stringify({
              reply: response.text,
              model: 'gemini-3.8-flash'
            }));
          } catch (err: any) {
            console.error('NEX AI Error:', err);
            res.statusCode = 500;
            res.setHeader('Content-Type', 'application/json');
            res.end(JSON.stringify({
              error: 'AI_GENERATION_FAILED',
              message: err?.message || 'Error communicating with AI service.'
            }));
          }
        });
      });
    }
  };
}

export default defineConfig(() => {
  return {
    plugins: [react(), tailwindcss(), nexAiPlugin()],
    resolve: {
      alias: {
        '@': path.resolve(__dirname, '.'),
      },
    },
    server: {
      // HMR is disabled in AI Studio via DISABLE_HMR env var.
      // Do not modify—file watching is disabled to prevent flickering during agent edits.
      hmr: process.env.DISABLE_HMR !== 'true',
      // Disable file watching when DISABLE_HMR is true to save CPU during agent edits.
      watch: process.env.DISABLE_HMR === 'true' ? null : {},
    },
  };
});

