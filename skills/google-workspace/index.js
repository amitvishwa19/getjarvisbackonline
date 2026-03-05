// google-workspace skill
// Actions: gdrive-list, gdrive-upload, gmail-send, calendar-create, calendar-list
// Requires: npm install googleapis

const fs = require('fs');
const path = require('path');

let google;
try {
  const { google: g } = require('googleapis');
  google = g;
} catch (e) {
  module.exports.handler = async () => {
    return 'Error: googleapis package not installed. Run: npm install googleapis';
  };
  process.exit(0);
}

function getOAuth2Client() {
  const clientId = process.env.GOOGLE_CLIENT_ID;
  const clientSecret = process.env.GOOGLE_CLIENT_SECRET;
  const refreshToken = process.env.GOOGLE_REFRESH_TOKEN;

  if (!clientId || !clientSecret || !refreshToken) {
    throw new Error('Missing GOOGLE_CLIENT_ID, GOOGLE_CLIENT_SECRET, or GOOGLE_REFRESH_TOKEN');
  }

  const oauth2Client = new google.auth.OAuth2(clientId, clientSecret, 'urn:ietf:wg:oauth:2.0:oob');
  oauth2Client.setCredentials({ refresh_token: refreshToken });
  return oauth2Client;
}

async function listDrive(args) {
  const drive = google.drive({ version: 'v3', auth: getOAuth2Client() });
  const params = { pageSize: 10 };
  if (args['folder-id']) {
    params.q = `'${args['folder-id']}' in parents and trashed=false`;
  } else {
    params.q = "trashed=false";
  }
  const res = await drive.files.list(params);
  const files = res.data.files;
  if (files.length === 0) {
    return 'Drive: No files found.';
  }
  let out = `📁 Drive files (${files.length}):\n`;
  files.forEach(f => {
    out += `- ${f.name} (ID: ${f.id})\n`;
  });
  return out;
}

async function uploadDrive(args) {
  const filePath = args['file'];
  if (!filePath || !fs.existsSync(filePath)) {
    return `Error: File not found: ${filePath}`;
  }
  const drive = google.drive({ version: 'v3', auth: getOAuth2Client() });
  const fileName = args['name'] || path.basename(filePath);
  const folderId = args['folder-id'] || null;

  const fileMetadata = {
    name: fileName,
    ...(folderId && { parents: [folderId] })
  };
  const media = {
    mimeType: 'application/octet-stream',
    body: fs.createReadStream(filePath)
  };

  const res = await drive.files.create({ requestBody: fileMetadata, media, fields: 'id, webViewLink' });
  const file = res.data;
  return `✅ Uploaded: ${fileName}\n🔗 https://drive.google.com/file/d/${file.id}/view`;
}

async function sendGmail(args) {
  const to = args['to'];
  const subject = args['subject'];
  const body = args['body'];
  if (!to || !subject || !body) {
    return 'Error: --to, --subject, and --body required';
  }

  const gmail = google.gmail({ version: 'v1', auth: getOAuth2Client() });
  const message = `From: me\nTo: ${to}\nSubject: ${subject}\n\n${body}`;
  const encoded = Buffer.from(message).toString('base64').replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');

  await gmail.users.messages.send({ userId: 'me', requestBody: { raw: encoded } });
  return `✅ Email sent to ${to}`;
}

async function listUnreadGmail(args) {
  const gmail = google.gmail({ version: 'v1', auth: getOAuth2Client() });
  const maxResults = parseInt(args['max-results'] || '10', 10);
  const res = await gmail.users.messages.list({
    userId: 'me',
    q: 'is:unread',
    maxResults: maxResults
  });
  const messages = res.data.messages || [];
  if (messages.length === 0) {
    return '📭 No unread emails.';
  }
  // Fetch details for each message (subject, from, snippet)
  let out = `📨 Unread emails (${messages.length}):\n`;
  for (const msg of messages) {
    try {
      const msgDetail = await gmail.users.messages.get({ userId: 'me', id: msg.id, format: 'metadata', metadataHeaders: ['Subject', 'From', 'Date'] });
      const headers = msgDetail.data.payload.headers;
      const subjectHeader = headers.find(h => h.name === 'Subject');
      const fromHeader = headers.find(h => h.name === 'From');
      const dateHeader = headers.find(h => h.name === 'Date');
      const subject = subjectHeader ? subjectHeader.value : '(no subject)';
      const from = fromHeader ? fromHeader.value : '(unknown sender)';
      const date = dateHeader ? dateHeader.value : '';
      out += `- ${subject}\n  From: ${from}\n  Date: ${date}\n  ID: ${msg.id}\n\n`;
    } catch (e) {
      out += `- (error fetching details for ${msg.id})\n`;
    }
  }
  return out;
}

async function listRecentGmail(args) {
  const gmail = google.gmail({ version: 'v1', auth: getOAuth2Client() });
  const maxResults = parseInt(args['max-results'] || '10', 10);
  const onlyUnread = args['unread'] === true || args['unread'] === 'true';
  const query = onlyUnread ? 'is:unread' : '';
  const res = await gmail.users.messages.list({
    userId: 'me',
    q: query,
    maxResults: maxResults,
    orderBy: 'date' // default descending by date
  });
  const messages = res.data.messages || [];
  if (messages.length === 0) {
    return query ? '📭 No unread emails.' : '📭 No emails found.';
  }
  let out = `📧 Recent emails (${messages.length}${query ? ', unread' : ''}):\n`;
  for (const msg of messages) {
    try {
      const msgDetail = await gmail.users.messages.get({ userId: 'me', id: msg.id, format: 'metadata', metadataHeaders: ['Subject', 'From', 'Date'] });
      const headers = msgDetail.data.payload.headers;
      const subjectHeader = headers.find(h => h.name === 'Subject');
      const fromHeader = headers.find(h => h.name === 'From');
      const dateHeader = headers.find(h => h.name === 'Date');
      const subject = subjectHeader ? subjectHeader.value : '(no subject)';
      const from = fromHeader ? fromHeader.value : '(unknown sender)';
      const date = dateHeader ? dateHeader.value : '';
      out += `- ${subject}\n  From: ${from}\n  Date: ${date}\n  ID: ${msg.id}\n\n`;
    } catch (e) {
      out += `- (error fetching details for ${msg.id})\n`;
    }
  }
  return out;
}

async function createCalendarEvent(args) {
  const title = args['title'];
  const start = args['start']; // ISO8601
  const end = args['end'];
  const description = args['description'] || '';

  if (!title || !start || !end) {
    return 'Error: --title, --start, --end required';
  }

  const calendar = google.calendar({ version: 'v3', auth: getOAuth2Client() });
  const res = await calendar.events.insert({
    calendarId: 'primary',
    requestBody: {
      summary: title,
      description,
      start: { dateTime: start },
      end: { dateTime: end }
    }
  });
  const event = res.data;
  return `✅ Event created: ${event.htmlLink}`;
}

async function listCalendarEvents(args) {
  const calendar = google.calendar({ version: 'v3', auth: getOAuth2Client() });
  const max = parseInt(args['max-results'] || '10', 10);
  const res = await calendar.events.list({
    calendarId: 'primary',
    maxResults: max,
    singleEvents: true,
    orderBy: 'startTime'
  });
  const events = res.data.items;
  if (!events || events.length === 0) {
    return 'Calendar: No upcoming events.';
  }
  let out = `📅 Upcoming events (${events.length}):\n`;
  events.forEach(e => {
    const start = e.start.dateTime || e.start.date;
    out += `- ${e.summary} @ ${start}\n`;
  });
  return out;
}

async function handler(args) {
  const action = args['action'] || args['a'];
  if (!action) {
    return 'Error: --action required (gdrive-list, gdrive-upload, gmail-send, calendar-create, calendar-list)';
  }

  try {
    switch (action) {
      case 'gdrive-list': return await listDrive(args);
      case 'gdrive-upload': return await uploadDrive(args);
      case 'gmail-send': return await sendGmail(args);
      case 'gmail-unread': return await listUnreadGmail(args);
      case 'gmail-recent': return await listRecentGmail(args);
      case 'calendar-create': return await createCalendarEvent(args);
      case 'calendar-list': return await listCalendarEvents(args);
      default: return `Error: Unknown action '${action}'. Valid actions: gdrive-list, gdrive-upload, gmail-send, gmail-unread, gmail-recent, calendar-create, calendar-list`;
    }
  } catch (err) {
    return `❌ ${err.message}`;
  }
}

module.exports = {
  name: 'google-workspace',
  description: 'Interact with Google Workspace (Drive, Gmail, Calendar)',
  usage: 'google-workspace --action <action> [options]\nActions: gdrive-list, gdrive-upload, gmail-send, gmail-unread, gmail-recent, calendar-create, calendar-list',
  handler
};
