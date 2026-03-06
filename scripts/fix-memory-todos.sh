#!/bin/bash
MEMORY="/home/ubuntu/.openclaw/workspace/MEMORY.md"
TMP="/tmp/memory_fixed.md"

# 1) Copy everything up to "## Pending Tasks" line (inclusive)
head -n $(grep -n '^## Pending Tasks' "$MEMORY" | head -1 | cut -d: -f1) "$MEMORY" > "$TMP"

# 2) Append unique bullets from Pending Tasks
sed -n '/^## Pending Tasks/,/^## /p' "$MEMORY" | grep '^- ' | sed 's/^[[:space:]]*//' | sort -u >> "$TMP"

# 3) Append everything after the Pending Tasks section (i.e., after the line that starts next heading, or end)
# Find the line number of the next heading after "## Pending Tasks", or if none, just tail from after Pending Tasks
START=$(( $(grep -n '^## Pending Tasks' "$MEMORY" | head -1 | cut -d: -f1) + 1 ))
# Find the next heading line after that
NEXT_HEAD=$(sed -n "$((START+1)),\$p" "$MEMORY" | grep -n '^## ' | head -1 | cut -d: -f1)
if [ -z "$NEXT_HEAD" ]; then
  # No next heading, append nothing? Actually tail from where? The section may go to EOF? But there is table after.
  # We'll handle differently: after we already appended bullets, we need to append the rest of file starting from after the last line of the Pending Tasks section.
  # Find the line after the last bullet or empty line before next heading. Simpler: we'll append remaining lines from the original file starting from the line after the "## Todo List (Supabase)" heading if present.
  tail -n +$(grep -n '^## Todo List (Supabase)' "$MEMORY" | cut -d: -f1) "$MEMORY" >> "$TMP"
else
  # Append from that next heading onward
  START_LINE=$(( START + NEXT_HEAD ))
  tail -n +$START_LINE "$MEMORY" >> "$TMP"
fi

mv "$TMP" "$MEMORY"
echo "Fixed MEMORY.md: Pending Tasks deduplicated."
