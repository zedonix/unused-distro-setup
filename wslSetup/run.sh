#!/bin/bin/env bash

sudo apt install -y build-essential curl wget git gh bash-completion zoxide fzf ripgrep ncdu eza tmux trash-cli
sudo apt install -y python3 python3-pip python3-venv nodejs npm luarocks sqlite3 lua5.4

sudo add-apt-repository ppa:neovim-ppa/stable
sudo apt-get update
sudo apt-get install neovim

wget https://github.com/dandavison/delta/releases/download/0.17.0/git-delta_0.17.0_amd64.deb
sudo apt install ./git-delta_0.17.0_amd64.deb
rm ./git-delta_0.17.0_amd64.deb

npm install -g tree-sitter-cli
npm install -g stylelint stylelint-config-standard

git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm
