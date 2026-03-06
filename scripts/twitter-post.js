#!/usr/bin/env node

/**
 * Twitter Post Script (with optional image)
 * Uses OAuth 1.0a and Twitter API v2
 * Supports Slack notifications
 *
 * Usage:
 *   node twitter-post.js "tweet text"
 *   node twitter-post.js "tweet with image" /path/to/image.jpg
 */

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

// Load .env from workspace root
const envPath = path.resolve(__dirname, '..', '.env');
if (fs.existsSync(envPath)) {
  const envContent = fs.readFileSync(envPath, 'utf8');
  envContent.split('\n').forEach(line => {
    const match = line.match(/^([^=]+)=(.*)$/);
    if (match) {
      const key = match[1].trim();
      const value = match[2].trim();
      if (!process.env[key]) process.env[key] = value; // don't override
    }
  });
}

// Twitter credentials
const CONSUMER_KEY = process.env.TWITTER_API_KEY;
const CONSUMER_SECRET = process.env.TWITTER_API_SECRET;
const ACCESS_TOKEN = process.env.TWITTER_ACCESS_TOKEN;
const ACCESS_TOKEN_SECRET = process.env.TWITTER_ACCESS_TOKEN_SECRET;

if (!CONSUMER_KEY || !CONSUMER_SECRET || !ACCESS_TOKEN || !ACCESS_TOKEN_SECRET) {
  console.error('❌ Missing Twitter credentials. Ensure .env contains:');
  console.error('   TWITTER_API_KEY, TWITTER_API_SECRET, TWITTER_ACCESS_TOKEN, TWITTER_ACCESS_TOKEN_SECRET');
  process.exit(1);
}

// Slack config (optional)
const SLACK_BOT_TOKEN = process.env.SLACK_BOT_TOKEN;
const SLACK_CHANNEL_ID = process.env.SLACK_CHANNEL_ID || 'C0AHWQG9536';

// OAuth 1.0a helpers
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

// Main
(async () => {
  const args = process.argv.slice(2);
  if (args.length < 1) {
    console.error('Usage: node twitter-post.js "tweet text" [image_path]');
    process.exit(1);
  }
  const text = args[0];
  const imagePath = args[1] || null;

  if (imagePath && !fs.existsSync(imagePath)) {
    console.error('❌ Image file not found:', imagePath);
    process.exit(1);
  }

  try {
    let mediaId = null;
    if (imagePath) {
      console.log('📸 Uploading image...');
      const uploadUrl = 'https://upload.twitter.com/1.1/media/upload.json';
      const authHeader = await getOAuthHeader('POST', uploadUrl);
      const form = new FormData();
      form.append('media', fs.createReadStream(imagePath));
      const uploadResponse = await fetch(uploadUrl, {
        method: 'POST',
        headers: {
          'Authorization': authHeader
        },
        body: form
      });
      const uploadData = await uploadResponse.json();
      if (uploadData.error) {
        throw new Error(uploadData.error?.message || 'Media upload failed');
      }
      mediaId = uploadData.media_id_string;
      console.log('✅ Media uploaded, ID:', mediaId);
    }

    console.log('🐦 Posting tweet...');
    const tweetUrl = 'https://api.twitter.com/2/tweets';
    const authHeader = await getOAuthHeader('POST', tweetUrl);
    const tweetBody = { text };
    if (mediaId) {
      tweetBody.media = { media_ids: [mediaId] };
    }
    const tweetResponse = await fetch(tweetUrl, {
      method: 'POST',
      headers: {
        'Authorization': authHeader,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(tweetBody)
    });
    const tweetText = await tweetResponse.text();
    let tweetData;
    try {
      tweetData = JSON.parse(tweetText);
    } catch (e) {
      throw new Error(`Invalid JSON response: ${tweetText}`);
    }
    if (!tweetResponse.ok) {
      console.error('Response body:', tweetText);
      const errMsg = tweetData.title || tweetData.error?.message || tweetData.errors?.[0]?.detail || tweetText;
      throw new Error(`HTTP ${tweetResponse.status}: ${errMsg}`);
    }
    const tweetId = tweetData.data?.id;
    if (!tweetId) {
      throw new Error(`No tweet ID in response: ${tweetText}`);
    }
    const tweetLink = `https://twitter.com/i/web/status/${tweetId}`;
    console.log('✅ Tweet posted!');
    console.log('ID:', tweetId);
    console.log('Link:', tweetLink);

    // Slack notification (optional)
    if (SLACK_BOT_TOKEN && SLACK_CHANNEL_ID) {
      const slackMsg = `📢 *New Tweet*\n*Content:* ${text}\n*Link:* ${tweetLink}\n*Time:* ${new Date().toISOString()}`;
      try {
        await fetch('https://slack.com/api/chat.postMessage', {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${SLACK_BOT_TOKEN}`,
            'Content-Type': 'application/json; charset=utf-8'
          },
          body: JSON.stringify({
            channel: SLACK_CHANNEL_ID,
            text: slackMsg
          })
        });
        console.log('✅ Slack notification sent');
      } catch (e) {
        console.error('Slack notification failed:', e.message);
      }
    }
  } catch (err) {
    console.error('❌ Error:', err.message);
    process.exit(1);
  }
})();
