#!/bin/zsh

. .dotfiles/init/arch/utilities.sh

# Zsh
if [[ $SHELL != /bin/zsh ]]; then
  echo Installing zsh
  if [[ $(which zsh) == "" ]]; then
    sudo pacman -S zsh
  fi
  chsh -s /bin/zsh
  echo Done
  echo Effect will not commit until restarting the terminal
else
  echo zsh in use
fi

# Yay
if [[ $(which yay) == "" ]]; then
  install_yay
else
  echo Yay installed
fi

sudo rm /etc/systemd/system/wallpaper.service
sudo rm /etc/systemd/system/wallpaper.timer
sudo rm /etc/systemd/system/wallpaper.sh
sudo rm -r /etc/systemd/system/wallpapers
sudo cp .dotfiles/arch/wallpaper.service /etc/systemd/system/wallpaper.service
sudo cp .dotfiles/arch/wallpaper.timer /etc/systemd/system/wallpaper.timer
sudo cp .dotfiles/arch/wallpaper.sh /etc/systemd/system/wallpaper.sh
sudo mkdir /etc/systemd/system/wallpapers
sudo cp .dotfiles/arch/wallpapers/* /etc/systemd/system/wallpapers
sudo mkdir /etc/systemd/system/getty@tty1.service.d
sudo cp .dotfiles/arch/autologin.conf /etc/systemd/system/getty@tty1.service.d/autologin.conf
systemctl enable wallpaper.timer
systemctl start wallpaper.timer

sudo pacman -Syu
sudo pacman -S --noconfirm exa bat ripgrep fd fzf neovim alacritty i3-wm xorg xorg-xinit xorg-server i3lock i3status rofi pulseaudio pavucontrol firefox feh spotify-launcher i3blocks nodejs python ipython python-pip nerd-fonts vlc thunar thunar-volman ark thunar-archive-plugin gvfs htop nvtop neofetch flameshot
for pkg in visual-studio-code-bin i3lock-color micromamba nvm spicetify-cli networkmanager-dmenu-git; do
  if ! yay -Q $pkg &>/dev/null; then
    yay -S --noconfirm $pkg
  else
    echo "$pkg is already installed"
  fi
done

echo "Would you like to apply the catppuccino theme to Spotify? (y/n)"
read -r response
if [[ $response == "y" ]]; then
  spicetify config current_theme catppuccino
  spicetify config color_scheme macchiato
  spicetify config inject_css 1 inject_theme_js 1 replace_colors 1 overwrite_assets 1
  spicetify apply
fi
