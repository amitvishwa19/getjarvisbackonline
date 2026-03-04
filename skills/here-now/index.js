// here-now skill — instant deploy
// usage: publish --dir <folder>
// Requires HERENOW_API_KEY environment variable.

const fs = require('fs');
const path = require('path');
const https = require('https');

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
      res.on('data', (chunk) => data += chunk);
      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          resolve();
        } else {
          reject(new Error(`Upload failed for ${filePath}: ${res.statusCode} ${data}`));
        }
      });
    });
    req.on('error', reject);
    const fileStream = fs.createReadStream(filePath);
    fileStream.on('error', reject);
    fileStream.pipe(req);
  });
}

async function handler(args, context) {
  const dir = args['dir'] || args['d'];
  if (!dir) {
    return 'Error: --dir <folder> required';
  }

  const baseDir = path.resolve(process.cwd(), dir);
  if (!fs.existsSync(baseDir)) {
    return `Error: Directory not found: ${baseDir}`;
  }

  const apiKey = process.env.HERENOW_API_KEY;
  if (!apiKey) {
    return 'Error: HERENOW_API_KEY environment variable not set. Set it in your environment.';
  }

  // Build file manifest recursively (relative paths with forward slashes)
  const files = [];
  function walk(current) {
    const entries = fs.readdirSync(current, { withFileTypes: true });
    for (const entry of entries) {
      const fullPath = path.join(current, entry.name);
      const relPath = path.relative(baseDir, fullPath).replace(/\\/g, '/');
      if (entry.isDirectory()) {
        walk(fullPath);
      } else if (entry.isFile()) {
        const stat = fs.statSync(fullPath);
        files.push({
          path: relPath,
          size: stat.size,
          contentType: getMimeType(fullPath)
        });
      }
    }
  }
  walk(baseDir);

  if (files.length === 0) {
    return 'Error: No files found in directory';
  }

  // Step 1: Create publish request
  const publishPayload = { files };
  let publishRes;
  try {
    publishRes = await new Promise((resolve, reject) => {
      const req = https.request(
        'https://here.now/api/v1/publish',
        {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${apiKey}`,
            'Content-Type': 'application/json'
          }
        },
        (res) => {
          let data = Buffer.from('');
          res.on('data', (chunk) => data = Buffer.concat([data, chunk]));
          res.on('end', () => {
            if (res.statusCode >= 200 && res.statusCode < 300) {
              try {
                resolve(JSON.parse(data.toString()));
              } catch (e) {
                reject(new Error(`Invalid JSON response: ${data.toString()}`));
              }
            } else {
              reject(new Error(`Publish create failed: ${res.statusCode} ${data.toString()}`));
            }
          });
        }
      );
      req.on('error', reject);
      req.write(JSON.stringify(publishPayload));
      req.end();
    });
  } catch (err) {
    return `❌ Publish initialization failed: ${err.message}`;
  }

  const { upload, siteUrl, slug } = publishRes;
  if (!upload || !upload.uploads || !upload.finalizeUrl || !upload.versionId) {
    return 'Error: Invalid response from here.now (missing upload details)';
  }

  // Step 2: Upload files (parallel)
  const uploadPromises = upload.uploads.map(u => {
    const absolutePath = path.join(baseDir, u.path.replace(/\//g, path.sep));
    return uploadFile({ ...u, path: absolutePath }).catch(err => {
      throw new Error(`Upload failed for ${u.path}: ${err.message}`);
    });
  });

  try {
    await Promise.all(uploadPromises);
  } catch (err) {
    return `❌ ${err.message}`;
  }

  // Step 3: Finalize
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
        res.on('data', (chunk) => data += chunk);
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
    return `❌ Finalize failed: ${err.message}`;
  }

  return `✅ Deployed to here.now!\n🌐 Site: ${siteUrl}\n🔖 Slug: ${slug}`;
}

module.exports = {
  name: 'here-now',
  description: 'Instant publish/deploy to here.now',
  usage: 'publish --dir <folder>',
  handler
};
