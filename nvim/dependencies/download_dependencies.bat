@echo off
setlocal

set "TREE_SITTER_URL=https://github.com/tree-sitter/tree-sitter/releases/download/v0.27.1/tree-sitter-cli-windows-x64.zip"
set "TREE_SITTER_OUTPUT=%~dp0tree-sitter-cli-windows-x64.zip"
set "RIPGREP_URL=https://github.com/BurntSushi/ripgrep/releases/download/15.2.0/ripgrep-15.2.0-x86_64-pc-windows-msvc.zip"
set "RIPGREP_OUTPUT=%~dp0ripgrep-15.2.0-x86_64-pc-windows-msvc.zip"
set "FZF_URL=https://github.com/junegunn/fzf/releases/download/v0.74.5/fzf-0.74.5-windows_amd64.zip"
set "FZF_OUTPUT=%~dp0fzf-0.74.5-windows_amd64.zip"

curl --fail --location --output "%TREE_SITTER_OUTPUT%" "%TREE_SITTER_URL%"
if errorlevel 1 (
    echo Failed to download tree-sitter CLI.
    exit /b 1
)

echo Downloaded tree-sitter CLI to "%TREE_SITTER_OUTPUT%".

curl --fail --location --output "%RIPGREP_OUTPUT%" "%RIPGREP_URL%"
if errorlevel 1 (
    echo Failed to download ripgrep.
    exit /b 1
)

echo Downloaded ripgrep to "%RIPGREP_OUTPUT%".

curl --fail --location --output "%FZF_OUTPUT%" "%FZF_URL%"
if errorlevel 1 (
    echo Failed to download fzf.
    exit /b 1
)

echo Downloaded fzf to "%FZF_OUTPUT%".
endlocal
