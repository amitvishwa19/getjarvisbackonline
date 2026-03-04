# Tavily Search Skill

Perform intelligent web searches using Tavily API (AI-powered search). Ideal for research, fact-checking, and gathering current information.

## Usage

```
tavily-search query "your search query" [--max-results N] [--include-raw]
```

## Examples

```
tavily-search query "latest React 19 features" --max-results 5
tavily-search query "AI agent frameworks comparison" --include-raw
```

## Environment Variables

- `TAVILY_API_KEY` — Your Tavily API key from https://tavily.com

## Output

Returns a structured result with:
- `answer` — AI-generated answer (if available)
- `results` — Array of search results (title, url, content, score)
- `raw` — Raw API response (if `--include-raw`)

## Limitations

- Requires Tavily API key (free tier available)
- Rate limits apply based on your plan
- Searches are web-based; results depend on Tavily's index