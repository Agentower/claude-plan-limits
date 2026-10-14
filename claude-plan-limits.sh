#!/bin/sh
# claude-plan-limits — your Claude plan's usage limits in Claude Code's status line.
# https://github.com/agentower/claude-plan-limits · MIT licence · no account needed
#
# Shows, for Claude Pro/Max: the model, how much of your 5-hour session limit and weekly limit
# you've used, and when each resets — e.g.  "Opus · 5h 42% (resets 16:00) · week 61% (Thu 11:00)".
# Turns amber-ish words into plain text: "5h 92% ⚠" when you're above 90 %.
#
# It reads only what Claude Code hands its status line and never sends anything anywhere,
# unless you opt in to Agentower (below).
#
# Optional — Agentower (https://agentower.com): see your whole team's plan limits and agents live.
# If ~/.agentower/claude-code.env exists (AGENTOWER_URL and AGENTOWER_TOKEN), only the limit
# numbers are sent to your Agentower tower when they change. Delete that file to stop.

input=$(cat | tr -d '\n\r')

model=$(printf '%s' "$input" | grep -oE '"display_name"[[:space:]]*:[[:space:]]*"[^"]*"' | head -n 1 | sed -E 's/.*:[[:space:]]*"//; s/"$//')

# "used_percentage" and "resets_at" (seconds since 1970) inside one window's object.
window() {
  obj=$(printf '%s' "$input" | grep -oE "\"$1\"[[:space:]]*:[[:space:]]*\\{[^}]*\\}" | head -n 1)
  [ -n "$obj" ] || return 1
  used=$(printf '%s' "$obj" | grep -oE '"used_percentage"[[:space:]]*:[[:space:]]*-?[0-9]+(\.[0-9]+)?' | grep -oE -- '-?[0-9]+(\.[0-9]+)?$')
  resets=$(printf '%s' "$obj" | grep -oE '"resets_at"[[:space:]]*:[[:space:]]*[0-9]+' | grep -oE '[0-9]+$')
  [ -n "$used" ]
}

# Local time of a reset: "16:00" today, "Thu 11:00" otherwise. Works with BSD (macOS) and GNU date.
when() {
  [ -n "$1" ] || return 0
  today=$(date +%Y%m%d)
  day=$(date -r "$1" +%Y%m%d 2>/dev/null || date -d "@$1" +%Y%m%d 2>/dev/null)
  if [ "$day" = "$today" ]; then fmt=%H:%M; else fmt="%a %H:%M"; fi
  date -r "$1" "+$fmt" 2>/dev/null || date -d "@$1" "+$fmt" 2>/dev/null
}

part() {
  pct=$(printf '%.0f' "$used")
  mark=""; [ "$pct" -ge 90 ] 2>/dev/null && mark=" ⚠"
  at=$(when "$resets")
  printf '%s %s%%%s%s' "$1" "$pct" "$mark" "${at:+ ($2$at)}"
}

line="${model:-Claude}"
json="{\"v\":1"
if window five_hour; then
  line="$line · $(part 5h 'resets ')"
  json="$json,\"five_hour\":{\"used\":$used${resets:+,\"resets_at\":$resets}}"
fi
if window seven_day; then
  line="$line · $(part week '')"
  json="$json,\"seven_day\":{\"used\":$used${resets:+,\"resets_at\":$resets}}"
fi
json="$json}"
printf '%s\n' "$line"

# ---- optional: Agentower ----------------------------------------------------------
[ "$json" = '{"v":1}' ] && exit 0
conf="${AGENTOWER_CONFIG:-$HOME/.agentower/claude-code.env}"
[ -r "$conf" ] || exit 0
. "$conf"
[ -n "$AGENTOWER_URL" ] && [ -n "$AGENTOWER_TOKEN" ] || exit 0
# Never send the key in clear: https only, except to this computer itself.
case "$AGENTOWER_URL" in
  https://*) ;;
  http://localhost|http://localhost[:/]*|http://127.0.0.1|http://127.0.0.1[:/]*|http://\[::1\]|http://\[::1\][:/]*) ;;
  *) exit 0 ;;
esac
last="${AGENTOWER_USAGE_CACHE:-$HOME/.agentower/plan-usage-last}"
if [ -r "$last" ] && [ "$(cat "$last")" = "$json" ] && [ -z "$(find "$last" -mmin +15 2>/dev/null)" ]; then exit 0; fi
printf '%s' "$json" > "$last" 2>/dev/null
[ -n "$AGENTOWER_DRY_RUN" ] && { printf 'SEND %s\n' "$json" >&2; exit 0; }
# The key goes to curl on its standard input (a config line), never on its command line, where
# other programs on this computer could read it.
{ printf 'header = "authorization: Bearer %s"\n' "$AGENTOWER_TOKEN"; printf 'data = "%s"\n' "$(printf '%s' "$json" | sed 's/\\/\\\\/g; s/"/\\"/g')"; } \
  | curl -sS --max-time 2 -X POST "$AGENTOWER_URL/v1/status/claude-code" -H "content-type: application/json" -K - >/dev/null 2>&1
exit 0
