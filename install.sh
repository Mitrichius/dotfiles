#!/usr/bin/env bash

DIR=$(pwd)

execute() {
  $1 &> /dev/null
  print_result $? "${2:-$1}"
}

print_error() {
  # Print output in red
  printf "\e[0;31m  [✖] $1 $2\e[0m\n"
}

print_question() {
  # Print output in yellow
  printf "\e[0;33m  [?] $1\e[0m" > $OUTPUT
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
  printf "\e[0;32m  [✔] $1\e[0m\n" > $OUTPUT
}

print_info() {
  # Print output in purple
  printf "\n\e[0;35m $1\e[0m\n\n" > $OUTPUT
}

ask_for_confirmation() {
  print_question "$1 (y/n) "
  if [ "$QUIET_MODE" = true ]; then
    REPLY=y
  else 
    read -n 1
    printf "\n"
  fi
}

answer_is_yes() {
  [[ "$REPLY" =~ ^[Yy]$ ]] \
    && return 0 \
    || return 1
}

install_zsh () {
  # Test to see if zshell is installed.  If it is:
  if [ -f /bin/zsh -o -f /usr/bin/zsh ]; then
    # Install Oh My Zsh if it isn't already present
    if [[ ! -d $HOME/.oh-my-zsh/ ]]; then
      sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
    fi
    # Set the default shell to zsh if it isn't currently set to zsh
    if [[ ! $(echo $SHELL) == $(which zsh) ]]; then
      chsh -s $(which zsh)
    fi
  else
    # If zsh isn't installed, get the platform of the current machine
    platform=$(uname);
    # If the platform is Linux, try an apt-get to install zsh and then recurse
    if [[ $platform == 'Linux' ]]; then
      if [[ -f /etc/redhat-release ]]; then
        sudo yum install zsh
        install_zsh
      fi
      if [[ -f /etc/debian_version ]]; then
        sudo apt-get install zsh
        install_zsh
      fi
    # If the platform is OS X, tell the user to install zsh :)
    elif [[ $platform == 'Darwin' ]]; then
      echo "We'll install zsh, then re-run this script!"
      brew install zsh
      exit
    fi
  fi

  # Install zsh theme
  execute "ln -sfn $DIR/themes/zsh/mitrichius.zsh-theme $HOME/.oh-my-zsh/themes/mitrichius.zsh-theme" "Zsh theme installed"

  if [ -f /bin/zsh -o -f /usr/bin/zsh ]; then

    if [ -e $HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions ]; then
      print_success "Zsh autosuggestions plugin already installed"
    else 
      execute "git clone git://github.com/zsh-users/zsh-autosuggestions $HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" "Zsh autosuggestions plugin installed"
    fi

    if [ -e $HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting ]; then
      print_success "Zsh syntax highlighting plugin already installed"
    else 
      execute "git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" "Zsh syntax highlighting plugin installed" 
    fi

  else 
    print_error "Git is needed to install zsh plugins"
  fi

  zsh
}

link_file() {
SOURCE_FILE="$DIR/$1"
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

usage() {
  echo "Usage: $0 [-q]" 1>&2; 
  exit 1; 
}

QUIET_MODE=false;
OUTPUT=/dev/stdout

while getopts "q" arg; do
  case "${arg}" in
    q)
      QUIET_MODE=true;
      OUTPUT=/dev/null
      ;;
    *)
      QUIET_MODE=false;
      usage
      ;;
  esac
done

FILES_SHELL=shell/*
FIlES_ALIASES=aliases/*

DATETIME=$(date '+%d-%m-%Y_%H:%M:%S');
BACKUP_DIR=$HOME/.backup/$DATETIME

# Warn user this script will overwrite current dotfiles
while true; do
  ask_for_confirmation "Warning: this will overwrite your current dotfiles. Original backup will be in $BACKUP_DIR. Continue?"
  if answer_is_yes; then
    break;
  else
    exit;
  fi;
done

print_info "Backup files"
mkdir -p $BACKUP_DIR
for file in $FILES_SHELL
do
	FILE_NAME=.${file##*/}
	ORIGINAL_FILE=$HOME/$FILE_NAME
	if [ -e $ORIGINAL_FILE ]; then 
		mv -f $ORIGINAL_FILE $BACKUP_DIR/$FILE_NAME
    if [ $? -eq 0 ]; then
      print_success "$ORIGINAL_FILE backed up"
    else
      print_error "Can't backup $ORIGINAL_FILE, exit";
      exit;
    fi 
	fi
done

# If zsh isn't installed, get the platform of the current machine
PLADFORM=$(uname);

print_info "Link aliases"
for file in $FIlES_ALIASES
do
	link_file $file
done

print_info "Link dotfiles"
for file in $FILES_SHELL
do
	link_file $file
done

print_info "Config global gitignore"
execute "git config --global core.excludesfile $HOME/.gitignore_global" "Global gitignore installed"

print_info "Install vim theme"
mkdir -p $HOME/.vim
execute "cp -R $DIR/themes/vim/* $HOME/.vim/" "Vim theme installed"



# Select shell
if [ "$QUIET_MODE" = true ]; then
  exit;
fi

while true; do
  read -p "bash or zsh? " answer
  case $answer in
    [bash]* ) bash; break;;
    [zsh]* ) install_zsh; break;;
    * ) echo "Please answer bash or zsh.";;
  esac
done
