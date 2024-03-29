#!/usr/bin/env bash

[[ -x `command -v wget` ]] && CMD="wget --no-check-certificate -O -"
[[ -x `command -v curl` ]] >/dev/null 2>&1 && CMD="curl -#L"

if [ -z "$CMD" ]; then
  echo "No curl or wget available. Aborting."
  exit
fi

ARGS=$@

echo "Downloading dotfiles"
mkdir -p "$HOME/dotfiles"
eval "$CMD https://github.com/mitrichius/dotfiles/tarball/main | tar -xzv -C $HOME/dotfiles --strip-components=1 --exclude='{.gitignore}'"
cd $HOME/dotfiles/ && ./install.sh ${ARGS} && cd -
