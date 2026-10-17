#!/bin/bash
# The lint gate: pure grep, no tools to install. Exits 1 on any hit and prints
# each offending line. Rules are listed in docs/context.md (Conventions).
set -u
cd "$(dirname "$0")/.."
export LC_ALL=en_US.UTF-8

fail=0
# rule <label> <extended regex> <grep flags> <paths...> -- [exclude path fragments...]
rule() {
    local label="$1" regex="$2" flags="$3"
    shift 3
    local paths=() excludes=() seen_sep=0
    for a in "$@"; do
        if [ "$a" = "--" ]; then seen_sep=1; continue; fi
        if [ $seen_sep -eq 0 ]; then paths+=("$a"); else excludes+=("$a"); fi
    done
    local existing=()
    for p in "${paths[@]}"; do [ -e "$p" ] && existing+=("$p"); done
    [ ${#existing[@]} -eq 0 ] && return 0
    local hits
    hits=$(grep -rnE $flags --include='*.swift' --include='*.md' --include='*.yml' --include='*.sh' \
        --exclude-dir=.build --exclude-dir=.swiftpm -e "$regex" "${existing[@]}" 2>/dev/null)
    for x in "${excludes[@]:-}"; do
        [ -n "$x" ] && hits=$(printf '%s\n' "$hits" | grep -v -F "$x")
    done
    hits=$(printf '%s\n' "$hits" | sed '/^$/d')
    if [ -n "$hits" ]; then
        echo "LINT FAIL [$label]"
        printf '%s\n' "$hits"
        fail=1
    fi
}

# (a) No SceneKit anywhere.
rule "a: no SceneKit" 'import SceneKit' "" Packages App

# (b) The pure target imports only Foundation and simd.
rule "b: StoreSimKit stays pure" 'import (SwiftUI|RealityKit|AppKit|UIKit|RealityFoundation)' "" \
    Packages/StoreSimKit/Sources/StoreSimKit

# (c) Colour literals live only in Brand/Brand.swift.
rule "c: colour literal outside Brand.swift" '(^|[^A-Za-z0-9_])(r|red): *[0-9]|0x[0-9A-Fa-f]{6}' "" Packages App -- "Brand/Brand.swift"

# (d) The brand name lives only in Brand/Brand.swift.
rule "d: brand name outside Brand.swift" '"Plum"' "" Packages/StoreSimKit/Sources App -- "Brand/Brand.swift"

# (e) English-only sources.
rule "e: non-English letters" '[ąćęłńóśźż]' "" Packages App

# (f) No competitor names.
rule "f: competitor name" 'zabka|żabka|7-?eleven' "-i" Packages App docs/asset-brief.md docs/context.md

# (g) Models load only through ModelLoader.
rule "g: model load outside ModelLoader" 'Entity\(contentsOf|Entity\.load|ModelEntity\.load|\.usdz"' "" Packages App -- "StoreSimRender/ModelLoader.swift"

if [ $fail -ne 0 ]; then
    exit 1
fi
echo "lint: ok"
