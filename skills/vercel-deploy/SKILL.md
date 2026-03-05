# vercel-deploy Skill

Instant deploy to Vercel.

## Usage

```
vercel-deploy --dir ./dist
vercel-deploy --folder build --prod
```

## Requirements

- `VERCEL_API_TOKEN` — from Vercel account settings (https://vercel.com/account/tokens)

## Notes

- Creates a new deployment on Vercel
- Deploys to production if `--prod` flag given
- Returns deployment URL
