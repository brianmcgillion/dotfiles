#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2025 Brian McGillion

# Read JSON input from stdin
input=$(cat)

# Extract values from JSON
model=$(echo "$input" | jq -r '.model.display_name // "Claude"')
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd')
remaining=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')

# Shorten directory path (replace home with ~)
short_cwd="${cwd/#$HOME/\~}"

# Get git branch if in a git repo (skip optional locks for safety)
git_branch=""
if git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1; then
  branch=$(git -C "$cwd" branch --show-current 2>/dev/null || git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
  if [ -n "$branch" ]; then
    git_branch=" $(printf '\033[0;36m')($branch)$(printf '\033[0m')"
  fi
fi

# Build context info
context_info=""
if [ -n "$remaining" ]; then
  # Color code based on remaining percentage
  if (($(echo "$remaining < 20" | bc -l 2>/dev/null || echo 0))); then
    context_color='\033[0;31m' # Red for low
  elif (($(echo "$remaining < 50" | bc -l 2>/dev/null || echo 0))); then
    context_color='\033[0;33m' # Yellow for medium
  else
    context_color='\033[0;32m' # Green for plenty
  fi
  context_info=" $(printf '%b' "${context_color}")${remaining}%$(printf '\033[0m')"
fi

# Build status line
printf '\033[0;34m' # Blue color
printf "%s" "$short_cwd"
printf '\033[0m' # Reset color
printf "%s" "$git_branch"
printf ' \033[0;35m' # Magenta for model
printf "[%s]" "$model"
printf '\033[0m' # Reset color
printf "%s" "$context_info"
printf '\n'
