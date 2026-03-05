# google-workspace Skill

Interact with Google Workspace (Drive, Gmail, Calendar).

## Usage

```
google-workspace --action gdrive-list [--folder-id <id>]
google-workspace --action gdrive-upload --file <path> [--folder-id <id>] [--name <filename>]
google-workspace --action gmail-send --to <email> --subject <subj> --body <text>
google-workspace --action calendar-create --title <title> --start <ISO8601> --end <ISO8601> [--description <desc>]
google-workspace --action calendar-list [--max-results 10]
```

## Setup

1. Create a project in [Google Cloud Console](https://console.cloud.google.com/).
2. Enable APIs: Google Drive, Gmail, Calendar.
3. Create OAuth 2.0 credentials (Desktop app).
4. Get `client_id` and `client_secret`.
5. Authorize and obtain `refresh_token` (use the skill's interactive auth or manual OAuth flow).
6. Set environment variables:

```bash
export GOOGLE_CLIENT_ID="your-client-id"
export GOOGLE_CLIENT_SECRET="your-client-secret"
export GOOGLE_REFRESH_TOKEN="your-refresh-token"
```

Alternatively, you can use a service account for domain-wide delegation (requires G Suite).

## Notes

- The skill uses the `googleapis` npm package. If not installed, run: `npm i googleapis` (in your agent environment).
- Tokens are auto-refreshed using the refresh token.
- Scopes required:
  - Drive: `https://www.googleapis.com/auth/drive`
  - Gmail: `https://www.googleapis.com/auth/gmail.send`
  - Calendar: `https://www.googleapis.com/auth/calendar`
