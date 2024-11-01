#!/bin/bash

sudo_execute()
{
	# Permissions verification
	if [ "$EUID" -ne 0 ]; then
		echo "Please run the script as root using sudo."
		exit 1
	fi
}

import_config_files()
{
	# Import config files into '~/'
	if ask "Do you want to import my custom configuration files ? (y/n) "; then
# Set script and user's directories
		echo "Importing custom config files into the user's home directory..."
		echo
		echo
		SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
		USER_HOME=$(eval echo "~$SUDO_USER")

# Check existence of source directory
		if [ ! -d "$SCRIPT_DIR/dotfiles" ]; then
			echo "Error: Directory $SCRIPT_DIR/dotfiles does not exist."
			return 1
		fi

# Copy each file and check success
		for file in ".bashrc" ".bash_aliases" ".vimrc" ".zshrc"; do
			cp "$SCRIPT_DIR/dotfiles/$file" "$USER_HOME/" && echo "$file copied successfully" || echo "Failed to copy $file"
		done

		echo "Configuration files successfully copied to your home directory !"
		echo
		echo
		echo
	else
		echo
		echo
		echo
		return 0
	fi
}

ask()
{
	while true; do
		read -p "$1 (y/n): " -n 1 -r first_reply
		echo

		if [[ ! $first_reply =~ ^[YyNn]$ ]]; then
			echo "Invalid input. Please enter 'y' for Yes or 'n' for No."
			echo
			continue
		fi

		read -p "Please confirm (same answer as before (y/n) : " -n 1 -r second_reply
		echo

		if [[ ! $second_reply =~ ^[YyNn]$ ]]; then
			echo "Invalid input. Please enter 'y' for Yes or 'n' for No."
			echo
			continue
		fi

		if [[ ! "${first_reply,,}" == "${second_reply,,}" ]]; then
			echo "The answers do not match. Please try again."
			echo
			continue
		fi

		if [[ ${first_reply,,} == "y" ]]; then
			return 0
		else
			return 1
		fi
	done
}

update_system()
{
	# Updating the system
	echo "Updating package lists and upgrading installed packages...
	
	"
	sudo apt update -y
	echo
	sudo apt upgrade -y
	echo
	echo
	echo
}

install_essential()
{
	# Install essential programs
	echo "Installing essential programs : bat, tree, git, vim, curl, wget, zsh, build-essential"
	echo
	echo
	sudo apt install -y bat tree git vim curl wget zsh build-essential
	echo
	echo
	echo
}

add_aliases()
{
	echo
	if ask "Do you want to use some of my custom aliases (choice possible for each alias) ? (y/n) "; then
	# Configure personnal aliases
		echo
		echo "Setting up custom aliases..."
		echo
		echo "#My aliases (import from autosetup project)\n" >> ~/.zshrc
		echo

		if ask "Do you want to use 'bat' for 'batcat' ? (y/n) "; then
			echo
			echo "alias bat='batcat'" >> ~/.zshrc
		fi
		
		if ask "Do you want to use 'update' for 'sudo apt-get update' ? (y/n) "; then
			echo
			echo "alias update='sudo apt-get update'" >> ~/.zshrc
		fi

		if ask "Do you want to use 'upgrade' for 'sudo apt-get upgrade' ? (y/n) "; then
			echo
			echo "alias upgrade='sudo apt-get upgrade'" >> ~/.zshrc
		fi

		if ask "Do you want to use 'norm' for 'norminette -R CheckForbiddenSourceHeader' ? (y/n) "; then
			echo
			echo "alias norm='norminette -R CheckForbiddenSourceHeader'" >> ~/.zshrc
		fi

		if ask "Do you want to use 'wnorm' for 'watch norminette -R CheckForbiddenSourceHeader' ? (y/n) "; then
			echo
			echo "alias wnorm='watch norminette -R CheckForbiddenSourceHeader'" >> ~/.zshrc
		fi

		if ask "Do you want to use 'ccf' for 'cc -Werror -Wextra -Wall' ? (y/n) "; then
			echo
			echo "alias ccf='cc -Werror -Wextra -Wall'" >> ~/.zshrc
		fi

		echo "Creation of custom aliases completed ! (see them in ~/.zshrc)"
	else
		echo "No alias added."
	fi
	echo
	echo
	echo
}

config_git()
{
	echo "Git configuration"
	echo
	echo
	if ask "Do you want to configure git ? (y/n) "; then
		echo
	# Configure git
		echo "Configuring Git..."
		echo
		read -p "Enter your Git user name: " git_username
		read -p "Enter your Git email address: " git_email
		git config --global user.name "$git_username"
		git config --global user.email "$git_email"
		echo "Git configuration completed with username: '$git_username' and email: '$git_email'"
	else
		echo "Git has not been configured with your information. (You can do it later with 'git config --global user.name' and 'git config --global user.email'"
	fi
	echo
	echo
	echo
}

setup_ohmyzsh()
{
	echo "Setting up OhMyZsh"
	echo
	echo
	if ask "Do you want to use (and setup) OhMyZsh ? (y/n) "; then
# Set Zsh as default terminal
		echo
		echo "Configure Zsh as default terminal..."
		echo
		if [ "$SHELL" != "/bin/zsh" ]; then
			chsh -s /bin/zsh
			echo "Zsh is now the default terminal !"
			echo
		fi

# Configure terminal with Oh-My-Zsh
		echo "Configure terminal with Oh-My-Zsh..."
		echo
		if [ ! -d "$HOME/.oh-my-zsh" ]; then
			sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
# Reload zsh configuration to apply changes
			source ~/.zshrc
			echo "Configuration changes are applied in this terminal, but you have to 
close it and reopen it to apply changes for next times."
		fi
	else
		echo "OhMyZsh installation and configuration cancelled."
	fi
	echo
	echo
	echo
}

personnalize_terminal()
{
	if ask "Do you want to use my personal terminal profile ? (background transparency) (y/n) "; then
	# Configure terminal background transparency
		echo "Configure terminal background transparency..."
		echo
# Get default terminal profile UUID
		DEFAULT_PROFILE=$(gsettings get org.gnome.Terminal.ProfilesList default | tr -d \')

# Disable use of system theme colors
		dconf write /org/gnome/terminal/legacy/profiles:/:$DEFAULT_PROFILE/use-theme-colors false

# Enable background transparency
		dconf write /org/gnome/terminal/legacy/profiles:/:$DEFAULT_PROFILE/use-transparent-background true

# Set transparency level
		dconf write /org/gnome/terminal/legacy/profiles:/:$DEFAULT_PROFILE/background-transparency-percent 13
		echo "Transparency of background terminal set to 13%."
	else
		echo "Terminal personalization cancelled."
	fi
	echo
	echo
	echo
}

install_norminette()
{
	if ask "Do you want to install the Holy norminette ? (y/n) "; then
	# Add 'norminette' module
		echo "Adding norminette module...
		"
		sudo apt update
		sudo apt install -y python3-setuptools pipx
		pipx install norminette
		pipx ensurepath
		source ~/.zshrc
		echo "Norminette added !"
	else
		echo "The norminette module will not be installed. May the force be with you !"
	fi
	echo
	echo
	echo
}

install_firefox()
{
	if ask "Do you want to install Firefox in .deb version ? (y/n) "; then
	# Install firefox in .deb version (or tranfer the snap firefox version profile
	# to .deb future installation, and install it)
		echo "Starting Firefox .deb installation..."
		echo
# Check disk space for Firefox installation
		echo "Checking available disk space..."
		echo
		AVAILABLE_SPACE=$(df ~/ | grep -vE '^Filesystem' | awk '{print $4}')
		if [ "$AVAILABLE_SPACE" -lt 1048576 ]; then
			echo "Not enough disk space for Firefox installation. Installation cancelled."
			echo
			echo
			echo
			return 0
		else
			AVAILABLE_SPACE_GB=$(echo "scale=2; $AVAILABLE_SPACE/1048576" | bc)
			echo "Disk space available : $AVAILABLE_SPACE_GB GB"
			echo
			echo
		fi

# Check dependencies for Firefox installation
		echo "Checking dependencies for Firefox installation..."
		echo
		sudo apt-get install firefox --dry-run
		echo
		echo
# Ask for confirmation to proceed with the installation
		if ask "Do you want to proceed with the installation of Firefox ? (y/n) "; then
# Perform the actual installation of Firefox
			echo "Start of Firefox .deb installation protocol..."
			echo
# Verification and copy of snap firefox version profile
			echo "User profile transfer (from snap/flatpack to .deb)..."
			echo
			if [ -d ~/.var/app/org.mozilla.firefox/.mozilla/firefox/ ]; then
				mkdir -p ~/.mozilla/firefox/
				cp -a ~/snap/firefox/common/.mozilla/firefox/* ~/.mozilla/firefox/
				echo "Transfer of flatpack firefox version profile, done !"
			else
				echo "No such flatpack firefox version profile finded. Searching for snap one..."
			fi
			if [ -d ~/snap/firefox/common/.mozilla/firefox/ ]; then
				mkdir -p ~/.mozilla/firefox/
				cp -a ~/snap/firefox/common/.mozilla/firefox/* ~/.mozilla/firefox/
				echo "Transfer of snap firefox version profile, done !"
				echo
			else
				echo "No such snap firefox version profile finded. Let's continue !"
				echo
			fi



			echo "Save Firefox profiles for each user (for : .deb, snap, flatpack)..."

			for user_home in /home/*; do
				user_name=$(basename "$user_home")
# .deb installation profile
				profile_dir_deb="$user_home/.mozilla/firefox"
				if [ -d "$profile_dir_deb" ]; then
					backup_dir="$user_home/.mozilla/firefox_backup_$(date +%Y%m%d)"
					echo "Profile (.deb) of $user_name saved in $backup_dir !"
					cp -a "$profile_dir_deb" "$backup_dir"
				fi
# Snap installation profile
				profile_dir_snap="$user_home/snap/firefox/common/.mozilla/firefox"
				if [ -d "$profile_dir_snap" ]; then
					backup_dir="$user_home/snap/firefox/common/.mozilla/firefox_backup_$(date +%Y%m%d)"
					echo "Profile (snap) of $user_name saved in $backup_dir !"
					cp -a "$profile_dir_snap" "$backup_dir"
				fi
	# Flatpak installation profile
				profile_dir_flatpak="$user_home/.var/app/org.mozilla.firefox/.mozilla/firefox"
				if [ -d "$profile_dir_flatpak" ]; then
					backup_dir="$user_home/.var/app/org.mozilla.firefox/.mozilla/firefox_backup_$(date +%Y%m%d)"
					echo "Profile (flatpack) of $user_name saved in $backup_dir !"
					cp -a "$profile_dir_flatpak" "$backup_dir"
				fi
			done
			echo "Sauvegarde des profils terminée."













# Update and install necessary dependencies
			echo "Install necessary dependencies..."
			echo
			sudo apt-get update
			echo
			sudo apt-get install -y curl wget apt-transport-https dirmngr ca-certificates
			echo
			echo
			echo "Needed dependencies are now installed !"
			echo

# Remove snap and/or flatpack version of firefox, and clean up any previous .deb installations
			echo "Removing snap and flatpack versions of firefox, and clean up any previous .deb installations..."
			echo
			if ! sudo snap remove --purge firefox; then
				echo "Error : Firefox Snap removal failed. Please check manually."
			else
				echo "Firefox Snap version removed with success !"
			fi
			echo
			echo "Removing flatpack version..."
			echo
			
			if ! sudo flatpak uninstall --delete-data org.mozilla.firefox; then
				echo "Error : Firefox Flatpak removal failed. Please check manually."
			else
				echo "Firefox Flatpack version removed with success !"
			echo
			
			if ! sudo apt purge firefox; then
				echo "Error: Firefox .deb removal failed. Please check manually."
			else
				echo "Previous firefox .deb version removed with success !"
			fi
			echo
			echo
			echo

# Configure the official Mozilla repository
			echo "Create a directory to store APT repository keys if it doesn't already exist..."
			sudo install -d -m 0755 /etc/apt/keyrings
			echo "Directory created. Let's continue !"
			echo
			echo
			echo "Import signing keys from Mozilla APT repository..."
			wget -q https://packages.mozilla.org/apt/repo-signing-key.gpg -O- | sudo tee /etc/apt/keyrings/packages.mozilla.org.asc > /dev/null
			echo "Mozilla APT repository signature keys imported correctly. Let's continue !"
			echo
			echo
			echo "Digital fingerprint verification..."
			if ! sudo -u "$SUDO_USER" gpg -n -q --import --import-options import-show /etc/apt/keyrings/packages.mozilla.org.asc | awk '/pub/ { getline; gsub(/^ +| +$/, ""); if ($0 == "35BAA0B33E9EB396F59CA838C0BA5CE6DC6315A3") { print "The digital fingerprint of the key matches (" $0 ").\nLet'\''s continue!\n"; exit 0 } else { print "Key verification failure: the fingerprint (" $0 ") does not match the one due."; exit 1 } }'; then
				echo "Digital fingerprint not as expected (35BAA0B33E9EB396F59CA838C0BA5CE6DC6315A3). Firefox installation has been cancelled for security reasons."
				echo
				echo
				return 1
			fi
			echo
			echo "Add the Mozilla APT repository to your list of sources ( /etc/apt/sources.list.d/mozilla.list )..."
			if ! grep -q "^deb .\+https://packages.mozilla.org/apt" /etc/apt/sources.list.d/mozilla.list; then
				echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main" | sudo tee -a /etc/apt/sources.list.d/mozilla.list > /dev/null
				echo "Mozilla APT repository successfully added to your list of sources ( /etc/apt/sources.list.d/mozilla.list )."
			else
				echo "Mozilla APT repository is already configured in your list of sources ( /etc/apt/sources.list.d/mozilla.list )."
			fi
			echo
			echo
			echo "Configuring APT to give priority to packages from the Mozilla repository..."
			echo '
Package: *
Pin: origin packages.mozilla.org
Pin-Priority: 1000
' | sudo tee /etc/apt/preferences.d/mozilla
			echo "APT has been correctly configured to give priority to packages from the Mozilla repository. Let's continue !"
			echo
			echo
#			echo '
#			Unattended-Upgrade::Allowed-Origins:: "packages.mozilla.org:${distro_codename}";
#			' | sudo tee /etc/apt/apt.conf.d/51unattended-upgrades-firefox
#			echo "Firefox preferences and automatic updates configured !"
#			echo

# Install Firefox from official Mozilla repository
			echo "Update your package list and install the Firefox .deb package..."
			echo
			sudo apt update
			sudo apt install -y firefox
			echo
			echo "Firefox installation done !"
		else
			echo "Firefox installation cancelled."
			echo
			echo
			echo
			return 0
		fi
	else
		echo "Firefox .deb installation cancelled."
	fi
	echo
	echo
	echo

	# Execute these commands below to return to the snap version of firefox
	#sudo rm -f /etc/apt/sources.list.d/mozilla.list
	#sudo rm -f /etc/apt/preferences.d/mozilla
	#sudo rm -f /etc/apt/apt.conf.d/51unattended-upgrades-firefox
	#sudo apt-get update
	#sudo apt-get -y purge firefox
	#sudo apt-get -y install firefox
	#sudo snap install firefox
	#sudo snap refresh
}

install_discord()
{
	if ask "Do you want to install Discord in .deb version ? (y/n) "; then
	# Install the .deb version of Discord after user confirmation
	# (if storage space is sufficient and dependencies are compatible)
		echo "Discord installation..."
		echo

# Check available disk space
		echo "Checking available disk space..."
		echo
		AVAILABLE_SPACE=$(df ~/ | grep -vE '^Filesystem' | awk '{print $4}')
		if [ "$AVAILABLE_SPACE" -lt 1048576 ]; then # Minimum 1GB in KB
			echo "Not enough disk space for discord installation. Installation cancelled."
			echo
			echo
			echo
			rm ~/discord.deb
			return 0
		else
			AVAILABLE_SPACE_GB=$(echo "scale=2; $AVAILABLE_SPACE/1048576" | bc)
			echo "Disk space available : $AVAILABLE_SPACE_GB GB"
			echo
		fi

# Download the Discord .deb file
		echo "Downloading Discord .deb file..."
		echo
		wget -O ~/discord.deb "https://discord.com/api/download?platform=linux&format=deb"
		echo "Discord .deb file downloaded !"
		echo

# Download the checksum file
		echo "Downloading Discord checksum file..."
		echo
		wget -O ~/discord.deb.sha256 "https://discord.com/api/download?platform=linux&format=sha256"

# Verify checksum
		echo
		echo "Verifying file integrity..."
		echo
		sha256sum -c ~/discord.deb.sha256
		if [ $? -ne 0 ]; then
			echo "Checksum verification failed. Installation aborted."
			echo
			echo
			echo
			rm ~/discord.deb ~/discord.deb.sha256
			return 0
		else
			echo "Checksum verification is valid. Let's continue !"
			echo
			rm ~/discord.deb.sha256
		fi

# Check dependencies with a dry-run installation
		echo "Checking required dependencies (see the result of virtual installation 
below, before validating installation)..."
		echo
		echo
		sudo apt install ~/discord.deb --dry-run
		echo
		echo

# Ask for confirmation to proceed with the installation
		if ask "Do you want to proceed with the installation of Discord? (y/n) "; then
# Perform the actual installation of Discord
			echo "Discord will be installed..."
			echo
			echo
			sudo apt install -y ~/discord.deb
# Remove the downloaded .deb file
			rm ~/discord.deb
			echo
			echo
			echo "Discord installation completed successfully."
		else
			echo "Installation cancelled."
			rm ~/discord.deb
			echo
			echo
			echo
			return 0
		fi
	else
		echo "Discord installation cancelled."
	fi
	echo
	echo
	echo
	echo
}

sudo_execute
update_system
import_config_files
install_essential
config_git
setup_ohmyzsh
personnalize_terminal
install_norminette
install_firefox
install_discord
add_aliases

echo "Configuration changes are applied in this terminal. Please close 
and re-open the terminal to apply changes for future sessions."

