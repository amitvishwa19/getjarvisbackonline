const { google } = require('googleapis');

const clientId = process.env.GOOGLE_CLIENT_ID;
const clientSecret = process.env.GOOGLE_CLIENT_SECRET;
const code = process.env.GOOGLE_AUTH_CODE || '4/1AfrIepAPkkwMRctr70hJBqj-dLpmjGjvIe94tXNwg80abOKtuHcT0y_SDFo'; // placeholder

if (!clientId || !clientSecret || !code) {
  console.error('Missing GOOGLE_CLIENT_ID, GOOGLE_CLIENT_SECRET, or GOOGLE_AUTH_CODE');
  process.exit(1);
}

const oauth2Client = new google.auth.OAuth2(
  clientId,
  clientSecret,
  'urn:ietf:wg:oauth:2.0:oob'
);

async function exchangeCode() {
  try {
    const { tokens } = await oauth2Client.getToken(code);
    console.log('=== GOOGLE TOKENS ===');
    console.log('Access Token:', tokens.access_token);
    console.log('Refresh Token:', tokens.refresh_token);
    console.log('Scope:', tokens.scope);
    console.log('Expiry:', tokens.expiry_date ? new Date(tokens.expiry_date).toISOString() : 'N/A');
    console.log('======================');
    console.log('\nAdd to your environment:');
    console.log(`export GOOGLE_REFRESH_TOKEN="${tokens.refresh_token}"`);
  } catch (err) {
    console.error('Error exchanging code:', err.response?.data || err.message);
    process.exit(1);
  }
}

exchangeCode();