cd /tmp

VER=$(curl -s https://api.github.com/repos/junegunn/fzf/releases/latest \
	| grep -Po '"tag_name": "v\K[0-9.]+')

wget https://github.com/junegunn/fzf/releases/download/v${VER}/fzf-${VER}-linux_amd64.tar.gz

tar -xzf fzf-${VER}-linux_amd64.tar.gz

sudo install fzf /usr/local/bin/

