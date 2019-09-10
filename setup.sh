#!/bin/bash
set -euo pipefail
cd $(dirname "$0")

help() {
  echo "Usage: $0 [OPTION]"
  echo "install stuff, setup github keys, download random tools"
  echo "       -n, --new"
  echo "                new computer"
  echo "       -s, --symlink"
  echo "                symlink rc files"
  echo "           --install-tools"
  echo "                install tools; "
  echo "           --update-tools; will auto-install tools if used with -n"
  echo "                only update local tools, don't run full setup"
  echo "       -g, --checkGithub"
  echo "                check/setup github_rsa"
  echo "       -h, --help"
  echo "                display this help"
  echo "expected usage: "
  echo "       for first time: '$0 -at'"
  echo "       for updating managed tools: '$0 -t'"
}


# getopt short options go together, long options have commas
TEMP=`getopt -o nsgh --long new,symlink,update-tools,install-tools,checkGithub,help -n 'test.sh' -- "$@"`
if [ $? != 0 ] ; then
    echo "Something wrong with getopt" >&2
    exit 1
fi
eval set -- "$TEMP"

new=false
symlink=false
updateTools=false
installTools=false
checkGithub=false
while true ; do
    case "$1" in
        -n|--new) new=true ; shift ;;
        -s|--symlink) symlink=true ; shift ;;
        --update-tools) updateTools=true ; shift ;;
        --install-tools) installTools=true ; shift ;;
        -g|--checkGithub) checkGithub=true ; shift ;;
        -h|--help) help ; exit 0 ;;
        --) shift ; break ;;
        *) echo "bad arg $1" ; exit 1 ;;
    esac
done


setup_github() {
  read -r -p "Brand new keys? [Y/n] " response
  case "$response" in
    [nN][oO]|[nN])
      echo "Alright setup your own key"
      read -n 1 -s -r -p "Press any key to continue"
      echo ""
      verify_github_remote
      return
      ;;
  esac
  ssh-keygen -N "" -f ~/.ssh/github_rsa
  cat ~/.ssh/github_rsa.pub
  echo "Add that to github"
  read -n 1 -s -r -p "Press any key to continue"
  echo ""
  verify_github_remote
}

verify_github_remote() {
  if ssh -T -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no git@github.com 2>&1 | grep "successfully authenticated" ; then
    read -r -p "You going to fix that key? [y/N] " response
    case "$response" in
      [yY][eE][sS]|[yY])
        echo "Alright good luck"
        read -n 1 -s -r -p "Press any key to continue"
        change_dofiles_remote
        ;;
    esac
    return;
  fi
}



change_dofiles_remote() {
  if git remote -v | grep https ; then
    read -r -p "Change github remote to not be https? [y/N] " response
    case "$response" in
      [yY][eE][sS]|[yY])
          git remote remove origin
          git remote add origin git@github.com:mtfurlan/dotfiles.git
        ;;
    esac
  fi
}

get_github_latest_release() {
  curl -s "$1/releases/latest" | sed 's/.*href=".*tag.\(.*\)">redirected.*/\1/'
}
get_github_latest_release_file() {
  echo "$1/releases/download/$(get_github_latest_release $1)/$2"
}

update_tools() {

  batVersion=$(curl -s https://github.com/sharkdp/bat/releases/latest | sed 's/.*releases\/tag\/v\([0-9.]*\)">redirected.*/\1/')
  batInstalledVersion=$(dpkg -s bat 2>/dev/null | grep Version | sed 's/Version: //') || true

  if [ "$batInstalledVersion" != "$batVersion" ]; then
    echo "VERSION MISMATCH: bat version: $batVersion, installedVersion: $batInstalledVersion"
    if [ "$(uname -m)" == "x86_64" ]; then
      wget -q -O "/tmp/bat_${batVersion}_amd64.deb" "https://github.com/sharkdp/bat/releases/download/v$batVersion/bat_${batVersion}_amd64.deb"
      sudo dpkg -i "/tmp/bat_${batVersion}_amd64.deb"
    else
      echo "can't install bat for this arch, fix setup script"
    fi
  fi

  pushd ~/.fzf
  git pull
  popd

  mkdir -p ~/.local/bin
  wget -q -O ~/.local/bin/up $(get_github_latest_release_file https://github.com/akavel/up up)
  chmod +x ~/.local/bin/up
  wget -q -O ~/.local/bin/diff-so-fancy https://raw.githubusercontent.com/so-fancy/diff-so-fancy/master/third_party/build_fatpack/diff-so-fancy
  chmod +x ~/.local/bin/diff-so-fancy

  pushd ~/src/PathPicker/debian
  git pull
  ./package.sh
  sudo dpkg -i ../fpp_*.deb
  popd
}

install_tools() {
  sudo apt-get install python3-dev python3-pip python3-setuptools jq -y
  sudo pip3 install thefuck yq

  git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf || true
  ~/.fzf/install --completion --key-bindings --no-update-rc

  git clone https://github.com/facebook/PathPicker.git ~/src/PathPicker || true

  update_tools
}


new_computer() {
  echo "updating and installing things from apt"

  if [ -x "$(which apt-get)" ] ; then
    if ! grep --quiet non-free /etc/apt/sources.list; then
      echo "/etc/apt/sources.list doesn't have nonfree"
      echo "exit when you're happy"
      bash --rcfile <(echo "PS1='subshell > '") -i
    fi
    sudo apt-get update
    sudo apt-get install vim-nox tmux git sl silversearcher-ag curl tree bash-completion rcm rename
  else
    echo "apt-get not installed, fix setup.sh for this platform"
  fi
}

# checks for ~/.ssh_github_rsa, and will change the dotfile remote to be git not https
check_github() {
  if [ ! -f ~/.ssh/github_rsa ]; then
    read -r -p "Setup github keys? [y/N] " response
    case "$response" in
      [yY][eE][sS]|[yY])
        setup_github
        ;;
    esac
  else
    verify_github_remote
  fi
}

ask_install_tools() {
  read -r -p "install random tools(thefuck, yq, fzf, up)? [y/N] " response
  case "$response" in
    [yY][eE][sS]|[yY])
      install_tools
      ;;
  esac
}

symlinks() {
  echo "making symlinks with rcup from rcm"
  # use rcm, do a dry run
  # so this is overly complex, but whatever.
  # I want to do things like symlink parts of the .vim dir, but not all parts, link the bin dir but without a dot, and exclude setup.sh and README

  # vim dir intended symlinks:
  #   /home/mark/.vim/bundle/Vundle.vim:/home/mark/.dotfiles/vim/bundle/Vundle.vim
  #   /home/mark/.vim/filetype.vim:/home/mark/.dotfiles/vim/filetype.vim
  #   /home/mark/.vim/ftdetect:/home/mark/.dotfiles/vim/ftdetect
  #   /home/mark/.vim/ftplugin:/home/mark/.dotfiles/vim/ftplugin
  #   /home/mark/.vim/spell:/home/mark/.dotfiles/vim/spell
  #   /home/mark/.vim/syntax:/home/mark/.dotfiles/vim/syntax
  # I want to only link Vundle, so all other plugins aren't in version control.
  # Should probably update vundle someday.
  # Everything else, like spelling and extra filetype plugins I want in version control

  # this probably assumes it's in the ~/.dotfiles dir

  SYMLINK_DIRS="vim/bundle/Vundle.vim $(find vim -maxdepth 1 -type d | grep -v bundle | tail -n +2) bin" lsrc -U bin -x setup.sh -x README.md
  read -r -p "that look good? [Y/n] " response
  case "$response" in
    [yY][eE][sS]|[yY]|"")
      ;; # don't exit, script continues
    *)
      echo "good luck, bye"
      exit 1;;
  esac
  SYMLINK_DIRS="vim/bundle/Vundle.vim $(find vim -maxdepth 1 -type d | grep -v bundle | tail -n +2) bin" rcup -v -U bin -x setup.sh -x README.md
}

## execution starts here
if [ "$new" = true ]; then
  echo "new computer"
  new_computer

  symlink=true
  checkGithub=true

  if [ "$installTools" = true ]; then
    install_tools
    installTools=false
  else
    ask_install_tools
  fi

  echo "if it's a thinkpad, do battery management setup"
  echo "    tpacpi-bat: https://github.com/teleshoes/tpacpi-bat"
  echo "    TODO: https://github.com/morgwai/tpbat-utils-acpi"

fi

if [ "$installTools" = true ]; then
  install_tools
fi
if [ "$updateTools" = true ]; then
  update_tools
fi
if [ "$symlink" = true ]; then
  symlinks
fi
if [ "$checkGithub" = true ]; then
  check_github
fi
