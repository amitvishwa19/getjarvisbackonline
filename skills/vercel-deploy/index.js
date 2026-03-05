// vercel-deploy skill — deploy static site to Vercel
// Usage: vercel-deploy --dir <folder> [--prod]
// Env: VERCEL_API_TOKEN

const fs = require('fs');
const path = require('path');
const https = require('https');

function readDirRecursively(dir) {
  const files = [];
  const entries = fs.readdirSync(dir, { withFileTypes: true });
  for (const entry of entries) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      files.push(...readDirRecursively(full));
    } else if (entry.isFile()) {
      files.push(full);
    }
  }
  return files;
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

function uploadFile({ url, filePath, mimeType }) {
  return new Promise((resolve, reject) => {
    const stats = fs.statSync(filePath);
    const fileSize = stats.size;
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
          reject(new Error(`Upload failed (${res.statusCode}): ${data}`));
        }
      });
    });
    req.on('error', reject);
    const stream = fs.createReadStream(filePath);
    stream.on('error', reject);
    stream.pipe(req);
  });
}

async function handler(args) {
  const dir = args['dir'] || args['d'];
  if (!dir) {
    return 'Error: --dir <folder> required';
  }

  const baseDir = path.resolve(process.cwd(), dir);
  if (!fs.existsSync(baseDir)) {
    return `Error: Directory not found: ${baseDir}`;
  }

  const token = process.env.VERCEL_API_TOKEN;
  if (!token) {
    return 'Error: VERCEL_API_TOKEN environment variable not set. Get one from https://vercel.com/account/tokens';
  }

  const isProd = args['prod'] === true || args['p'] === true;

  // Generate a unique project name to avoid conflicts
  const randomSuffix = Math.random().toString(36).substring(2, 8);
  const projectName = `${path.basename(baseDir)}-${randomSuffix}`;

  // Gather all files
  const allFiles = readDirRecursively(baseDir);
  if (allFiles.length === 0) {
    return 'Error: No files found in directory';
  }

  // Build file map: key=relative path, value=base64 content
  const fileMap = {};
  for (const fullPath of allFiles) {
    const relPath = path.relative(baseDir, fullPath).replace(/\\/g, '/');
    const content = fs.readFileSync(fullPath);
    fileMap[relPath] = content.toString('base64');
  }

  // Create deployment
  const body = {
    name: projectName,
    ...(isProd && { target: 'production' })
  };
  // Add files
  body.files = fileMap;

  return new Promise((resolve, reject) => {
    const req = https.request({
      hostname: 'api.vercel.com',
      path: '/v10/deployments',
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      }
    }, (res) => {
      let data = '';
      res.on('data', (chunk) => data += chunk);
      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          try {
            const json = JSON.parse(data);
            const url = json.deploymentUrl || json.url || `https://${json.alias || ''}.vercel.app`;
            resolve(`✅ Deployed to Vercel!\n🌐 ${url}`);
          } catch (e) {
            reject(new Error(`Invalid JSON response: ${data}`));
          }
        } else {
          reject(new Error(`Vercel API error ${res.statusCode}: ${data}`));
        }
      });
    });
    req.on('error', reject);
    req.write(JSON.stringify(body));
    req.end();
  });
}

module.exports = {
  name: 'vercel-deploy',
  description: 'Deploy static site to Vercel',
  usage: 'vercel-deploy --dir <folder> [--prod]',
  handler
};
