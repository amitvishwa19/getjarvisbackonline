# here-now Skill

Instant publish/deploy to https://here.now hosting service.

## Usage

```
publish --dir ./dist
publish --folder build --prod
```

## Features

- Deploy static sites instantly
- Supports directory or zip upload
- Returns public URL after deployment
- Optional production flag

## Environment Variables

- `HERENOW_API_KEY` — Your here.now API token

## Implementation Notes

- API endpoint: `https://api.here.now/v1/deploy` (adjust if different)
- Method: POST
- Content-Type: `multipart/form-data` with `file` field (zip) OR direct folder upload via tarball
- Headers: `Authorization: Bearer ${HERENOW_API_KEY}`
- Response: `{ "url": "https://your-site.here.now" }`
