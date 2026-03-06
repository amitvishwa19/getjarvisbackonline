#!/usr/bin/env node
// Deploy folder to here.now (matches skill implementation)

const fs = require('fs');
const path = require('path');
const https = require('https');

// Load .env from workspace root
const envPath = path.resolve(__dirname, '..', '.env');
if (fs.existsSync(envPath)) {
  const envContent = fs.readFileSync(envPath, 'utf8');
  envContent.split('\n').forEach(line => {
    // Skip comments and empty lines
    if (line.startsWith('#') || !line.includes('=')) return;
    const idx = line.indexOf('=');
    const key = line.substring(0, idx).trim();
    let value = line.substring(idx + 1).trim();
    // Remove optional quotes
    if (value.startsWith('"') && value.endsWith('"')) value = value.slice(1, -1);
    if (value.startsWith("'") && value.endsWith("'")) value = value.slice(1, -1);
    if (!process.env[key]) process.env[key] = value;
  });
}

const dir = process.argv[2] || 'docs/dist';
const baseDir = path.resolve(process.cwd(), dir);

const apiKey = process.env.HERENOW_API_KEY;
if (!apiKey) {
  console.error('❌ HERENOW_API_KEY not set in environment');
  process.exit(1);
}

function getMimeType(filePath) {
  const ext = path.extname(filePath).toLowerCase();
  const map = {
    '.html': 'text/html; charset=utf-8',
    '.htm': 'text/html; charset=utf-8',
    '.css': 'text/css; charset=utf-8',
    '.js': 'text/javascript; charset=utf-8',
    '.mjs': 'text/javascript; charset=utf-8',
    '.json': 'application/json; charset=utf-8',
    '.txt': 'text/plain; charset=utf-8',
    '.md': 'text/markdown; charset=utf-8',
    '.png': 'image/png',
    '.jpg': 'image/jpeg',
    '.jpeg': 'image/jpeg',
    '.gif': 'image/gif',
    '.svg': 'image/svg+xml',
    '.ico': 'image/x-icon',
    '.pdf': 'application/pdf',
    '.mp4': 'video/mp4',
    '.webm': 'video/webm',
    '.mp3': 'audio/mpeg',
    '.wav': 'audio/wav',
    '.woff': 'font/woff',
    '.woff2': 'font/woff2',
    '.ttf': 'font/ttf',
    '.eot': 'application/vnd.ms-fontobject',
    '.otf': 'font/otf'
  };
  return map[ext] || 'application/octet-stream';
}

function walk(dir, files = []) {
  const entries = fs.readdirSync(dir, { withFileTypes: true });
  for (const entry of entries) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      walk(full, files);
    } else if (entry.isFile()) {
      const rel = path.relative(baseDir, full).replace(/\\/g, '/');
      files.push({
        path: rel,
        size: fs.statSync(full).size,
        contentType: getMimeType(full)
      });
    }
  }
  return files;
}

function uploadFile({ url, path: filePath, headers }) {
  return new Promise((resolve, reject) => {
    const stat = fs.statSync(filePath);
    const fileSize = stat.size;
    const mimeType = headers['Content-Type'] || getMimeType(filePath);
    const req = https.request(url, {
      method: 'PUT',
      headers: {
        'Content-Type': mimeType,
        'Content-Length': fileSize
      }
    }, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          resolve();
        } else {
          reject(new Error(`Upload ${filePath}: ${res.statusCode} ${data}`));
        }
      });
    });
    req.on('error', reject);
    fs.createReadStream(filePath).pipe(req);
  });
}

(async () => {
  if (!fs.existsSync(baseDir)) {
    console.error(`❌ Directory not found: ${baseDir}`);
    process.exit(1);
  }

  console.log(`📦 Publishing folder: ${baseDir}`);
  const files = walk(baseDir);
  console.log(`📁 Files to upload: ${files.length}`);

  // Step 1: Init
  console.log('🔧 Initializing publish...');
  let initRes;
  try {
    initRes = await new Promise((resolve, reject) => {
      const req = https.request('https://here.now/api/v1/publish', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${apiKey}`,
          'Content-Type': 'application/json'
        }
      }, (res) => {
        let data = Buffer.from('');
        res.on('data', chunk => data = Buffer.concat([data, chunk]));
        res.on('end', () => {
          if (res.statusCode >= 200 && res.statusCode < 300) {
            try { resolve(JSON.parse(data.toString())); }
            catch (e) { reject(new Error(`Invalid JSON: ${data}`)); }
          } else {
            reject(new Error(`Init failed: ${res.statusCode} ${data}`));
          }
        });
      });
      req.on('error', reject);
      req.write(JSON.stringify({ files }));
      req.end();
    });
  } catch (err) {
    console.error('❌ Init error:', err.message);
    if (err.message.includes('Invalid JSON') || err.message.includes('Init failed')) {
      // err may have response data attached; print stack
      console.error('Full error:', err);
    }
    process.exit(1);
  }

  const { upload, siteUrl, slug } = initRes;
  if (!upload?.uploads?.length) {
    console.error('❌ No uploads in response');
    process.exit(1);
  }

  // Step 2: Upload all files (parallel)
  console.log('☁️ Uploading files...');
  const uploadPromises = upload.uploads.map(u => {
    const absPath = path.join(baseDir, u.path.replace(/\//g, path.sep));
    return uploadFile({ ...u, path: absPath });
  });

  try {
    await Promise.all(uploadPromises);
    console.log('✅ All files uploaded');
  } catch (err) {
    console.error('❌ Upload error:', err.message);
    process.exit(1);
  }

  // Step 3: Finalize
  console.log('✨ Finalizing...');
  try {
    await new Promise((resolve, reject) => {
      const req = https.request(upload.finalizeUrl, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${apiKey}`,
          'Content-Type': 'application/json'
        }
      }, (res) => {
        let data = '';
        res.on('data', chunk => data += chunk);
        res.on('end', () => {
          if (res.statusCode >= 200 && res.statusCode < 300) {
            resolve();
          } else {
            reject(new Error(`Finalize failed: ${res.statusCode} ${data}`));
          }
        });
      });
      req.on('error', reject);
      req.write(JSON.stringify({ versionId: upload.versionId }));
      req.end();
    });
  } catch (err) {
    console.error('❌ Finalize error:', err.message);
    process.exit(1);
  }

  console.log('\n🎉 Deployed to here.now!');
  console.log(`🌐 Site: ${siteUrl}`);
  console.log(`🔖 Slug: ${slug}`);
}, (err) => {
  console.error('❌ Unexpected:', err);
  process.exit(1);
})();
