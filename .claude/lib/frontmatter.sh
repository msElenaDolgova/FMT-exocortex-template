#!/bin/bash
# .claude/lib/frontmatter.sh — shared YAML frontmatter reader.
# Source this file, then call: get_field <file> <field>
# Returns the scalar value of <field>: from the YAML block between leading --- delimiters.
# Strips surrounding quotes and whitespace. Outputs nothing if field is absent.

get_field() {
    local file="$1" field="$2"
    [ -f "$file" ] || return 1
    awk -v f="$field" '
        NR == 1 && /^---[[:space:]]*$/ { in_fm = 1; next }
        in_fm && /^---[[:space:]]*$/ { exit }
        in_fm {
            n = index($0, ":")
            if (n > 1) {
                key = substr($0, 1, n - 1)
                gsub(/^[[:space:]]+|[[:space:]]+$/, "", key)
                if (key == f) {
                    val = substr($0, n + 1)
                    gsub(/^[[:space:]]+|[[:space:]]+$/, "", val)
                    gsub(/^["'"'"']|["'"'"']$/, "", val)
                    print val
                    exit
                }
            }
        }
    ' "$file"
}
