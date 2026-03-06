#!/usr/bin/env node
// Test Twitter OAuth 1.0a authentication (read-only, no posting quota)
// Calls GET /2/users/me

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

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

function percentEncode(str) {
  return encodeURIComponent(str)
    .replace(/[!'()*]/g, c => '%' + c.charCodeAt(0).toString(16).toUpperCase());
}

function generateNonce() {
  return crypto.randomBytes(16).toString('hex');
}

function generateTimestamp() {
  return Math.floor(Date.now() / 1000).toString();
}

function buildSignatureBase(method, url, params) {
  const encoded = {};
  for (const [k, v] of Object.entries(params)) {
    encoded[percentEncode(k)] = percentEncode(String(v));
  }
  const sortedKeys = Object.keys(encoded).sort();
  const paramString = sortedKeys.map(k => `${k}=${encoded[k]}`).join('&');
  return [
    method.toUpperCase(),
    percentEncode(url),
    percentEncode(paramString)
  ].join('&');
}

function buildOAuthHeader(oauthParams) {
  const parts = [];
  const keys = ['oauth_consumer_key', 'oauth_token', 'oauth_nonce', 'oauth_timestamp', 'oauth_signature_method', 'oauth_version', 'oauth_signature'];
  for (const key of keys) {
    if (oauthParams[key] !== undefined) {
      parts.push(`${key}="${percentEncode(oauthParams[key])}"`);
    }
  }
  return 'OAuth ' + parts.join(', ');
}

async function getOAuthHeader(method, url, extraParams = {}) {
  const oauth = {
    oauth_consumer_key: CONSUMER_KEY,
    oauth_token: ACCESS_TOKEN,
    oauth_nonce: generateNonce(),
    oauth_timestamp: generateTimestamp(),
    oauth_signature_method: 'HMAC-SHA1',
    oauth_version: '1.0'
  };
  const allParams = { ...extraParams, ...oauth };
  const signatureBase = buildSignatureBase(method, url, allParams);
  const signingKey = `${percentEncode(CONSUMER_SECRET)}&${percentEncode(ACCESS_TOKEN_SECRET)}`;
  const signature = crypto.createHmac('sha1', signingKey).update(signatureBase).digest('base64');
  oauth.oauth_signature = signature;
  return buildOAuthHeader(oauth);
}

(async () => {
  try {
    const url = 'https://api.twitter.com/2/users/me?user.fields=username,id';
    const authHeader = await getOAuthHeader('GET', url);
    const response = await fetch(url, {
      method: 'GET',
      headers: {
        'Authorization': authHeader
      }
    });
    const text = await response.text();
    console.log(`Response (${response.status}):`, text);
    if (!response.ok) {
      process.exit(1);
    } else {
      console.log('✅ Authentication works!');
    }
  } catch (err) {
    console.error('❌ Error:', err.message);
    process.exit(1);
  }
})();
