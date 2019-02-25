#!/bin/bash

if [ ! -d ~/code/dotfiles ]; then
  echo "Cloning dotfiles"
  mkdir -p ~/code
  cd ~/code
  git clone https://github.com/bydavy/dotfiles.git
  cd ~/code/dotfiles
  git remote set-url origin git@github.com:bydavy/dotfiles.git
fi

cd ~/code/dotfiles 
./setup.sh
cd
. .bashrc

/usr/sbin/sshd -D