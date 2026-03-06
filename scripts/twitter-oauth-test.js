#!/usr/bin/env node
// Minimal OAuth 1.0a test using oauth-1.0a library
// Get user info (read-only)

const fs = require('fs');
const path = require('path');
const https = require('https');
const crypto = require('crypto');
const oauth = require('oauth-1.0a');

// Load .env
const envPath = path.resolve(__dirname, '..', '.env');
if (fs.existsSync(envPath)) {
  const envContent = fs.readFileSync(envPath, 'utf8');
  envContent.split('\n').forEach(line => {
    const match = line.match(/^([^=]+)=(.*)$/);
    if (match) {
      const key = match[1].trim();
      const value = match[2].trim();
      if (!process.env[key]) process.env[key] = value;
    }
  });
}

const CONSUMER_KEY = process.env.TWITTER_API_KEY;
const CONSUMER_SECRET = process.env.TWITTER_API_SECRET;
const ACCESS_TOKEN = process.env.TWITTER_ACCESS_TOKEN;
const ACCESS_TOKEN_SECRET = process.env.TWITTER_ACCESS_TOKEN_SECRET;

if (!CONSUMER_KEY || !CONSUMER_SECRET || !ACCESS_TOKEN || !ACCESS_TOKEN_SECRET) {
  console.error('❌ Missing credentials');
  process.exit(1);
}

// OAuth 1.0a client
const client = oauth({
  consumer: { key: CONSUMER_KEY, secret: CONSUMER_SECRET },
  signature_method: 'HMAC-SHA1',
  hash_function(base_string, key) {
    return crypto.createHmac('sha1', key).update(base_string).digest('base64');
  }
});

const request_data = {
  url: 'https://api.twitter.com/2/users/me',
  method: 'GET',
  data: { 'user.fields': 'username,id' }
};

const authHeader = client.authorize(request_data, {
  key: ACCESS_TOKEN,
  secret: ACCESS_TOKEN_SECRET
});

console.log('Authorization header:', authHeader);

// Now make request
const url = new URL('https://api.twitter.com/2/users/me');
url.searchParams.set('user.fields', 'username,id');

https.get(url, {
  headers: {
    'Authorization': authHeader
  }
}, (res) => {
  let data = '';
  res.on('data', chunk => data += chunk);
  res.on('end', () => {
    console.log(`Status: ${res.statusCode}`);
    console.log('Body:', data);
    if (res.statusCode === 200) {
      console.log('✅ Auth successful!');
    } else {
      console.error('❌ Auth failed');
    }
  });
}).on('error', (e) => {
  console.error('Request error:', e);
});
