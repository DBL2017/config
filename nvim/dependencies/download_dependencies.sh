#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

TREE_SITTER_URL=https://github.com/tree-sitter/tree-sitter/releases/download/v0.27.1/tree-sitter-cli-linux-x64.zip
TREE_SITTER_OUTPUT="$SCRIPT_DIR/tree-sitter-cli-linux-x64.zip"

curl --fail --location --output "$TREE_SITTER_OUTPUT" "$TREE_SITTER_URL"
printf 'Downloaded tree-sitter CLI to "%s".\n' "$TREE_SITTER_OUTPUT"
