#!/usr/bin/env bash

# include my library helpers for colorized echo and require_brew, etc
source ./lib_sh/echos.sh
source ./lib_sh/requirers.sh

bot "Hi! I'm going to install tooling and tweak your system settings. Here I go..."

# Ask for the administrator password upfront
if sudo grep -q "# %wheel\tALL=(ALL) NOPASSWD: ALL" "/etc/sudoers"; then

  # Ask for the administrator password upfront
  bot "I need you to enter your sudo password so I can install some things:"
  sudo -v

  # Keep-alive: update existing sudo time stamp until the script has finished
  while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

fi

running "Installing XCode command-line tools."
xcode-select --install
sleep 1
osascript <<EOD
  tell application "System Events"
    tell process "Install Command Line Developer Tools"
      keystroke return
      click button "Agree" of window "License Agreement"
    end tell
  end tell
EOD

running "checking homebrew install"
brew_bin=$(which brew) 2>&1 > /dev/null
if [[ $? != 0 ]]; then
  action "installing homebrew"
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    if [[ $? != 0 ]]; then
      error "unable to install homebrew, script $0 abort!"
      exit 2
  fi
else
  ok
  # Make sure we’re using the latest Homebrew
  running "updating homebrew"
  brew update
  ok
  bot "before installing brew packages, we can upgrade any outdated packages."
  read -r -p "run brew upgrade? [y|N] " response
  if [[ $response =~ ^(y|yes|Y) ]];then
      # Upgrade any already-installed formulae
      action "upgrade brew packages..."
      brew upgrade
      ok "brews updated..."
  else
      ok "skipped brew package upgrades.";
  fi
fi

#####
# install brew cask (UI Packages)
#####
running "checking brew-cask install"
output=$(brew tap | grep cask)
if [[ $? != 0 ]]; then
  action "installing brew-cask"
  require_brew caskroom/cask/brew-cask
fi
brew tap caskroom/versions > /dev/null 2>&1
ok

# skip those GUI clients, git command-line all the way
require_brew git
# need fontconfig to install/build fonts
require_brew fontconfig

running "Installing GNU core utilities (those that come with macOS are outdated)."
# Don’t forget to add `$(brew --prefix coreutils)/libexec/gnubin` to `$PATH`.
brew install coreutils

running "Installing GNU utils."
brew install moreutils
brew install findutils
brew install gnu-sed --with-default-names
running "Install Bash 4."
# Note: don’t forget to add `/usr/local/bin/bash` to `/etc/shells` before
# running `chsh`.
brew install bash
brew tap homebrew/versions
brew install bash-completion2

running "Switch to using brew-installed bash as default shell"
sudo bash -c 'echo /usr/local/bin/bash >> /etc/shells'
chsh -s /usr/local/bin/bash

running "Installing wget with IRI support."
brew install wget --with-iri

running "Installing more recent versions of some macOS tools."
brew install vim --with-override-system-vi
brew install homebrew/dupes/grep
brew install homebrew/dupes/openssh
brew install homebrew/dupes/screen

running "Installing other useful binaries."
brew install ssh-copy-id
brew install tree

running "Installing a few Cask apps."
brew cask install sublime-text
brew cask install google-chrome
brew cask install spectacle && mv-f ~/init/spectacle-Shortcuts.json ~/Library/Application Support/Spectacle/Shortcuts.json
brew cask install appcleaner
brew cask install spotify
brew cask install bartender

running "Installing Pivotal taps and PCF CLI deps."
brew tap cloudfoundry/tap
brew install cf-cli
brew install maven
brew install gpg

bot "To set the Material Theme for Sublime Text, check here:"
open https://github.com/equinusocio/material-theme

bot "Installing Mac App Store apps."
brew install mas
mas signin matt@u6.co.za
running "Installing PopClip"
mas install 445189367
running "Installing 1Password"
mas install 443987910
running "Installing Evernote"
mas install 406056744
running "Install Slack"
mas install 803453959
running "Installing iStatistica"
mas install 1025822138
running "Installing WhatsApp Desktop"
mas install 1147396723
running "Installing Amphetamine"
mas install 937984704

bot "installing fonts"
./fonts/install.sh
brew tap caskroom/fonts
require_cask font-fontawesome
require_cask font-awesome-terminal-fonts
require_cask font-hack
require_cask font-inconsolata-dz-for-powerline
require_cask font-inconsolata-g-for-powerline
require_cask font-inconsolata-for-powerline
require_cask font-roboto-mono
require_cask font-roboto-mono-for-powerline
require_cask font-source-code-pro
require_cask font-fira-code
ok

running "Remove outdated versions from the Brew cellar."
brew cleanup

running "Setting system preferences from .macos file."
source .macos
