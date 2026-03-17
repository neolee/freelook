#!/bin/sh
set -eu

file_name="${1:-README.md}"
language="${2:-markdown}"

printf '%s [%s] ready\n' "$file_name" "$language"
