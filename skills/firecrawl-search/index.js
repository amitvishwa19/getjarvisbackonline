const https = require('https');

/**
 * Firecrawl Search Skill
 * Web scraping and crawling via Firecrawl API
 */

async function handler(args, context) {
  const { action, url, query, limit = 10, outputFormat = 'json', extractLinks = false, includeHtml = false } = args;

  const apiKey = process.env.FIRECRAWL_API_KEY;
  if (!apiKey) {
    throw new Error('FIRECRAWL_API_KEY environment variable not set');
  }

  let endpoint;
  let body;

  if (action === 'scrape') {
    if (!url) throw new Error('URL required for scrape');
    endpoint = '/v1/scrape';
    body = JSON.stringify({
      url,
      formats: [outputFormat],
      include_links: extractLinks,
      include_html: includeHtml
    });
  } else if (action === 'crawl') {
    if (!url) throw new Error('URL required for crawl');
    endpoint = '/v1/crawl';
    body = JSON.stringify({
      url,
      limit: parseInt(limit, 10) || 10,
      formats: [outputFormat]
    });
  } else if (action === 'search') {
    if (!query || !url) throw new Error('query and site URL required for search');
    endpoint = '/v1/search';
    body = JSON.stringify({
      query,
      search_url: url,
      limit: parseInt(limit, 10) || 10
    });
  } else {
    throw new Error(`Unknown action: ${action}. Use: scrape, crawl, search`);
  }

  const options = {
    hostname: 'api.firecrawl.com',
    port: 443,
    path: endpoint,
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${apiKey}`,
      'Content-Length': body.length
    }
  };

  return new Promise((resolve, reject) => {
    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        if (res.statusCode !== 200) {
          reject(new Error(`Firecrawl API error: ${res.statusCode} ${data}`));
          return;
        }
        try {
          const result = JSON.parse(data);
          resolve(result);
        } catch (e) {
          reject(e);
        }
      });
    });

    req.on('error', reject);
    req.write(body);
    req.end();
  });
}

module.exports = { handler };