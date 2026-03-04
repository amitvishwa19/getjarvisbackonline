const https = require('https');

/**
 * Tavily Search Skill
 * Performs web search via Tavily API
 */

async function handler(args, context) {
  const { query, maxResults = 5, includeRaw = false } = args;

  const apiKey = process.env.TAVILY_API_KEY;
  if (!apiKey) {
    throw new Error('TAVILY_API_KEY environment variable not set');
  }

  const requestBody = JSON.stringify({
    query,
    max_results: parseInt(maxResults, 10) || 5,
    include_raw: includeRaw
  });

  const options = {
    hostname: 'api.tavily.com',
    port: 443,
    path: '/search',
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${apiKey}`,
      'Content-Length': requestBody.length
    }
  };

  return new Promise((resolve, reject) => {
    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        if (res.statusCode !== 200) {
          reject(new Error(`Tavily API error: ${res.statusCode} ${data}`));
          return;
        }
        try {
          const result = JSON.parse(data);
          // Simplify output
          const simplified = {
            answer: result.answer || null,
            results: (result.results || []).map(r => ({
              title: r.title,
              url: r.url,
              content: r.content,
              score: r.score
            })),
            query: result.query,
            follow_up_questions: result.follow_up_questions || []
          };
          if (includeRaw) {
            simplified.raw = result;
          }
          resolve(simplified);
        } catch (e) {
          reject(e);
        }
      });
    });

    req.on('error', reject);
    req.write(requestBody);
    req.end();
  });
}

module.exports = { handler };