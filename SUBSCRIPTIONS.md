# SUBSCRIPTIONS.md - Sub-Agent Registry

JARVIS orchestrates six specialized sub-agents. They are spawned on-demand via `sessions_spawn` with auto-selected models.

## 1. daily-planner

**Purpose:** Task planning, sprints, project breakdown, timelines  
**Spawn command:**
```yaml
task: "Break down the following project into sprints with timelines and resource allocation:\n\n<project_description>"
model: auto (structured reasoning)
thinking: high
```

**Use-cases:**
- Sprint planning
- Task division
- Resource allocation
- Deadlines & Gantt-style breakdown

---

## 2. google-workspace-manager

**Purpose:** Emails, proposals, client communication, documentation  
**Spawn command:**
```yaml
task: "Draft a professional client update email about <topic>. Include progress summary and next steps."
model: auto (clarity + tone)
thinking: medium
```
Or invoke directly via `google-workspace` skill for API actions (gdrive, gmail, calendar).

**Use-cases:**
- Client quotes
- Technical proposal drafts
- Progress reports
- Documentation + SRS/PRD outlines

---

## 3. medical-bulletin (Agency Wellness)

**Purpose:** Research + summaries of mental health, ergonomics, team wellness, productivity physiology  
**Spawn command:**
```yaml
task: "<research_query_about_team_wellness_or_ergonomics>"
model: auto (factual reliability)
thinking: medium
```
**Safety:** Informational only, not medical advice.

**Use-cases:**
- Ergonomic best practices for devs
- Productivity physiology tips
- Mental health resource curation

---

## 4. researcher

**Purpose:** Deep technical research  
**Spawn command:**
```yaml
task: "<deep_technical_question>"
model: openrouter/stepfun/step-3.5-flash:free (fast, balanced)
thinking: high
```

**Use-cases:**
- Comparing frameworks (Next.js vs Astro vs Remix)
- API documentation analysis
- Benchmarking tools & libraries
- Security & compliance research

---

## 5. socialmedia-manager

**Purpose:** Agency marketing, content, posts, case studies  
**Spawn command:**
```yaml
task: "Write a LinkedIn post about <topic> targeting developer audience. Include relevant hashtags."
model: auto (creativity)
thinking: medium
```

**Use-cases:**
- LinkedIn agency content
- Developer marketing
- Portfolio case studies
- Hashtag optimization

---

## 6. system-monitor

**Purpose:** Technical diagnostics, DevOps analysis, code review  
**Spawn command:**
```yaml
task: "Review this code for smells, performance issues, and security risks:\n\n<code_snippet>"
model: auto (technical depth)
thinking: high
```
Or run health scripts from `scripts/` periodically.

**Use-cases:**
- Code smell detection
- Risk assessment
- Performance optimization
- Infrastructure health

---

## Model Selection Logic

Always prefer free OpenRouter models. Auto-select based on:
- reasoning depth
- creativity
- speed
- safety
- factual accuracy
- technical proficiency

Default: `openrouter/auto` (lets OpenClaw pick best available free model)

---

## Invocation Pattern

JARVIS decides which sub-agent to use, spawns it with `sessions_spawn`, merges results. Sub-agents never speak directly.