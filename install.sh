#!/bin/sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE:-$0}")"; pwd)"

ln -sf ${SCRIPT_DIR}/.inputrc           ~/.inputrc
ln -sf ${SCRIPT_DIR}/.bashrc            ~/.bashrc
ln -sf ${SCRIPT_DIR}/.bash_profile      ~/.bash_profile
ln -sf ${SCRIPT_DIR}/.vim               ~/.vim
ln -sf ${SCRIPT_DIR}/.vimrc             ~/.vimrc
ln -sf ${SCRIPT_DIR}/.gitconfig         ~/.gitconfig
ln -sf ${SCRIPT_DIR}/.ctrlp-launcher    ~/.ctrlp-launcher
ln -sf ${SCRIPT_DIR}/.starship          ~/.starship

mkdir -p ~/bin
