#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR=$(dirname "$(realpath "$0")")
cd "$SCRIPT_DIR"

username=piyush

# Hostname
while true; do
  read -p "Hostname: " hostname
  if [[ ! "$hostname" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?$ ]]; then
    echo "Invalid hostname. Use 1-63 letters, digits, or hyphens (not starting or ending with hyphen)."
    continue
  fi
  break
done
sudo hostnamectl set-hostname "$hostname"
sudo sed -i "s/^127\.0\.1\.1.*/127.0.1.1    $hostname/" /etc/hosts

# Which type of install?
# First choice: vm or hardware
echo "Choose one:"
select hardware in "vm" "hardware"; do
  [[ -n $hardware ]] && break
  echo "Invalid choice. Please select 1 for vm or 2 for hardware."
done

# extra choice: laptop or bluetooth or none
if [[ "$hardware" == "hardware" ]]; then
  echo "Choose one:"
  select extra in "laptop" "bluetooth" "none"; do
    [[ -n $extra ]] && break
    echo "Invalid choice."
  done
else
  extra="none"
fi

# Which type of packages?
# Main package selection
case "$hardware" in
vm)
  sed -n '1p;2p' pkgs.txt | tr ' ' '\n' | grep -v '^$' >>pkglist.txt
  ;;
hardware)
  sed -n '1,3p' pkgs.txt | tr ' ' '\n' | grep -v '^$' >>pkglist.txt
  ;;
esac

# For hardware:max, add lines 5 and/or 6 based on $extra
if [[ "$hardware" == "hardware" ]]; then
  case "$extra" in
  laptop)
    sed -n '4,5p' pkgs.txt | tr ' ' '\n' | grep -v '^$' >>pkglist.txt
    ;;
  bluetooth)
    sed -n '4p' pkgs.txt | tr ' ' '\n' | grep -v '^$' >>pkglist.txt
    ;;
  none) ;;
  esac
fi

# sudo zypper ar -f https://download.opensuse.org/repositories/devel:languages:python/openSUSE_Tumbleweed/devel:languages:python.repo
# sudo zypper ar -f http://codecs.opensuse.org/openh264/openSUSE_Tumbleweed repo-openh264
sudo zypper --gpg-auto-import-keys ar -cf obs://home:iDesmI ananicy-cpp
sudo zypper --gpg-auto-import-keys ar -cfp 90 http://ftp.gwdg.de/pub/linux/misc/packman/suse/openSUSE_Tumbleweed/ packman
sudo zypper --gpg-auto-import-keys refresh
sudo zypper rr repo-openh264
sudo zypper ref -f
sudo zypper dup --from packman --allow-vendor-change

xargs -a pkglist.txt sudo zypper install -y

sudo npm install -g corepack@latest
corepack enable
corepack prepare pnpm@latest --activate
pipx ensurepath
pipx install thefuck

