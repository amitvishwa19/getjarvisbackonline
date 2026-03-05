# Firecrawl Search Skill

Advanced web scraping and crawling using Firecrawl API. Extract content from any URL, crawl entire sites, or perform focused searches.

## Usage

```
firecrawl-search crawl <url> [--limit N] [--output-format json|markdown]
firecrawl-search scrape <url> [--extract-links] [--include-html]
firecrawl-search search "query" --site <url> [--max-results N]
```

## Examples

```
firecrawl-search crawl https://example.com/docs --limit 10
firecrawl-search scrape https://blog.example.com/post --extract-links
firecrawl-search search "API documentation" --site https://docs.example.com --max-results 5
```

## Environment Variables

- `FIRECRAWL_API_KEY` — Your Firecrawl API key from https://firecrawl.com

## Output

Returns structured data:
- For `crawl`: list of discovered pages with titles, URLs, content
- For `scrape`: page content, metadata, extracted links (if requested)
- For `search`: search results with snippets and URLs

## Notes

- Firecrawl handles JavaScript rendering, rate limiting, and anti-bot bypass
- Respect `robots.txt` and rate limits
- API key required (free tier available)