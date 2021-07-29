#!/usr/bin/env bash

yellow='\033[0;33m'

warn() {
    echo -e "\n${yellow}$*${reset}" >&2
}

tight=$(grep "\"=" "Project.toml" | sort | sed 's/ //g')

tight_deps=$(grep "\"=" "Project.toml" | grep -v "^julia" | sort | cut -d ' ' -f 1)

[[ -z "${tight_deps}" ]] && {
    warn "No tight deps found in Project.toml, consider adding some by adding large dependencies with version of the form \"= M.m.p\" to your Project.toml [compat] section."
}

OUT=TightProject.toml

echo "[deps]" > "$OUT"

for dep in $tight_deps; do
    grep -m 1 "^$dep[ ]*=[ ]*\"[a-f0-9]\{8\}" "Project.toml" | sed 's/ //g' >> "$OUT"
done

echo "" >> "$OUT"
echo "[compat]" >> "$OUT"

for dep in "$tight"; do
    echo "$dep" >> "$OUT"
done

