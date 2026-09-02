wget https://github.com/tree-sitter/tree-sitter/releases/latest/download/tree-sitter-linux-x64.gz
# wget https://github.com/tree-sitter/tree-sitter/releases/download/v0.24.7/tree-sitter-linux-x64.gz

gunzip tree-sitter-linux-x64.gz
chmod +x tree-sitter-linux-x64

sudo mv tree-sitter-linux-x64 /usr/local/bin/tree-sitter
