#!/usr/bin/env bash

execute() {
  $1 &> /dev/null
  print_result $? "${2:-$1}"
}

print_error() {
  # Print output in red
  printf "\e[0;31m  [✖] $1 $2\e[0m\n"
}

print_info() {
  # Print output in purple
  printf "\n\e[0;35m $1\e[0m\n\n"
}

print_question() {
  # Print output in yellow
  printf "\e[0;33m  [?] $1\e[0m"
}

print_result() {
  [ $1 -eq 0 ] \
    && print_success "$2" \
    || print_error "$2"

  [ "$3" == "true" ] && [ $1 -ne 0 ] \
    && exit
}

print_success() {
  # Print output in green
  printf "\e[0;32m  [✔] $1\e[0m\n"
}

ask_for_confirmation() {
  print_question "$1 (y/n) "
  read -n 1
  printf "\n"
}

answer_is_yes() {
  [[ "$REPLY" =~ ^[Yy]$ ]] \
    && return 0 \
    || return 1
}

get_os() {
  declare -r OS_NAME="$(uname -s)"
  local os=""
  if [ "$OS_NAME" == "Darwin" ]; then
    os="osx"
  elif [ "$OS_NAME" == "Linux" ] && [ -e "/etc/lsb-release" ]; then
    os="ubuntu"
  fi
  printf "%s" "$os"
}

link_file() {
SOURCE_FILE="$(pwd)/$1"
	TARGET_FILE="$HOME/.${1##*/}"
	if [ ! -e $TARGET_FILE ]; then
		execute "ln -sfn $SOURCE_FILE $TARGET_FILE" "$TARGET_FILE → $SOURCE_FILE"
	elif [ "$(readlink "$TARGET_FILE")" == "$SOURCE_FILE" ]; then
      	print_success "$TARGET_FILE → $SOURCE_FILE"
    else
		ask_for_confirmation "'$TARGET_FILE' already exists, do you want to overwrite it?"
	  	if answer_is_yes; then
	  		rm -rf "$TARGET_FILE"
			execute "ln -sfn $SOURCE_FILE $TARGET_FILE" "$TARGET_FILE → $SOURCE_FILE"
	    else
	        print_error "$TARGET_FILE → $SOURCE_FILE"
      	fi
	fi
}

FILES_SHELL=shell/*
FIlES_ALIASES=aliases/*

# Warn user this script will overwrite current dotfiles
while true; do
  read -p "Warning: this will overwrite your current dotfiles. Original backup will be in ~/.backup. Continue? [y/n] " yn
  case $yn in
    [Yy]* ) break;;
    [Nn]* ) exit;;
    * ) echo "Please answer yes or no.";;
  esac
done

echo "Backup files"
mkdir -p $HOME/.backup
for file in $FILES_SHELL
do
	FILE_NAME=.${file##*/}
	ORIGINAL_FILE=$HOME/$FILE_NAME
	if [ -e $ORIGINAL_FILE ]; then 
		rm -rf $HOME/.backup/$FILE_NAME
		mv -f $ORIGINAL_FILE $HOME/.backup/$FILE_NAME
	fi
done

# If zsh isn't installed, get the platform of the current machine
PLADFORM=$(uname);

echo "Link aliases"
for file in $FIlES_ALIASES
do
	link_file $file
done

echo "Link dotfiles"
for file in $FILES_SHELL
do
	link_file $file
done

# Add solarized colors for vim if not present
if [ ! -f $HOME/.vim/colors/solarized.vim ]; then
    curl -fLo $HOME/.vim/colors/solarized.vim --create-dirs \
    https://raw.githubusercontent.com/altercation/vim-colors-solarized/master/colors/solarized.vim
fi

#TODO: custom aliases depenging on system


#TODO: Dracula theme (zsh) download 
#TODO: two installers (bash and zsh)