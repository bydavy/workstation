#!/bin/bash

if [ ! -d ~/.dotfiles ]; then
  echo "Cloning dotfiles"
  git clone https://github.com/bydavy/dotfiles.git .dotfiles
  cd ~/.dotfiles
  git remote set-url origin git@github.com:bydavy/dotfiles.git
fi

cd ~/.dotfiles
./setup.sh
cd
. .bashrc

if [ -f /data/secrets/pull-secrets.sh ]; then
  /data/secrets/pull-secrets.sh
fi

/usr/sbin/sshd -D
